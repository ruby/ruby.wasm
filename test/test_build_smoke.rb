require "test-unit"
require "tmpdir"
require "bundler"

class TestBuildSmoke < Test::Unit::TestCase
  def run_rbwasm(*args)
    rbwasm_path = File.expand_path("../../exe/rbwasm", __FILE__)
    system("bundle", "exec", rbwasm_path, *args, exception: true)
  end

  def run_wasmtime(*args)
    IO.popen(["wasmtime", *args], &:read)
  end

  def test_build_rack
    Dir.mktmpdir do |dir|
      gemfile_path = File.join(dir, "Gemfile")
      output_path = File.join(dir, "output.wasm")

      File.write(gemfile_path, <<-GEMFILE)
      source "https://rubygems.org"
      gem "rack", "3.0.8"
      GEMFILE
      Bundler.with_unbundled_env do
        ENV["RUBY_WASM_ROOT"] = File.expand_path("../../", __FILE__)
        ENV["BUNDLE_GEMFILE"] = gemfile_path
        assert system("bundle", "install")
        run_rbwasm("build", "-o", output_path)
        assert_equal "Rack::RELEASE=3.0.8\n",
                     run_wasmtime(
                       output_path,
                       "-r/bundle/setup.rb",
                       "-rrack",
                       "-e",
                       "puts \"Rack::RELEASE=\#{Rack::RELEASE}\""
                     )
      end
    end
  end
end
