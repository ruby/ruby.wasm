module Reline
    def self.get_screen_size
        raise Errno::EINVAL
    end
    class Unicode
        def self.calculate_width(str, allow_escape_code = false)
            1
        end
    end
end
