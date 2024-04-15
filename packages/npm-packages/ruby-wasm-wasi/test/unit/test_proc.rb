require "test-unit"
require "js"

class JS::TestProc < Test::Unit::TestCase
  def test_with_js_call
    function_to_call = JS.eval("return { a: (callback) => { callback(1) } }")
    b = nil
    function_to_call.call(:a, Proc.new { |a| b = a.to_i })
    assert_equal 1, b

    # Implicit conversion from block to Proc.
    function_to_call.call(:a) { |a| b = a.to_i }
    assert_equal 1, b
  end

  def test_store_in_js
    function_to_call = JS.eval(<<~JS)
      let callback;
      return {
        set: (c) => { callback = c },
        invoke: () => { callback(1) }
      }
    JS
    b = nil
    function_to_call.call(:set) { |a| b = a.to_i }
    function_to_call.call(:invoke)
    assert_equal 1, b
  end

  def test_return_value
    obj = JS.eval(<<~JS)
      return { check: (callback) => { return callback(1) } }
    JS
    assert_equal 4, obj.call(:check, ->(a) { 3 + a.to_i }).to_i
  end
end
