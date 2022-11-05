import * as RbAbi from "./bindgen/rb-abi-guest";
import {
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

  constructor() {
    this.guest = new RbAbi.RbAbiGuest();
    this.transport = new JsValueTransport();
    this.exceptionFormatter = new RbExceptionFormatter();
  }

  /**
   * Initialize the Ruby VM with the given command line arguments
   * @param args The command line arguments to pass to Ruby. Must be
   * an array of strings starting with the Ruby program name.
   */
  initialize(args: string[] = ["ruby.wasm", "--disable-gems", "-e_=0"]) {
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
    await this.guest.instantiate(instance);
  }

  /**
   * Add intrinsic import entries, which is necessary to interact JavaScript
   * and Ruby's WebAssembly instance.
   * @param imports The import object to add to the WebAssembly instance
   */
  addToImports(imports: WebAssembly.Imports) {
    this.guest.addToImports(imports);
    function wrapTry(f: (...args: any[]) => JsAbiValue): () => JsAbiResult {
      return (...args) => {
        try {
          return { tag: "success", val: f(...args) };
        } catch (e) {
          return { tag: "failure", val: e };
        }
      };
    }
    addRbJsAbiHostToImports(
      imports,
      {
        evalJs: wrapTry((code) => {
          return Function(code)();
        }),
        isJs: (value) => {
          // Just for compatibility with the old JS API
          return true;
        },
        globalThis: () => {
          if (typeof globalThis !== "undefined") {
            return globalThis;
          } else if (typeof global !== "undefined") {
            return global;
          } else if (typeof window !== "undefined") {
            return window;
          }
          throw new Error("unable to locate global object");
        },
        intToJsNumber: (value) => {
          return value;
        },
        stringToJsString: (value) => {
          return value;
        },
        boolToJsBool: (value) => {
          return value;
        },
        procToJsFunction: (rawRbAbiValue) => {
          const rbValue = this.rbValueofPointer(rawRbAbiValue);
          return (...args) => {
            rbValue.call("call", ...args.map((arg) => this.wrap(arg)));
          };
        },
        rbObjectToJsRbValue: (rawRbAbiValue) => {
          return this.rbValueofPointer(rawRbAbiValue);
        },
        jsValueToString: (value) => {
          // According to the [spec](https://tc39.es/ecma262/multipage/text-processing.html#sec-string-constructor-string-value)
          // `String(value)` always returns a string.
          return String(value);
        },
        jsValueToInteger(value) {
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
        exportJsValueToHost: (value) => {
          // See `JsValueExporter` for the reason why we need to do this
          this.transport.takeJsValue(value);
        },
        importJsValueFromHost: () => {
          return this.transport.consumeJsValue();
        },
        instanceOf: (value, klass) => {
          if (typeof klass === "function") {
            return value instanceof klass;
          } else {
            return false;
          }
        },
        jsValueTypeof(value) {
          return typeof value;
        },
        jsValueEqual(lhs, rhs) {
          return lhs == rhs;
        },
        jsValueStrictlyEqual(lhs, rhs) {
          return lhs === rhs;
        },
        reflectApply: wrapTry((target, thisArgument, args) => {
          return Reflect.apply(target as any, thisArgument, args);
        }),
        reflectConstruct: function (target, args) {
          throw new Error("Function not implemented.");
        },
        reflectDeleteProperty: function (target, propertyKey): boolean {
          throw new Error("Function not implemented.");
        },
        reflectGet: wrapTry((target, propertyKey) => {
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
        reflectSet: wrapTry((target, propertyKey, value) => {
          return Reflect.set(target, propertyKey, value);
        }),
        reflectSetPrototypeOf: function (target, prototype): boolean {
          throw new Error("Function not implemented.");
        },
      },
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

  evalAsync(code: string): Promise<RbValue> {
    const JS = this.eval("require 'js'; JS");
    return new Promise((resolve, reject) => {
      JS.call(
        "eval_async",
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
    return this.transport.importJsValue(value, this);
  }

  private privateObject(): RubyVMPrivate {
    return {
      transport: this.transport,
      exceptionFormatter: this.exceptionFormatter,
    };
  }

  private rbValueofPointer(pointer: number): RbValue {
    const abiValue = new (RbAbi.RbAbiValue as any)(pointer, this.guest);
    return new RbValue(abiValue, this, this.privateObject());
  }
}

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
  ) {}

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
    return new RbValue(
      callRbMethod(this.vm, this.privateObject, this.inner, callee, innerArgs),
      this.vm,
      this.privateObject
    );
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
    return this.vm.guest.rstringPtr(rbString);
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
    return this.privateObject.transport.exportJsValue(jsValue);
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
    if (e instanceof WebAssembly.RuntimeError && e.message === "unreachable") {
      vm.guest.rbVmBugreport();
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
    const [value, status] = vm.guest.rbFuncallvProtect(recv, mid, args);
    checkStatusTag(status, vm, privateObject);
    return value;
  });
};
const evalRbCode = (vm: RubyVM, privateObject: RubyVMPrivate, code: string) => {
  return wrapRbOperation(vm, () => {
    const [value, status] = vm.guest.rbEvalStringProtect(code + "\0");
    checkStatusTag(status, vm, privateObject);
    return new RbValue(value, vm, privateObject);
  });
};

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
