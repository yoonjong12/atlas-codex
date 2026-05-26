#!/usr/bin/env bash
# Verify Bitbucket credentials.
# Usage: bb_auth.sh [check]
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/_lib.sh"

_require_creds
code=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  "$API/user")

case "$code" in
  200) echo "OK: Bitbucket connected as $BITBUCKET_EMAIL" ;;
  401) _die "401 Invalid credentials" ;;
  403) _die "403 Missing scopes (need read:repository, read:pullrequest, write:pullrequest, read:pipeline)" ;;
  *)   _die "HTTP $code" ;;
esac
