require "test-unit"
require "js"

class TestHash < Test::Unit::TestCase
  def test_to_js
    assert_true({ a: 1, b: "two", c: [3] }.to_js.is_a?(JS::Object))
  end

  def test_to_js_convert_members_to_js_object
    js_hash = { a: 1, b: "two", c: [3] }.to_js

    assert_true js_hash.is_a?(JS::Object)
    assert_equal 1, js_hash[:a].to_i
    assert_equal "two", js_hash[:b].to_s
    assert_equal 3, js_hash[:c][0].to_i
  end
end
