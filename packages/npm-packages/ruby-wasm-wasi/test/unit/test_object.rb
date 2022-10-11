require "test-unit"
require "js"

class JS::TestObject < Test::Unit::TestCase
  def test_typeof
    assert_equal "number", JS.eval("return 1;").typeof
    assert_equal "boolean", JS.eval("return true;").typeof
    assert_equal "string", JS.eval("return 'x';").typeof
    assert_equal "object", JS.eval("return null;").typeof
    assert_equal "undefined", JS.eval("return undefined;").typeof
    assert_equal "object", JS.global.typeof
  end

  def assert_object_eql?(result, a, b)
    assert_equal result, a == b
    assert_equal !result, a != b
    assert_equal result, a.eql?(b)
    assert_equal result, b.eql?(a)
  end

  def test_eql?
    assert_object_eql? true, JS.eval("return 24;"), JS.eval("return 24;")
    assert_object_eql? true, JS.eval("return null;"), JS.eval("return null;")
    assert_object_eql? true,
                       JS.eval("return undefined;"),
                       JS.eval("return undefined;")
    assert_object_eql? true, JS.eval("return 'x';"), JS.eval("return 'x';")
    assert_object_eql? true,
                       JS.eval("return null;"),
                       JS.eval("return undefined;")

    assert_object_eql? false, JS.eval("return 24;"), JS.eval("return 42;")
    assert_object_eql? false, JS.eval("return NaN;"), JS.eval("return NaN;")
  end

  def assert_object_strictly_eql?(result, a, b)
    assert_equal result, a.strictly_eql?(b)
    assert_equal result, b.strictly_eql?(a)
  end

  def test_strictly_eql?
    assert_object_strictly_eql? true,
                                JS.eval("return 24;"),
                                JS.eval("return 24;")
    assert_object_strictly_eql? true,
                                JS.eval("return null;"),
                                JS.eval("return null;")
    assert_object_strictly_eql? true,
                                JS.eval("return undefined;"),
                                JS.eval("return undefined;")
    assert_object_strictly_eql? false,
                                JS.eval("return new String('str');"),
                                JS.eval("return 'str';")
    assert_object_strictly_eql? false,
                                JS.eval("return null;"),
                                JS.eval("return undefined;")
  end

  def test_to_s
    assert_equal "24", JS.eval("return 24;").to_s
    assert_equal "true", JS.eval("return true;").to_s
    assert_equal "null", JS.eval("return null;").to_s
    assert_equal "undefined", JS.eval("return undefined;").to_s
  end

  def test_inspect
    assert_equal "24", JS.eval("return 24;").inspect
    assert_equal "true", JS.eval("return true;").inspect
    assert_equal "null", JS.eval("return null;").inspect
    assert_equal "undefined", JS.eval("return undefined;").inspect
  end

  def test_call
    assert_nothing_raised { JS.global.call(:Array) }
    assert_equal "1,2,3", JS.global.call(:Array, 1, 2, 3).to_s
  end

  def test_method_missing
    assert_equal "42", JS.eval("return 42;").toString.to_s
    assert_equal "o", JS.eval("return 'hello';").charAt(4).to_s
  end

  def test_method_missing_with_block
    obj = JS.eval(<<~JS)
      return {
        takeBlock(block) {
          return block(1, 2, 3);
        }
      }
    JS
    block_called = false
    # TODO: Support return value in block
    result =
      obj.takeBlock do |a, b, c|
        block_called = true
        # TODO: Compare them as integers after introducing `JS::Object#to_i`
        assert_equal 1.to_s, a.to_s
        assert_equal 2.to_s, b.to_s
        assert_equal 3.to_s, c.to_s
      end
    assert_true block_called
  end

  def test_method_missing_with_undefined_method
    object = JS.eval(<<~JS)
      return { foo() { return true; } };
    JS
    assert_raise(NoMethodError) { object.bar }
  end

  def test_respond_to_missing?
    object = JS.eval(<<~JS)
      return { foo() { return true; } };
    JS
    assert_true object.respond_to?(:foo)
    assert_false object.respond_to?(:bar)
  end

  def test_member_get
    object = JS.eval(<<~JS)
      return { foo: 42 };
    JS
    assert_equal 42.to_s, object[:foo].to_s
    assert_equal 42.to_s, object["foo"].to_s
  end

  def test_member_set
    object = JS.eval(<<~JS)
      return { foo: 42 };
    JS
    object[:foo] = 24
    assert_equal 24.to_s, object[:foo].to_s
    object["foo"] = 42
    assert_equal 42.to_s, object["foo"].to_s
  end
end
