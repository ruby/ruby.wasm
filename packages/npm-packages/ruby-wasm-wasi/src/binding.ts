import { RubyJsRubyRuntime } from "./bindgen/interfaces/ruby-js-ruby-runtime.js";
import * as RbAbi from "./bindgen/legacy/rb-abi-guest.js";
import { data_view, to_uint32 } from "./bindgen/legacy/intrinsics.js";

/**
 * This interface bridges between the Ruby runtime and the JavaScript runtime
 * and defines how to interact with underlying import/export functions.
 */
export interface Binding {
  rubyShowVersion(): void;
  rubyInit(args: string[]): void;
  rubyInitLoadpath(): void;
  rbEvalStringProtect(str: string): [RbAbiValue, number];
  rbFuncallvProtect(recv: RbAbiValue, mid: RbAbi.RbId, args: RbAbiValue[]): [RbAbiValue, number];
  rbFuncallvProtectAsync(recv: RbAbiValue, mid: RbAbi.RbId, args: RbAbiValue[]): Promise<[RbAbiValue, number]>;
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
  jspiPromising: ((fn: (...args: any[]) => any) => (...args: any[]) => Promise<any>) | undefined;

  async setInstance(instance: WebAssembly.Instance): Promise<void> {
    await this.instantiate(instance);
  }

  rbFuncallvProtectAsync(recv: RbAbiValue, mid: RbAbi.RbId, args: RbAbiValue[]): Promise<[RbAbiValue, number]> {
    const self = this as any;
    const memory = this.instance.exports.memory as WebAssembly.Memory;
    const realloc = this.instance.exports["cabi_realloc"] as (...args: any[]) => number;
    const wasm = WebAssembly as any;

    this.jspiPromising ||= (typeof wasm.promising === "function" ? wasm.promising.bind(wasm) : undefined);
    if (!this.jspiPromising) {
      throw new Error("trying to suspend without WebAssembly.promising");
    }

    const vec = args as any[];
    const len = vec.length;
    const ptr = realloc(0, 0, 4, len * 4);
    for (let i = 0; i < vec.length; i++) {
      const obj = vec[i];
      if (!(obj instanceof RbAbi.RbAbiValue)) throw new TypeError("expected instance of RbAbiValue");
      data_view(memory).setInt32(ptr + i * 4, self._resource0_slab.insert(obj.clone()), true);
    }

    const recvObj = recv as any;
    if (!(recvObj instanceof RbAbi.RbAbiValue)) throw new TypeError("expected instance of RbAbiValue");
    const exported = self._exports[
      "rb-funcallv-protect: func(recv: handle<rb-abi-value>, mid: u32, args: list<handle<rb-abi-value>>) -> tuple<handle<rb-abi-value>, s32>"
    ] as (...args: any[]) => number;
    const promising = this.jspiPromising(exported);

    return promising(self._resource0_slab.insert(recvObj.clone()), to_uint32(mid), ptr, len).then((ret: number) => {
      return [
        self._resource0_slab.remove(data_view(memory).getInt32(ret + 0, true)),
        data_view(memory).getInt32(ret + 4, true),
      ];
    });
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
  rubyInit(args: string[]): void {
    this.underlying.rubyInit(args);
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
  rbFuncallvProtectAsync(recv: RbAbiValue, mid: number, args: RbAbiValue[]): Promise<[RbAbiValue, number]> {
    return Promise.resolve(this.underlying.rbFuncallvProtect(recv, mid, args));
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
