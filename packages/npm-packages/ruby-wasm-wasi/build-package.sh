#!/bin/bash
set -eu

package_dir="$(cd "$(dirname "$0")" && pwd)"
dist_dir="$package_dir/dist"
repo_dir="$package_dir/../../../"

rm -rf "$dist_dir"

(cd "$package_dir" && npm run build)

mkdir "$dist_dir/bindgen"
cp $(find "$package_dir/src/bindgen" -name "*.js" -or -name "*.d.ts") "$dist_dir/bindgen"

cp "$repo_dir/LICENSE" "$dist_dir/LICENSE"
cp "$repo_dir/NOTICE" "$dist_dir/NOTICE"
