#!/usr/bin/env ruby

require "fileutils"

unless ARGV.length == 1
  puts "Usage: #{$0} <dist_dir>"
  exit 1
end

package_dir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
dist_dir = ARGV[0]

def sync_dir(src, dst, pattern)
  Dir.glob(File.join(src, pattern)).each do |f|
    rel = f.delete_prefix(src + "/")
    dst_f = File.join(dst, rel)
    FileUtils.mkdir_p(File.dirname(dst_f))
    puts "Copying #{f} -> #{dst_f}"
    FileUtils.cp_r(f, dst_f)
  end
end

["esm", "cjs"].each do |format|
  src = File.join(package_dir, "src/bindgen")
  dst = File.join(dist_dir, format, "bindgen")
  sync_dir(src, dst, "**/*.d.ts")
end
