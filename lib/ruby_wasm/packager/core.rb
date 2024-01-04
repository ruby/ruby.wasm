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

  def_delegators :build_strategy, :cache_key, :artifact

  private

  def build_strategy
    @build_strategy ||=
      begin
        has_exts = @packager.specs.any? { |spec| spec.extensions.any? }
        if @packager.support_dynamic_linking?
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
    end

    def artifact
      derive_build.crossruby.artifact
    end

    def derive_build
      return @build if @build
      __skip__ =
        build ||= RubyWasm::Build.new(name, **@packager.full_build_options)
      build.crossruby.user_exts = user_exts(build)
      # Emscripten uses --global-base=1024 by default, but it conflicts with
      # --stack-first and -z stack-size since global-base 1024 is smaller than
      # the large stack size.
      # Also -g produces some warnings on Emscripten and it confuses the configure
      # script of Ruby.
      if @packager.full_build_options[:target] != "wasm32-unknown-emscripten"
        build.crossruby.debugflags = %w[-g]
        build.crossruby.wasmoptflags = %w[-O3 -g]
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
      exts.empty? ? base : "#{base}-#{hash.hexdigest}"
    end
  end
end
