export namespace RubyJsRubyRuntime {
  export function rubyShowVersion(): void;
  export function rubyInit(): void;
  export function rubySysinit(args: string[]): void;
  export function rubyOptions(args: string[]): RbIseq;
  export function rubyScript(name: string): void;
  export function rubyInitLoadpath(): void;
  export function rbEvalStringProtect(str: string): [RbAbiValue, number];
  export function rbFuncallvProtect(recv: RbAbiValue, mid: RbId, args: RbAbiValue[]): [RbAbiValue, number];
  export function rbIntern(name: string): RbId;
  export function rbErrinfo(): RbAbiValue;
  export function rbClearErrinfo(): void;
  export function rstringPtr(value: RbAbiValue): string;
  export function rbVmBugreport(): void;
  export function rbGcEnable(): boolean;
  export function rbGcDisable(): boolean;
  export function rbSetShouldProhibitRewind(newValue: boolean): boolean;
  export { RbIseq };
  export { RbAbiValue };
}
import type { JsAbiValue } from './ruby-js-js-runtime.js';
export { JsAbiValue };
export type RbErrno = number;
export type RbId = number;

export class RbIseq {
}

export class RbAbiValue {
}
