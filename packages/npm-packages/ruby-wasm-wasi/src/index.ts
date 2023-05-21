import * as RbAbi from "./bindgen/rb-abi-guest";
import {
  RbJsAbiHost,
  addRbJsAbiHostToImports,
  JsAbiResult,
  JsAbiValue,
} from "./bindgen/rb-js-abi-host";

/**
 * A Ruby VM instance
 *
 * @example
 *
 * const wasi = new WASI();
 * const vm = new RubyVM();
 * const imports = {
 *   wasi_snapshot_preview1: wasi.wasiImport,
 * };
 *
 * vm.addToImports(imports);
 *
 * const instance = await WebAssembly.instantiate(rubyModule, imports);
 * await vm.setInstance(instance);
 * wasi.initialize(instance);
 * vm.initialize();
 *
 */
export class RubyVM {
  guest: RbAbi.RbAbiGuest;
  private instance: WebAssembly.Instance | null = null;
  private transport: JsValueTransport;
  private exceptionFormatter: RbExceptionFormatter;
  private guestObjectTracker: RbValueLifetimeTracker<RbAbi.RbAbiValue> | null = null;
  private hostObjectTracker: JsValueLifetimeTracker<any> = new JsValueLifetimeTracker();
  private interfaceState: RbAbiInterfaceState = {
    hasJSFrameAfterRbFrame: false,
  };

  constructor() {
    // Wrap exported functions from Ruby VM to prohibit nested VM operation
    // if the call stack has sandwitched JS frames like JS -> Ruby -> JS -> Ruby.
    const proxyExports = (exports: RbAbi.RbAbiGuest) => {
      const excludedMethods: (keyof RbAbi.RbAbiGuest)[] = [
        "addToImports",
        "instantiate",
        "rbSetShouldProhibitRewind",
        "rbGcDisable",
        "rbGcEnable",
      ];
      const excluded = ["constructor"].concat(excludedMethods);
      // wrap all methods in RbAbi.RbAbiGuest class
      for (const key of Object.getOwnPropertyNames(
        RbAbi.RbAbiGuest.prototype
      )) {
        if (excluded.includes(key)) {
          continue;
        }
        const value = exports[key];
        if (typeof value === "function") {
          exports[key] = (...args: any[]) => {
            const isNestedVMCall = this.interfaceState.hasJSFrameAfterRbFrame;
            if (isNestedVMCall) {
              const oldShouldProhibitRewind =
                this.guest.rbSetShouldProhibitRewind(true);
              const oldIsDisabledGc = this.guest.rbGcDisable();
              const result = Reflect.apply(value, exports, args);
              this.guest.rbSetShouldProhibitRewind(oldShouldProhibitRewind);
              if (!oldIsDisabledGc) {
                this.guest.rbGcEnable();
              }
              return result;
            } else {
              return Reflect.apply(value, exports, args);
            }
          };
        }
      }
      return exports;
    };
    this.guest = proxyExports(new RbAbi.RbAbiGuest());
    this.transport = new JsValueTransport();
    this.exceptionFormatter = new RbExceptionFormatter();
  }

  /**
   * Initialize the Ruby VM with the given command line arguments
   * @param args The command line arguments to pass to Ruby. Must be
   * an array of strings starting with the Ruby program name.
   */
  initialize(
    args: string[] = ["ruby.wasm", "--disable-gems", "-EUTF-8", "-e_=0"]
  ) {
    const c_args = args.map((arg) => arg + "\0");
    this.guest.rubyInit();
    this.guest.rubySysinit(c_args);
    this.guest.rubyOptions(c_args);
  }

  /**
   * Set a given instance to interact JavaScript and Ruby's
   * WebAssembly instance. This method must be called before calling
   * Ruby API.
   *
   * @param instance The WebAssembly instance to interact with. Must
   * be instantiated from a Ruby built with JS extension, and built
   * with Reactor ABI instead of command line.
   */
  async setInstance(instance: WebAssembly.Instance) {
    this.instance = instance;
    this.guestObjectTracker = new RbValueLifetimeTracker((rbAbiValue) => {
      this.guest.dropRbValue(rbAbiValue);
    });
    await this.guest.instantiate(instance);
  }

