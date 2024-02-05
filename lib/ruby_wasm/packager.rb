# A class responsible for packaging whole Ruby project
class RubyWasm::Packager
  # Initializes a new instance of the RubyWasm::Packager class.
  #
  # @param config [Hash] The build config used for building Ruby.
  # @param definition [Bundler::Definition] The Bundler definition.
  def initialize(config = nil, definition = nil)
    @definition = definition
    @config = config
  end

  # Packages the Ruby code into a Wasm binary. (including extensions)
  #
  # @param executor [RubyWasm::BuildExecutor] The executor for building the Wasm binary.
  # @param dest_dir [String] The destination used to construct the filesystem.
  # @param options [Hash] The packaging options.
  # @return [Array<Integer>] The bytes of the packaged Wasm binary.
  def package(executor, dest_dir, options)
    ruby_core = self.ruby_core_build()
    tarball = ruby_core.build(executor, options)

    fs = RubyWasm::Packager::FileSystem.new(dest_dir, self)
    fs.package_ruby_root(tarball, executor)

    ruby_wasm_bin = File.expand_path("bin/ruby", fs.ruby_root)
    wasm_bytes = File.binread(ruby_wasm_bin).bytes

    fs.package_gems
    fs.remove_non_runtime_files(executor)
    fs.remove_stdlib(executor) unless options[:stdlib]

    if full_build_options[:target] == "wasm32-unknown-wasi"
      # wasi-vfs supports only WASI target
      wasi_vfs = RubyWasmExt::WasiVfs.new
      wasi_vfs.map_dir("/bundle", fs.bundle_dir)
      wasi_vfs.map_dir("/usr", File.dirname(fs.ruby_root))

      wasm_bytes = wasi_vfs.pack(wasm_bytes)
    end

    wasm_bytes = RubyWasmExt.preinitialize(wasm_bytes) if options[:optimize]
    wasm_bytes
  end

  def ruby_core_build
    @ruby_core_build ||= RubyWasm::Packager::Core.new(self)
  end

  # The list of excluded gems from the Bundler definition.
  EXCLUDED_GEMS = %w[ruby_wasm bundler]

  # Retrieves the specs from the Bundler definition, excluding the excluded gems.
  def specs
    return [] unless @definition
    @definition.specs.reject { |spec| EXCLUDED_GEMS.include?(spec.name) }
  end

  # Checks if dynamic linking is supported.
  def support_dynamic_linking?
    ENV["RUBY_WASM_EXPERIMENTAL_DYNAMIC_LINKING"] == "1"
  end

  # Retrieves the root directory of the Ruby project.
  # The root directory contains the following stuff:
  #  * patches/{source}/*.patch
  #  * build_manifest.json
  #  * rubies
  #  * build
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

  # Retrieves the alias definitions for the Ruby sources.
  def self.build_source_aliases(root)
    # @type var sources: Hash[string, RubyWasm::Packager::build_source]
    sources = {
      "head" => {
        type: "github",
        repo: "ruby/ruby",
        rev: "master"
      },
      "3.3" => {
        type: "tarball",
        url: "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.0.tar.gz"
      },
      "3.2" => {
        type: "tarball",
        url: "https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.3.tar.gz"
      }
    }
    sources.each do |name, source|
      source[:name] = name
      patches = Dir[File.join(root, "patches", name, "*.patch")]
        .map { |p| File.expand_path(p) }
      source[:patches] = patches
    end

    build_manifest = File.join(root, "build_manifest.json")
    if File.exist?(build_manifest)
      begin
        manifest = JSON.parse(File.read(build_manifest))
        manifest["ruby_revisions"].each do |name, rev|
          sources[name][:rev] = rev
        end
      rescue StandardError => e
        RubyWasm.logger.warn "Failed to load build_manifest.json: #{e}"
      end
    end
    sources
  end

  ALL_DEFAULT_EXTS =
    "bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor,zlib,openssl"

  # Retrieves the build options used for building Ruby itself.
  def build_options
    default = {
      target: "wasm32-unknown-wasi",
      src: "3.3",
      default_exts: ALL_DEFAULT_EXTS
    }
    override = @config || {}
    # Merge the default options with the config options
    default.merge(override)
  end

  # Retrieves the resolved build options
  def full_build_options
    options = build_options
    build_dir = File.join(root, "build")
    rubies_dir = File.join(root, "rubies")
    toolchain = RubyWasm::Toolchain.get(options[:target], build_dir)
    src =
      if options[:src].is_a?(Hash)
        options[:src]
      else
        src_name = options[:src]
        aliases = self.class.build_source_aliases(root)
        aliases[src_name] ||
          raise(
            "Unknown Ruby source: #{src_name} (available: #{aliases.keys.join(", ")})"
          )
      end
    options.merge(
      toolchain: toolchain,
      build_dir: build_dir,
      rubies_dir: rubies_dir,
      src: src
    )
  end
end
