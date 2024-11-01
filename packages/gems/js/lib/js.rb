require "js.so"
require_relative "js/hash.rb"
require_relative "js/array.rb"
require_relative "js/nil_class.rb"

# The JS module provides a way to interact with JavaScript from Ruby.
#
# == Example
#
#   require 'js'
#   JS.eval("return 1 + 2") # => 3
#   JS.global[:document].write("Hello, world!")
#   div = JS.global[:document].createElement("div")
#   div[:innerText] = "click me"
#   body = JS.global[:document][:body]
#   if body[:classList].contains?("main")
#     body.appendChild(div)
#   end
#   div.addEventListener("click") do |event|
#     puts event          # => # [object MouseEvent]
#     puts event[:detail] # => 1
#     div[:innerText] = "clicked!"
#   end
#
# If you are using `ruby.wasm` without `stdlib` you will not have `addEventListener`
# and other specialized functions defined. You can still acomplish many
# of the same things using `call` instead.
#
# == Example
#
#   require 'js'
#   JS.eval("return 1 + 2") # => 3
#   JS.global[:document].call(:write, "Hello, world!")
#   div = JS.global[:document].call(:createElement, "div")
#   div[:innerText] = "click me"
#   if body[:classList].call(:contains, "main") == JS::True
#     body.appendChild(div)
#   end
#   div.call(:addEventListener, "click") do |event|
#     puts event          # => # [object MouseEvent]
#     puts event[:detail] # => 1
#     div[:innerText] = "clicked!"
#   end
#
module JS
  Undefined = JS.eval("return undefined")
  Null = JS.eval("return null")

  # A boolean value in JavaScript is always a JS::Object instance from Ruby's point of view.
  # If we use the boolean value returned by a JavaScript function as the condition for an if expression in Ruby,
  # the if expression will always be true.
  #
  # == Bad Example
  #
  #   searchParams = JS.global[:URLSearchParams].new(JS.global[:location][:search])
  #   if searchParams.has('phrase')
  #     # Always pass through here.
  #     ...
  #   else
  #     ...
  #   end
  #
  # Therefore, the JS::True constant is used to determine if the JavaScript function return value is true or false.
  #
  # == Good Example
  #
  #   if searchParams.has('phrase') == JS::True
  #     ...
  #   end
  True = JS.eval("return true;")
  False = JS.eval("return false;")

  class PromiseScheduler
    def initialize(loop)
      @loop = loop
    end

    def await(promise)
      current = Fiber.current
      promise.call(
        :then,
        ->(value) { current.transfer(value, :success); nil },
        ->(value) { current.transfer(value, :failure); nil }
      )
      if @loop == current
        raise (
                "JS::Object#await can be called only from RubyVM#evalAsync or RbValue#callAsync JS API\n" +
                  "If you are using browser.script.iife.js, please ensure that you specify `data-eval=\"async\"` in your script tag\n" +
                  "e.g. <script type=\"text/ruby\" data-eval=\"async\">puts :hello</script>\n" +
                  "Or <script type=\"text/ruby\" data-eval=\"async\" src=\"path/to/script.rb\"></script>"
              )
      end
      value, status = @loop.transfer
      raise JS::Error.new(value) if status == :failure
      value
    end
  end

  @promise_scheduler = PromiseScheduler.new Fiber.current

  def self.promise_scheduler
    @promise_scheduler
  end

  private

  def self.__eval_async_rb(rb_code, future)
    self.__async(future) do
      JS::Object.wrap(Kernel.eval(rb_code.to_s, TOPLEVEL_BINDING, "eval_async"))
    end
  end

  def self.__call_async_method(recv, method_name, future, *args)
    self.__async(future) { recv.send(method_name.to_s, *args) }
  end

  def self.__async(future, &block)
    Fiber
      .new do
        future.resolve block.call
      rescue => e
        future.reject JS::Object.wrap(e)
      end
      .transfer
  end
end

