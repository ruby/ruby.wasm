require "optparse"
require "rbconfig"

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
        reconfigure: false,
        clean: false,
        ruby_version: "3.3",
        target_triplet: "wasm32-unknown-wasi",
        profile: "full",
        stdlib: true,
        disable_gems: false
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

          opts.on("--reconfigure", "Re-execute configure for Ruby") do
            options[:reconfigure] = true
          end

          opts.on("--clean", "Clean build artifacts") { options[:clean] = true }

          opts.on("-o", "--output FILE", "Output file") do |file|
            options[:output] = file
          end

          opts.on("--[no-]stdlib", "Include stdlib") do |stdlib|
            options[:stdlib] = stdlib
          end

          opts.on("--disable-gems", "Disable gems") do
            options[:disable_gems] = true
          end

          opts.on("--format FORMAT", "Output format") do |format|
            options[:format] = format
          end

          opts.on("--print-ruby-cache-key", "Print Ruby cache key") do
            options[:print_ruby_cache_key] = true
          end
        end
        .parse!(args)

      verbose = RubyWasm.logger.level == :debug
      executor = RubyWasm::BuildExecutor.new(verbose: verbose)
      packager = self.derive_packager(options)

      if options[:print_ruby_cache_key]
        self.do_print_ruby_cache_key(packager)
        exit
      end

      unless options[:output]
        @stderr.puts "Output file is not specified"
        exit 1
      end

      require "tmpdir"

      if options[:save_temps]
        tmpdir = Dir.mktmpdir
        self.do_build(executor, tmpdir, packager, options)
        @stderr.puts "Temporary files are saved to #{tmpdir}"
        exit
      else
        Dir.mktmpdir do |tmpdir|
          self.do_build(executor, tmpdir, packager, options)
        end
      end
    end

    private

    def build_config(options)
      config = { target: options[:target_triplet], src: options[:ruby_version] }
      case options[:profile]
      when "full"
        config[:default_exts] = RubyWasm::Packager::ALL_DEFAULT_EXTS
      when "minimal"
        config[:default_exts] = ""
      else
        RubyWasm.logger.error "Unknown profile: #{options[:profile]} (available: full, minimal)"
        exit 1
      end
      config[:suffix] = "-#{options[:profile]}"
      config
    end

    def derive_packager(options)
      __skip__ =
        if defined?(Bundler) && !options[:disable_gems]
          definition = Bundler.definition
        end
      RubyWasm::Packager.new(build_config(options), definition)
    end

    def do_print_ruby_cache_key(packager)
      ruby_core_build = packager.ruby_core_build
      require "digest"
      digest = Digest::SHA256.new
      ruby_core_build.cache_key(digest)
      hexdigest = digest.hexdigest
      require "json"
      @stdout.puts JSON.generate(
                     hexdigest: hexdigest,
                     artifact: ruby_core_build.artifact
                   )
    end

    def do_build(executor, tmpdir, packager, options)
      require_relative "ruby_wasm.so"
      wasm_bytes = packager.package(executor, tmpdir, options)
      RubyWasm.logger.info "Size: #{SizeFormatter.format(wasm_bytes.size)}"
      case options[:output]
      when "-"
        @stdout.write wasm_bytes.pack("C*")
      else
        File.binwrite(options[:output], wasm_bytes.pack("C*"))
        RubyWasm.logger.debug "Wrote #{options[:output]}"
      end
    end
  end
end
