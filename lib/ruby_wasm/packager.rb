# A class responsible for packaging whole Ruby project
class RubyWasm::Packager
  # Initializes a new instance of the RubyWasm::Packager class.
  #
  # @param root [String] The root directory of the Ruby project.
  #   The root directory (will) contain the following files:
  #    * build_manifest.json
  #    * rubies
  #    * build
  # @param config [Hash] The build config used for building Ruby.
  # @param definition [Bundler::Definition] The Bundler definition.
  # @param features [RubyWasm::FeatureSet] The features used for packaging.
  def initialize(root, config = nil, definition = nil, features: RubyWasm::FeatureSet.derive_from_env)
    @root = root
    @definition = definition
    @config = config
    @features = features
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

    wasm_bytes = File.binread(File.join(fs.ruby_root, "bin", "ruby"))

    ruby_core.build_gem_exts(executor, fs.bundle_dir)

    fs.package_gems
    fs.remove_non_runtime_files(executor)
    if options[:stdlib]
      options[:without_stdlib_components].each do |component|
        fs.remove_stdlib_component(executor, component)
      end
    else
      fs.remove_stdlib(executor)
    end

    if full_build_options[:target] == "wasm32-unknown-wasip1" && !features.support_dynamic_linking?
      # wasi-vfs supports only WASI target
      wasi_vfs = RubyWasmExt::WasiVfs.new
      wasi_vfs.map_dir("/bundle", fs.bundle_dir)
      wasi_vfs.map_dir("/usr", File.dirname(fs.ruby_root))

      wasm_bytes = wasi_vfs.pack(wasm_bytes)
    end
    wasm_bytes = ruby_core.link_gem_exts(executor, fs.ruby_root, fs.bundle_dir, wasm_bytes)

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
    @specs ||= @definition.resolve.materialize(@definition.requested_dependencies)
      .reject { |spec| EXCLUDED_GEMS.include?(spec.name) }
    @specs
  end

  def features
    @features
  end

  ALL_DEFAULT_EXTS =
    "cgi/escape,continuation,coverage,date,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,json,json/generator,json/parser,objspace,pathname,psych,rbconfig/sizeof,ripper,stringio,strscan,monitor,zlib,openssl"

  # Retrieves the build options used for building Ruby itself.
  def build_options
    default = {
      target: RubyWasm::Target.new("wasm32-unknown-wasip1"),
      default_exts: ALL_DEFAULT_EXTS
    }
    override = @config || {}
    # Merge the default options with the config options
    default.merge(override)
  end

  # Retrieves the resolved build options
  def full_build_options
    options = build_options
    build_dir = File.join(@root, "build")
    rubies_dir = File.join(@root, "rubies")
    toolchain = RubyWasm::Toolchain.get(options[:target], build_dir)
    options.merge(
      toolchain: toolchain,
      build_dir: build_dir,
      rubies_dir: rubies_dir,
      src: options[:src]
    )
  end
end
