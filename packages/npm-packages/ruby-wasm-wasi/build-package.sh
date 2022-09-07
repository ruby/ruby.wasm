#!/bin/bash
set -eu

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

mkdir "$dist_dir/bindgen"
cp $(find "$package_dir/src/bindgen" -name "*.js" -or -name "*.d.ts") "$dist_dir/bindgen"
