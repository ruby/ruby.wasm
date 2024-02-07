require 'date'

class DateTime
    def to_js
        JS.global[:Date].new(self.iso8601)
    end
end