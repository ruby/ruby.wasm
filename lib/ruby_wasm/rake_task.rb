require "rake/tasklib"
require_relative "./util"
require_relative "./build"

class RubyWasm::BuildTask < ::Rake::TaskLib
  # Name of the task.
  attr_accessor :name

  def initialize(
    name,
    target:,
    src:,
    toolchain: nil,
    build_dir: nil,
    rubies_dir: nil,
    **options,
    &block
  )
    target = Target.new(target)
    @build =
      RubyWasm::Build.new(
        name,
        target: target,
        src: src,
        toolchain: toolchain,
        build_dir: build_dir || File.join(Dir.pwd, "build"),
        rubies_dir: rubies_dir || File.join(Dir.pwd, "rubies"),
        **options,
        &block
      )
    yield @build if block_given?
    @crossruby = @build.crossruby
    # Rake.verbose can be Object.new by default, so compare with true explicitly.
    executor = RubyWasm::BuildExecutor.new(verbose: Rake.verbose == true)

    desc "Cross-build Ruby for #{@target}"
    task name do
      next if File.exist? @crossruby.artifact
      @crossruby.build(executor)
    end
    namespace name do
      task :remake do
        @crossruby.build(executor, remake: true)
      end
      task :reconfigure do
        @crossruby.build(executor, reconfigure: true)
      end
      task :clean do
        @crossruby.clean(executor)
      end
    end
  end

  def hexdigest
    require "digest"
    digest = Digest::SHA256.new
    @build.cache_key(digest)
    digest.hexdigest
  end
end
