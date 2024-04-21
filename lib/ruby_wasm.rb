require "logger"

require_relative "ruby_wasm/version"
require_relative "ruby_wasm/util"
require_relative "ruby_wasm/build"
require_relative "ruby_wasm/feature_set"
require_relative "ruby_wasm/packager"
require_relative "ruby_wasm/packager/component_adapter"
require_relative "ruby_wasm/packager/file_system"
require_relative "ruby_wasm/packager/core"

module RubyWasm
  class << self
    attr_accessor :log_level

    def logger
      @logger ||=
        begin
          logger =
            Logger.new(
              $stderr,
              level: @log_level || Logger::INFO,
              progname: "rbwasm"
            )
          logger.formatter =
            proc { |severity, datetime, progname, msg| "#{severity}: #{msg}\n" }
          logger
        end
    end

    def logger=(logger)
      @logger = logger
    end
  end
end
