#!/bin/bash
set -eu

usage() {
    echo "Usage: $(basename $0) ruby_root dist_dir"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

ruby_root="$1"
dist_dir="$2"
package_dir="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$dist_dir"
cp "$package_dir/package.json" "$dist_dir/package.json"

cp "$ruby_root/usr/local/bin/ruby.wasm" "$dist_dir/ruby.wasm"
cp "$ruby_root/usr/local/bin/ruby" "$dist_dir/ruby.js"
echo "export const createRubyModule = Module;" >> "$dist_dir/ruby.js"

file_packager="$(dirname $(which emcc))/tools/file_packager"
if [ ! -f "$file_packager" ]; then
    echo "file_packager tool not found"
    exit 1
fi

ruby_stdlib_js="$dist_dir/ruby_stdlib.js"
rm "$ruby_stdlib_js"
echo "export function loadRubyStdlib() {" >> "$ruby_stdlib_js"
"$file_packager" "$dist_dir/ruby_stdlib.data" \
    --export-name=globalThis.__ruby_module \
    --preload "$ruby_root/usr/local/lib@/usr/local/lib" \
    --exclude '*.gem' --exclude "libruby-static.a" >> "$ruby_stdlib_js"
echo "}" >> "$ruby_stdlib_js"

(cd "$package_dir" && npx rollup "$package_dir/index.js" -o "$dist_dir/index.js")
