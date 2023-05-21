/**
* A JavaScript value. In the future, this will be replaced by handle types.
* The underlying value should be owned by the JavaScript host environment
* and should live at least until all handles to it are dropped.
*/
export type JsAbiValue = number;
export type JsAbiResult = JsAbiResultSuccess | JsAbiResultFailure;
export interface JsAbiResultSuccess {
  tag: "success",
  val: JsAbiValue,
}
export interface JsAbiResultFailure {
  tag: "failure",
  val: JsAbiValue,
}
export type RawInteger = RawIntegerF64 | RawIntegerBignum;
export interface RawIntegerF64 {
  tag: "f64",
  val: number,
}
export interface RawIntegerBignum {
  tag: "bignum",
  val: string,
}
export function addRbJsAbiHostToImports(imports: any, obj: RbJsAbiHost, get_export: (name: string) => WebAssembly.ExportValue): void;
export interface RbJsAbiHost {
  evalJs(code: string): JsAbiResult;
  isJs(value: JsAbiValue): boolean;
  instanceOf(value: JsAbiValue, klass: JsAbiValue): boolean;
  globalThis(): JsAbiValue;
  intToJsNumber(value: number): JsAbiValue;
  floatToJsNumber(value: number): JsAbiValue;
  stringToJsString(value: string): JsAbiValue;
  boolToJsBool(value: boolean): JsAbiValue;
  procToJsFunction(value: number): JsAbiValue;
  rbObjectToJsRbValue(rawRbAbiValue: number): JsAbiValue;
  jsValueToString(value: JsAbiValue): string;
  jsValueToInteger(value: JsAbiValue): RawInteger;
  exportJsValueToHost(value: JsAbiValue): void;
  importJsValueFromHost(): JsAbiValue;
  jsValueTypeof(value: JsAbiValue): string;
  jsValueEqual(lhs: JsAbiValue, rhs: JsAbiValue): boolean;
  jsValueStrictlyEqual(lhs: JsAbiValue, rhs: JsAbiValue): boolean;
  reflectApply(target: JsAbiValue, thisArgument: JsAbiValue, arguments: Uint32Array): JsAbiResult;
  reflectConstruct(target: JsAbiValue, arguments: Uint32Array): JsAbiValue;
  reflectDeleteProperty(target: JsAbiValue, propertyKey: string): boolean;
  reflectGet(target: JsAbiValue, propertyKey: string): JsAbiResult;
  reflectGetOwnPropertyDescriptor(target: JsAbiValue, propertyKey: string): JsAbiValue;
  reflectGetPrototypeOf(target: JsAbiValue): JsAbiValue;
  reflectHas(target: JsAbiValue, propertyKey: string): boolean;
  reflectIsExtensible(target: JsAbiValue): boolean;
  reflectOwnKeys(target: JsAbiValue): Uint32Array;
  reflectPreventExtensions(target: JsAbiValue): boolean;
  reflectSet(target: JsAbiValue, propertyKey: string, value: JsAbiValue): JsAbiResult;
  reflectSetPrototypeOf(target: JsAbiValue, prototype: JsAbiValue): boolean;
}
