import { RubyJsRubyRuntime } from "./bindgen/interfaces/ruby-js-ruby-runtime.js";
import * as RbAbi from "./bindgen/legacy/rb-abi-guest.js";

/**
 * This interface bridges between the Ruby runtime and the JavaScript runtime
 * and defines how to interact with underlying import/export functions.
 */
export interface Binding {
  rubyShowVersion(): void;
  rubyInit(): void;
  rubySysinit(args: string[]): void;
  rubyOptions(args: string[]): void;
  rubyScript(name: string): void;
  rubyInitLoadpath(): void;
  rbEvalStringProtect(str: string): [RbAbi.RbAbiValue, number];
  rbFuncallvProtect(recv: RbAbi.RbAbiValue, mid: RbAbi.RbId, args: RbAbi.RbAbiValue[]): [RbAbi.RbAbiValue, number];
  rbIntern(name: string): RbAbi.RbId;
  rbErrinfo(): RbAbi.RbAbiValue;
  rbClearErrinfo(): void;
  rstringPtr(value: RbAbi.RbAbiValue): string;
  rbVmBugreport(): void;
  rbGcEnable(): boolean;
  rbGcDisable(): boolean;
  rbSetShouldProhibitRewind(newValue: boolean): boolean;

  setInstance(instance: WebAssembly.Instance): Promise<void>;
  addToImports(imports: WebAssembly.Imports): void;
}

export class LegacyBinding extends RbAbi.RbAbiGuest implements Binding {
  async setInstance(instance: WebAssembly.Instance): Promise<void> {
    await this.instantiate(instance);
  }
}

export class ComponentBinding implements Binding {
  underlying: typeof RubyJsRubyRuntime;

  constructor(underlying: typeof RubyJsRubyRuntime) {
    this.underlying = underlying;
  }

  rubyShowVersion(): void {
    this.underlying.rubyShowVersion();
  }
  rubyInit(): void {
    this.underlying.rubyInit();
  }
  rubySysinit(args: string[]): void {
    this.underlying.rubySysinit(args);
  }
  rubyOptions(args: string[]) {
    this.underlying.rubyOptions(args);
  }
  rubyScript(name: string): void {
    throw new Error("Method not implemented.");
  }
  rubyInitLoadpath(): void {
    throw new Error("Method not implemented.");
  }
  rbEvalStringProtect(str: string): [RbAbi.RbAbiValue, number] {
    throw new Error("Method not implemented.");
  }
  rbFuncallvProtect(recv: RbAbi.RbAbiValue, mid: number, args: RbAbi.RbAbiValue[]): [RbAbi.RbAbiValue, number] {
    throw new Error("Method not implemented.");
  }
  rbIntern(name: string): number {
    throw new Error("Method not implemented.");
  }
  rbErrinfo(): RbAbi.RbAbiValue {
    throw new Error("Method not implemented.");
  }
  rbClearErrinfo(): void {
    throw new Error("Method not implemented.");
  }
  rstringPtr(value: RbAbi.RbAbiValue): string {
    throw new Error("Method not implemented.");
  }
  rbVmBugreport(): void {
    throw new Error("Method not implemented.");
  }
  rbGcEnable(): boolean {
    throw new Error("Method not implemented.");
  }
  rbGcDisable(): boolean {
    throw new Error("Method not implemented.");
  }
  rbSetShouldProhibitRewind(newValue: boolean): boolean {
    throw new Error("Method not implemented.");
  }

  async setInstance(instance: WebAssembly.Instance): Promise<void> {
    // No-op
  }
  addToImports(imports: WebAssembly.Imports): void {
    // No-op
  }
}
