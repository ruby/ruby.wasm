require "test-unit"
require "js"

class TestNilClass < Test::Unit::TestCase
  def test_to_js
    assert_same JS::Null, nil.to_js
    assert_equal "null", nil.to_js.to_s
  end
end
