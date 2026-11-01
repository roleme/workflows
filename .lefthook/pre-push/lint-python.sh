#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=pypi depName=ruff
RUFF_VERSION=0.17.2

uvx "ruff@${RUFF_VERSION}" check "$@"
