import { data_view, to_uint32, UTF8_DECODER, utf8_encode, UTF8_ENCODED_LEN, Slab, throw_invalid_bool } from './intrinsics.js';
export class RbAbiGuest {
  constructor() {
    this._resource0_slab = new Slab();
  }
  addToImports(imports) {
    if (!("canonical_abi" in imports)) imports["canonical_abi"] = {};
    
    imports.canonical_abi['resource_drop_rb-abi-value'] = i => {
      this._resource0_slab.remove(i).drop();
    };
    imports.canonical_abi['resource_clone_rb-abi-value'] = i => {
      const obj = this._resource0_slab.get(i);
      return this._resource0_slab.insert(obj.clone())
    };
    imports.canonical_abi['resource_get_rb-abi-value'] = i => {
      return this._resource0_slab.get(i)._wasm_val;
    };
    imports.canonical_abi['resource_new_rb-abi-value'] = i => {
      const registry = this._registry0;
      return this._resource0_slab.insert(new RbAbiValue(i, this));
    };
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
    this._registry0 = new FinalizationRegistry(this._exports['canonical_abi_drop_rb-abi-value']);
  }
  rubyShowVersion() {
    this._exports['ruby-show-version: func() -> ()']();
  }
  rubyInit(arg0) {
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
    this._exports['ruby-init: func(args: list<string>) -> ()'](result1, len1);
  }
  rubyInitLoadpath() {
    this._exports['ruby-init-loadpath: func() -> ()']();
  }
  rbEvalStringProtect(arg0) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const ptr0 = utf8_encode(arg0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    const ret = this._exports['rb-eval-string-protect: func(str: string) -> tuple<handle<rb-abi-value>, s32>'](ptr0, len0);
    return [this._resource0_slab.remove(data_view(memory).getInt32(ret + 0, true)), data_view(memory).getInt32(ret + 4, true)];
  }
  rbFuncallvProtect(arg0, arg1, arg2) {
    const memory = this._exports.memory;
    const realloc = this._exports["cabi_realloc"];
    const obj0 = arg0;
    if (!(obj0 instanceof RbAbiValue)) throw new TypeError('expected instance of RbAbiValue');
    const vec2 = arg2;
    const len2 = vec2.length;
    const result2 = realloc(0, 0, 4, len2 * 4);
    for (let i = 0; i < vec2.length; i++) {
      const e = vec2[i];
      const base = result2 + i * 4;
      const obj1 = e;
      if (!(obj1 instanceof RbAbiValue)) throw new TypeError('expected instance of RbAbiValue');
      data_view(memory).setInt32(base + 0, this._resource0_slab.insert(obj1.clone()), true);
    }
    const ret = this._exports['rb-funcallv-protect: func(recv: handle<rb-abi-value>, mid: u32, args: list<handle<rb-abi-value>>) -> tuple<handle<rb-abi-value>, s32>'](this._resource0_slab.insert(obj0.clone()), to_uint32(arg1), result2, len2);
    return [this._resource0_slab.remove(data_view(memory).getInt32(ret + 0, true)), data_view(memory).getInt32(ret + 4, true)];
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
    const ret = this._exports['rb-errinfo: func() -> handle<rb-abi-value>']();
    return this._resource0_slab.remove(ret);
  }
  rbClearErrinfo() {
    this._exports['rb-clear-errinfo: func() -> ()']();
  }
  rstringPtr(arg0) {
    const memory = this._exports.memory;
    const obj0 = arg0;
    if (!(obj0 instanceof RbAbiValue)) throw new TypeError('expected instance of RbAbiValue');
    const ret = this._exports['rstring-ptr: func(value: handle<rb-abi-value>) -> string'](this._resource0_slab.insert(obj0.clone()));
    const ptr1 = data_view(memory).getInt32(ret + 0, true);
    const len1 = data_view(memory).getInt32(ret + 4, true);
    const result1 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr1, len1));
    this._exports["cabi_post_rstring-ptr"](ret);
    return result1;
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

export class RbAbiValue {
  constructor(wasm_val, obj) {
    this._wasm_val = wasm_val;
    this._obj = obj;
    this._refcnt = 1;
    obj._registry0.register(this, wasm_val, this);
  }
  
  clone() {
    this._refcnt += 1;
    return this;
  }
  
  drop() {
    this._refcnt -= 1;
    if (this._refcnt !== 0)
    return;
    this._obj._registry0.unregister(this);
    const dtor = this._obj._exports['canonical_abi_drop_rb-abi-value'];
    const wasm_val = this._wasm_val;
    delete this._obj;
    delete this._refcnt;
    delete this._wasm_val;
    dtor(wasm_val);
  }
}
