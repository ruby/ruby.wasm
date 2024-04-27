require "forwardable"

class RubyWasm::Packager::Core
  def initialize(packager)
    @packager = packager
  end

  def build(executor, options)
    strategy = build_strategy
    strategy.build(executor, options)
  end

  extend Forwardable

  def_delegators :build_strategy, :cache_key, :artifact, :build_and_link_exts

  private

  def build_strategy
    @build_strategy ||=
      begin
        has_exts = @packager.specs.any? { |spec| spec.extensions.any? }
        if @packager.features.support_dynamic_linking?
          DynamicLinking.new(@packager)
        else
          StaticLinking.new(@packager)
        end
      end
  end

  class BuildStrategy
    def initialize(packager)
      @packager = packager
    end

    def build(executor, options)
      raise NotImplementedError
    end

    def build_and_link_exts(executor)
      raise NotImplementedError
    end

    # Array of paths to extconf.rb files.
    def specs_with_extensions
      @packager.specs.filter_map do |spec|
        exts =
          spec.extensions.select do |ext|
            # Filter out extensions of default gems (e.g. json, openssl)
            # for the exactly same gem version.
            File.exist?(File.join(spec.full_gem_path, ext))
          end
        next nil if exts.empty?
        [spec, exts]
      end
    end

    def cache_key(digest)
      raise NotImplementedError
    end

    def artifact
      raise NotImplementedError
    end
  end

  class DynamicLinking < BuildStrategy
    def build(executor, options)
      build = derive_build
      force_rebuild =
        options[:remake] || options[:clean] || options[:reconfigure]
      if File.exist?(build.crossruby.artifact) && !force_rebuild
        # Always build extensions because they are usually not expensive to build
        return build.crossruby.artifact
      end
      build.crossruby.clean(executor) if options[:clean]

      do_build =
        proc do
          build.crossruby.build(
            executor,
            remake: options[:remake],
            reconfigure: options[:reconfigure]
          )
        end

      __skip__ =
        if defined?(Bundler)
          Bundler.with_unbundled_env(&do_build)
        else
          do_build.call
        end
      build.crossruby.artifact
    end

    def build_and_link_exts(executor)
      build = derive_build
      self.build_exts(executor, build)
      self.link_exts(executor, build)
    end

    def link_exts(executor, build)
      ruby_root = build.crossruby.dest_dir

      libraries = [File.join(ruby_root, "usr", "local", "bin", "ruby")]

      # TODO: Should be computed from dyinfo of ruby binary
      wasi_libc_shared_libs = [
        "libc.so",
        "libwasi-emulated-getpid.so",
        "libwasi-emulated-mman.so",
        "libwasi-emulated-process-clocks.so",
        "libwasi-emulated-signal.so",
      ]

      wasi_libc_shared_libs.each do |lib|
        # @type var toolchain: RubyWasm::WASISDK
        toolchain = build.toolchain
        wasi_sdk_path = toolchain.wasi_sdk_path
        libraries << File.join(wasi_sdk_path, "share/wasi-sysroot/lib/wasm32-wasi", lib)
      end
      wasi_adapter = RubyWasm::Packager::ComponentAdapter.wasi_snapshot_preview1("command")
      adapters = [wasi_adapter]
      dl_openable_libs = Dir.glob(File.join(ruby_root, "usr", "local", "lib", "ruby", "**", "*.so"))
      linker = RubyWasmExt::ComponentLink.new
      linker.use_built_in_libdl(true)
      linker.stub_missing_functions(false)
      linker.validate(true)

      libraries.each do |lib|
        # Non-DL openable libraries should be referenced as base name
        lib_name = File.basename(lib)
        module_bytes = File.binread(lib)
        RubyWasm.logger.info "Linking #{lib_name} (#{module_bytes.size} bytes)"
        linker.library(lib_name, module_bytes, false)
      end

      dl_openable_libs.each do |lib|
        # DL openable lib_name should be a relative path from ruby_root
        lib_name = "/" + Pathname.new(lib).relative_path_from(Pathname.new(ruby_root)).to_s
        module_bytes = File.binread(lib)
        RubyWasm.logger.info "Linking #{lib_name} (#{module_bytes.size} bytes)"
        linker.library(lib_name, module_bytes, true)
      end

      adapters.each do |adapter|
        adapter_name = File.basename(adapter)
        # e.g. wasi_snapshot_preview1.command.wasm -> wasi_snapshot_preview1
        adapter_name = adapter_name.split(".")[0]
        module_bytes = File.binread(adapter)
        linker.adapter(adapter_name, module_bytes)
      end
      return linker.encode()
    end

    def build_exts(executor, build)
      exts = specs_with_extensions.flat_map do |spec, exts|
        exts.map do |ext|
          ext_feature = File.dirname(ext) # e.g. "ext/cgi/escape"
          ext_srcdir = File.join(spec.full_gem_path, ext_feature)
          ext_relative_path = File.join(spec.full_name, ext_feature)
          RubyWasm::CrossRubyExtProduct.new(
            ext_srcdir,
            build.toolchain,
            features: @packager.features,
            ext_relative_path: ext_relative_path
          )
        end
      end

      exts.each do |prod|
        executor.begin_section prod.class, prod.name, "Building"
        prod.build(executor, build.crossruby)
        executor.end_section prod.class, prod.name
      end
    end

    def cache_key(digest)
      derive_build.cache_key(digest)
    end

    def artifact
      derive_build.crossruby.artifact
    end

    def target
      RubyWasm::Target.new(@packager.full_build_options[:target], pic: true)
    end

    def derive_build
      return @build if @build
      __skip__ =
        build ||= RubyWasm::Build.new(
          name, **@packager.full_build_options,
          target: target,
          # NOTE: We don't need linking libwasi_vfs because we use wasi-virt instead.
          wasi_vfs: nil
        )
      build.crossruby.cflags = %w[-fPIC -fvisibility=default]
      if @packager.full_build_options[:target] != "wasm32-unknown-emscripten"
        build.crossruby.debugflags = %w[-g]
        build.crossruby.wasmoptflags = %w[-O3 -g --pass-arg=asyncify-relocatable]
        build.crossruby.ldflags = %w[
          -Xlinker
          --stack-first
          -Xlinker
          -z
          -Xlinker
          stack-size=16777216
        ]
        build.crossruby.xldflags = %w[
          -Xlinker -shared
          -Xlinker --export-dynamic
          -Xlinker --export-all
          -Xlinker --experimental-pic
          -Xlinker -export-if-defined=__main_argc_argv
        ]
      end
      @build = build
      build
    end

    def name
      require "digest"
      options = @packager.full_build_options
      src_channel = options[:src][:name]
      target_triplet = options[:target]
      "ruby-#{src_channel}-#{target_triplet}-pic#{options[:suffix]}"
    end
  end

  class StaticLinking < BuildStrategy
    def build(executor, options)
      build = derive_build
      force_rebuild =
        options[:remake] || options[:clean] || options[:reconfigure]
      if File.exist?(build.crossruby.artifact) && !force_rebuild
        return build.crossruby.artifact
      end
      build.crossruby.clean(executor) if options[:clean]

      do_build =
        proc do
          build.crossruby.build(
            executor,
            remake: options[:remake],
            reconfigure: options[:reconfigure]
          )
        end

      __skip__ =
        if defined?(Bundler)
          Bundler.with_unbundled_env(&do_build)
        else
          do_build.call
        end
      build.crossruby.artifact
    end

    def cache_key(digest)
      derive_build.cache_key(digest)
      if enabled = @packager.features.support_component_model?
        digest << enabled.to_s
      end
    end

    def artifact
      derive_build.crossruby.artifact
    end

    def target
      RubyWasm::Target.new(@packager.full_build_options[:target])
    end

    def derive_build
      return @build if @build
      __skip__ =
        build ||= RubyWasm::Build.new(name, **@packager.full_build_options, target: target)
      build.crossruby.user_exts = user_exts(build)
      # Emscripten uses --global-base=1024 by default, but it conflicts with
      # --stack-first and -z stack-size since global-base 1024 is smaller than
      # the large stack size.
      # Also -g produces some warnings on Emscripten and it confuses the configure
      # script of Ruby.
      if @packager.full_build_options[:target] != "wasm32-unknown-emscripten"
        build.crossruby.debugflags = %w[-g]
        # We assume that imported functions provided through WASI will not change
        # asyncify state, so we ignore them.
        build.crossruby.wasmoptflags = %w[-O3 -g --pass-arg=asyncify-ignore-imports]
        build.crossruby.ldflags = %w[
          -Xlinker
          --stack-first
          -Xlinker
          -z
          -Xlinker
          stack-size=16777216
        ]
      end
      @build = build
      build
    end

    def build_and_link_exts(executor)
      build = derive_build
      ruby_root = build.crossruby.dest_dir
      module_bytes = File.binread(File.join(ruby_root, "usr", "local", "bin", "ruby"))
      return module_bytes unless @packager.features.support_component_model?

      linker = RubyWasmExt::ComponentEncode.new
      linker.validate(true)
      linker.module(module_bytes)
      linker.adapter(
        "wasi_snapshot_preview1",
        File.binread(RubyWasm::Packager::ComponentAdapter.wasi_snapshot_preview1("reactor"))
      )

      linker.encode()
    end

    def user_exts(build)
      @user_exts ||=
        specs_with_extensions.flat_map do |spec, exts|
          exts.map do |ext|
            ext_feature = File.dirname(ext) # e.g. "ext/cgi/escape"
            ext_srcdir = File.join(spec.full_gem_path, ext_feature)
            ext_relative_path = File.join(spec.full_name, ext_feature)
            RubyWasm::CrossRubyExtProduct.new(
              ext_srcdir,
              build.toolchain,
              features: @packager.features,
              ext_relative_path: ext_relative_path
            )
          end
        end
    end

    def name
      require "digest"
      options = @packager.full_build_options
      src_channel = options[:src][:name]
      target_triplet = options[:target]
      base = "ruby-#{src_channel}-#{target_triplet}#{options[:suffix]}"
      exts = specs_with_extensions.sort
      hash = ::Digest::MD5.new
      specs_with_extensions.each { |spec, _| hash << spec.full_name }
      if enabled = @packager.features.support_component_model?
        hash << enabled.to_s
      end
      exts.empty? ? base : "#{base}-#{hash.hexdigest}"
    end
  end
end
