#!/bin/bash

set -e

[ ! -z "${RUBYWASM_UID+x}" ] && usermod --uid "$RUBYWASM_UID" --non-unique me
[ ! -z "${RUBYWASM_GID+x}" ] && groupmod --gid "$RUBYWASM_GID" --non-unique me
exec gosu me "$@"
