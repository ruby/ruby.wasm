module RubyWasm
  class Downloader
    def format_size(size)
      units = %w[B KB MB GB TB]
      unit = 0
      while size > 1024 and unit < units.size - 1
        size /= 1024.0
        unit += 1
      end
      "%s #{units[unit]}" % size.round(2)
    end

    def download(url, dest, message)
      require "open-uri"
      content_length = nil
      uri = URI.parse(url)
      OpenURI.open_uri(
        uri,
        content_length_proc: ->(len) { content_length = len },
        progress_proc: ->(size) do
          print "\r#{message} (#{format_size(content_length)}) %.2f%%" %
                  (size.to_f / content_length * 100)
        end
      ) { |f| File.open(dest, "wb") { |out| out.write f.read } }
      puts "\r"
    end
  end
end
