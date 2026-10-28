#!/usr/bin/env bash
set -euo pipefail

run=true
if [ "${FORCE:-false}" != "true" ]; then
  base="${BASE:-}"
  if [ -z "$base" ] && [ -n "${GITHUB_BASE_REF:-}" ]; then
    base="origin/$GITHUB_BASE_REF"
  fi
  if [ -n "$base" ]; then
    specs=()
    while IFS= read -r line; do
      line="${line#"${line%%[![:space:]]*}"}"
      [ -n "$line" ] && specs+=(":(glob)$line")
    done <<< "${PATHS:-}"
    if [ -z "$(git diff --name-only --diff-filter=d "$base"...HEAD -- ${specs[@]+"${specs[@]}"})" ]; then
      run=false
    fi
  fi
fi
echo "run=$run"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "run=$run" >> "$GITHUB_OUTPUT"
fi
