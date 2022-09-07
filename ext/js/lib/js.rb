require "js.so"

class JS::Object
    def method_missing(name, *args)
        self.call(name, *args)
    end
end