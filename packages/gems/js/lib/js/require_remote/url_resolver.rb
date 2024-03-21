module JS
  class RequireRemote
    ScriptLocation = Data.define(:url, :filename, :path)

    # When require_relative is called within a running Ruby script,
    # the URL is resolved from a relative file path based on the URL of the running Ruby script.
    # It uses a stack to store URLs of running Ruby Script.
    # Push the URL onto the stack before executing the new script.
    # Then pop it when the script has finished executing.
    class URLResolver
      def initialize(base_url)
        @url_stack = [base_url]
      end

      def get_location(relative_feature)
        filename = filename_from(relative_feature)
        url = resolve(filename)
        path = JS.global[:URL].new(url, @url_stack.first).pathname.to_s # Get path relative to first call. Supports different urls.
        ScriptLocation.new(url, filename, path)
      end

      def push(url)
        @url_stack.push url
      end

      def pop()
        @url_stack.pop
      end

      private

      def filename_from(relative_feature)
        if relative_feature.end_with?(".rb")
          relative_feature
        else
          "#{relative_feature}.rb"
        end
      end

      # Return a URL object of JavaScript.
      def resolve(relative_filepath)
        JS.global[:URL].new relative_filepath, @url_stack.last
      end
    end
  end
end