  /**
   * Add intrinsic import entries, which is necessary to interact JavaScript
   * and Ruby's WebAssembly instance.
   * @param imports The import object to add to the WebAssembly instance
   */
  addToImports(imports: WebAssembly.Imports) {
    this.guest.addToImports(imports);
    const wrapTry = (f: (...args: any[]) => any): (...args: any[]) => JsAbiResult => {
      return (...args: any[]) => {
        try {
          return { tag: "success", val: this.hostObjectTracker.insert(f(...args)) };
        } catch (e) {
          if (e instanceof RbFatalError) {
            // RbFatalError should not be caught by Ruby because it Ruby VM
            // can be already in an inconsistent state.
            throw e;
          }
          return { tag: "failure", val: this.hostObjectTracker.insert(e) };
        }
      };
    }
    imports["rb-js-abi-host"] = {
      rb_wasm_throw_prohibit_rewind_exception: (
        messagePtr: number,
        messageLen: number
      ) => {
        const memory = this.instance.exports.memory as WebAssembly.Memory;
        const str = new TextDecoder().decode(
          new Uint8Array(memory.buffer, messagePtr, messageLen)
        );
        throw new RbFatalError(
          "Ruby APIs that may rewind the VM stack are prohibited under nested VM operation " +
            `(${str})\n` +
            "Nested VM operation means that the call stack has sandwitched JS frames like JS -> Ruby -> JS -> Ruby " +
            "caused by something like `window.rubyVM.eval(\"JS.global[:rubyVM].eval('Fiber.yield')\")`\n" +
            "\n" +
            "Please check your call stack and make sure that you are **not** doing any of the following inside the nested Ruby frame:\n" +
            "  1. Switching fibers (e.g. Fiber#resume, Fiber.yield, and Fiber#transfer)\n" +
            "     Note that `evalAsync` JS API switches fibers internally\n" +
            "  2. Raising uncaught exceptions\n" +
            "     Please catch all exceptions inside the nested operation\n" +
            "  3. Calling Continuation APIs\n"
        );
      },
    };
    // NOTE: The GC may collect objects that are still referenced by Wasm
    // locals because Asyncify cannot scan the Wasm stack above the JS frame.
    // So we need to keep track whether the JS frame is sandwitched by Ruby
    // frames or not, and prohibit nested VM operation if it is.
    const proxyImports = (imports: RbJsAbiHost) => {
      for (const [key, value] of Object.entries(imports)) {
        if (typeof value === "function") {
          imports[key] = (...args: any[]) => {
            const oldValue = this.interfaceState.hasJSFrameAfterRbFrame;
            this.interfaceState.hasJSFrameAfterRbFrame = true;
            const result = Reflect.apply(value, imports, args);
            this.interfaceState.hasJSFrameAfterRbFrame = oldValue;
            return result;
          };
        }
      }
      return imports;
    };

    addRbJsAbiHostToImports(
      imports,
      proxyImports({
        dropJsValue: (value) => {
          this.hostObjectTracker.remove(value);
        },
        evalJs: wrapTry((code) => {
          return Function(code)();
        }),
        isJs: (value) => {
          // Just for compatibility with the old JS API
          return true;
        },
        globalThis: () => {
          let result: any;
          if (typeof globalThis !== "undefined") {
            result = globalThis;
          } else if (typeof global !== "undefined") {
            result = global;
          } else if (typeof window !== "undefined") {
            result = window;
          } else {
            throw new Error("unable to locate global object");
          }
          return this.hostObjectTracker.insert(result);
        },
        intToJsNumber: (value) => {
          return this.hostObjectTracker.insert(value);
        },
        floatToJsNumber: (value) => {
          return this.hostObjectTracker.insert(value);
        },
        stringToJsString: (value) => {
          return this.hostObjectTracker.insert(value);
        },
        boolToJsBool: (value) => {
          return this.hostObjectTracker.insert(value);
        },
        procToJsFunction: (rawRbAbiValue) => {
          const rbProcValue = this.rbValueOfPointer(rawRbAbiValue);
          return this.hostObjectTracker.insert((...args: any[]) => {
            rbProcValue.call("call", ...args.map((arg) => this.wrap(arg)));
          });
        },
        rbObjectToJsRbValue: (rawRbAbiValue) => {
          return this.hostObjectTracker.insert(this.rbValueOfPointer(rawRbAbiValue));
        },
        jsValueToString: (value) => {
          // According to the [spec](https://tc39.es/ecma262/multipage/text-processing.html#sec-string-constructor-string-value)
          // `String(value)` always returns a string.
          return String(this.hostObjectTracker.get(value));
        },
        jsValueToInteger(v) {
          const value = this.hostObjectTracker.get(v);
          if (typeof value === "number") {
            return { tag: "f64", val: value };
          } else if (typeof value === "bigint") {
            return { tag: "bignum", val: BigInt(value).toString(10) + "\0" };
          } else if (typeof value === "string") {
            return { tag: "bignum", val: value + "\0" };
          } else if (typeof value === "undefined") {
            return { tag: "f64", val: 0 };
          } else {
            return { tag: "f64", val: Number(value) };
          }
        },
        exportJsValueToHost: (v) => {
          // See `JsValueExporter` for the reason why we need to do this
          const value = this.hostObjectTracker.get(v);
          this.transport.takeJsValue(value);
        },
        importJsValueFromHost: () => {
          return this.transport.consumeJsValue();
        },
        instanceOf: (rawValue, rawKlass) => {
          const value = this.hostObjectTracker.get(rawValue);
          const klass = this.hostObjectTracker.get(rawKlass);
          if (typeof klass === "function") {
            return value instanceof klass;
          } else {
            return false;
          }
        },
        jsValueTypeof: (value) => {
          return typeof this.hostObjectTracker.get(value);
        },
        jsValueEqual: (lhs, rhs) => {
          return this.hostObjectTracker.get(lhs) == this.hostObjectTracker.get(rhs);
        },
        jsValueStrictlyEqual: (lhs, rhs) => {
          return this.hostObjectTracker.get(lhs) === this.hostObjectTracker.get(rhs);
        },
        reflectApply: wrapTry((rawTarget, rawThisArgument, rawArgs: Uint32Array) => {
          const target = this.hostObjectTracker.get(rawTarget);
          const thisArgument = this.hostObjectTracker.get(rawThisArgument);
          const args = rawArgs.map((arg) => this.hostObjectTracker.get(arg));
          return Reflect.apply(target as any, thisArgument, args);
        }),
        reflectConstruct: function (target, args) {
          throw new Error("Function not implemented.");
        },
        reflectDeleteProperty: function (target, propertyKey): boolean {
          throw new Error("Function not implemented.");
        },
        reflectGet: wrapTry((rawTarget, propertyKey) => {
          const target = this.hostObjectTracker.get(rawTarget);
          return target[propertyKey];
        }),
        reflectGetOwnPropertyDescriptor: function (
          target,
          propertyKey: string
        ) {
          throw new Error("Function not implemented.");
        },
        reflectGetPrototypeOf: function (target) {
          throw new Error("Function not implemented.");
        },
        reflectHas: function (target, propertyKey): boolean {
          throw new Error("Function not implemented.");
        },
        reflectIsExtensible: function (target): boolean {
          throw new Error("Function not implemented.");
        },
        reflectOwnKeys: function (target) {
          throw new Error("Function not implemented.");
        },
        reflectPreventExtensions: function (target): boolean {
          throw new Error("Function not implemented.");
        },
        reflectSet: wrapTry((rawTarget, rawPropertyKey, rawValue) => {
          const target = this.hostObjectTracker.get(rawTarget);
          const propertyKey = this.hostObjectTracker.get(rawPropertyKey);
          const value = this.hostObjectTracker.get(rawValue);
          return Reflect.set(target, propertyKey, value);
        }),
        reflectSetPrototypeOf: function (target, prototype): boolean {
          throw new Error("Function not implemented.");
        },
      }),
      (name) => {
        return this.instance.exports[name];
      }
    );
  }

