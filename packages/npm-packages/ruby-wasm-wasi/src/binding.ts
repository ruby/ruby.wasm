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

  constructor() {}

  setUnderlying(underlying: typeof RubyJsRubyRuntime): void {
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
    return this.underlying.rbFuncallvProtect(recv, mid, args);
  }
  rbIntern(name: string): number {
    return this.underlying.rbIntern(name);
  }
  rbErrinfo(): RbAbiValue {
    return this.underlying.rbErrinfo();
  }
  rbClearErrinfo(): void {
    return this.underlying.rbClearErrinfo();
  }
  rstringPtr(value: RbAbiValue): string {
    return this.underlying.rstringPtr(value);
  }
  rbVmBugreport(): void {
    this.underlying.rbVmBugreport();
  }
  rbGcEnable(): boolean {
    return this.underlying.rbGcEnable();
  }
  rbGcDisable(): boolean {
    return this.underlying.rbGcDisable();
  }
  rbSetShouldProhibitRewind(newValue: boolean): boolean {
    return this.underlying.rbSetShouldProhibitRewind(newValue);
  }

  async setInstance(instance: WebAssembly.Instance): Promise<void> {
    // No-op
  }
  addToImports(imports: WebAssembly.Imports): void {
    // No-op
  }
}
