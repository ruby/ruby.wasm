import { data_view, UTF8_DECODER, utf8_encode, UTF8_ENCODED_LEN, Slab, throw_invalid_bool } from './intrinsics.js';
export function addRbJsAbiHostToImports(imports, obj, get_export) {
  if (!("rb-js-abi-host" in imports)) imports["rb-js-abi-host"] = {};
  imports["rb-js-abi-host"]["eval-js: func(code: string) -> variant { success(handle<js-abi-value>), failure(handle<js-abi-value>) }"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg0;
    const len0 = arg1;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.evalJs(result0);
    const variant1 = ret0;
    switch (variant1.tag) {
      case "success": {
        const e = variant1.val;
        data_view(memory).setInt8(arg2 + 0, 0, true);
        data_view(memory).setInt32(arg2 + 4, resources0.insert(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg2 + 0, 1, true);
        data_view(memory).setInt32(arg2 + 4, resources0.insert(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["is-js: func(value: handle<js-abi-value>) -> bool"] = function(arg0) {
    const ret0 = obj.isJs(resources0.get(arg0));
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["instance-of: func(value: handle<js-abi-value>, klass: handle<js-abi-value>) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.instanceOf(resources0.get(arg0), resources0.get(arg1));
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["global-this: func() -> handle<js-abi-value>"] = function() {
    const ret0 = obj.globalThis();
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["int-to-js-number: func(value: s32) -> handle<js-abi-value>"] = function(arg0) {
    const ret0 = obj.intToJsNumber(arg0);
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["string-to-js-string: func(value: string) -> handle<js-abi-value>"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const ptr0 = arg0;
    const len0 = arg1;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.stringToJsString(result0);
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["bool-to-js-bool: func(value: bool) -> handle<js-abi-value>"] = function(arg0) {
    const bool0 = arg0;
    const ret0 = obj.boolToJsBool(bool0 == 0 ? false : (bool0 == 1 ? true : throw_invalid_bool()));
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["proc-to-js-function: func(value: u32) -> handle<js-abi-value>"] = function(arg0) {
    const ret0 = obj.procToJsFunction(arg0 >>> 0);
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["rb-object-to-js-rb-value: func(raw-rb-abi-value: u32) -> handle<js-abi-value>"] = function(arg0) {
    const ret0 = obj.rbObjectToJsRbValue(arg0 >>> 0);
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["js-value-to-string: func(value: handle<js-abi-value>) -> string"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.jsValueToString(resources0.get(arg0));
    const ptr0 = utf8_encode(ret0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    data_view(memory).setInt32(arg1 + 4, len0, true);
    data_view(memory).setInt32(arg1 + 0, ptr0, true);
  };
  imports["rb-js-abi-host"]["js-value-to-integer: func(value: handle<js-abi-value>) -> variant { f64(float64), bignum(string) }"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.jsValueToInteger(resources0.get(arg0));
    const variant1 = ret0;
    switch (variant1.tag) {
      case "f64": {
        const e = variant1.val;
        data_view(memory).setInt8(arg1 + 0, 0, true);
        data_view(memory).setFloat64(arg1 + 8, +e, true);
        break;
      }
      case "bignum": {
        const e = variant1.val;
        data_view(memory).setInt8(arg1 + 0, 1, true);
        const ptr0 = utf8_encode(e, realloc, memory);
        const len0 = UTF8_ENCODED_LEN;
        data_view(memory).setInt32(arg1 + 12, len0, true);
        data_view(memory).setInt32(arg1 + 8, ptr0, true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for RawInteger");
    }
  };
  imports["rb-js-abi-host"]["export-js-value-to-host: func(value: handle<js-abi-value>) -> ()"] = function(arg0) {
    obj.exportJsValueToHost(resources0.get(arg0));
  };
  imports["rb-js-abi-host"]["import-js-value-from-host: func() -> handle<js-abi-value>"] = function() {
    const ret0 = obj.importJsValueFromHost();
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["js-value-typeof: func(value: handle<js-abi-value>) -> string"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.jsValueTypeof(resources0.get(arg0));
    const ptr0 = utf8_encode(ret0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    data_view(memory).setInt32(arg1 + 4, len0, true);
    data_view(memory).setInt32(arg1 + 0, ptr0, true);
  };
  imports["rb-js-abi-host"]["js-value-equal: func(lhs: handle<js-abi-value>, rhs: handle<js-abi-value>) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.jsValueEqual(resources0.get(arg0), resources0.get(arg1));
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["js-value-strictly-equal: func(lhs: handle<js-abi-value>, rhs: handle<js-abi-value>) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.jsValueStrictlyEqual(resources0.get(arg0), resources0.get(arg1));
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-apply: func(target: handle<js-abi-value>, this-argument: handle<js-abi-value>, arguments: list<handle<js-abi-value>>) -> variant { success(handle<js-abi-value>), failure(handle<js-abi-value>) }"] = function(arg0, arg1, arg2, arg3, arg4) {
    const memory = get_export("memory");
    const len0 = arg3;
    const base0 = arg2;
    const result0 = [];
    for (let i = 0; i < len0; i++) {
      const base = base0 + i * 4;
      result0.push(resources0.get(data_view(memory).getInt32(base + 0, true)));
    }
    const ret0 = obj.reflectApply(resources0.get(arg0), resources0.get(arg1), result0);
    const variant1 = ret0;
    switch (variant1.tag) {
      case "success": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 0, true);
        data_view(memory).setInt32(arg4 + 4, resources0.insert(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 1, true);
        data_view(memory).setInt32(arg4 + 4, resources0.insert(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["reflect-construct: func(target: handle<js-abi-value>, arguments: list<handle<js-abi-value>>) -> handle<js-abi-value>"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const len0 = arg2;
    const base0 = arg1;
    const result0 = [];
    for (let i = 0; i < len0; i++) {
      const base = base0 + i * 4;
      result0.push(resources0.get(data_view(memory).getInt32(base + 0, true)));
    }
    const ret0 = obj.reflectConstruct(resources0.get(arg0), result0);
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["reflect-delete-property: func(target: handle<js-abi-value>, property-key: string) -> bool"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectDeleteProperty(resources0.get(arg0), result0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-get: func(target: handle<js-abi-value>, property-key: string) -> variant { success(handle<js-abi-value>), failure(handle<js-abi-value>) }"] = function(arg0, arg1, arg2, arg3) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectGet(resources0.get(arg0), result0);
    const variant1 = ret0;
    switch (variant1.tag) {
      case "success": {
        const e = variant1.val;
        data_view(memory).setInt8(arg3 + 0, 0, true);
        data_view(memory).setInt32(arg3 + 4, resources0.insert(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg3 + 0, 1, true);
        data_view(memory).setInt32(arg3 + 4, resources0.insert(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["reflect-get-own-property-descriptor: func(target: handle<js-abi-value>, property-key: string) -> handle<js-abi-value>"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectGetOwnPropertyDescriptor(resources0.get(arg0), result0);
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["reflect-get-prototype-of: func(target: handle<js-abi-value>) -> handle<js-abi-value>"] = function(arg0) {
    const ret0 = obj.reflectGetPrototypeOf(resources0.get(arg0));
    return resources0.insert(ret0);
  };
  imports["rb-js-abi-host"]["reflect-has: func(target: handle<js-abi-value>, property-key: string) -> bool"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectHas(resources0.get(arg0), result0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-is-extensible: func(target: handle<js-abi-value>) -> bool"] = function(arg0) {
    const ret0 = obj.reflectIsExtensible(resources0.get(arg0));
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-own-keys: func(target: handle<js-abi-value>) -> list<handle<js-abi-value>>"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.reflectOwnKeys(resources0.get(arg0));
    const vec0 = ret0;
    const len0 = vec0.length;
    const result0 = realloc(0, 0, 4, len0 * 4);
    for (let i = 0; i < vec0.length; i++) {
      const e = vec0[i];
      const base = result0 + i * 4;
      data_view(memory).setInt32(base + 0, resources0.insert(e), true);
    }
    data_view(memory).setInt32(arg1 + 4, len0, true);
    data_view(memory).setInt32(arg1 + 0, result0, true);
  };
  imports["rb-js-abi-host"]["reflect-prevent-extensions: func(target: handle<js-abi-value>) -> bool"] = function(arg0) {
    const ret0 = obj.reflectPreventExtensions(resources0.get(arg0));
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-set: func(target: handle<js-abi-value>, property-key: string, value: handle<js-abi-value>) -> variant { success(handle<js-abi-value>), failure(handle<js-abi-value>) }"] = function(arg0, arg1, arg2, arg3, arg4) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectSet(resources0.get(arg0), result0, resources0.get(arg3));
    const variant1 = ret0;
    switch (variant1.tag) {
      case "success": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 0, true);
        data_view(memory).setInt32(arg4 + 4, resources0.insert(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 1, true);
        data_view(memory).setInt32(arg4 + 4, resources0.insert(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["reflect-set-prototype-of: func(target: handle<js-abi-value>, prototype: handle<js-abi-value>) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.reflectSetPrototypeOf(resources0.get(arg0), resources0.get(arg1));
    return ret0 ? 1 : 0;
  };
  if (!("canonical_abi" in imports)) imports["canonical_abi"] = {};
  
  const resources0 = new Slab();
  imports.canonical_abi["resource_drop_js-abi-value"] = (i) => {
    const val = resources0.remove(i);
    if (obj.dropJsAbiValue)
    obj.dropJsAbiValue(val);
  };
}