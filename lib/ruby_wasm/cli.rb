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
      OptionParser
        .new do |opts|
          opts.banner = <<~USAGE
          Usage: rbwasm [options...] [command]

          Available commands: #{available_commands.join(", ")}
        USAGE
          opts.version = RubyWasm::VERSION
          opts.on("-h", "--help", "Prints this help") do
            @stdout.puts opts
            exit
          end
          opts.on("--log-level LEVEL", "Log level") do |level|
            RubyWasm.log_level = level.to_sym
          end
        end
        .order!(args)

      command = args.shift
      case command
      when "build"
        build(args)
      else
        @stderr.puts "Unknown command: #{command}"
        exit
      end
    end

    def build(args)
      # @type var options: Hash[Symbol, untyped]
      options = {
        save_temps: false,
        optimize: false,
        target_triplet: "wasm32-unknown-wasi",
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

          opts.on("--target TRIPLET", "Target triplet") do |triplet|
            options[:target_triplet] = triplet
          end

          opts.on("--optimize", "Optimize the output") do
            options[:optimize] = true
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

      require "tmpdir"

      if options[:save_temps]
        tmpdir = Dir.mktmpdir
        self.do_build(executor, tmpdir, options)
        @stdout.puts "Temporary files are saved to #{tmpdir}"
        exit
      else
        Dir.mktmpdir { |tmpdir| self.do_build(executor, tmpdir, options) }
      end
    end

    private def do_build(executor, tmp_dir, options)
      packager = RubyWasm::Packager.new(tmp_dir, options[:target_triplet])
      wasm_bytes = packager.package(executor, options)
      @stdout.puts "Size: #{SizeFormatter.format(wasm_bytes.size)}"
      if options[:output]
        File.binwrite(options[:output], wasm_bytes.pack("C*"))
        @stdout.puts "Wrote #{options[:output]}"
      else
        @stderr.puts "Writing to stdout"
        @stdout.write wasm_bytes.pack("C*")
      end
    end
  end
end
