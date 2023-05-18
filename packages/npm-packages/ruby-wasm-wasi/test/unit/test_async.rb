require "test-unit"
require "js"

class JS::TestAsync < Test::Unit::TestCase
  def test_await_promise_resolve
    promise = JS.eval("return Promise.resolve(42)")
    assert_equal 42, promise.await.to_i
    # Promise can be resolved multiple times.
    assert_equal 42, promise.await.to_i
  end

  def test_await_promise_reject
    promise = JS.eval("return Promise.reject(42)")
    e = assert_raise(JS::Error) { promise.await }
    assert_equal "42", e.message
  end

  def test_await_promise_chained
    promise = JS.eval("return Promise.resolve(42).then(x => x + 1)")
    assert_equal 43, promise.await.to_i
  end

  def test_await_non_promise
    assert_equal 42, JS.eval("return 42").await.to_i
  end

  def make_promise_and_continuation
    JS.eval(<<~JS)
      let continuation = null;
      const promise = new Promise((resolve, reject) => {
        continuation = { resolve, reject };
      });
      return { promise, continuation };
    JS
  end

  def test_concurrent_promises
    pac0 = make_promise_and_continuation
    pac1 = make_promise_and_continuation
    pac0[:continuation].resolve(42)
    pac1[:continuation].resolve(43)
    assert_equal 43, pac1[:promise].await.to_i
    assert_equal 42, pac0[:promise].await.to_i
  end

  def test_await_in_fiber
    fiber_ended = false
    Fiber
      .new do
        promise = JS.eval("return Promise.resolve(42)")
        assert_equal 42, promise.await.to_i
        fiber_ended = true
      end
      .resume
    assert_equal true, fiber_ended
  end
end
