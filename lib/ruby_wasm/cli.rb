require "optparse"
require "rbconfig"
require_relative "ruby_wasm.so"

module RubyWasm
  class CLI
    def initialize(stdout:, stderr:)
      @stdout = stdout
      @stderr = stderr
    end

    def run(args)
      available_commands = %w[build]
      parser =
        OptionParser.new do |opts|
          opts.banner = <<~USAGE
          Usage: rbwasm [options...] [command]

          Available commands: #{available_commands.join(", ")}
        USAGE
          opts.version = RubyWasm::VERSION
          opts.on("-h", "--help", "Prints this help") do
            @stderr.puts opts
            exit
          end
          opts.on("--log-level LEVEL", "Log level") do |level|
            RubyWasm.log_level = level.to_sym
          end
        end
      parser.order!(args)

      command = args.shift
      case command
      when "build"
        build(args)
      else
        @stderr.puts parser
        exit
      end
    end

    def build(args)
      # @type var options: Hash[Symbol, untyped]
      options = {
        save_temps: false,
        optimize: false,
        remake: false,
        ruby_version: "3.3",
        target_triplet: "wasm32-unknown-wasi",
        profile: "full",
        stdlib: true
      }
      OptionParser
        .new do |opts|
          opts.banner = "Usage: rbwasm componentize [options]"
          opts.on("-h", "--help", "Prints this help") do
            @stdout.puts opts
            exit
          end

          opts.on("--save-temps", "Save temporary files") do
            options[:save_temps] = true
          end

          opts.on("--ruby-version VERSION", "Ruby version") do |version|
            options[:ruby_version] = version
          end

          opts.on("--target TRIPLET", "Target triplet") do |triplet|
            options[:target_triplet] = triplet
          end

          opts.on(
            "--build-profile PROFILE",
            "Build profile. full or minimal"
          ) { |profile| options[:profile] = profile }

          opts.on("--optimize", "Optimize the output") do
            options[:optimize] = true
          end

          opts.on("--remake", "Re-execute make for Ruby") do
            options[:remake] = true
          end

          opts.on("-o", "--output FILE", "Output file") do |file|
            options[:output] = file
          end

          opts.on("--[no-]stdlib", "Include stdlib") do |stdlib|
            options[:stdlib] = stdlib
          end
        end
        .parse!(args)

      verbose = RubyWasm.logger.level == :debug
      executor = RubyWasm::BuildExecutor.new(verbose: verbose)

      unless options[:output]
        @stderr.puts "Output file is not specified"
        exit 1
      end

      require "tmpdir"

      if options[:save_temps]
        tmpdir = Dir.mktmpdir
        self.do_build(executor, tmpdir, options)
        @stderr.puts "Temporary files are saved to #{tmpdir}"
        exit
      else
        Dir.mktmpdir { |tmpdir| self.do_build(executor, tmpdir, options) }
      end
    end

    private

    def build_config(options)
      config = { target: options[:target_triplet], src: options[:ruby_version] }
      case options[:profile]
      when "full"
        config[:profile] = RubyWasm::Packager::ALL_DEFAULT_EXTS
      when "minimal"
        config[:profile] = ""
      else
        RubyWasm.logger.error "Unknown profile: #{options[:profile]} (available: full, minimal)"
        exit 1
      end
    end

    def do_build(executor, tmp_dir, options)
      definition = Bundler.definition if defined?(Bundler)
      packager =
        RubyWasm::Packager.new(tmp_dir, options[:target_triplet], definition)
      wasm_bytes = packager.package(executor, options)
      @stderr.puts "Size: #{SizeFormatter.format(wasm_bytes.size)}"
      case options[:output]
      when "-"
        @stdout.write wasm_bytes.pack("C*")
      else
        File.binwrite(options[:output], wasm_bytes.pack("C*"))
        @stderr.puts "Wrote #{options[:output]}"
      end
    end
  end
end
