#!/bin/bash

set -eu

usage() {
    echo "Usage: $(basename $0) ruby_version dist_dir"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

ruby_version="$1"
dist_dir="$PWD/$2"
package_dir="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$dist_dir"

# Cache rubies in the package dir
export RUBY_WASM_ROOT="$package_dir/../../.."
export BUNDLE_GEMFILE="$package_dir/Gemfile"
cd "$package_dir"

echo "$0: Entering $package_dir"

rbwasm_options="--ruby-version $ruby_version --target wasm32-unknown-wasi --build-profile full"
bundle exec rbwasm build ${rbwasm_options[@]} --no-stdlib -o "$dist_dir/ruby.wasm"
"$WASMOPT" --strip-debug "$dist_dir/ruby.wasm" -o "$dist_dir/ruby.wasm"
bundle exec rbwasm build ${rbwasm_options[@]} -o "$dist_dir/ruby.debug+stdlib.wasm"
"$WASMOPT" --strip-debug "$dist_dir/ruby.debug+stdlib.wasm" -o "$dist_dir/ruby+stdlib.wasm"
