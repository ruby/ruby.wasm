require "test-unit"
require "tmpdir"
require_relative "../lib/ruby_wasm"

class StaticExtensionCacheTest < Test::Unit::TestCase
  class CrossRuby
    attr_reader :artifact, :calls, :extension, :user_exts, :clean_count
    attr_accessor :fail_build, :during_build

    def initialize(dir)
      @artifact = File.join(dir, "ruby.tar.gz")
      @extension = File.join(dir, "extension")
      FileUtils.mkdir_p(@extension)
      File.write(File.join(@extension, "js.c"), "original")
      @user_exts = [
        RubyWasm::CrossRubyExtProduct.new(@extension, nil, features: nil)
      ]
      @calls = []
      @clean_count = 0
    end

    def build(_executor, **options)
      @calls << options
      @during_build.call if @during_build
      File.write(artifact, "ruby")
      raise "build failed" if fail_build
    end

    def clean(_executor)
      @clean_count += 1
      FileUtils.rm_f(artifact)
    end
  end

  class Strategy < RubyWasm::Packager::Core::StaticLinking
    def initialize(build)
      @build = build
    end

    def derive_build
      @build
    end
  end

  def setup
    @dir = Dir.mktmpdir
    @build = Struct.new(:crossruby).new(CrossRuby.new(@dir))
    @strategy = Strategy.new(@build)
    @executor = Object.new
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def build(**options)
    @strategy.build(@executor, options)
  end

  def test_unchanged_extensions_reuse_artifact
    build
    build
    assert_equal 1, @build.crossruby.calls.size
  end

  def test_extension_content_change_rebuilds
    build
    path = File.join(@build.crossruby.extension, "js.c")
    File.write(path, "modified")
    build
    assert_equal 2, @build.crossruby.calls.size
    assert_equal(
      { remake: true, reconfigure: nil },
      @build.crossruby.calls.last
    )
    assert_equal 0, @build.crossruby.clean_count
  end

  def test_added_and_deleted_extension_inputs_rebuild
    build
    path = File.join(@build.crossruby.extension, "extra.h")
    File.write(path, "header")
    build
    FileUtils.rm_f(path)
    build
    assert_equal 3, @build.crossruby.calls.size
  end

  def test_existing_artifact_without_record_rebuilds
    File.write(@build.crossruby.artifact, "old build")
    build
    assert_equal 1, @build.crossruby.calls.size
  end

  def test_existing_artifact_without_extensions_is_reused
    @build.crossruby.user_exts.clear
    File.write(@build.crossruby.artifact, "prebuilt Ruby")
    build
    assert_empty @build.crossruby.calls
  end

  def test_force_options_rebuild_even_with_matching_inputs
    build
    build(remake: true)
    build(reconfigure: true)
    build(clean: true)
    assert_equal 4, @build.crossruby.calls.count { |call| call.is_a?(Hash) }
    assert_equal 1, @build.crossruby.clean_count
    assert_equal true, @build.crossruby.calls[2][:reconfigure]
  end

  def test_failed_forced_build_invalidates_previous_record
    build
    @build.crossruby.fail_build = true
    assert_raise(RuntimeError) { build(remake: true) }
    @build.crossruby.fail_build = false
    build
    assert_equal 3, @build.crossruby.calls.size
  end

  def test_inputs_edited_during_build_are_not_recorded
    @build.crossruby.during_build =
      proc do
        File.write(
          File.join(@build.crossruby.extension, "js.c"),
          "edited during build"
        )
      end
    build
    @build.crossruby.during_build = nil
    build
    assert_equal 2, @build.crossruby.calls.size
  end
end