  /**
   * Print the Ruby version to stdout
   */
  printVersion() {
    this.guest.rubyShowVersion();
  }

  /**
   * Runs a string of Ruby code from JavaScript
   * @param code The Ruby code to run
   * @returns the result of the last expression
   *
   * @example
   * vm.eval("puts 'hello world'");
   * const result = vm.eval("1 + 2");
   * console.log(result.toString()); // 3
   *
   */
  eval(code: string): RbValue {
    return evalRbCode(this, this.privateObject(), code);
  }

  /**
   * Runs a string of Ruby code with top-level `JS::Object#await`
   * Returns a promise that resolves when execution completes.
   * @param code The Ruby code to run
   * @returns a promise that resolves to the result of the last expression
   *
   * @example
   * const text = await vm.evalAsync(`
   *   require 'js'
   *   response = JS.global.fetch('https://example.com').await
   *   response.text.await
   * `);
   * console.log(text.toString()); // <html>...</html>
   */
  evalAsync(code: string): Promise<RbValue> {
    const JS = this.eval("require 'js'; JS");
    return new Promise((resolve, reject) => {
      JS.call(
        "__eval_async_rb",
        this.wrap(code),
        this.wrap({
          resolve,
          reject: (error: RbValue) => {
            reject(
              new RbError(
                this.exceptionFormatter.format(
                  error,
                  this,
                  this.privateObject()
                )
              )
            );
          },
        })
      );
    });
  }

