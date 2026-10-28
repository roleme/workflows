#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=docker depName=ghcr.io/gitleaks/gitleaks
GITLEAKS_VERSION=v8.30.1

base="${BASE:-}"
if [ -z "$base" ] && [ -n "${GITHUB_BASE_REF:-}" ]; then
  base="origin/$GITHUB_BASE_REF"
fi
if [ -z "$base" ]; then
  base=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || true)
fi

log_opts=()
if [ -n "$base" ]; then
  log_opts=(--log-opts="$base..HEAD")
fi
top=$(git rev-parse --show-toplevel)
common=$(cd "$(git rev-parse --git-common-dir)" && pwd)
mounts=(-v "$top:$top")
case "$common" in
  "$top"/*) ;;
  *) mounts+=(-v "$common:$common") ;;
esac
docker run --rm "${mounts[@]}" -w "$top" \
  -e GIT_CONFIG_COUNT=1 -e GIT_CONFIG_KEY_0=safe.directory -e "GIT_CONFIG_VALUE_0=*" \
  "ghcr.io/gitleaks/gitleaks:${GITLEAKS_VERSION}" git --redact --verbose --no-banner ${log_opts[@]+"${log_opts[@]}"} "$top"
