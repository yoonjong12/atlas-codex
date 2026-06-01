#!/usr/bin/env bash
# Bitbucket Cloud PR operations.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/_lib.sh"

_read_value() {
  local value="${1:-}"
  if [[ "$value" == @* ]]; then
    local file="${value#@}"
    [[ -f "$file" ]] || _die "file not found: $file"
    cat "$file"
  else
    printf '%s' "$value"
  fi
}

cmd=${1:-}
[[ -z "$cmd" ]] && _usage "bb_pr.sh" \
  "get <pr_id>                        PR details (title/state/branches/dates)" \
  "diff <pr_id>                       unified diff" \
  "comments <pr_id>                   all comments grouped (general + inline per file)" \
  "activity <pr_id>                   approvals/updates/comment activity" \
  "list [state]                       list PRs (default OPEN)" \
  "find-by-branch [branch]            open PR for branch (default: current)" \
  "create <title> [desc|@file] [source] [dest]  create PR (branches default current -> main)" \
  "comment <pr_id> <body>             post general comment" \
  "inline <pr_id> <path> <line> <body>  post inline comment on path:line (to-line)" \
  "update <pr_id> <key> <value|@file> update title or description" \
  "approve <pr_id>                    approve PR" \
  "merge <pr_id> [message|@file]      merge PR and close source branch"
shift

case "$cmd" in
  get)
    pr=${1:?pr_id}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr" | _py "
import sys,json
d=json.load(sys.stdin)
print(f'#{d[\"id\"]}: {d[\"title\"]}')
print(f'State: {d[\"state\"]}')
print(f'Author: {d[\"author\"][\"display_name\"]}')
print(f'Branch: {d[\"source\"][\"branch\"][\"name\"]} -> {d[\"destination\"][\"branch\"][\"name\"]}')
print(f'Created: {d[\"created_on\"][:10]}  Updated: {d[\"updated_on\"][:10]}')
print(f'URL: {d[\"links\"][\"html\"][\"href\"]}')
desc=(d.get('description') or '').strip()
if desc: print('---\n'+desc)
"
    ;;
  diff)
    pr=${1:?pr_id}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr/diff"
    ;;
  comments)
    pr=${1:?pr_id}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr/comments?pagelen=100" | _py "
import sys,json
d=json.load(sys.stdin)
general=[]; inline={}
for c in d.get('values',[]):
    if c.get('deleted'): continue
    raw=(c.get('content') or {}).get('raw','').strip()
    who=(c.get('user') or {}).get('display_name','?')
    when=c.get('created_on','')[:10]
    ref=f'[{when} {who}]'
    il=c.get('inline')
    if il:
        key=il.get('path','?')
        inline.setdefault(key,[]).append((il.get('to') or il.get('from'), ref, raw))
    else:
        general.append((ref,raw))
if general:
    print('== General ==')
    for ref,raw in general: print(f'{ref} {raw}')
for path,items in inline.items():
    print(f'\n== Inline: {path} ==')
    for ln,ref,raw in sorted(items,key=lambda x:(x[0] or 0)):
        print(f'  L{ln} {ref} {raw}')
"
    ;;
  activity)
    pr=${1:?pr_id}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr/activity?pagelen=50" | _py "
import sys,json
d=json.load(sys.stdin)
for a in d.get('values',[]):
    if 'approval' in a:
        ap=a['approval']; print(f'APPROVE  {ap[\"date\"][:10]}  {ap[\"user\"][\"display_name\"]}')
    elif 'update' in a:
        u=a['update']; print(f'UPDATE   {u[\"date\"][:10]}  {u[\"state\"]}  by {u[\"author\"][\"display_name\"]}')
    elif 'comment' in a:
        c=a['comment']; raw=(c.get('content') or {}).get('raw','')[:60]
        print(f'COMMENT  {c[\"created_on\"][:10]}  {c[\"user\"][\"display_name\"]}: {raw}')
"
    ;;
  list)
    state=${1:-OPEN}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests?state=$state&pagelen=25" | _py "
import sys,json
d=json.load(sys.stdin)
for pr in d.get('values',[]):
    print(f'#{pr[\"id\"]:<5} [{pr[\"state\"]:<8}] {pr[\"source\"][\"branch\"][\"name\"]:<40} {pr[\"title\"]}')
"
    ;;
  find-by-branch)
    branch=${1:-$(git branch --show-current)}
    _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests?state=OPEN&pagelen=50" | _py "
