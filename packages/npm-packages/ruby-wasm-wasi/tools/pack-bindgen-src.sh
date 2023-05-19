#!/bin/bash
set -eu

if [ $# -ne 1 ]; then
    echo "Usage: $0 <dist_dir>"
    exit 1
fi

package_dir="$(cd "$(dirname "$0")/.." && pwd)"
dist_dir="$1"

mkdir -p "$dist_dir/bindgen"
find "$package_dir/src/bindgen" -name "*.d.ts" -exec cp {} "$dist_dir/bindgen" \;
