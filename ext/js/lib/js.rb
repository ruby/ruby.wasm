require "js.so"

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