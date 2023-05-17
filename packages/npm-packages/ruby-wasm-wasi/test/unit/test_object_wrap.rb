require "test-unit"
require "js"

class JS::TestObjectWrap < Test::Unit::TestCase
  def test_identity
    intrinsics = JS.eval(<<-JS)
      return { identity(v) { return v } }
    JS
    o1 = Object.new
    o1_clone = intrinsics.call(:identity, JS::Object.wrap(o1))
    assert_equal o1.object_id, o1_clone.call("call", "object_id").call("toJS").to_i
  end
end
