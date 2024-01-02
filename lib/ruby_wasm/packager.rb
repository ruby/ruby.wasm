class RubyWasm::Packager
  def initialize(dest_dir, target_triplet, definition = Bundler.definition)
    @dest_dir = dest_dir
    @definition = definition
    @target_triplet = target_triplet
  end

  def package(executor, options)
    require_relative "ruby_wasm.so"

    ruby_core = RubyWasm::Packager::Core.new(self)
    tarball = ruby_core.build(executor)

    fs = RubyWasm::Packager::FileSystem.new(@dest_dir, self)
    fs.package_ruby_root(tarball, executor)

    ruby_wasm_bin = File.expand_path("bin/ruby", fs.ruby_root)
    wasm_bytes = File.binread(ruby_wasm_bin).bytes

    fs.package_gems
    fs.remove_non_runtime_files(executor)
    fs.remove_stdlib(executor) unless options[:stdlib]

    wasi_vfs = RubyWasmExt::WasiVfs.new
    wasi_vfs.map_dir("/bundle", fs.bundle_dir)
    wasi_vfs.map_dir("/usr", File.dirname(fs.ruby_root))

    wasm_bytes = wasi_vfs.pack(wasm_bytes)

    wasm_bytes = RubyWasmExt.preinitialize(wasm_bytes) if options[:optimize]
    wasm_bytes
  end

  EXCLUDED_GEMS = %w[ruby_wasm bundler]

  def specs
    @definition.specs.reject { |spec| EXCLUDED_GEMS.include?(spec.name) }
  end

  def support_dynamic_linking?
    @ruby_channel == "head"
  end

  def root
    @root ||=
      begin
        if explicit = ENV["RUBY_WASM_ROOT"]
          explicit
        else
          Bundler.root
        end
      rescue Bundler::GemfileNotFound
        Dir.pwd
      end
  end

  def build_options
    {
      target: @target_triplet,
      src: {
        name: "3.3",
        type: "tarball",
        url: "https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.0.tar.gz"
      },
      default_exts:
        "bigdecimal,cgi/escape,continuation,coverage,date,dbm,digest/bubblebabble,digest,digest/md5,digest/rmd160,digest/sha1,digest/sha2,etc,fcntl,fiber,gdbm,json,json/generator,json/parser,nkf,objspace,pathname,psych,racc/cparse,rbconfig/sizeof,ripper,stringio,strscan,monitor,zlib,openssl",
      toolchain: RubyWasm::Toolchain.get(@target_triplet),
      build_dir: File.join(root, "build"),
      rubies_dir: File.join(root, "rubies")
    }
  end
end
