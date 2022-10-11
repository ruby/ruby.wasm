require "test-unit"
require "js"

class JS::TestJS < Test::Unit::TestCase
  def test_is_a?
    # A ruby object always returns false
    assert_false JS.is_a?(1, Integer)
    assert_false JS.is_a?("x", String)
    # A js object is not an instance of itself
    assert_false JS.is_a?(JS.global, JS.global)
    # globalThis is an instance of Object
    assert_true JS.is_a?(JS.global, JS.global[:Object])
  end

  def test_eval
    JS.eval("var x = 42;")
    # Variable scope is isolated in each JS.eval
    assert_equal "not defined", JS.eval(<<~JS).to_s
      try {
        return x;
      } catch {
        return "not defined";
      }
    JS
  end
end
