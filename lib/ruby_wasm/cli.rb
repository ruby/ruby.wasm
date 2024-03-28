require "optparse"
require "rbconfig"

module RubyWasm
  class CLI
    def initialize(stdout:, stderr:)
      @stdout = stdout
      @stderr = stderr
    end

    def run(args)
      available_commands = %w[build pack]
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
      when "pack"
        pack(args)
      else
        @stderr.puts "Unknown command: #{command}"
        @stderr.puts parser
        exit
      end
    end

    def build(args)
      # @type var options: cli_options
      options = {
        save_temps: false,
        optimize: false,
        remake: false,
        reconfigure: false,
        clean: false,
        ruby_version: "3.3",
        target_triplet: "wasm32-unknown-wasip1",
        profile: "full",
        stdlib: true,
        disable_gems: false,
        gemfile: nil,
        patches: [],
      }
      OptionParser
        .new do |opts|
          opts.banner = "Usage: rbwasm build [options]"
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

          opts.on("-p", "--patch PATCH", "Apply a patch") do |patch|
            options[:patches] << patch
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

    def pack(args)
      self.require_extension
      RubyWasmExt::WasiVfs.run_cli([$0, "pack", *args])
    end

    private

    def build_config(options)
      # @type var config: Packager::build_config
      config = { target: options[:target_triplet], src: compute_build_source(options) }
      case options[:profile]
      when "full"
        config[:default_exts] = config[:src][:all_default_exts]
        env_additional_exts = ENV["RUBY_WASM_ADDITIONAL_EXTS"] || ""
        unless env_additional_exts.empty?
          config[:default_exts] += "," + env_additional_exts
        end
      when "minimal"
        config[:default_exts] = ""
      else
        RubyWasm.logger.error "Unknown profile: #{options[:profile]} (available: full, minimal)"
        exit 1
      end
      config[:suffix] = "-#{options[:profile]}"
      config
    end

    def compute_build_source(options)
      src_name = options[:ruby_version]
      aliases = self.class.build_source_aliases(root)
      source = aliases[src_name]
      if source.nil?
        if File.directory?(src_name)
          # Treat as a local source if the given name is a source directory.
          RubyWasm.logger.debug "Using local source: #{src_name}"
          if options[:patches].any?
            RubyWasm.logger.warn "Patches specified through --patch are ignored for local sources"
          end
          # @type var local_source: RubyWasm::Packager::build_source_local
          local_source = { type: "local", path: src_name }
          # @type var local_source: RubyWasm::Packager::build_source
          local_source = local_source.merge(name: "local", patches: [])
          return local_source
        end
        # Otherwise, it's an unknown source.
        raise(
          "Unknown Ruby source: #{src_name} (available: #{aliases.keys.join(", ")} or a local directory)"
        )
      end
      # Apply user-specified patches in addition to bundled patches.
      source[:patches].concat(options[:patches])
      source
    end

    # Retrieves the alias definitions for the Ruby sources.
    def self.build_source_aliases(root)
      # @type var sources: Hash[string, RubyWasm::Packager::build_source]
      sources = {
        "head" => {
          type: "github",
          repo: "ruby/ruby",
          rev: "master",
          all_default_exts: RubyWasm::Packager::ALL_DEFAULT_EXTS,
        },
        "3.3" => {
          type: "tarball",
          url: "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.0.tar.gz",
          all_default_exts: "bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor,zlib,openssl",
        },
        "3.2" => {
          type: "tarball",
          url: "https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.3.tar.gz",
          all_default_exts: "bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor,zlib,openssl",
        }
      }

      # Apply bundled and user-specified `<root>/patches` directories.
      sources.each do |name, source|
        source[:name] = name
        patches_dirs = [bundled_patches_path, File.join(root, "patches")]
        source[:patches] = patches_dirs.flat_map do |patches_dir|
          Dir[File.join(patches_dir, name, "*.patch")]
            .map { |p| File.expand_path(p) }
        end
      end

      build_manifest = File.join(root, "build_manifest.json")
      if File.exist?(build_manifest)
        begin
          manifest = JSON.parse(File.read(build_manifest))
          manifest["ruby_revisions"].each do |name, rev|
            source = sources[name]
            next unless source[:type] == "github"
            # @type var source: RubyWasm::Packager::build_source_github
            source[:rev] = rev
          end
        rescue StandardError => e
          RubyWasm.logger.warn "Failed to load build_manifest.json: #{e}"
        end
      end
      sources
    end

    # Retrieves the root directory of the Ruby project.
    def root
      __skip__ =
        @root ||=
          begin
            if explicit = ENV["RUBY_WASM_ROOT"]
              File.expand_path(explicit)
            elsif defined?(Bundler)
              Bundler.root
            else
              Dir.pwd
            end
          rescue Bundler::GemfileNotFound
            Dir.pwd
          end
    end

    # Path to the directory containing the bundled patches, which is shipped
    # as part of ruby_wasm gem to backport fixes or try experimental features
    # before landing them to the ruby/ruby repository.
    def self.bundled_patches_path
      dir = __dir__
      raise "Unexpected directory structure, no __dir__!??" unless dir
      lib_source_root = File.join(dir, "..", "..")
      File.join(lib_source_root, "patches")
    end

    def derive_packager(options)
      definition = nil
      __skip__ = if defined?(Bundler) && !options[:disable_gems]
        begin
          # Silence Bundler UI if --print-ruby-cache-key is specified not to bother the JSON output.
          level = options[:print_ruby_cache_key] ? :silent : Bundler.ui.level
          old_level = Bundler.ui.level
          Bundler.ui.level = level
          definition = Bundler.definition
        ensure
          Bundler.ui.level = old_level
        end
      end
      RubyWasm::Packager.new(root, build_config(options), definition)
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
      self.require_extension
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

    def require_extension
      # Tries to require the extension for the given Ruby version first
      begin
        RUBY_VERSION =~ /(\d+\.\d+)/
        require_relative "#{Regexp.last_match(1)}/ruby_wasm.so"
      rescue LoadError
        require_relative "ruby_wasm.so"
      end
    end
  end
end
