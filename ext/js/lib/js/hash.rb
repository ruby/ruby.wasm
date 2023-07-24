class Hash
  # Convert a hash to a JavaScript object
  def to_js
    new_object = JS.eval("return {}")
    self.each do |key, value|
      new_object[key] = value
    end
    new_object
  end
end
