class Array
  # Convert Ruby array to JavaScript array
  def to_js
    new_array = JS.eval("return []")
    # NOTE: This method call implicitly convert element to JS object by to_js
    new_array.push *self
    new_array
  end
end
