module RubyWasm
  module SizeFormatter
    def format(size)
      units = %w[B KB MB GB TB]
      unit = 0
      while size > 1024 and unit < units.size - 1
        size /= 1024.0
        unit += 1
      end
      "%s #{units[unit]}" % size.round(2)
    end

    module_function :format
  end
end
