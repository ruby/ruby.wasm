#!/bin/bash
set -eu

usage() {
    echo "Usage: $(basename $0) ruby_root"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

ruby_root="$1"
package_dir="$(cd "$(dirname "$0")" && pwd)"
dist_dir="$package_dir/dist"

find_compatible_node() {
    # Find `node` executable (>= 15) in PATH
    IFS=':' read -ra dirs <<< "$PATH"
    for dir in "${dirs[@]}"; do
        if [ -f "$dir/node" ] && [ -x "$dir/node" ]; then
            node_version=$("$dir/node" --version)
            if [ "${node_version:1:2}" -ge 15 ]; then
                echo "$dir/node"
                return
            fi
        fi
    done
    echo "node >= 15 is required to build the package" >&2
    exit 1
}

mkdir -p "$dist_dir"

nodejs="$(find_compatible_node)"

cp "$ruby_root/usr/local/bin/ruby.wasm" "$dist_dir/ruby.wasm"
cp "$ruby_root/usr/local/bin/ruby" "$dist_dir/ruby.js"

file_packager="$(dirname $(which emcc))/tools/file_packager"
if [ ! -f "$file_packager" ]; then
    echo "file_packager tool not found"
    exit 1
fi

ruby_stdlib_js="$dist_dir/ruby_stdlib.js"
rm -f "$ruby_stdlib_js"
echo "export function loadRubyStdlib() {" >> "$ruby_stdlib_js"
"$file_packager" "$dist_dir/ruby_stdlib.data" \
    --export-name=globalThis.__ruby_module \
    --preload "$ruby_root/usr/local/lib@/usr/local/lib" \
    --exclude '*.gem' --exclude "libruby-static.a" >> "$ruby_stdlib_js"
echo "}" >> "$ruby_stdlib_js"

(cd "$package_dir" && PATH="$(dirname "$nodejs"):$PATH" npm run build)
