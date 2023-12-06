require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

require "rb_sys/extensiontask"

RbSys::ExtensionTask.new("ruby_wasm") { |ext| ext.lib_dir = "lib/ruby_wasm" }
