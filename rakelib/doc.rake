require "rdoc/task"
require "ruby_wasm/version"

RDoc::Task.new do |doc|
  doc.main = "README.md"
  doc.title = "ruby.wasm Documentation"
  doc.rdoc_files = FileList.new %w[*.md packages/gems/js/ext/**/*.c packages/gems/js/lib/**/*.rb]
end

namespace :doc do
  desc "Update docs/api/javascript.md"
  task :api_js do
    sh "npx",
       "documentation",
       "readme",
       "--readme-file",
       "./packages/npm-packages/ruby-wasm-wasi/README.md",
       "--section",
       "API",
       "--markdown-toc",
       "false",
       "./packages/npm-packages/ruby-wasm-wasi/dist/esm/index.js"
  end
end
