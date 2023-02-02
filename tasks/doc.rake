require "rdoc/task"
require "ruby_wasm/version"

RDoc::Task.new do |doc|
  doc.main = "README.md"
  doc.title = "ruby.wasm #{RubyWasm::VERSION} Documentation"
  doc.rdoc_files = FileList.new %w[*.md lib/**/*.rb ext/**/*.c ext/**/*.rb]
end
