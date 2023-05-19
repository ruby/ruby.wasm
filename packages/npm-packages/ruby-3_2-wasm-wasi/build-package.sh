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
base_package_dir="$package_dir/../ruby-wasm-wasi"
dist_dir="$package_dir/dist"

rm -rf "$dist_dir"
set -ex
(cd "$package_dir" && npm run build)
$base_package_dir/tools/pack-ruby-wasm.sh "$ruby_root" "$dist_dir"
