require "js.so"

class JS::Object
    def method_missing(name, *args, &block)
        self.call(name, *args, &block)
    end
end