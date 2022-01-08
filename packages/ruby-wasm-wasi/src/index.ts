import * as RbAbi from "./bindgen/rb-js-abi-guest";
import { addRbJsAbiHostToImports } from "./bindgen/rb-js-abi-host";

/**
 * Error class thrown by Ruby execution
 */
export class RbError extends Error {
  constructor(message: string) {
    super(message);
  }
}

/**
 * A Ruby VM instance
 *
 * ## Example
 *
 * ```javascript
 * const wasi = new WASI();
 * const vm = new RubyVM();
 * const imports = {
 *   wasi_snapshot_preview1: wasi.wasiImport,
 * };
 *
 * vm.addToImports(imports);
 *
 * const instance = await WebAssembly.instantiate(rubyModule, imports);
 * await vm.init(instance);
 * wasi.initialize(instance);
 * ```
 */
export class RubyVM {
  guest: RbAbi.RbJsAbiGuest;
  private instance: WebAssembly.Instance | null = null;

  constructor() {
    this.guest = new RbAbi.RbJsAbiGuest();
  }

  /**
   * Set a given instance to interact JavaScript and Ruby's
   * WebAssembly instance. This method must be called before calling
   * Ruby API.
   *
   * The `instance` must be instantiated from a Ruby built with JS
   * extension, and built with Reactor ABI instead of command line.
   */
  async setInstance(instance: WebAssembly.Instance) {
    this.instance = instance;
    await this.guest.instantiate(instance);
  }

  /**
   * Add intrinsic import entries, which is necessary to interact JavaScript
   * and Ruby's WebAssembly instance.
   */
  addToImports(imports: WebAssembly.Imports) {
    this.guest.addToImports(imports);
    addRbJsAbiHostToImports(
      imports,
      {
        evalJs: (code) => {
          new Function(code)();
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
   * Returns the result of the last expression
   */
  eval(code: string): RbValue {
    return evalRbCode(this.guest, code);
  }
}

/**
 * A RbValue is an object that represents a value in Ruby
 */
export class RbValue {
  constructor(public inner: RbAbi.RbValue, private guest: RbAbi.RbJsAbiGuest) {}

  /**
   * Call a given method with given arguments
   */
  call(callee: string, ...args: RbValue[]): RbValue {
    const innerArgs = args.map((arg) => arg.inner);
    return new RbValue(
      callRbMethod(this.guest, this.inner, callee, innerArgs),
      this.guest
    );
  }

  [Symbol.toPrimitive](hint: string) {
    if (hint === "string" || hint === "default") {
      return this.toString();
    } else if (hint === "number") {
      return null;
    }
    return null;
  }
  toString(): string {
    const rbString = callRbMethod(this.guest, this.inner, "to_s", []);
    return this.guest.rstringPtr(rbString);
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

const formatException = (
  klass: string,
  message: string,
  backtrace: [string, string]
) => {
  return `${backtrace[0]}: ${message} (${klass})\n${backtrace[1]}`;
};

const checkStatusTag = (rawTag: number, guest: RbAbi.RbJsAbiGuest) => {
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
      const error = new RbValue(guest.rbErrinfo(), guest);
      const newLine = evalRbCode(guest, `"\n"`);
      const backtrace = error.call("backtrace");
      const firstLine = backtrace.call("at", evalRbCode(guest, "0"));
      const restLines = backtrace
        .call("drop", evalRbCode(guest, "1"))
        .call("join", newLine);
      throw new RbError(
        formatException(error.call("class").toString(), error.toString(), [
          firstLine.toString(),
          restLines.toString(),
        ])
      );
    default:
      throw new RbError(`unknown error tag: ${rawTag}`);
  }
};

const callRbMethod = (
  guest: RbAbi.RbJsAbiGuest,
  recv: RbAbi.RbValue,
  callee: string,
  args: RbAbi.RbValue[]
) => {
  const mid = guest.rbIntern(callee + "\0");
  const [value, status] = guest.rbFuncallvProtect(recv, mid, args);
  checkStatusTag(status, guest);
  return value;
};
const evalRbCode = (guest: RbAbi.RbJsAbiGuest, code: string) => {
  const [value, status] = guest.rbEvalStringProtect(code + "\0");
  checkStatusTag(status, guest);
  return new RbValue(value, guest);
};
