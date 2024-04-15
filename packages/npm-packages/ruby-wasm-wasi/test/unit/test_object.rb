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

    # Compare with JS::Object like object
    assert_equal true, JS.eval("return 42;") == 42
    assert_equal true, JS.eval("return 42;").eql?(42)
    assert_equal false, JS.eval("return 42;") != 42
    # Compare with non JS::Object like object
    assert_equal false, JS.eval("return 42;") == Object.new
    assert_equal true, JS.eval("return 42;") != Object.new
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

  def test_to_s_encoding
    assert_equal Encoding::UTF_8, JS.eval("return 'str';").to_s.encoding
    assert_equal Encoding::UTF_8, JS.eval("return 'あいうえお';").to_s.encoding
  end

  def test_inspect
    assert_equal "str", JS.eval("return 'str';").to_s
    assert_equal "24", JS.eval("return 24;").inspect
    assert_equal "true", JS.eval("return true;").inspect
    assert_equal "null", JS::Null.inspect
    assert_equal "undefined", JS::Undefined.inspect
    assert_equal "[object Object]", JS.eval("return {}").inspect
    assert_equal "[object X class]", JS.eval(<<~JS).inspect
      class X {
        get [Symbol.toStringTag]() {
          return 'X class';
        }
      }
      return new X();
    JS
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

  def test_call_with_undefined_method
    assert_raise("which is a undefined and not a function") do
      JS.global.call(:undefined_method)
    end
  end

  def test_call_with_non_js_object
    assert_raise("argument 2 is not a JS::Object like object") do
      JS.global.call(:Object, Object.new)
    end
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

  def test_new_standard_built_in_object
    assert_equal 1.2, JS.global[:Number].new(1.23).toFixed(1).to_f
    assert_equal "hello", JS.global[:String].new("hello").to_s
    assert_equal 3, JS.global[:Array].new(1, 2, 3).pop().to_i
    assert_equal 2023, JS.global[:Date].new(2023, 1, 1).getFullYear().to_i
  end

  def test_new_standard_built_in_object_with_js_string
    assert_equal "hello", JS.global[:String].new(JS.eval("return 'hello'")).to_s
  end

  def test_new_named_constructor
    JS.eval(<<~JS)
      globalThis.Person = function Person(first, last) {
        this.firstName = first;
        this.lastName = last;
      }
    JS

    assert_equal "John", JS.global[:Person].new("John", "Doe")[:firstName].to_s
  end

  def test_new_anonymous_constructor
    JS.eval(<<~JS)
      globalThis.Dog = function(name, breed) {
        this.name = name;
        this.breed = breed;
      }
    JS

    assert_equal "Labrador",
                 JS.global[:Dog].new("Fido", "Labrador")[:breed].to_s
  end

  def test_new_custom_class
    JS.eval(<<~JS)
      globalThis.CustomClass = class CustomClass {
        constructor(options) {
          this.option1 = options.option1;
          this.option2 = options.option2;
        }
      }
    JS

    assert_equal "hello",
                 JS.global[:CustomClass].new(option1: "hello")[:option1].to_s
  end

  def test_new_custom_class_with_js_object
    JS.eval(<<~JS)
      class CustomClass {
        constructor(options) {
          this.option1 = options.option1;
          this.option2 = options.option2;
        }
      }
      globalThis.CustomClass = CustomClass;
    JS

    js_object = JS.eval('return { option1: "hello" }')
    assert_equal "hello", JS.global[:CustomClass].new(js_object)[:option1].to_s
  end

  def test_new_with_block
    ctor = JS.eval <<~JS
      return function (a, b, c) {
        this.ret = c(a, b);
      }
    JS
    new_obj = ctor.new(1, 2) { |a, b| a.to_i + b.to_i }
    assert_equal 3, new_obj[:ret].to_i

    promise = JS.global[:Promise].new do |resolve, reject|
      resolve.apply 42
    end
    value = promise.await
    assert_equal 42, value.to_i

    promise = JS.global[:Promise].new do |resolve, reject|
      JS.global.queueMicrotask(resolve)
    end
    promise.await
  end

  def test_to_a
    assert_equal [1, 2, 3], JS.eval("return [1, 2, 3];").to_a.map(&:to_i)
    assert_equal %w[f o o], JS.eval("return 'foo';").to_a.map(&:to_s)

    set = JS.eval("return new Set(['foo', 'bar', 'baz', 'foo']);").to_a
    assert_equal %w[foo bar baz], set.map(&:to_s)

    map = JS.eval("return new Map([[1, 2], [2, 4], [4, 8]]);").to_a
    assert_equal ({ 1 => 2, 2 => 4, 4 => 8 }), map.to_h { _1.to_a.map(&:to_i) }
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

  def test_method_missing_with_?
    object = JS.eval(<<~JS)
      return {
        return_true() { return true; },
        return_false() { return false; },
        return_object() { return {}; }
      };
    JS

    # Normally return JS::Object when without ?
    assert_true object.return_true == JS::True
    assert_true object.return_false == JS::False

    # Return Ruby boolean value when with ?
    assert_true object.return_true?
    assert_false object.return_false?

    # Return Ruby false when the return value is not JS::True
    assert_false object.return_object?
  end

  def test_respond_to_missing?
    object = JS.eval(<<~JS)
      return { foo() { return true; } };
    JS
    assert_true object.respond_to?(:foo)
    assert_true object.respond_to?(:new)
    assert_false object.respond_to?(:bar)
  end

  def test_member_get
    object = JS.eval(<<~JS)
      return { foo: 42 };
    JS
    assert_equal 42.to_s, object[:foo].to_s
    assert_equal 42.to_s, object["foo"].to_s

    assert_raise(JS::Error) { JS::Undefined[:foo] }

    assert_equal JS::Undefined.to_s, object["bar"].to_s
  end

  def test_member_set
    object = JS.eval(<<~JS)
      return { foo: 42 };
    JS
    object[:foo] = 24
    assert_equal 24.to_s, object[:foo].to_s
    object["foo"] = 42
    assert_equal 42.to_s, object["foo"].to_s

    assert_raise(JS::Error) { JS::Undefined[:foo] = 42 }

    # Create new property
    object["bar"] = 41
    assert_equal 41.to_s, object["bar"].to_s
  end

  def test_member_set_with_non_js_object
    assert_raise_message("wrong argument type Object (expected JS::Object like object)") do
      JS.global[:tmp] = Object.new
    end
  end

  def test_member_set_with_stress_gc
    GC.stress = true
    JS.global[:tmp] = "1"
    GC.stress = false
  end

  def test_apply
    object = JS.eval(<<~JS)
      return { foo(a, b, c) { return a + b + c; } };
    JS
    assert_equal 6, object[:foo].apply(1, 2, 3).to_i
    floor = JS.global[:Math][:floor]
    assert_equal 3, floor.apply(3.14).to_i
  end
end
