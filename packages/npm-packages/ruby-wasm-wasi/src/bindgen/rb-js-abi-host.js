import { data_view, UTF8_DECODER, utf8_encode, UTF8_ENCODED_LEN, Slab } from './intrinsics.js';
export function addRbJsAbiHostToImports(imports, obj, get_export) {
  if (!("rb-js-abi-host" in imports)) imports["rb-js-abi-host"] = {};
  imports["rb-js-abi-host"]["eval-js"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const ptr0 = arg0;
    const len0 = arg1;
    const ret = obj.evalJs(UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0)));
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["is-js"] = function(arg0) {
    const ret = obj.isJs(resources0.get(arg0));
    const variant0 = ret;
    let variant0_0;
    switch (variant0) {
      case false: {
        variant0_0 = 0;
        break;
      }
      case true: {
        variant0_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant0_0;
  };
  imports["rb-js-abi-host"]["instance-of"] = function(arg0, arg1) {
    const ret = obj.instanceOf(resources0.get(arg0), resources0.get(arg1));
    const variant0 = ret;
    let variant0_0;
    switch (variant0) {
      case false: {
        variant0_0 = 0;
        break;
      }
      case true: {
        variant0_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant0_0;
  };
  imports["rb-js-abi-host"]["global-this"] = function() {
    const ret = obj.globalThis();
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["int-to-js-number"] = function(arg0) {
    const ret = obj.intToJsNumber(arg0);
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["string-to-js-string"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const ptr0 = arg0;
    const len0 = arg1;
    const ret = obj.stringToJsString(UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0)));
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["bool-to-js-bool"] = function(arg0) {
    let variant0;
    switch (arg0) {
      case 0: {
        variant0 = false;
        break;
      }
      case 1: {
        variant0 = true;
        break;
      }
      default:
      throw new RangeError("invalid variant discriminant for bool");
    }
    const ret = obj.boolToJsBool(variant0);
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["proc-to-js-function"] = function(arg0) {
    const ret = obj.procToJsFunction(arg0 >>> 0);
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["rb-object-to-js-rb-value"] = function(arg0) {
    const ret = obj.rbObjectToJsRbValue(arg0 >>> 0);
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["js-value-to-string"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("canonical_abi_realloc");
    const ret = obj.jsValueToString(resources0.get(arg0));
    const ptr0 = utf8_encode(ret, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    data_view(memory).setInt32(arg1 + 8, len0, true);
    data_view(memory).setInt32(arg1 + 0, ptr0, true);
  };
  imports["rb-js-abi-host"]["export-js-value-to-host"] = function(arg0) {
    obj.exportJsValueToHost(resources0.get(arg0));
  };
  imports["rb-js-abi-host"]["import-js-value-from-host"] = function() {
    const ret = obj.importJsValueFromHost();
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["js-value-typeof"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("canonical_abi_realloc");
    const ret = obj.jsValueTypeof(resources0.get(arg0));
    const ptr0 = utf8_encode(ret, realloc, memory);
    const len0 = UTF8_ENCODED_LEN;
    data_view(memory).setInt32(arg1 + 8, len0, true);
    data_view(memory).setInt32(arg1 + 0, ptr0, true);
  };
  imports["rb-js-abi-host"]["js-value-equal"] = function(arg0, arg1) {
    const ret = obj.jsValueEqual(resources0.get(arg0), resources0.get(arg1));
    const variant0 = ret;
    let variant0_0;
    switch (variant0) {
      case false: {
        variant0_0 = 0;
        break;
      }
      case true: {
        variant0_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant0_0;
  };
  imports["rb-js-abi-host"]["js-value-strictly-equal"] = function(arg0, arg1) {
    const ret = obj.jsValueStrictlyEqual(resources0.get(arg0), resources0.get(arg1));
    const variant0 = ret;
    let variant0_0;
    switch (variant0) {
      case false: {
        variant0_0 = 0;
        break;
      }
      case true: {
        variant0_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant0_0;
  };
  imports["rb-js-abi-host"]["reflect-apply"] = function(arg0, arg1, arg2, arg3) {
    const memory = get_export("memory");
    const len0 = arg3;
    const base0 = arg2;
    const result0 = [];
    for (let i = 0; i < len0; i++) {
      const base = base0 + i * 4;
      result0.push(resources0.get(data_view(memory).getInt32(base + 0, true)));
    }
    const ret = obj.reflectApply(resources0.get(arg0), resources0.get(arg1), result0);
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["reflect-construct"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const len0 = arg2;
    const base0 = arg1;
    const result0 = [];
    for (let i = 0; i < len0; i++) {
      const base = base0 + i * 4;
      result0.push(resources0.get(data_view(memory).getInt32(base + 0, true)));
    }
    const ret = obj.reflectConstruct(resources0.get(arg0), result0);
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["reflect-delete-property"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const ret = obj.reflectDeleteProperty(resources0.get(arg0), UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0)));
    const variant1 = ret;
    let variant1_0;
    switch (variant1) {
      case false: {
        variant1_0 = 0;
        break;
      }
      case true: {
        variant1_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant1_0;
  };
  imports["rb-js-abi-host"]["reflect-get"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const ret = obj.reflectGet(resources0.get(arg0), UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0)));
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["reflect-get-own-property-descriptor"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const ret = obj.reflectGetOwnPropertyDescriptor(resources0.get(arg0), UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0)));
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["reflect-get-prototype-of"] = function(arg0) {
    const ret = obj.reflectGetPrototypeOf(resources0.get(arg0));
    return resources0.insert(ret);
  };
  imports["rb-js-abi-host"]["reflect-has"] = function(arg0, arg1, arg2) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const ret = obj.reflectHas(resources0.get(arg0), UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0)));
    const variant1 = ret;
    let variant1_0;
    switch (variant1) {
      case false: {
        variant1_0 = 0;
        break;
      }
      case true: {
        variant1_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant1_0;
  };
  imports["rb-js-abi-host"]["reflect-is-extensible"] = function(arg0) {
    const ret = obj.reflectIsExtensible(resources0.get(arg0));
    const variant0 = ret;
    let variant0_0;
    switch (variant0) {
      case false: {
        variant0_0 = 0;
        break;
      }
      case true: {
        variant0_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant0_0;
  };
  imports["rb-js-abi-host"]["reflect-own-keys"] = function(arg0, arg1) {
    const memory = get_export("memory");
    const realloc = get_export("canonical_abi_realloc");
    const ret = obj.reflectOwnKeys(resources0.get(arg0));
    const vec0 = ret;
    const len0 = vec0.length;
    const result0 = realloc(0, 0, 4, len0 * 4);
    for (let i = 0; i < vec0.length; i++) {
      const e = vec0[i];
      const base = result0 + i * 4;
      data_view(memory).setInt32(base + 0, resources0.insert(e), true);
    }
    data_view(memory).setInt32(arg1 + 8, len0, true);
    data_view(memory).setInt32(arg1 + 0, result0, true);
  };
  imports["rb-js-abi-host"]["reflect-prevent-extensions"] = function(arg0) {
    const ret = obj.reflectPreventExtensions(resources0.get(arg0));
    const variant0 = ret;
    let variant0_0;
    switch (variant0) {
      case false: {
        variant0_0 = 0;
        break;
      }
      case true: {
        variant0_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant0_0;
  };
  imports["rb-js-abi-host"]["reflect-set"] = function(arg0, arg1, arg2, arg3) {
    const memory = get_export("memory");
    const ptr0 = arg1;
    const len0 = arg2;
    const ret = obj.reflectSet(resources0.get(arg0), UTF8_DECODER.decode(new Uint8Array(memory.buffer, ptr0, len0)), resources0.get(arg3));
    const variant1 = ret;
    let variant1_0;
    switch (variant1) {
      case false: {
        variant1_0 = 0;
        break;
      }
      case true: {
        variant1_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant1_0;
  };
  imports["rb-js-abi-host"]["reflect-set-prototype-of"] = function(arg0, arg1) {
    const ret = obj.reflectSetPrototypeOf(resources0.get(arg0), resources0.get(arg1));
    const variant0 = ret;
    let variant0_0;
    switch (variant0) {
      case false: {
        variant0_0 = 0;
        break;
      }
      case true: {
        variant0_0 = 1;
        break;
      }
      default:
      throw new RangeError("invalid variant specified for bool");
    }
    return variant0_0;
  };
  if (!("canonical_abi" in imports)) imports["canonical_abi"] = {};
  
  const resources0 = new Slab();
  imports.canonical_abi["resource_drop_js-abi-value"] = (i) => {
    const val = resources0.remove(i);
    if (obj.dropJsAbiValue)
    obj.dropJsAbiValue(val);
  };
}