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
  rbEvalStringProtect(str: string): [RbAbiValue, number];
  rbFuncallvProtect(recv: RbAbiValue, mid: RbAbi.RbId, args: RbAbiValue[]): [RbAbiValue, number];
  rbIntern(name: string): RbAbi.RbId;
  rbErrinfo(): RbAbiValue;
  rbClearErrinfo(): void;
  rstringPtr(value: RbAbiValue): string;
  rbVmBugreport(): void;
  rbGcEnable(): boolean;
  rbGcDisable(): boolean;
  rbSetShouldProhibitRewind(newValue: boolean): boolean;

  setInstance(instance: WebAssembly.Instance): Promise<void>;
  addToImports(imports: WebAssembly.Imports): void;
}

// Low-level opaque representation of a Ruby value.
export interface RbAbiValue {}

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
    this.underlying.rubyScript(name);
  }
  rubyInitLoadpath(): void {
    this.underlying.rubyInitLoadpath();
  }
  rbEvalStringProtect(str: string): [RbAbiValue, number] {
    return this.underlying.rbEvalStringProtect(str);
  }
  rbFuncallvProtect(recv: RbAbiValue, mid: number, args: RbAbiValue[]): [RbAbiValue, number] {
    return this.rbFuncallvProtect(recv, mid, args);
  }
  rbIntern(name: string): number {
    return this.rbIntern(name);
  }
  rbErrinfo(): RbAbi.RbAbiValue {
    return this.rbErrinfo();
  }
  rbClearErrinfo(): void {
    return this.rbClearErrinfo();
  }
  rstringPtr(value: RbAbi.RbAbiValue): string {
    return this.rstringPtr(value);
  }
  rbVmBugreport(): void {
    this.rbVmBugreport();
  }
  rbGcEnable(): boolean {
    return this.rbGcEnable();
  }
  rbGcDisable(): boolean {
    return this.rbGcDisable();
  }
  rbSetShouldProhibitRewind(newValue: boolean): boolean {
    return this.rbSetShouldProhibitRewind(newValue);
  }

  async setInstance(instance: WebAssembly.Instance): Promise<void> {
    // No-op
  }
  addToImports(imports: WebAssembly.Imports): void {
    // No-op
  }
}
