import * as RbAbi from "./bindgen/rb-abi-guest";
import { addRbJsAbiHostToImports, JsAbiValue } from "./bindgen/rb-js-abi-host";

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
  private exporter: JsValueExporter;
  private exceptionFormatter: RbExceptionFormatter;

  constructor() {
    this.guest = new RbAbi.RbAbiGuest();
    this.exporter = new JsValueExporter();
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
    addRbJsAbiHostToImports(
      imports,
      {
        evalJs: (code) => {
          return Function(code)();
        },
        isJs: (value) => {
          return value == null || !(value instanceof RbValue);
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
        jsValueToString: (value) => {
          return value.toString();
        },
        takeJsValue: (value) => {
          this.exporter.takeJsValue(value);
        },
        instanceOf: (value, klass) => {
          if (typeof klass === "function") {
            return value instanceof klass;
          } else {
            return false;
          }
        },
        reflectApply: function (target, thisArgument, args) {
          return Reflect.apply(target as any, thisArgument, args);
        },
        reflectConstruct: function (target, args) {
          throw new Error("Function not implemented.");
        },
        reflectDeleteProperty: function (target, propertyKey): boolean {
          throw new Error("Function not implemented.");
        },
        reflectGet: function (target, propertyKey) {
          return Reflect.get(target, propertyKey);
        },
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
        reflectSet: function (target, propertyKey, value): boolean {
          return Reflect.set(target, propertyKey, value);
        },
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
    return evalRbCode(this, { exporter: this.exporter, exceptionFormatter: this.exceptionFormatter }, code);
  }
}

class JsValueExporter {
  private _takenJsValues: JsAbiValue = null;
  takeJsValue(value: JsAbiValue) {
    this._takenJsValues = value;
  }
  exportJsValue(): JsAbiValue {
    return this._takenJsValues;
  }
}

/**
 * A RbValue is an object that represents a value in Ruby
 */
export class RbValue {
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
    jsValue.call("__export_to_js");
    return this.privateObject.exporter.exportJsValue();
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
  exporter: JsValueExporter,
  exceptionFormatter: RbExceptionFormatter,
};


class RbExceptionFormatter {
  private literalsCache: [RbValue, RbValue, RbValue] | null = null;

  format(error: RbValue, vm: RubyVM, privateObject: RubyVMPrivate): string {
    const [zeroLiteral, oneLiteral, newLineLiteral] = (() => {
      if (this.literalsCache == null) {
        const zeroOneNewLine: [RbValue, RbValue, RbValue] = [
          evalRbCode(vm, privateObject, "0"),
          evalRbCode(vm, privateObject, "1"),
          evalRbCode(vm, privateObject, `"\n"`)
        ];
        this.literalsCache = zeroOneNewLine;
        return zeroOneNewLine;
      } else {
        return this.literalsCache;
      }
    })();

    const backtrace = error.call("backtrace");
    const firstLine = backtrace.call("at", zeroLiteral);
    const restLines = backtrace.call("drop", oneLiteral).call("join", newLineLiteral);
    return this.formatString(error.call("class").toString(), error.toString(), [
      firstLine.toString(),
      restLines.toString(),
    ])
  }

  formatString(
    klass: string,
    message: string,
    backtrace: [string, string]
  ): string {
    return `${backtrace[0]}: ${message} (${klass})\n${backtrace[1]}`;
  };
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
      throw new RbError(privateObject.exceptionFormatter.format(error, vm, privateObject));
    default:
      throw new RbError(`unknown error tag: ${rawTag}`);
  }
};

const callRbMethod = (
  vm: RubyVM,
  privateObject: RubyVMPrivate,
  recv: RbAbi.RbAbiValue,
  callee: string,
  args: RbAbi.RbAbiValue[]
) => {
  const mid = vm.guest.rbIntern(callee + "\0");
  const [value, status] = vm.guest.rbFuncallvProtect(recv, mid, args);
  checkStatusTag(status, vm, privateObject);
  return value;
};
const evalRbCode = (vm: RubyVM, privateObject: RubyVMPrivate, code: string) => {
  const [value, status] = vm.guest.rbEvalStringProtect(code + "\0");
  checkStatusTag(status, vm, privateObject);
  return new RbValue(value, vm, privateObject);
};

/**
 * Error class thrown by Ruby execution
 */
export class RbError extends Error {
  constructor(message: string) {
    super(message);
  }
}
