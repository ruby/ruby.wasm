# frozen_string_literal: true

require_relative "lib/js/version"

Gem::Specification.new do |spec|
  spec.name = "js"
  spec.version = JS::VERSION
  spec.authors = ["Yuta Saito"]
  spec.email = ["kateinoigakukun@gmail.com"]

  spec.summary = %q{JavaScript bindings for ruby.wasm}
  spec.description = %q{JavaScript bindings for ruby.wasm. This gem provides a way to use JavaScript functionalities from Ruby through WebAssembly.}
  spec.homepage = "https://github.com/ruby/ruby.wasm"

  spec.metadata = {
    "source_code_uri" => "https://github.com/ruby/ruby.wasm/tree/main/packages/gems/js",
  }

  spec.license = "MIT"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/js/extconf.rb"]
end
