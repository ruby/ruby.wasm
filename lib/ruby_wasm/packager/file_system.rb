# Package Ruby code into a mountable directory.
class RubyWasm::Packager::FileSystem
  def initialize(dest_dir, packager)
    @dest_dir = dest_dir
    @packager = packager
    @ruby_root = File.join(@dest_dir, "usr", "local")
  end

  def package_ruby_root(tarball, executor)
    usr_dir = File.dirname(@ruby_root)
    executor.mkdir_p usr_dir
    executor.system(
      "tar",
      "-C",
      usr_dir,
      "-xzf",
      tarball,
      "--strip-components=2"
    )
  end

  def remove_stdlib(executor)
    # Include only rbconfig.rb
    rbconfig =
      File.join(
        @ruby_root,
        "lib",
        "ruby",
        ruby_version,
        "wasm32-wasi",
        "rbconfig.rb"
      )
    # Remove all files except rbconfig.rb
    RubyWasm.logger.info "Removing stdlib (except rbconfig.rb: #{rbconfig})"
    rbconfig_contents = File.read(rbconfig)
    executor.rm_rf @ruby_root
    executor.mkdir_p File.dirname(rbconfig)
    File.write(rbconfig, rbconfig_contents)
  end

  def remove_stdlib_component(executor, component)
    RubyWasm.logger.info "Removing stdlib component: #{component}"
    case component
    when "enc"
      # Remove all encodings except for encdb.so and transdb.so
      enc_dir = File.join(@ruby_root, "lib", "ruby", ruby_version, "wasm32-wasi", "enc")
      Dir.glob(File.join(enc_dir, "**/*.so")).each do |entry|
        next if entry.end_with?("encdb.so", "transdb.so")
        RubyWasm.logger.debug "Removing stdlib encoding: #{entry}"
        executor.rm_rf entry
      end
    else
      raise "Unknown stdlib component: #{component}"
    end
  end

  def package_gems
    @packager.specs.each do |spec|
      RubyWasm.logger.info "Packaging gem: #{spec.full_name}"
    end
    self.each_gem_content_path do |relative, source|
      RubyWasm.logger.debug "Packaging gem file: #{relative}"
      dest = File.join(@dest_dir, relative)
      FileUtils.mkdir_p File.dirname(dest)
      FileUtils.cp_r source, dest
    end

    setup_rb_path = File.join(bundle_relative_path, "setup.rb")
    RubyWasm.logger.info "Packaging setup.rb: #{setup_rb_path}"
    full_setup_rb_path = File.join(@dest_dir, setup_rb_path)
    FileUtils.mkdir_p File.dirname(full_setup_rb_path)
    File.write(full_setup_rb_path, setup_rb_content)
  end

  def setup_rb_content
    content = ""
    self.each_gem_require_path do |relative, _|
      content << %Q[$:.unshift File.expand_path("#{File.join("/", relative)}")\n]
    end
    content
  end

  def remove_non_runtime_files(executor)
    patterns = %w[
      usr/local/lib/libruby-static.a
      usr/local/bin/ruby
      usr/local/include
    ]

    patterns << "**/*.so" unless @packager.features.support_dynamic_linking?
    patterns.each do |pattern|
      Dir
        .glob(File.join(@dest_dir, pattern))
        .each do |entry|
          RubyWasm.logger.debug do
            relative_entry = Pathname.new(entry).relative_path_from(@dest_dir)
            "Removing non-runtime file: #{relative_entry}"
          end
          executor.rm_rf entry
        end
    end
  end

  def bundle_dir
    File.join(@dest_dir, bundle_relative_path)
  end

  def ruby_root
    @ruby_root
  end

  private

  # Iterates over each gem's require path and extension path.
  # Yields the installation relative path and the source path.
  def each_gem_require_path(&block)
    each_gem_extension_path(&block)
    @packager.specs.each do |spec|
      # Use raw_require_paths to exclude extensions
      spec.raw_require_paths.each do |require_path|
        source = File.expand_path(require_path, spec.full_gem_path)
        next unless File.exist?(source)
        relative =
          File.join(bundle_relative_path, "gems", spec.full_name, require_path)
        yield relative, source
      end
    end
  end

  def each_gem_content_path(&block)
    each_gem_extension_path(&block)

    @packager.specs.each do |spec|
      next unless File.exist?(spec.full_gem_path)

      # spec.files is only valid before the gem is packaged.
      if spec.source.path?
        relative_paths = spec.files
      else
        # All files in .gem are required.
        relative_paths = Dir.children(spec.full_gem_path)
      end
      relative_paths.each do |require_path|
        source = File.expand_path(require_path, spec.full_gem_path)
        next unless File.exist?(source)
        relative =
          File.join(bundle_relative_path, "gems", spec.full_name, require_path)
        yield relative, source
      end
    end
  end

  def each_gem_extension_path
    @packager.specs.each do |spec|
      if !spec.extensions.empty? && File.exist?(spec.extension_dir)
        relative = File.join(bundle_relative_path, "extensions", spec.full_name)
        yield relative, spec.extension_dir
      end
    end
  end

  def bundle_relative_path
    "bundle"
  end

  def ruby_version
    rubyarchdir = self.rubyarchdir
    File.basename(File.dirname(rubyarchdir))
  end

  def rubyarchdir
    maybe =
      Dir.glob(File.join(@ruby_root, "lib", "ruby", "*", "wasm32-wasi")).first
    maybe || raise("Cannot find rubyarchdir")
  end
end
