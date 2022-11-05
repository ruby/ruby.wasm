require "test-unit"
require "js"

class JS::TestAsync < Test::Unit::TestCase
  def test_await_promise_resolve
    promise = JS.eval("return Promise.resolve(42)")
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
end
