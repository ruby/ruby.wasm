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
workdir="$(mktemp -d)"

mkdir -p "$dist_dir"

cp -R "$ruby_root" "$workdir/ruby-root"

(
  cd "$workdir" && \
  "$WASMOPT" --strip-debug ruby-root/usr/local/bin/ruby -o ./ruby-root/ruby.wasm && \
  "$WASI_VFS_CLI" pack ./ruby-root/ruby.wasm --mapdir /usr::./ruby-root/usr --mapdir /gems::$package_dir/gems -o "$dist_dir/irb.wasm" && \
  wasi-preset-args "$dist_dir/irb.wasm" -o "$dist_dir/irb.wasm" -- -I/gems/lib /gems/libexec/irb --prompt default
)
