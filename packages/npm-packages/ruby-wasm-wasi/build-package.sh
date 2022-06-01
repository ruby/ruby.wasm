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
repo_dir="$package_dir/../../../"

rm -rf "$dist_dir"

wit-bindgen js \
    --import "$repo_dir/ext/witapi/bindgen/rb-abi-guest.wit" \
    --export "$repo_dir/ext/js/bindgen/rb-js-abi-host.wit" \
    --out-dir "$package_dir/src/bindgen"

(
    cd "$package_dir" && \
    npx rollup -c rollup.config.js && \
    npx tsc --build
)

wasm-opt --strip-debug "$ruby_root/usr/local/bin/ruby" -o "$dist_dir/ruby.wasm"

# Build +stdlib versions (removing files that are not used in normal use cases)
workdir="$(mktemp -d)"
cp -R "$ruby_root" "$workdir/ruby-root"
rm -rf $workdir/ruby-root/usr/local/include
rm -f $workdir/ruby-root/usr/local/lib/libruby-static.a
rm -f $workdir/ruby-root/usr/local/bin/ruby
wasi-vfs pack "$dist_dir/ruby.wasm" --mapdir /usr::$workdir/ruby-root/usr -o "$dist_dir/ruby+stdlib.wasm"
wasi-vfs pack "$ruby_root/usr/local/bin/ruby" --mapdir /usr::$workdir/ruby-root/usr -o "$dist_dir/ruby.debug+stdlib.wasm"


mkdir "$dist_dir/bindgen"
cp $(find "$package_dir/src/bindgen" -name "*.js" -or -name "*.d.ts") "$dist_dir/bindgen"
