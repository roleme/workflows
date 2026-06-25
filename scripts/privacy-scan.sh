#!/usr/bin/env bash
# privacy-scan.sh — fail if tracked files contain private infrastructure
# markers. Shared by the reusable CI workflow and the local pre-commit hook so
# both enforce the exact same rules.
#
# Scans all tracked files (git ls-files). Built-in patterns are GENERIC and
# safe to live in this PUBLIC repo (private IP ranges, .local hosts, common
# host paths, key/secret markers). Caller-specific private hostnames are NOT
# hardcoded here — a private caller passes them via $EXTRA_PATTERNS
# (newline-separated extended-regexps), so the secret-ish list stays in the
# private repo that runs the scan, never in this public one.
#
# Usage:
#   EXTRA_PATTERNS=$'domovas\\.uk\nmininas\\.local' scripts/privacy-scan.sh
#
# Env:
#   EXTRA_PATTERNS  newline-separated ERE patterns to also flag (optional)
#   ALLOW_FILE      path to a file listing path globs to skip (optional)
#
# Exits non-zero (and prints offending file:line) if anything matches.
set -euo pipefail

# Generic markers — no private values, safe for a public repo.
builtin_patterns=(
  '\b10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b'          # 10.0.0.0/8
  '\b192\.168\.[0-9]{1,3}\.[0-9]{1,3}\b'                # 192.168.0.0/16
  '\b172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}\b' # 172.16.0.0/12
  '\b[a-z0-9-]+\.local\b'                               # mDNS/.local hosts
  '/home/[a-z0-9_-]+/'                                  # host home paths
  '/volume[0-9]+/'                                      # Synology volume paths
  '/etc/komodo/'                                        # komodo host config
  'ghp_[A-Za-z0-9]{30,}'                                # GitHub PAT
  'github_pat_[A-Za-z0-9_]{30,}'                        # fine-grained PAT
  'xox[baprs]-[A-Za-z0-9-]{10,}'                        # Slack token
  '-----BEGIN[A-Z ]*PRIVATE KEY-----'                   # private keys
  'cli_secret'                                          # komodo cli secret key
)

# Caller-supplied extra patterns (one ERE per line).
mapfile -t extra_patterns < <(printf '%s' "${EXTRA_PATTERNS:-}" | sed '/^[[:space:]]*$/d')

patterns=("${builtin_patterns[@]}" "${extra_patterns[@]}")

# This script defines the patterns, so it would match itself — exclude it, plus
# the lockfile-ish / binary stuff that produces noise. Callers can extend via
# ALLOW_FILE (one path-glob per line).
exclude_globs=(
  '*privacy-scan.sh'
  '*.png' '*.jpg' '*.jpeg' '*.gif' '*.ico' '*.pdf' '*.lock'
)
if [[ -n "${ALLOW_FILE:-}" && -f "${ALLOW_FILE}" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    exclude_globs+=("$line")
  done < "${ALLOW_FILE}"
fi

is_excluded() {
  local f="$1" g
  for g in "${exclude_globs[@]}"; do
    # shellcheck disable=SC2053
    [[ "$f" == $g ]] && return 0
  done
  return 1
}

# Build a single alternation for one grep pass per file.
joined=$(printf '%s|' "${patterns[@]}")
joined="${joined%|}"

found=0
while IFS= read -r f; do
  is_excluded "$f" && continue
  # -I skips binary files; -n gives line numbers; -E extended regex.
  if matches=$(grep -InE "$joined" -- "$f" 2>/dev/null); then
    found=1
    echo "::error file=$f::private-infra marker found" 2>/dev/null || true
    while IFS= read -r m; do
      echo "  $f:$m"
    done <<< "$matches"
  fi
done < <(git ls-files)

if [[ "$found" -ne 0 ]]; then
  echo ""
  echo "privacy-scan: found private-infrastructure markers above." >&2
  echo "If a match is a false positive, exclude its path via ALLOW_FILE." >&2
  exit 1
fi

echo "privacy-scan: clean — no private-infrastructure markers found."