  /**
   * Wrap a JavaScript value into a Ruby JS::Object
   * @param value The value to convert to RbValue
   * @returns the RbValue object representing the given JS value
   *
   * @example
   * const hash = vm.eval(`Hash.new`)
   * hash.call("store", vm.eval(`"key1"`), vm.wrap(new Object()));
   */
  wrap(value: any): RbValue {
    return this.transport.importJsValue(this.hostObjectTracker.insert(value), this);
  }

  private privateObject(): RubyVMPrivate {
    return {
      transport: this.transport,
      guestObjectTracker: this.guestObjectTracker,
      hostObjectTracker: this.hostObjectTracker,
      exceptionFormatter: this.exceptionFormatter,
    };
  }

  private rbValueOfPointer(pointer: RbAbi.RbAbiValue): RbValue {
    return new RbValue(pointer, this, this.privateObject());
  }
}

type RbAbiInterfaceState = {
  /**
   * Track if the last JS frame that was created by a Ruby frame
   * to determine if we have a sandwitched JS frame between Ruby frames.
   **/
  hasJSFrameAfterRbFrame: boolean;
};

/**
 * Export a JS value held by the Ruby VM to the JS environment.
 * This is implemented in a dirty way since wit cannot reference resources
 * defined in other interfaces.
 * In our case, we can't express `function(v: rb-abi-value) -> js-abi-value`
 * because `rb-js-abi-host.wit`, that defines `js-abi-value`, is implemented
 * by embedder side (JS) but `rb-abi-guest.wit`, that defines `rb-abi-value`
 * is implemented by guest side (Wasm).
 *
 * This class is a helper to export by:
 * 1. Call `function __export_to_js(v: rb-abi-value)` defined in guest from embedder side.
 * 2. Call `function takeJsValue(v: js-abi-value)` defined in embedder from guest side with
 *    underlying JS value of given `rb-abi-value`.
 * 3. Then `takeJsValue` implementation escapes the given JS value to the `_takenJsValues`
 *    stored in embedder side.
 * 4. Finally, embedder side can take `_takenJsValues`.
 *
 * Note that `exportJsValue` is not reentrant.
 *
 * @private
 */
class JsValueTransport {
  private _takenJsValue: JsAbiValue = null;
  takeJsValue(value: JsAbiValue) {
    this._takenJsValue = value;
  }
  consumeJsValue(): JsAbiValue {
    return this._takenJsValue;
  }

  exportJsValue(value: RbValue): JsAbiValue {
    value.call("__export_to_js");
    return this._takenJsValue;
  }

  importJsValue(value: JsAbiValue, vm: RubyVM): RbValue {
    this._takenJsValue = value;
    return vm.eval('require "js"; JS::Object').call("__import_from_js");
  }
}

/**
 * A RbValue is an object that represents a value in Ruby
 */
export class RbValue {
  /**
   * @hideconstructor
   */
  constructor(
    private inner: RbAbi.RbAbiValue,
    private vm: RubyVM,
    private privateObject: RubyVMPrivate
  ) {
    this.privateObject.guestObjectTracker.track(inner);
  }

