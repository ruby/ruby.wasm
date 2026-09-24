class Hash
  # Convert a hash to a JavaScript object
  def to_js
    # Object() instead of JS.eval, which a CSP without 'unsafe-eval' blocks.
    new_object = JS.global.call(:Object)
    self.each { |key, value| new_object[key] = value }
    new_object
  end
end
