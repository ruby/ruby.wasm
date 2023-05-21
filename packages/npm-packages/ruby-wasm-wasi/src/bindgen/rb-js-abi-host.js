import { data_view, to_uint32, UTF8_DECODER, utf8_encode, UTF8_ENCODED_LEN, throw_invalid_bool } from './intrinsics.js';
export function addRbJsAbiHostToImports(imports, obj, get_export) {
  if (!("rb-js-abi-host" in imports)) imports["rb-js-abi-host"] = {};
  imports["rb-js-abi-host"]["drop-js-value: func(value: u32) -> ()"] = function(arg0) {
    obj.dropJsValue(arg0 >>> 0);
  };
  imports["rb-js-abi-host"]["eval-js: func(code: string) -> variant { success(u32), failure(u32) }"] = function(arg0, arg1, arg2) {
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
        data_view(memory).setInt32(arg2 + 4, to_uint32(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg2 + 0, 1, true);
        data_view(memory).setInt32(arg2 + 4, to_uint32(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["is-js: func(value: u32) -> bool"] = function(arg0) {
    const ret0 = obj.isJs(arg0 >>> 0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["instance-of: func(value: u32, klass: u32) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.instanceOf(arg0 >>> 0, arg1 >>> 0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["global-this: func() -> u32"] = function() {
    const ret0 = obj.globalThis();
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["int-to-js-number: func(value: s32) -> u32"] = function(arg0) {
    const ret0 = obj.intToJsNumber(arg0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["float-to-js-number: func(value: float64) -> u32"] = function(arg0) {
    const ret0 = obj.floatToJsNumber(arg0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["string-to-js-string: func(value: string) -> u32"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const ptr0 = arg0;
    const len0 = arg1;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.stringToJsString(result0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["bool-to-js-bool: func(value: bool) -> u32"] = function(arg0) {
    const bool0 = arg0;
    const ret0 = obj.boolToJsBool(bool0 == 0 ? false : (bool0 == 1 ? true : throw_invalid_bool()));
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["proc-to-js-function: func(value: u32) -> u32"] = function(arg0) {
    const ret0 = obj.procToJsFunction(arg0 >>> 0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["rb-object-to-js-rb-value: func(raw-rb-abi-value: u32) -> u32"] = function(arg0) {
    const ret0 = obj.rbObjectToJsRbValue(arg0 >>> 0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["js-value-to-string: func(value: u32) -> string"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.jsValueToString(arg0 >>> 0);
    const ptr0 = utf8_encode(ret0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    data_view(memory).setInt32(arg1 + 4, len0, true);
    data_view(memory).setInt32(arg1 + 0, ptr0, true);
  };
  imports["rb-js-abi-host"]["js-value-to-integer: func(value: u32) -> variant { f64(float64), bignum(string) }"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.jsValueToInteger(arg0 >>> 0);
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
  imports["rb-js-abi-host"]["export-js-value-to-host: func(value: u32) -> ()"] = function(arg0) {
    obj.exportJsValueToHost(arg0 >>> 0);
  };
  imports["rb-js-abi-host"]["import-js-value-from-host: func() -> u32"] = function() {
    const ret0 = obj.importJsValueFromHost();
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["js-value-typeof: func(value: u32) -> string"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.jsValueTypeof(arg0 >>> 0);
    const ptr0 = utf8_encode(ret0, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    data_view(memory).setInt32(arg1 + 4, len0, true);
    data_view(memory).setInt32(arg1 + 0, ptr0, true);
  };
  imports["rb-js-abi-host"]["js-value-equal: func(lhs: u32, rhs: u32) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.jsValueEqual(arg0 >>> 0, arg1 >>> 0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["js-value-strictly-equal: func(lhs: u32, rhs: u32) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.jsValueStrictlyEqual(arg0 >>> 0, arg1 >>> 0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-apply: func(target: u32, this-argument: u32, arguments: list<u32>) -> variant { success(u32), failure(u32) }"] = function(arg0, arg1, arg2, arg3, arg4) {
    const memory = get_export("memory");
    const ptr0 = arg2;
    const len0 = arg3;
    const result0 = new Uint32Array(memory.buffer.slice(ptr0, ptr0 + len0 * 4));
    const ret0 = obj.reflectApply(arg0 >>> 0, arg1 >>> 0, result0);
    const variant1 = ret0;
    switch (variant1.tag) {
      case "success": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 0, true);
        data_view(memory).setInt32(arg4 + 4, to_uint32(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 1, true);
        data_view(memory).setInt32(arg4 + 4, to_uint32(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["reflect-construct: func(target: u32, arguments: list<u32>) -> u32"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = new Uint32Array(memory.buffer.slice(ptr0, ptr0 + len0 * 4));
    const ret0 = obj.reflectConstruct(arg0 >>> 0, result0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["reflect-delete-property: func(target: u32, property-key: string) -> bool"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectDeleteProperty(arg0 >>> 0, result0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-get: func(target: u32, property-key: string) -> variant { success(u32), failure(u32) }"] = function(arg0, arg1, arg2, arg3) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectGet(arg0 >>> 0, result0);
    const variant1 = ret0;
    switch (variant1.tag) {
      case "success": {
        const e = variant1.val;
        data_view(memory).setInt8(arg3 + 0, 0, true);
        data_view(memory).setInt32(arg3 + 4, to_uint32(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg3 + 0, 1, true);
        data_view(memory).setInt32(arg3 + 4, to_uint32(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["reflect-get-own-property-descriptor: func(target: u32, property-key: string) -> u32"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectGetOwnPropertyDescriptor(arg0 >>> 0, result0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["reflect-get-prototype-of: func(target: u32) -> u32"] = function(arg0) {
    const ret0 = obj.reflectGetPrototypeOf(arg0 >>> 0);
    return to_uint32(ret0);
  };
  imports["rb-js-abi-host"]["reflect-has: func(target: u32, property-key: string) -> bool"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectHas(arg0 >>> 0, result0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-is-extensible: func(target: u32) -> bool"] = function(arg0) {
    const ret0 = obj.reflectIsExtensible(arg0 >>> 0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-own-keys: func(target: u32) -> list<u32>"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("cabi_realloc");
    const ret0 = obj.reflectOwnKeys(arg0 >>> 0);
    const val0 = ret0;
    const len0 = val0.length;
    const ptr0 = realloc(0, 0, 4, len0 * 4);
    (new Uint8Array(memory.buffer, ptr0, len0 * 4)).set(new Uint8Array(val0.buffer, val0.byteOffset, len0 * 4));
    data_view(memory).setInt32(arg1 + 4, len0, true);
    data_view(memory).setInt32(arg1 + 0, ptr0, true);
  };
  imports["rb-js-abi-host"]["reflect-prevent-extensions: func(target: u32) -> bool"] = function(arg0) {
    const ret0 = obj.reflectPreventExtensions(arg0 >>> 0);
    return ret0 ? 1 : 0;
  };
  imports["rb-js-abi-host"]["reflect-set: func(target: u32, property-key: string, value: u32) -> variant { success(u32), failure(u32) }"] = function(arg0, arg1, arg2, arg3, arg4) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const result0 = UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0));
    const ret0 = obj.reflectSet(arg0 >>> 0, result0, arg3 >>> 0);
    const variant1 = ret0;
    switch (variant1.tag) {
      case "success": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 0, true);
        data_view(memory).setInt32(arg4 + 4, to_uint32(e), true);
        break;
      }
      case "failure": {
        const e = variant1.val;
        data_view(memory).setInt8(arg4 + 0, 1, true);
        data_view(memory).setInt32(arg4 + 4, to_uint32(e), true);
        break;
      }
      default:
      throw new RangeError("invalid variant specified for JsAbiResult");
    }
  };
  imports["rb-js-abi-host"]["reflect-set-prototype-of: func(target: u32, prototype: u32) -> bool"] = function(arg0, arg1) {
    const ret0 = obj.reflectSetPrototypeOf(arg0 >>> 0, arg1 >>> 0);
    return ret0 ? 1 : 0;
  };
}