#!/usr/bin/env bash
# Shared helpers for atlas bb_*.sh scripts.
# Source, do not execute directly.

set -euo pipefail

API="https://api.bitbucket.org/2.0"

_die() { echo "ERROR: $*" >&2; exit 1; }

_require_creds() {
  [[ -n "${BITBUCKET_EMAIL:-}" ]] || _die "BITBUCKET_EMAIL not set. Run /atlas:setup."
  [[ -n "${BITBUCKET_API_TOKEN:-}" ]] || _die "BITBUCKET_API_TOKEN not set. Run /atlas:setup."
}

_curl() {
  _require_creds
  curl -sS --fail-with-body -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" "$@"
}

_detect_repo() {
  # Sets WORKSPACE, REPO_SLUG from env or git remote.
  if [[ -n "${WORKSPACE:-}" && -n "${REPO_SLUG:-}" ]]; then return 0; fi
  local remote
  remote=$(git remote get-url origin 2>/dev/null) || _die "no git remote 'origin'; set WORKSPACE/REPO_SLUG env"
  WORKSPACE=$(echo "$remote" | sed -E 's#.*bitbucket.org[:/]([^/]+)/.*#\1#')
  REPO_SLUG=$(echo "$remote" | sed -E 's#.*bitbucket.org[:/][^/]+/([^.]+)(\.git)?$#\1#')
  [[ -n "$WORKSPACE" && -n "$REPO_SLUG" ]] || _die "could not parse workspace/repo from $remote"
  export WORKSPACE REPO_SLUG
}

_usage() {
  local script=$1 ; shift
  echo "Usage: $script <subcommand> [args]" >&2
  echo "" >&2
  echo "Subcommands:" >&2
  printf '  %s\n' "$@" >&2
  exit 2
}

# Emit jq-like filtered fields via python (jq not assumed installed).
_py() { python3 -c "$@"; }
