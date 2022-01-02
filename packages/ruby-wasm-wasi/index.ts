import * as RbAbi from "./bindgen/rb-js-abi-guest";
import { addRbJsAbiHostToImports } from "./bindgen/rb-js-abi-host";

enum ruby_value_type {
  None = 0x00,

  Object = 0x01,
  Class = 0x02,
  Module = 0x03,
  Float = 0x04,
  RString = 0x05,
  Regexp = 0x06,
  Array = 0x07,
  Hash = 0x08,
  Struct = 0x09,
  Bignum = 0x0a,
  File = 0x0b,
  Data = 0x0c,
  Match = 0x0d,
  Complex = 0x0e,
  Rational = 0x0f,

  Nil = 0x11,
  True = 0x12,
  False = 0x13,
  Symbol = 0x14,
  Fixnum = 0x15,
  Undef = 0x16,

  IMemo = 0x1a,
  Node = 0x1b,
  IClass = 0x1c,
  Zombie = 0x1d,

  Mask = 0x1f,
}

enum ruby_tag_type {
  None	  = 0x0,
  Return	= 0x1,
  Break	= 0x2,
  Next	  = 0x3,
  Retry	= 0x4,
  Redo	  = 0x5,
  Raise	= 0x6,
  Throw	= 0x7,
  Fatal	= 0x8,
  Mask	  = 0xf
};

class RbError extends Error {
  constructor(message: string) {
    super(message)
  }
}

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
      const error = RbValue.createProxy(guest.rbErrinfo(), guest);
      throw new RbError(`${error}`)
    default:
      throw new RbError(`unknown error tag: ${rawTag}`)
  }
}

const projectRbRawValue = (v: RbAbi.RbValue) => (v as any)._wasm_val as number;
const callRbMethod = (guest: RbAbi.RbJsAbiGuest, recv: RbAbi.RbValue, callee: string, args: any[]) => {
  const mid = guest.rbIntern(callee + "\0");
  const [value, status] = guest.rbFuncallvProtect(recv, mid, args);
  checkStatusTag(status, guest);
  return value;
}

export class RbValue {
  private constructor(public inner: RbAbi.RbValue, private guest: RbAbi.RbJsAbiGuest) {}

  static createProxy(abiValue: RbAbi.RbValue, guest: RbAbi.RbJsAbiGuest): RbValue {
    return new Proxy(new RbValue(abiValue, guest), new RbValueProxyHandler(guest));
  }

  rawValue(): number {
    return (this.inner as any)._wasm_val;
  }
  [Symbol.toPrimitive](hint: string) {
    if (hint === "string" || hint === "default") {
      return this.toString();
    }
    return null;
  }
  toString(): string {
    const rbString = callRbMethod(this.guest, this.inner, "to_s", []);
    return this.guest.rstringPtr(rbString);
  }
}

class RbValueProxyHandler implements ProxyHandler<RbValue> {
  constructor(private guest: RbAbi.RbJsAbiGuest) {}
  get(target: RbValue, p: string | symbol): any {
    if (p in target) {
      return target[p];
    }
    const guest = this.guest;
    return function() {
      const args = [...arguments];
      return callRbMethod(guest, target.inner, p.toString(), args)
    }
  }
}

export class RubyVM {
  guest: RbAbi.RbJsAbiGuest;
  private instance: WebAssembly.Instance | null = null;
  constructor() {
    this.guest = new RbAbi.RbJsAbiGuest();
  }

  async init(instance: WebAssembly.Instance) {
    this.instance = instance;
    await this.guest.instantiate(instance);
  }

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

  printVersion() {
    this.guest.rubyShowVersion();
  }

  /**
   * Runs a string of Ruby code from JavaScript
   * Returns the result of the last expression
   */
  eval(code: string): RbValue {
    const [value, status] = this.guest.rbEvalStringProtect(code + "\0");
    checkStatusTag(status, this.guest);
    return RbValue.createProxy(value, this.guest);
  }
}
