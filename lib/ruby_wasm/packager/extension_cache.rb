require "digest"
require "fileutils"

class RubyWasm::Packager::ExtensionCache
  def initialize(artifact, extensions)
    @artifact = artifact
    @extensions = extensions
    @record = "#{artifact}.extensions.sha256"
  end

  # Inputs may be edited during a build, so only record builds whose inputs
  # stayed unchanged. Invalidate the previous record first so a failed forced
  # rebuild cannot leave an older artifact eligible for reuse.
  def fetch(force: false)
    extensions_key_before_build = key
    if !force && reusable?(extensions_key_before_build)
      RubyWasm.logger.info "Reusing Ruby: #{@artifact}"
      return @artifact
    end

    FileUtils.rm_f(@record)
    yield

    extensions_key_after_build = key
    if extensions_key_before_build == extensions_key_after_build
      File.write(@record, extensions_key_after_build)
    end
    @artifact
  end

  private

  def reusable?(key)
    return false unless File.file?(@artifact)
    return true if @extensions.empty?

    File.file?(@record) && File.read(@record) == key
  end

  def key
    digest = Digest::SHA256.new
    @extensions.each { |ext| ext.cache_key(digest) }
    digest.hexdigest
  end
end
