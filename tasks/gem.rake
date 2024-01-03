require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

begin
  require "rb_sys/extensiontask"

  RbSys::ExtensionTask.new("ruby_wasm") { |ext| ext.lib_dir = "lib/ruby_wasm" }
rescue LoadError => e
  task :compile do
    $stderr.puts "Skipping compilation of ruby_wasm extension: #{e.message}"
    exit 1
  end
end
