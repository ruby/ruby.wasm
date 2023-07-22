require "test-unit"
require "js"

class TestArray < Test::Unit::TestCase
  def test_to_js
    assert_true [true, false, nil, 1, "b", { name: "Alice" }].to_js.is_a?(
                  JS::Object
                )
    assert_equal 3, [1, "b", 3].to_js[:length].to_i
  end

  def test_to_js_convert_members_to_js_object
    js_array = [1, "b", { name: "Alice" }].to_js

    assert_true js_array[0].is_a?(JS::Object)
    assert_equal 1, js_array[0].to_i
    assert_equal "b", js_array[1].to_s
    assert_equal "Alice", js_array[2][:name].to_s
  end
end
