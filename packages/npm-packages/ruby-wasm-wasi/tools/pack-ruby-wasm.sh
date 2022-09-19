#!/bin/bash

usage() {
    echo "Usage: $(basename $0) ruby_root dist_dir"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

ruby_root="$1"
dist_dir="$2"
package_dir="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$dist_dir"

"$WASMOPT" --strip-debug "$ruby_root/usr/local/bin/ruby" -o "$dist_dir/ruby.wasm"

# Build +stdlib versions (removing files that are not used in normal use cases)

workdir="$(mktemp -d)"
cp -R "$ruby_root" "$workdir/ruby-root"
rm -rf $workdir/ruby-root/usr/local/include
rm -f $workdir/ruby-root/usr/local/lib/libruby-static.a
rm -f $workdir/ruby-root/usr/local/bin/ruby
"$WASI_VFS_CLI" pack "$dist_dir/ruby.wasm" --mapdir /usr::$workdir/ruby-root/usr -o "$dist_dir/ruby+stdlib.wasm"
"$WASI_VFS_CLI" pack "$ruby_root/usr/local/bin/ruby" --mapdir /usr::$workdir/ruby-root/usr -o "$dist_dir/ruby.debug+stdlib.wasm"

cp $dist_dir/*.wasm "$package_dir/dist/"
