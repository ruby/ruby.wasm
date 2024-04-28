export namespace RubyJsJsRuntime {
  export function evalJs(code: string): JsAbiResult;
  export function isJs(value: JsAbiValue): boolean;
  export function instanceOf(value: JsAbiValue, klass: JsAbiValue): boolean;
  export function globalThis(): JsAbiValue;
  export function intToJsNumber(value: number): JsAbiValue;
  export function floatToJsNumber(value: number): JsAbiValue;
  export function stringToJsString(value: string): JsAbiValue;
  export function boolToJsBool(value: boolean): JsAbiValue;
  export function procToJsFunction(): JsAbiValue;
  export function rbObjectToJsRbValue(): JsAbiValue;
  export function jsValueToString(value: JsAbiValue): string;
  export function jsValueToInteger(value: JsAbiValue): RawInteger;
  export function exportJsValueToHost(value: JsAbiValue): void;
  export function importJsValueFromHost(): JsAbiValue;
  export function jsValueTypeof(value: JsAbiValue): string;
  export function jsValueEqual(lhs: JsAbiValue, rhs: JsAbiValue): boolean;
  export function jsValueStrictlyEqual(lhs: JsAbiValue, rhs: JsAbiValue): boolean;
  export function reflectApply(target: JsAbiValue, thisArgument: JsAbiValue, arguments: JsAbiValue[]): JsAbiResult;
  export function reflectGet(target: JsAbiValue, propertyKey: string): JsAbiResult;
  export function reflectSet(target: JsAbiValue, propertyKey: string, value: JsAbiValue): JsAbiResult;
  export function throwProhibitRewindException(message: string): void;
  export { JsAbiValue };
}
export type JsAbiResult = JsAbiResultSuccess | JsAbiResultFailure;
export interface JsAbiResultSuccess {
  tag: 'success',
  val: JsAbiValue,
}
export interface JsAbiResultFailure {
  tag: 'failure',
  val: JsAbiValue,
}
export type RawInteger = RawIntegerAsFloat | RawIntegerBignum;
export interface RawIntegerAsFloat {
  tag: 'as-float',
  val: number,
}
export interface RawIntegerBignum {
  tag: 'bignum',
  val: string,
}

export class JsAbiValue {
}
