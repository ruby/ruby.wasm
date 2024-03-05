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

  def test_try_convert
    assert_nil JS.try_convert(Object.new)
  end

  def test_constasts
    assert_equal "null", JS::Null.to_s
    assert_equal "undefined", JS::Undefined.to_s
    assert_equal "true", JS::True.to_s
    assert_equal "false", JS::False.to_s
  end

  def test_create_promise
    promise =
      JS.create_promise do
        reciever = JS.global[:Object].new
        reciever[:resolve] = _1
        reciever.resolve(42)
      end
    assert_equal 42, promise.await.to_i
  end

  def test_create_promise_with_set_timeout_function
    assert_equal JS::Undefined.to_s,
                 JS.create_promise { JS.global.setTimeout(_1, 0) }.await.to_s
  end
end
