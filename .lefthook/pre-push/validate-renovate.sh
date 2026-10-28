#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=npm depName=renovate
RENOVATE_VERSION=44

config="${CONFIG_FILE:-renovate.json}"
if [ ! -f "$config" ]; then
  echo "validate-renovate: no $config"
  exit 0
fi
flags=()
if [ "${STRICT:-false}" = "true" ]; then
  flags=(--no-global --strict)
fi
npx --yes --package "renovate@${RENOVATE_VERSION}" renovate-config-validator ${flags[@]+"${flags[@]}"} "$config"
