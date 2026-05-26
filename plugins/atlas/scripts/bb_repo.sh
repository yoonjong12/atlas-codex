#!/usr/bin/env bash
# Bitbucket Cloud repository operations.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/_lib.sh"

cmd=${1:-}
[[ -z "$cmd" ]] && _usage "bb_repo.sh" \
  "info                                   repo summary" \
  "branches                               recent branches (25)" \
  "commits [branch]                       recent commits (10)" \
  "src <branch> <path>                    file contents" \
  "ls <branch> <dir>                      directory listing" \
  "diff <source> <destination>            ref..ref diff" \
  "list [workspace]                       list repos in workspace" \
  "branch-create <name> <from_hash_or_branch>  create branch" \
  "branch-delete <name>                   delete branch"
shift

case "$cmd" in
  info)
    _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG" | _py "
import sys,json
d=json.load(sys.stdin)
print(f'Name: {d[\"full_name\"]}')
print(f'Language: {d.get(\"language\",\"N/A\")}')
print(f'Main branch: {d.get(\"mainbranch\",{}).get(\"name\",\"N/A\")}')
print(f'Updated: {d[\"updated_on\"][:10]}')
print(f'Size: {d.get(\"size\",\"N/A\")} bytes')
print(f'URL: {d[\"links\"][\"html\"][\"href\"]}')
"
    ;;
  branches)
    _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/refs/branches?pagelen=25&sort=-target.date" | _py "
import sys,json
d=json.load(sys.stdin)
for b in d.get('values',[]):
    print(f'{b[\"name\"]:<50} {b[\"target\"][\"date\"][:10]}  {b[\"target\"][\"hash\"][:8]}')
"
    ;;
  commits)
    branch=${1:-}
    _detect_repo
    url="$API/repositories/$WORKSPACE/$REPO_SLUG/commits"
    [[ -n "$branch" ]] && url="$url/$branch"
    _curl "$url?pagelen=10" | _py "
import sys,json
d=json.load(sys.stdin)
for c in d.get('values',[]):
    who=(c['author'].get('user') or {}).get('display_name',c['author'].get('raw','?'))
    msg=c['message'].split('\n')[0][:60]
    print(f'{c[\"hash\"][:8]}  {c[\"date\"][:10]}  {who:<20} {msg}')
"
    ;;
  src)
    branch=${1:?branch}; path=${2:?path}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/src/$branch/$path"
    ;;
  ls)
    branch=${1:?branch}; dir=${2:-}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/src/$branch/$dir?pagelen=100" | _py "
import sys,json
d=json.load(sys.stdin)
for e in d.get('values',[]):
    kind='D' if e['type']=='commit_directory' else 'F'
    print(f'{kind}  {e[\"path\"]}')
"
    ;;
  diff)
    src=${1:?source}; dst=${2:?destination}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/diff/$src..$dst"
    ;;
  list)
    ws=${1:-${WORKSPACE:-}}
    [[ -z "$ws" ]] && { _detect_repo; ws=$WORKSPACE; }
    _curl "$API/repositories/$ws?pagelen=25&sort=-updated_on" | _py "
import sys,json
d=json.load(sys.stdin)
for r in d.get('values',[]):
    print(f'{r[\"slug\"]:<40} {r.get(\"language\",\"\"):<10} {r[\"updated_on\"][:10]}')
"
    ;;
  branch-create)
    name=${1:?branch name}; from=${2:?from hash or branch}; _detect_repo
    payload=$(python3 -c 'import json,sys; print(json.dumps({"name":sys.argv[1],"target":{"hash":sys.argv[2]}}))' "$name" "$from")
    _curl -X POST -H "Content-Type: application/json" -d "$payload" \
      "$API/repositories/$WORKSPACE/$REPO_SLUG/refs/branches" \
      | _py "import sys,json; d=json.load(sys.stdin); print(f'created branch {d[\"name\"]} at {d[\"target\"][\"hash\"][:8]}')"
    ;;
  branch-delete)
    name=${1:?branch name}; _detect_repo
    curl -sS --fail-with-body -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
      -X DELETE -o /dev/null -w "HTTP %{http_code}\n" \
      "$API/repositories/$WORKSPACE/$REPO_SLUG/refs/branches/$name"
    ;;
  *) _die "unknown subcommand: $cmd" ;;
esac