import sys,json,os
d=json.load(sys.stdin); b='$branch'
for pr in d.get('values',[]):
    if pr['source']['branch']['name']==b:
        print(f'#{pr[\"id\"]}: {pr[\"title\"]}')
        break
else:
    print('no open PR for branch',b)
"
    ;;
  create)
    title=${1:?title}; desc_arg=${2:-}; source_branch=${3:-$(git branch --show-current)}; dest_branch=${4:-main}
    description=$(_read_value "$desc_arg")
    [[ -n "$source_branch" ]] || _die "source branch is required"
    _detect_repo
    payload=$(python3 - "$title" "$description" "$source_branch" "$dest_branch" <<'PY'
import json
import sys

title, description, source_branch, dest_branch = sys.argv[1:5]
print(json.dumps({
    "title": title,
    "description": description,
    "source": {"branch": {"name": source_branch}},
    "destination": {"branch": {"name": dest_branch}},
    "close_source_branch": True,
}))
PY
)
    _curl -X POST -H "Content-Type: application/json" -d "$payload" \
      "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests" \
      | _py "
import sys,json
d=json.load(sys.stdin)
print(f'created #{d[\"id\"]}: {d[\"title\"]}')
print(f'Branch: {d[\"source\"][\"branch\"][\"name\"]} -> {d[\"destination\"][\"branch\"][\"name\"]}')
print(f'URL: {d[\"links\"][\"html\"][\"href\"]}')
"
    ;;
  comment)
    pr=${1:?pr_id}; body=$(_read_value "${2:?body}"); _detect_repo
    _curl -X POST -H "Content-Type: application/json" \
      -d "$(python3 -c 'import json,sys; print(json.dumps({"content":{"raw":sys.argv[1]}}))' "$body")" \
      "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr/comments" \
      | _py "import sys,json; d=json.load(sys.stdin); print(f'posted comment id={d.get(\"id\")}')"
    ;;
  inline)
    pr=${1:?pr_id}; path=${2:?path}; line=${3:?line}; body=$(_read_value "${4:?body}"); _detect_repo
    payload=$(python3 -c 'import json,sys; print(json.dumps({"content":{"raw":sys.argv[1]},"inline":{"path":sys.argv[2],"to":int(sys.argv[3])}}))' "$body" "$path" "$line")
    _curl -X POST -H "Content-Type: application/json" -d "$payload" \
      "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr/comments" \
      | _py "import sys,json; d=json.load(sys.stdin); print(f'posted inline id={d.get(\"id\")} on {d.get(\"inline\",{}).get(\"path\")}:{d.get(\"inline\",{}).get(\"to\")}')"
    ;;
  update)
    pr=${1:?pr_id}; key=${2:?key=title|description}; val=$(_read_value "${3:?value}"); _detect_repo
    [[ "$key" == "title" || "$key" == "description" ]] || _die "update key must be title or description"
    payload=$(python3 -c 'import json,sys; print(json.dumps({sys.argv[1]: sys.argv[2]}))' "$key" "$val")
    _curl -X PUT -H "Content-Type: application/json" -d "$payload" \
      "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr" \
      | _py "import sys,json; d=json.load(sys.stdin); print(f'updated #{d[\"id\"]}: {d[\"title\"]}')"
    ;;
  approve)
    pr=${1:?pr_id}; _detect_repo
    _curl -X POST "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr/approve" \
      | _py "import sys,json; d=json.load(sys.stdin); print(f'approved by {d[\"user\"][\"display_name\"]}')"
    ;;
  merge)
    pr=${1:?pr_id}; message=$(_read_value "${2:-}"); _detect_repo
    payload=$(python3 - "$message" <<'PY'
import json
import sys

message = sys.argv[1]
payload = {"close_source_branch": True}
if message:
    payload["message"] = message
print(json.dumps(payload))
PY
)
    _curl -X POST -H "Content-Type: application/json" -d "$payload" \
      "$API/repositories/$WORKSPACE/$REPO_SLUG/pullrequests/$pr/merge" \
      | _py "
import sys,json
d=json.load(sys.stdin)
print(f'merged #{d[\"id\"]}: {d[\"title\"]}')
print(f'State: {d[\"state\"]}')
print(f'URL: {d[\"links\"][\"html\"][\"href\"]}')
"
    ;;
  *) _die "unknown subcommand: $cmd" ;;
esac
