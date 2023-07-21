require 'test-unit'
require 'js'

class TestArray < Test::Unit::TestCase
  def test_initialize
    assert_true JS::Array.new([0]).is_a?(JS::Array)
    assert_true JS::Array.new([1, 2, 3]).is_a?(JS::Array)
    assert_true JS::Array.new(['a', 'b', 'c']).is_a?(JS::Array)
    assert_true JS::Array.new([{name: 'Alice'}, {name: 'Bob'}]).is_a?(JS::Array)
  end

  def test_to_a_returns_wrapped_js_object
    assert_true JS::Array.new([1, 2, 3]).to_a.is_a?(JS::Object)
    assert_true JS::Array.new(['a', 'b', 'c']).to_a.typeof == 'object'
    assert_equal 2, JS::Array.new([{name: 'Alice'}, {name: 'Bob'}]).to_a[:length].to_i
  end

  def test_members_of_array
    assert_equal 0, JS::Array.new([0]).to_a[0].to_i
    assert_equal 1, JS::Array.new([0, 1]).to_a[1].to_i
    assert_equal 2, JS::Array.new([0, 1, 2]).to_a[2].to_i
    assert_equal 'a', JS::Array.new(['a', 'b', 'c']).to_a[0].to_s
    assert_equal 'b', JS::Array.new(['a', 'b', 'c']).to_a[1].to_s
    assert_equal 'c', JS::Array.new(['a', 'b', 'c']).to_a[2].to_s
    assert_equal 'Alice', JS::Array.new([{name: 'Alice'}, {name: 'Bob'}]).to_a[0][:name].to_s
    assert_equal 'Bob', JS::Array.new([{name: 'Alice'}, {name: 'Bob'}]).to_a[1][:name].to_s
  end
end
