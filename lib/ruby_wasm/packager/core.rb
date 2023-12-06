class RubyWasm::Packager::Core
  def initialize(packager)
    @packager = packager
  end

  def build(executor)
    strategy = build_strategy
    strategy.build(executor)
  end

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

    def build(executor)
      raise NotImplementedError
    end

    # Array of paths to extconf.rb files.
    def specs_with_extensions
      @packager.specs.select { |spec| !spec.extensions.empty? }
    end
  end

  class DynamicLinking < BuildStrategy
  end

  class StaticLinking < BuildStrategy
    def build(executor)
      @build ||= RubyWasm::Build.new(name, **@packager.build_options)
      @build.crossruby.user_exts = user_exts
      @build.crossruby.debugflags = %w[-g]
      @build.crossruby.wasmoptflags = %w[-O3 -g]
      @build.crossruby.ldflags = %w[
        -Xlinker
        --stack-first
        -Xlinker
        -z
        -Xlinker
        stack-size=16777216
      ]
      Bundler.with_unbundled_env { @build.crossruby.build(executor) }
      @build.crossruby.artifact
    end

    def user_exts
      @user_exts ||=
        specs_with_extensions.flat_map do |spec|
          spec.extensions.map do |ext|
            ext_feature = File.dirname(ext) # e.g. "ext/cgi/escape"
            ext_srcdir = File.join(spec.full_gem_path, ext_feature)
            ext_relative_path = File.join(spec.full_name, ext_feature)
            RubyWasm::CrossRubyExtProduct.new(
              ext_srcdir,
              @build.toolchain,
              ext_relative_path: ext_relative_path
            )
          end
        end
    end

    def name
      require "digest"
      options = @packager.build_options
      src_channel = options[:src][:name]
      target_triplet = options[:target]
      base = "ruby-#{src_channel}-static-#{target_triplet}"
      exts = specs_with_extensions.sort
      hash = ::Digest::MD5.new
      specs_with_extensions.each { |spec| hash << spec.full_name }
      exts.empty? ? base : "#{base}-#{hash.hexdigest}"
    end
  end
end
