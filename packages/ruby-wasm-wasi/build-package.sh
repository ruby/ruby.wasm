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

# TODO(katei): Embed stdlib by wasi-vfs after it's published

mkdir -p "$dist_dir/bin"
cp "$ruby_root/usr/local/bin/ruby" "$dist_dir/bin/ruby.wasm"
