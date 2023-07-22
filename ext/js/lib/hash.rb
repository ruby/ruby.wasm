require "json"

class Hash
  # Convert a hash to a JavaScript object
  def to_js
    JS.eval("return #{self.to_json}")
  end
end
