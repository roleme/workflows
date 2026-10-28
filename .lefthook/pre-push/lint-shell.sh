#!/usr/bin/env bash
set -euo pipefail

# renovate: datasource=pypi depName=shellcheck-py
SHELLCHECK_VERSION=0.11.0.1

files=()
while IFS= read -r -d '' f; do files+=("$f"); done < <(git ls-files -z '*.sh' '*.bash')
if [ "${#files[@]}" -eq 0 ]; then
  echo "lint-shell: no shell scripts"
  exit 0
fi
uvx --from "shellcheck-py==${SHELLCHECK_VERSION}" shellcheck --severity="${SEVERITY:-warning}" "${files[@]}"
