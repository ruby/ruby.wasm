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
repo_dir="$package_dir/../../../"

rm -rf "$dist_dir"
(
  cd "$base_package_dir" && \
  npm ci && \
  ./build-package.sh "$ruby_root"
)
set -ex
(cd "$package_dir" && npm run build)
cp -R "$base_package_dir/dist/." "$dist_dir"
$base_package_dir/tools/pack-ruby-wasm.sh "$ruby_root" "$dist_dir"
