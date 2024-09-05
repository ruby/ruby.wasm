require "rdoc/task"
require "ruby_wasm/version"

RDoc::Task.new do |doc|
  doc.main = "README.md"
  doc.title = "ruby.wasm Documentation"
  doc.rdoc_files =
    FileList.new %w[
                   *.md
                   packages/gems/js/ext/**/*.c
                   packages/gems/js/lib/**/*.rb
                 ]
end

desc "Generate TypeScript documentation"
task :typedoc do
  sh "npm install"
  mkdir_p "html/npm/@ruby/wasm-wasi"
  sh "npx typedoc packages/npm-packages/ruby-wasm-wasi/src/index.ts --sort source-order --out html/npm/@ruby/wasm-wasi"
end

desc "Generate documentation site"
task :doc do
  Rake::Task["rdoc"].invoke
  Rake::Task["typedoc"].invoke
end
