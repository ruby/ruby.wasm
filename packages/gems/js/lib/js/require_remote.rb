require "singleton"
require "js"
require_relative "./require_remote/url_resolver"
require_relative "./require_remote/evaluator"

module JS
  # This class is used to load remote Ruby scripts.
  #
  # == Example
  #
  #   require 'js/require_remote'
  #   JS::RequireRemote.instance.load("foo")
  #
  # This class is intended to be used to replace Kernel#require_relative.
  #
  # == Example
  #
  #   require 'js/require_remote'
  #   module Kernel
  #     def require_relative(path) = JS::RequireRemote.instance.load(path)
  #   end
  #
  # If you want to load the bundled gem
  #
  # == Example
  #
  #    require 'js/require_remote'
  #    module Kernel
  #      alias original_require_relative require_relative
  #
  #      def require_relative(path)
  #        caller_path = caller_locations(1, 1).first.absolute_path || ''
  #        dir = File.dirname(caller_path)
  #        file = File.absolute_path(path, dir)
  #
  #        original_require_relative(file)
  #      rescue LoadError
  #        JS::RequireRemote.instance.load(path)
  #      end
  #   end
  #
  class RequireRemote
    include Singleton

    def initialize
      base_url = JS.global[:URL].new(JS.global[:location][:href])
      @resolver = URLResolver.new(base_url)
      @evaluator = Evaluator.new
    end

    # Load the given feature from remote.
    def load(relative_feature)
      location = @resolver.get_location(relative_feature)

      # Do not load the same URL twice.
      return false if @evaluator.evaluated?(location.url[:href].to_s)

      response = JS.global.fetch(location.url).await
      unless response[:status].to_i == 200
        raise LoadError.new "cannot load such url -- #{response[:status]} #{location.url}"
      end

      # The fetch API may have responded to a redirect response
      # and fetched the script from a different URL than the original URL.
      # Retrieve the final URL again from the response object.
      final_url = response[:url].to_s

      # Do not evaluate the same URL twice.
      return false if @evaluator.evaluated?(final_url)

      code = response.text().await.to_s

      evaluate(code, location.filename, final_url)
    end

    private

    def evaluate(code, filename, final_url)
      @resolver.push(final_url)
      @evaluator.evaluate(code, filename, final_url)
      @resolver.pop
      true
    end
  end
end