  /**
   * Call a given method with given arguments
   *
   * @param callee name of the Ruby method to call
   * @param args arguments to pass to the method. Must be an array of RbValue
   *
   * @example
   * const ary = vm.eval("[1, 2, 3]");
   * ary.call("push", 4);
   * console.log(ary.call("sample").toString());
   *
   */
  call(callee: string, ...args: RbValue[]): RbValue {
    const innerArgs = args.map((arg) => arg.inner);
    return callRbMethod(this.vm, this.privateObject, this.inner, callee, innerArgs);
  }

  /**
   * @see {@link https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/Symbol/toPrimitive}
   * @param hint Preferred type of the result primitive value. `"number"`, `"string"`, or `"default"`.
   */
  [Symbol.toPrimitive](hint: string) {
    if (hint === "string" || hint === "default") {
      return this.toString();
    } else if (hint === "number") {
      return null;
    }
    return null;
  }

  /**
   * Returns a string representation of the value by calling `to_s`
   */
  toString(): string {
    const rbString = callRbMethod(
      this.vm,
      this.privateObject,
      this.inner,
      "to_s",
      []
    );
    return this.vm.guest.rstringPtr(rbString.inner);
  }

  /**
   * Returns a JavaScript object representation of the value
   * by calling `to_js`.
   *
   * Returns null if the value is not convertible to a JavaScript object.
   */
  toJS(): any {
    const JS = this.vm.eval("JS");
    const jsValue = JS.call("try_convert", this);
    if (jsValue.call("nil?").toString() === "true") {
      return null;
    }
    const rawValue = this.privateObject.transport.exportJsValue(jsValue);
    return this.privateObject.hostObjectTracker.get(rawValue);
  }
}

enum ruby_tag_type {
  None = 0x0,
  Return = 0x1,
  Break = 0x2,
  Next = 0x3,
  Retry = 0x4,
  Redo = 0x5,
  Raise = 0x6,
  Throw = 0x7,
  Fatal = 0x8,
  Mask = 0xf,
}

type RubyVMPrivate = {
  transport: JsValueTransport;
  hostObjectTracker: JsValueLifetimeTracker<any>;
  guestObjectTracker: RbValueLifetimeTracker<RbAbi.RbAbiValue>;
  exceptionFormatter: RbExceptionFormatter;
};

class RbExceptionFormatter {
  private literalsCache: [RbValue, RbValue, RbValue] | null = null;

  format(error: RbValue, vm: RubyVM, privateObject: RubyVMPrivate): string {
    const [zeroLiteral, oneLiteral, newLineLiteral] = (() => {
      if (this.literalsCache == null) {
        const zeroOneNewLine: [RbValue, RbValue, RbValue] = [
          evalRbCode(vm, privateObject, "0"),
          evalRbCode(vm, privateObject, "1"),
          evalRbCode(vm, privateObject, `"\n"`),
        ];
        this.literalsCache = zeroOneNewLine;
        return zeroOneNewLine;
      } else {
        return this.literalsCache;
      }
    })();

    const backtrace = error.call("backtrace");
    if (backtrace.call("nil?").toString() === "true") {
      return this.formatString(
        error.call("class").toString(),
        error.toString()
      );
    }
    const firstLine = backtrace.call("at", zeroLiteral);
    const restLines = backtrace
      .call("drop", oneLiteral)
      .call("join", newLineLiteral);
    return this.formatString(error.call("class").toString(), error.toString(), [
      firstLine.toString(),
      restLines.toString(),
    ]);
  }

  formatString(
    klass: string,
    message: string,
    backtrace?: [string, string]
  ): string {
    if (backtrace) {
      return `${backtrace[0]}: ${message} (${klass})\n${backtrace[1]}`;
    } else {
      return `${klass}: ${message}`;
    }
  }
}