# Inherit BasicObject to prevent define coventional menthods.  #Override the `Object#send` to give priority to `send` method of JavaScript.
#
# This is to make it easier to use JavaScript Objects with `send` method such as `WebSocket` and `XMLHttpRequest`.
# The JavaScript method call short-hand in `JS::Object` is implemented using `method_missing`.
# If JS::Object inherits from Object, the `send` method defined in Ruby will take precedence over the JavaScript `send` method.
# If you want to call the JavaScript `send` method, you must use the `call` method as follows:
#
#   ws = JS.global[:WebSocket].new("ws://example.com")
#   ws.call(:send, ["Hello, world! from Ruby"])
#
# This inheritation allows you to call the JavaScript `send` method with the following syntax:
#
#   ws.send("Hello, world! from Ruby")
class JS::Object < BasicObject
  # Create a JavaScript object with the new method
  #
  # The below examples show typical usage in Ruby
  #
  #   JS.global[:Object].new
  #   JS.global[:Number].new(1.23)
  #   JS.global[:String].new("string")
  #   JS.global[:Array].new(1, 2, 3)
  #   JS.global[:Date].new(2020, 1, 1)
  #   JS.global[:Error].new("error message")
  #   JS.global[:URLSearchParams].new(JS.global[:location][:search])
  #   JS.global[:Promise].new ->(resolve, reject) { resolve.call(42) }
  #
  def new(*args, &block)
    args = args + [block] if block
    ::JS.global[:Reflect].construct(self, args.to_js)
  end

  # Converts +self+ to an Array:
  #
  #   JS.eval("return [1, 2, 3]").to_a.map(&:to_i)    # => [1, 2, 3]
  #   JS.global[:document].querySelectorAll("p").to_a # => [[object HTMLParagraphElement], ...
  def to_a
    as_array = ::JS.global[:Array].from(self)
    ::Array.new(as_array[:length].to_i) { as_array[_1] }
  end

  # Provide a shorthand form for JS::Object#call
  #
  # This method basically calls the JavaScript method with the same
  # name as the Ruby method name as is using JS::Object#call.
  #
  # Exceptions are the following cases:
  # * If the method name ends with a question mark (?), the question mark is removed
  #   and the method is called as a predicate method. The return value is converted to
  #   a Ruby boolean value automatically.
  #
  # This shorthand is unavailable for the following cases and you need to use
  # JS::Object#call instead:
  # * If the method name is invalid as a Ruby method name (e.g. contains a hyphen, reserved word, etc.)
  # * If the method name is already defined as a Ruby method under JS::Object
  # * If the JavaScript method name ends with a question mark (?)
  def method_missing(sym, *args, &block)
    sym_str = sym.to_s
    if sym_str.end_with?("?")
      # When a JS method is called with a ? suffix, it is treated as a predicate method,
      # and the return value is converted to a Ruby boolean value automatically.
      result = invoke_js_method(sym_str[0..-2].to_sym, *args, &block)
      # Type coerce the result to boolean type
      # to match the true/false determination in JavaScript's if statement.
      return ::JS.global.Boolean(result) == ::JS::True
    end

    invoke_js_method(sym, *args, &block)
  end

  # Check if a JavaScript method exists
  #
  # See JS::Object#method_missing for details.
  def respond_to_missing?(sym, include_private)
    sym_str = sym.to_s
    sym = sym_str[0..-2].to_sym if sym_str.end_with?("?")
    self[sym].typeof == "function"
  end

  # Call the receiver (a JavaScript function) with `undefined` as its receiver context.
  # This method is similar to JS::Object#call, but it is used to call a function that is not
  # a method of an object.
  #
  #   floor = JS.global[:Math][:floor]
  #   floor.apply(3.14) # => 3
  #   JS.global[:Promise].new do |resolve, reject|
  #     resolve.apply(42)
  #   end.await # => 42
  def apply(*args, &block)
    args = args + [block] if block
    ::JS.global[:Reflect].call(:apply, self, ::JS::Undefined, args.to_js)
  end

  # Await a JavaScript Promise like `await` in JavaScript.
  # This method looks like a synchronous method, but it actually runs asynchronously using fibers.
  # In other words, the next line to the `await` call at Ruby source will be executed after the
  # promise will be resolved. However, it does not block JavaScript event loop, so the next line
  # to the RubyVM.evalAsync` (in the case when no `await` operator before the call expression)
  # at JavaScript source will be executed without waiting for the promise.
  #
  # The below example shows how the execution order goes. It goes in the order of "step N"
  #
  #   # In JavaScript
  #   const response = vm.evalAsync(`
  #     puts "step 1"
  #     JS.global.fetch("https://example.com").await
  #     puts "step 3"
  #   `) // => Promise
  #   console.log("step 2")
  #   await response
  #   console.log("step 4")
  #
  # The below examples show typical usage in Ruby
  #
  #   JS.eval("return new Promise((ok) => setTimeout(() => ok(42), 1000))").await # => 42 (after 1 second)
  #   JS.global.fetch("https://example.com").await                                # => [object Response]
  #   JS.eval("return 42").await                                                  # => 42
  #   JS.eval("return new Promise((ok, err) => err(new Error())").await           # => raises JS::Error
  def await
    # Promise.resolve wrap a value or flattens promise-like object and its thenable chain
    promise = ::JS.global[:Promise].resolve(self)
    ::JS.promise_scheduler.await(promise)
  end

  # The `respond_to?` method is only used in unit tests.
  # There is little need to define it here.
  # However, methods suffixed with `?` do not conflict with JavaScript methods.
  # As there are no disadvantages, we will define the `respond_to?` method here
  # in the same way as the `nil?` and `is_a?` methods, prioritizing convenience.
  [:nil?, :is_a?, :raise, :respond_to?].each do |method|
    define_method(method, ::Object.instance_method(method))
  end

  private

  # Invoke a JavaScript method
  # If the property of JavaScritp object does not exist, raise a `NoMethodError`.
  # If the property exists but is not a function, raise a `TypeError`.
  def invoke_js_method(sym, *args, &block)
    return self.call(sym, *args, &block) if self[sym].typeof == "function"

    # Check to see if a non-functional property exists.
    if ::JS.global[:Reflect].call(:has, self, sym.to_s) == ::JS::True
      raise ::TypeError,
            "`#{sym}` is not a function. To reference a property, use `[:#{sym}]` syntax instead."
    end

    raise ::NoMethodError,
          "undefined method `#{sym}' for an instance of JS::Object"
  end
end

# A wrapper class for JavaScript Error to allow the Error to be thrown in Ruby.
class JS::Error
  def initialize(exception)
    @exception = exception
    super
  end

  def message
    stack = @exception[:stack]
    if stack.typeof == "string"
      # Error.stack contains the error message also
      stack.to_s
    else
      @exception.to_s
    end
  end
end
