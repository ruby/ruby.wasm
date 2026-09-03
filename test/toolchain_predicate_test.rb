require "test-unit"
require_relative "../lib/ruby_wasm/build/toolchain"
# require "bundler"

class ToolchainPredicateTest < Test::Unit::TestCase
  def test_base_toolchain_is_not_wasi_sysroot
    assert_equal false, Class.new(RubyWasm::Toolchain).allocate.wasi_sysroot?
  end

  def test_wasi_sdk_is_wasi_sysroot
    assert_equal true, Class.new(RubyWasm::WASISDK).allocate.wasi_sysroot?
  end

  def test_emscripten_is_not_wasi_sysroot
    assert_equal false, Class.new(RubyWasm::Emscripten).allocate.wasi_sysroot?
  end
end