class Array
  # Convert Ruby array to JavaScript array
  def to_js
    # Array() instead of JS.eval, which a CSP without 'unsafe-eval' blocks.
    # Not JS.global[:Array].new: JS::Object#new calls Array#to_js.
    new_array = JS.global.call(:Array)
    # NOTE: This method call implicitly convert element to JS object by to_js
    new_array.push *self
    new_array
  end
end
