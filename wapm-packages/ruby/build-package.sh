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
  wasm-opt --strip-debug ruby-root/usr/local/bin/ruby -o ./ruby-root/ruby.wasm && \
  wasi-vfs pack ./ruby-root/ruby.wasm --mapdir /usr::./ruby-root/usr -o "$dist_dir/ruby.wasm"
)
