class IO
    def winsize
        [24, 80]
    end

    def wait_readable(timeout = nil)
        false
    end
end
