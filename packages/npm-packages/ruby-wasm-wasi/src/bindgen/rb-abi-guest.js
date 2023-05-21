import { data_view, to_uint32, UTF8_DECODER, utf8_encode, UTF8_ENCODED_LEN, throw_invalid_bool } from './intrinsics.js';
export class RbAbiGuest {
  addToImports(imports) {
  }
  
  async instantiate(module, imports) {
    imports = imports || {};
    this.addToImports(imports);
    
    if (module instanceof WebAssembly.Instance) {
      this.instance = module;
    } else if (module instanceof WebAssembly.Module) {
      this.instance = await WebAssembly.instantiate(module, imports);
    } else if (module instanceof ArrayBuffer || module instanceof Uint8Array) {
      const { instance } = await WebAssembly.instantiate(module, imports);
      this.instance = instance;
    } else {
      const { instance } = await WebAssembly.instantiateStreaming(module, imports);
      this.instance = instance;
    }
    this._exports = this.instance.exports;
  }
  dropRbValue(arg0) {
    this._exports['drop-rb-value: func(value: u32) -> ()'](to_uint32(arg0));
  }
  rubyShowVersion() {
    this._exports['ruby-show-version: func() -> ()']();
  }
  rubyInit() {
    this._exports['ruby-init: func() -> ()']();
  }
  rubySysinit(arg0) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const vec1 = arg0;
    const len1 = vec1.length;
    const result1 = realloc(0, 0, 4, len1 * 8);
    for (let i = 0; i < vec1.length; i++) {
      const e = vec1[i];
      const base = result1 + i * 8;
      const ptr0 = utf8_encode(e, realloc, memory);
      const len0 = UTF8_ENCODED_LEN;
      data_view(memory).setInt32(base + 4, len0, true);
      data_view(memory).setInt32(base + 0, ptr0, true);
    }
    this._exports['ruby-sysinit: func(args: list<string>) -> ()'](result1, len1);
  }
  rubyOptions(arg0) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const vec1 = arg0;
    const len1 = vec1.length;
    const result1 = realloc(0, 0, 4, len1 * 8);
    for (let i = 0; i < vec1.length; i++) {
      const e = vec1[i];
      const base = result1 + i * 8;
      const ptr0 = utf8_encode(e, realloc, memory);
      const len0 = UTF8_ENCODED_LEN;
      data_view(memory).setInt32(base + 4, len0, true);
      data_view(memory).setInt32(base + 0, ptr0, true);
    }
    const ret = this._exports['ruby-options: func(args: list<string>) -> u32'](result1, len1);
    return ret >>> 0;
  }
  rubyScript(arg0) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const ptr0 = utf8_encode(arg0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    this._exports['ruby-script: func(name: string) -> ()'](ptr0, len0);
  }
  rubyInitLoadpath() {
    this._exports['ruby-init-loadpath: func() -> ()']();
  }
  rbEvalStringProtect(arg0) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const ptr0 = utf8_encode(arg0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    const ret = this._exports['rb-eval-string-protect: func(str: string) -> tuple<u32, s32>'](ptr0, len0);
    return [data_view(memory).getInt32(ret + 0, true) >>> 0, data_view(memory).getInt32(ret + 4, true)];
  }
  rbFuncallvProtect(arg0, arg1, arg2) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const val0 = arg2;
    const len0 = val0.length;
    const ptr0 = realloc(0, 0, 4, len0 * 4);
    (new Uint8Array(memory.buffer, ptr0, len0 * 4)).set(new Uint8Array(val0.buffer, val0.byteOffset, len0 * 4));
    const ret = this._exports['rb-funcallv-protect: func(recv: u32, mid: u32, args: list<u32>) -> tuple<u32, s32>'](to_uint32(arg0), to_uint32(arg1), ptr0, len0);
    return [data_view(memory).getInt32(ret + 0, true) >>> 0, data_view(memory).getInt32(ret + 4, true)];
  }
  rbIntern(arg0) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const ptr0 = utf8_encode(arg0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    const ret = this._exports['rb-intern: func(name: string) -> u32'](ptr0, len0);
    return ret >>> 0;
  }
  rbErrinfo() {
    const ret = this._exports['rb-errinfo: func() -> u32']();
    return ret >>> 0;
  }
  rbClearErrinfo() {
    this._exports['rb-clear-errinfo: func() -> ()']();
  }
  rstringPtr(arg0) {
    const memory = this._exports.memory;
    const ret = this._exports['rstring-ptr: func(value: u32) -> string'](to_uint32(arg0));
    const ptr0 = data_view(memory).getInt32(ret + 0, true);
    const len0 = data_view(memory).getInt32(ret + 4, true);
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    this._exports["cabi_post_rstring-ptr"](ret);
    return result0;
  }
  rbVmBugreport() {
    this._exports['rb-vm-bugreport: func() -> ()']();
  }
  rbGcEnable() {
    const ret = this._exports['rb-gc-enable: func() -> bool']();
    const bool0 = ret;
    return bool0 == 0 ? false : (bool0 == 1 ? true : throw_invalid_bool());
  }
  rbGcDisable() {
    const ret = this._exports['rb-gc-disable: func() -> bool']();
    const bool0 = ret;
    return bool0 == 0 ? false : (bool0 == 1 ? true : throw_invalid_bool());
  }
  rbSetShouldProhibitRewind(arg0) {
    const ret = this._exports['rb-set-should-prohibit-rewind: func(new-value: bool) -> bool'](arg0 ? 1 : 0);
    const bool0 = ret;
    return bool0 == 0 ? false : (bool0 == 1 ? true : throw_invalid_bool());
  }
}
