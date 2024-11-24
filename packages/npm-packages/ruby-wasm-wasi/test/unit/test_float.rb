require "test-unit"
require "js"

class JS::TestFloat < Test::Unit::TestCase
  def test_to_js
    assert_equal (1.0).to_js, JS.eval("return 1.0;")
    assert_equal (0.5).to_js, JS.eval("return 0.5;")
    assert_equal (0.3).to_js, JS.eval("return 0.3;")
  end
end
