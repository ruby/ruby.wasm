# frozen_string_literal: true

require_relative "lib/ruby_wasm/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_wasm"
  spec.version = RubyWasm::VERSION
  spec.authors = ["Yuta Saito"]
  spec.email = ["kateinoigakukun@gmail.com"]

  spec.summary = %q{Ruby to WebAssembly toolkit}
  spec.description = %q{Ruby to WebAssembly toolkit. This gem takes Ruby code and Gemfile, and packages them with Ruby runtime into a WebAssembly binary.}
  spec.homepage = "https://github.com/ruby/ruby.wasm"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}) ||
        f.match(%r{\A(?:packages|builders|vendor)/})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/ruby_wasm/Cargo.toml"]
end
