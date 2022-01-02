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

mkdir -p "$dist_dir"
cp "$package_dir/package.json" "$dist_dir/package.json"

# TODO(katei): Embed stdlib by wasi-vfs after it's published

mkdir -p "$dist_dir/bin"
cp "$ruby_root/usr/local/bin/ruby" "$dist_dir/bin/ruby.wasm"

(
    cd "$package_dir" && \
    wit-bindgen js \
        --import "$package_dir/../../ext/js/bindgen/rb-js-abi-guest.wit" \
        --export "$package_dir/../../ext/js/bindgen/rb-js-abi-host.wit" \
        --out-dir "$package_dir/bindgen" && \
    npx rollup -c rollup.config.js
)
