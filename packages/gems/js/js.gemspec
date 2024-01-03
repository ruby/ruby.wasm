# frozen_string_literal: true

require_relative "../../../lib/ruby_wasm/version"

Gem::Specification.new do |spec|
  spec.name = "js"
  spec.version = RubyWasm::VERSION
  spec.authors = ["Yuta Saito"]
  spec.email = ["kateinoigakukun@gmail.com"]

  spec.summary = "JavaScript bindings for ruby.wasm"

  spec.license = "MIT"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/js/extconf.rb", "ext/witapi/extconf.rb"]
end
