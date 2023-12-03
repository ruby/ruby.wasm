#!/bin/bash
set -eu

if [ $# -ne 1 ]; then
    echo "Usage: $0 <dist_dir>"
    exit 1
fi

dist_dir="$1"

echo '{ "type": "module" }' > "$dist_dir/esm/package.json"
