#!/bin/bash

set -eu

usage() {
    echo "Usage: $(basename $0) dist_dir"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

dist_dir="$PWD/$1"
package_dir="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$dist_dir"

# Cache rubies in the package dir
export RUBY_WASM_ROOT="$package_dir/../../../"
cd "$package_dir"
bundle exec rbwasm build --no-stdlib -o "$dist_dir/ruby.wasm"
"$WASMOPT" --strip-debug "$dist_dir/ruby.wasm" -o "$dist_dir/ruby.wasm"
bundle exec rbwasm build -o "$dist_dir/ruby.debug+stdlib.wasm"
"$WASMOPT" --strip-debug "$dist_dir/ruby.debug+stdlib.wasm" -o "$dist_dir/ruby+stdlib.wasm"
