#!/bin/bash
set -eu

if [ $# -ne 1 ]; then
    echo "Usage: $0 <dist_dir>"
    exit 1
fi

package_dir="$(cd "$(dirname "$0")/.." && pwd)"
dist_dir="$1"

for format in "esm" "cjs"; do
  mkdir -p "$dist_dir/$format/bindgen/legacy"
  find "$package_dir/src/bindgen/legacy" -name "*.d.ts" -exec cp {} "$dist_dir/$format/bindgen/legacy" \;
done
