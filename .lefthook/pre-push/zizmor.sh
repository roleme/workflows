#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=pypi depName=zizmor
ZIZMOR_VERSION=1.31.1

format=()
if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  format=(--format=github)
fi
uvx "zizmor@${ZIZMOR_VERSION}" ${format[@]+"${format[@]}"} "${@:-.}"
