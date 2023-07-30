class Hash
  # Convert a hash to a JavaScript object
  def to_js
    new_object = JS.eval("return {}")
    self.each { |key, value| new_object[key] = value }
    new_object
  end
end
