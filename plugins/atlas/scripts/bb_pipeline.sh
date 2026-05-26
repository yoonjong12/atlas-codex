#!/usr/bin/env bash
# Bitbucket Cloud pipeline operations.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/_lib.sh"

cmd=${1:-}
[[ -z "$cmd" ]] && _usage "bb_pipeline.sh" \
  "latest [branch]             latest pipeline (default: current branch)" \
  "get <uuid>                  pipeline details" \
  "steps <uuid>                step table (status + duration)" \
  "log <uuid> <step_uuid>      step log output" \
  "wait <uuid> [interval=75]   block until COMPLETED, print final state"
shift

_state_line() {
  _py "
import sys,json
d=json.load(sys.stdin)
if 'values' in d:
    v=d['values']
    if not v: print('no pipelines'); sys.exit(0)
    d=v[0]
uuid=d['uuid'].strip('{}')
state=d['state']['name']
result=(d['state'].get('result') or {}).get('name','-')
commit=d.get('target',{}).get('commit',{}).get('hash','')[:8]
branch=d.get('target',{}).get('ref_name','')
print(f'uuid={uuid}  state={state}  result={result}  commit={commit}  branch={branch}')
"
}

case "$cmd" in
  latest)
    branch=${1:-$(git branch --show-current 2>/dev/null || echo '')}
    _detect_repo
    q="sort=-created_on&pagelen=1"
    [[ -n "$branch" ]] && q="$q&target.ref_name=$branch"
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pipelines/?$q" | _state_line
    ;;
  get)
    uuid=${1:?uuid}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pipelines/{$uuid}" | _state_line
    ;;
  steps)
    uuid=${1:?uuid}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pipelines/{$uuid}/steps/" | _py "
import sys,json
d=json.load(sys.stdin)
print(f'{\"Step\":<30} {\"State\":<12} {\"Result\":<12} {\"Duration\":>8}')
for s in d.get('values',[]):
    nm=s.get('name','(unnamed)')[:30]
    st=s['state']['name']
    rs=(s['state'].get('result') or {}).get('name','-')
    dur=s.get('duration_in_seconds',0)
    print(f'{nm:<30} {st:<12} {rs:<12} {dur:>6}s  {s[\"uuid\"].strip(chr(123)+chr(125))}')
"
    ;;
  log)
    uuid=${1:?uuid}; step=${2:?step_uuid}; _detect_repo
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pipelines/{$uuid}/steps/{$step}/log"
    ;;
  wait)
    uuid=${1:?uuid}; interval=${2:-75}; _detect_repo
    while true; do
      state=$(_curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pipelines/{$uuid}" \
        | _py "import sys,json; print(json.load(sys.stdin)['state']['name'])")
      echo "$(date +%T) state=$state"
      [[ "$state" == "COMPLETED" ]] && break
      sleep "$interval"
    done
    _curl "$API/repositories/$WORKSPACE/$REPO_SLUG/pipelines/{$uuid}" | _state_line
    ;;
  *) _die "unknown subcommand: $cmd" ;;
esac
