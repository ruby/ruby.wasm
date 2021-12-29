import { createRubyModule } from "./dist/ruby"
import { loadRubyStdlib } from "./dist/ruby_stdlib"

export const loadRuby = async (defaultModule) => {
  const RubyModule = await createRubyModule(defaultModule);
  globalThis.__ruby_module = RubyModule;
  loadRubyStdlib();
  return RubyModule;
}
