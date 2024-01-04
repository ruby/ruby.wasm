require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

begin
  require "rb_sys/extensiontask"

  gemspec = Gem::Specification.load("ruby_wasm.gemspec")
  RbSys::ExtensionTask.new("ruby_wasm", gemspec) do |ext|
    ext.lib_dir = "lib/ruby_wasm"
  end
rescue LoadError => e
  task :compile do
    $stderr.puts "Skipping compilation of ruby_wasm extension: #{e.message}"
    exit 1
  end
end
