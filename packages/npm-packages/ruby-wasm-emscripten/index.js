import createRubyModule from "./dist/ruby";
import { loadRubyStdlib } from "./dist/ruby_stdlib";

export const loadRuby = async (defaultModule) => {
  const RubyModule = defaultModule;
  globalThis.__ruby_module = RubyModule;
  loadRubyStdlib();
  await createRubyModule(RubyModule);
  return RubyModule;
}
