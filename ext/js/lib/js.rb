require "js.so"

# The JS module provides a way to interact with JavaScript from Ruby.
#
# == Example
#
#   require 'js'
#   JS.eval("return 1 + 2") # => 3
#   JS.global[:document].write("Hello, world!")
#   JS.global[:document].addEventListner("click") do |event|
#     puts event          # => # [object MouseEvent]
#     puts event[:detail] # => 1
#   end
#
module JS
  Undefined = JS.eval("return undefined")
  Null = JS.eval("return null")
end

class JS::Object
  def method_missing(sym, *args, &block)
    if self[sym].typeof == "function"
      self.call(sym, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(sym, include_private)
    return true if super
    self[sym].typeof == "function"
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
