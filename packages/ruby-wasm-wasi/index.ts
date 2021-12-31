import { RbJsAbiGuest } from "./bindgen/rb-js-abi-guest";
import { addRbJsAbiHostToImports } from "./bindgen/rb-js-abi-host";

export class RubyVM {
  private guest: RbJsAbiGuest;
  private instance: WebAssembly.Instance | null = null;
  constructor() {
    this.guest = new RbJsAbiGuest();
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
            (new Function(code))()
        },
      },
      (name) => {
        return this.instance.exports[name];
      }
    );
  }
}