const checkStatusTag = (
  rawTag: number,
  vm: RubyVM,
  privateObject: RubyVMPrivate
) => {
  switch (rawTag & ruby_tag_type.Mask) {
    case ruby_tag_type.None:
      break;
    case ruby_tag_type.Return:
      throw new RbError("unexpected return");
    case ruby_tag_type.Next:
      throw new RbError("unexpected next");
    case ruby_tag_type.Break:
      throw new RbError("unexpected break");
    case ruby_tag_type.Redo:
      throw new RbError("unexpected redo");
    case ruby_tag_type.Retry:
      throw new RbError("retry outside of rescue clause");
    case ruby_tag_type.Throw:
      throw new RbError("unexpected throw");
    case ruby_tag_type.Raise:
    case ruby_tag_type.Fatal:
      const error = new RbValue(vm.guest.rbErrinfo(), vm, privateObject);
      if (error.call("nil?").toString() === "true") {
        throw new RbError("no exception object");
      }
      // clear errinfo if got exception due to no rb_jump_tag
      vm.guest.rbClearErrinfo();
      throw new RbError(
        privateObject.exceptionFormatter.format(error, vm, privateObject)
      );
    default:
      throw new RbError(`unknown error tag: ${rawTag}`);
  }
};

function wrapRbOperation<R>(vm: RubyVM, body: () => R): R {
  try {
    return body();
  } catch (e) {
    if (e instanceof RbError) {
      throw e;
    }
    // All JS exceptions triggered by Ruby code are translated to Ruby exceptions,
    // so non-RbError exceptions are unexpected.
    vm.guest.rbVmBugreport();
    if (e instanceof WebAssembly.RuntimeError && e.message === "unreachable") {
      const error = new RbError(`Something went wrong in Ruby VM: ${e}`);
      error.stack = e.stack;
      throw error;
    } else {
      throw e;
    }
  }
}

const callRbMethod = (
  vm: RubyVM,
  privateObject: RubyVMPrivate,
  recv: RbAbi.RbAbiValue,
  callee: string,
  args: RbAbi.RbAbiValue[]
) => {
  const mid = vm.guest.rbIntern(callee + "\0");
  return wrapRbOperation(vm, () => {
    const rawArgs = Uint32Array.from(args);
    const [value, status] = vm.guest.rbFuncallvProtect(recv, mid, rawArgs);
    checkStatusTag(status, vm, privateObject);
    return new RbValue(value, vm, privateObject);
  });
};
const evalRbCode = (vm: RubyVM, privateObject: RubyVMPrivate, code: string) => {
  return wrapRbOperation(vm, () => {
    const [value, status] = vm.guest.rbEvalStringProtect(code + "\0");
    checkStatusTag(status, vm, privateObject);
    return new RbValue(value, vm, privateObject);
  });
};

class LifetimeTracked<Value> {
  constructor(public value: Value) {}
}

class RbValueLifetimeTracker<Value> {
  private registry: FinalizationRegistry<Value>
  constructor(drop: (value: Value) => void) {
    this.registry = new FinalizationRegistry((value) => {
      drop(value);
    });
  }

  track(value: Value) {
    this.registry.register(new LifetimeTracked(value), value);
  }
}

type JsValueLifetimeSlot<Value> = {
  next: number;
  value: Value;
}

class JsValueLifetimeTracker<Value> {
  private list: JsValueLifetimeSlot<Value>[];
  private head: number;

  constructor() {
    this.list = [];
    this.head = 0;
  }

  insert(value: Value): JsAbiValue {
    if (this.head >= this.list.length) {
      this.list.push({
        next: this.list.length + 1,
        value: undefined,
      });
    }
    const ret = this.head;
    const slot = this.list[ret];
    this.head = slot.next;
    slot.next = -1;
    slot.value = value;
    return ret;
  }

  get(idx: JsAbiValue) {
    if (idx >= this.list.length)
      throw new RangeError('handle index not valid');
    const slot = this.list[idx];
    if (slot.next === -1)
      return slot.value;
    throw new RangeError('handle index not valid');
  }

  remove(idx: JsAbiValue) {
    const ret = this.get(idx); // validate the slot
    const slot = this.list[idx];
    slot.value = undefined;
    slot.next = this.head;
    this.head = idx;
    return ret;
  }
}

/**
 * Error class thrown by Ruby execution
 */
export class RbError extends Error {
  /**
   * @hideconstructor
   */
  constructor(message: string) {
    super(message);
  }
}

/**
 * Error class thrown by Ruby execution when it is not possible to recover.
 * This is usually caused when Ruby VM is in an inconsistent state.
 */
export class RbFatalError extends RbError {
  /**
   * @hideconstructor
   */
  constructor(message: string) {
    super("Ruby Fatal Error: " + message);
  }
}
