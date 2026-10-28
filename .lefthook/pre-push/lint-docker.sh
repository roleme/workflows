#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=docker depName=hadolint/hadolint
HADOLINT_VERSION=v2.15.1

config="${CONFIG:-.hadolint.yaml}"
mount=()
args=(--failure-threshold "${FAILURE_THRESHOLD:-error}")
if [ -f "$config" ]; then
  mount=(-v "$PWD/$config:/hadolint.yaml:ro")
  args+=(--config /hadolint.yaml)
fi

rc=0
while IFS= read -r -d '' f; do
  echo "hadolint $f"
  docker run --rm -i ${mount[@]+"${mount[@]}"} "hadolint/hadolint:${HADOLINT_VERSION}" hadolint "${args[@]}" - < "$f" || rc=1
done < <(git ls-files -z '*Dockerfile' '*.Dockerfile')
exit "$rc"
