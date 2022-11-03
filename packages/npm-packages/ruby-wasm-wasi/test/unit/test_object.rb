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
    assert_equal "str", JS.eval("return 'str';").to_s
    assert_equal "24", JS.eval("return 24;").to_s
    assert_equal "true", JS.eval("return true;").to_s
    assert_equal "null", JS.eval("return null;").to_s
    assert_equal "undefined", JS.eval("return undefined;").to_s
  end

  def test_inspect
    assert_equal "str", JS.eval("return 'str';").to_s
    assert_equal "24", JS.eval("return 24;").inspect
    assert_equal "true", JS.eval("return true;").inspect
    assert_equal "null", JS.eval("return null;").inspect
    assert_equal "undefined", JS.eval("return undefined;").inspect
  end

  def test_to_i_from_number
    assert_equal 1, JS.eval("return 1;").to_i
    assert_equal -1, JS.eval("return -1;").to_i
    assert_equal 1, JS.eval("return 1.8;").to_i
    assert_equal (2**53 - 1), JS.eval("return Number.MAX_SAFE_INTEGER;").to_i
    assert_equal -(2**53 - 1), JS.eval("return Number.MIN_SAFE_INTEGER;").to_i
    assert_equal Float::MAX.to_i, JS.eval("return Number.MAX_VALUE;").to_i
    assert_equal 0, JS.eval("return Number.MIN_VALUE;").to_i

    # Special values
    assert_raise(FloatDomainError) { JS.eval("return NaN;").to_i }
    assert_raise(FloatDomainError) { JS.eval("return Infinity;").to_i }
    assert_raise(FloatDomainError) { JS.eval("return -Infinity;").to_i }
  end

  def test_to_i_from_bigint
    assert_equal 1, JS.eval("return 1n;").to_i
    assert_equal 0xffff0000, JS.eval("return 0xffff0000n;").to_i
    assert_equal (1 << 32), JS.eval("return (1n << 32n);").to_i
    assert_equal (1 << 64), JS.eval("return (1n << 64n);").to_i
  end

  def test_to_i_from_non_numeric
    assert_equal 0, JS.eval("return null;").to_i
    assert_equal 0, JS.eval("return undefined;").to_i

    # String
    assert_equal 0, JS.eval("return '';").to_i
    assert_equal 42, JS.eval("return '42';").to_i
    assert_equal 0, JS.eval("return 'str';").to_i
    assert_equal 42, JS.eval("return '42str';").to_i
  end

  def test_to_f
    assert_equal 1.0, JS.eval("return 1;").to_f
    assert_equal -1.0, JS.eval("return -1;").to_f
    assert_true JS.eval("return NaN;").to_f.nan?
    assert_equal 1, JS.eval("return Infinity;").to_f.infinite?
    assert_equal -1, JS.eval("return -Infinity;").to_f.infinite?
    # Maximum positive value of IEEE 754 double-precision float
    # (1.0 + ((2 ** 52 - 1) * (2 ** -52.0))) * (2 ** 1023.0)
    assert_equal 1.7976931348623157e+308,
                 JS.eval("return Number.MAX_VALUE;").to_f
    # Minimum positive value of IEEE 754 double-precision float
    # 1.0 * 2 ** -52 * 2**-1022 (Subnormal number)
    assert_equal 5.0e-324, JS.eval("return Number.MIN_VALUE;").to_f
  end

  def test_to_f_from_bigint
    assert_true JS.eval("return 1n;").to_f.is_a?(Float)
    assert_equal 1, JS.eval("return 1n;").to_f
    assert_equal 0xffff0000, JS.eval("return 0xffff0000n;").to_f
    assert_equal (1 << 32), JS.eval("return (1n << 32n);").to_f
    assert_equal (1 << 64), JS.eval("return (1n << 64n);").to_f
  end

  def test_to_f_from_non_numeric
    assert_equal 0, JS.eval("return null;").to_f
    assert_equal 0, JS.eval("return undefined;").to_f

    # String
    assert_equal 42, JS.eval("return '42';").to_f
    assert_equal 42.5, JS.eval("return '42.5';").to_f
    assert_equal 0, JS.eval("return '';").to_f
    assert_equal 0, JS.eval("return 'str';").to_f
    assert_equal 42, JS.eval("return '42str';").to_f
    assert_equal 42.4, JS.eval("return '42.4str';").to_f
  end

  def test_call
    assert_nothing_raised { JS.global.call(:Array) }
    assert_equal "1,2,3", JS.global.call(:Array, 1, 2, 3).to_s
  end

  def test_call_with_stress_gc
    obj = JS.eval(<<~JS)
      return { takeArg() {} }
    JS
    GC.stress = true
    obj.call(:takeArg, "1")
    obj.call(:takeArg) {}
    GC.stress = false
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
        assert_equal 1, a.to_i
        assert_equal 2, b.to_i
        assert_equal 3, c.to_i
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

  def test_member_set_with_stress_gc
    GC.stress = true
    JS.global[:tmp] = "1"
    GC.stress = false
  end
end
