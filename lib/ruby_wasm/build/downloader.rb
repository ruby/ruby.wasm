module RubyWasm
  class Downloader
    def download(url, dest, message)
      require "open-uri"
      content_length = 0
      uri = URI.parse(url)
      OpenURI.open_uri(
        uri,
        content_length_proc: ->(len) { content_length = len },
        progress_proc: ->(size) do
          print "\r#{message} (#{SizeFormatter.format(content_length)}) %.2f%%" %
                  (size.to_f / content_length * 100)
        end
      ) { |f| File.open(dest, "wb") { |out| out.write f.read } }
      puts "\r"
    end
  end
end
