#!/bin/bash

set -eo pipefail

if [ -n "$1" ]; then
  BASE_BRANCH="$1"
elif [ -n "$GITHUB_EVENT_BEFORE" ] && [ "push" = "$GITHUB_EVENT_NAME" ]; then
  BASE_BRANCH="$GITHUB_EVENT_BEFORE"
elif [ -n "$GITHUB_BASE_REF" ]; then
  BASE_BRANCH="origin/$GITHUB_BASE_REF"
else
  BASE_BRANCH="@{upstream}"
fi

MERGE_BASE=$(git merge-base $BASE_BRANCH HEAD)

git diff -U0 --no-color $MERGE_BASE -- '*.c' '*.h' | clang-format-diff -i -p1
exit $?
