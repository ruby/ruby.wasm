export function addRbJsAbiHostToImports(imports: any, obj: RbJsAbiHost, get_export: (name: string) => WebAssembly.ExportValue): void;
export interface RbJsAbiHost {
  evalJs(code: string): JsAbiValue;
  isJs(value: JsAbiValue): boolean;
  instanceOf(value: JsAbiValue, klass: JsAbiValue): boolean;
  globalThis(): JsAbiValue;
  intToJsNumber(value: number): JsAbiValue;
  stringToJsString(value: string): JsAbiValue;
  boolToJsBool(value: boolean): JsAbiValue;
  procToJsFunction(value: number): JsAbiValue;
  rbObjectToJsRbValue(rawRbAbiValue: number): JsAbiValue;
  jsValueToString(value: JsAbiValue): string;
  exportJsValueToHost(value: JsAbiValue): void;
  importJsValueFromHost(): JsAbiValue;
  jsValueTypeof(value: JsAbiValue): string;
  jsValueEqual(lhs: JsAbiValue, rhs: JsAbiValue): boolean;
  jsValueStrictlyEqual(lhs: JsAbiValue, rhs: JsAbiValue): boolean;
  reflectApply(target: JsAbiValue, thisArgument: JsAbiValue, arguments: JsAbiValue[]): JsAbiValue;
  reflectConstruct(target: JsAbiValue, arguments: JsAbiValue[]): JsAbiValue;
  reflectDeleteProperty(target: JsAbiValue, propertyKey: string): boolean;
  reflectGet(target: JsAbiValue, propertyKey: string): JsAbiValue;
  reflectGetOwnPropertyDescriptor(target: JsAbiValue, propertyKey: string): JsAbiValue;
  reflectGetPrototypeOf(target: JsAbiValue): JsAbiValue;
  reflectHas(target: JsAbiValue, propertyKey: string): boolean;
  reflectIsExtensible(target: JsAbiValue): boolean;
  reflectOwnKeys(target: JsAbiValue): JsAbiValue[];
  reflectPreventExtensions(target: JsAbiValue): boolean;
  reflectSet(target: JsAbiValue, propertyKey: string, value: JsAbiValue): boolean;
  reflectSetPrototypeOf(target: JsAbiValue, prototype: JsAbiValue): boolean;
  dropJsAbiValue?: (val: JsAbiValue) => void;
}
export interface JsAbiValue {
}
