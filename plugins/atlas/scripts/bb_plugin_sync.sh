#!/usr/bin/env bash
# Sync Claude Code plugins from remote to local.
# Scans ~/.claude/plugins/marketplaces/ — the single source of truth for plugin clones.
# Usage: bb_plugin_sync.sh <subcommand> [args]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"

MARKETPLACE_DIR="${HOME}/.claude/plugins/marketplaces"

_find_plugin_clones() {
  local filter="${1:-}"
  [[ -d "$MARKETPLACE_DIR" ]] || _die "marketplace dir not found: $MARKETPLACE_DIR"
  for dir in "$MARKETPLACE_DIR"/*/; do
    [[ -d "$dir/.git" ]] || continue
    local name
    name=$(basename "$dir")
    if [[ -z "$filter" || "$name" == *"$filter"* ]]; then
      local remote version=""
      remote=$(git -C "$dir" remote get-url origin 2>/dev/null || echo "?")
      local pj
      pj=$(find "$dir" -name "plugin.json" -path "*/.claude-plugin/*" -maxdepth 3 2>/dev/null | head -1)
      [[ -n "$pj" ]] && version=$(_py "import json; print(json.load(open('$pj'))['version'])" 2>/dev/null || echo "?")
      local head_info
      head_info=$(git -C "$dir" log --oneline -1 2>/dev/null || echo "?")
      echo "PATH: $dir"
      echo "  REMOTE: $remote"
      echo "  VERSION: ${version:-unknown}"
      echo "  HEAD: $head_info"
      echo ""
    fi
  done
}

_sync() {
  local clone_path="$1"
  local branch="${2:-main}"

  [[ -d "$clone_path/.git" ]] || _die "not a git repo: $clone_path"

  echo "=== Fetching from remote ==="
  git -C "$clone_path" fetch --all --tags 2>&1

  local current_branch
  current_branch=$(git -C "$clone_path" symbolic-ref --short HEAD 2>/dev/null || echo "DETACHED")

  if [[ "$current_branch" == "DETACHED" ]]; then
    echo "=== Detached HEAD — checking out origin/$branch ==="
    git -C "$clone_path" checkout "origin/$branch" 2>&1
  else
    echo "=== On branch $current_branch — pulling ==="
    git -C "$clone_path" pull origin "$branch" 2>&1
  fi

  local new_head
  new_head=$(git -C "$clone_path" log --oneline -1)
  echo "=== Synced to: $new_head ==="

  echo ""
  echo "=== Refreshing Claude Code plugin cache ==="
  local plugin_name="" marketplace_name=""
  local pj
  pj=$(find "$clone_path" -name "plugin.json" -path "*/.claude-plugin/*" -maxdepth 3 2>/dev/null | head -1)
  if [[ -n "$pj" ]]; then
    plugin_name=$(_py "import json; print(json.load(open('$pj'))['name'])" 2>/dev/null || echo "")
  fi

  # Derive marketplace name from path: .../marketplaces/<marketplace>/
  local real_path
  real_path=$(cd "$clone_path" && pwd -P)
  if [[ "$real_path" == */marketplaces/* ]]; then
    marketplace_name=$(echo "$real_path" | sed -E 's#.*/marketplaces/([^/]+).*#\1#')
  fi

  if [[ -n "$plugin_name" && -n "$marketplace_name" ]]; then
    local plugin_id="${plugin_name}@${marketplace_name}"
    echo "Plugin: $plugin_id"
    claude plugin update "$plugin_id" 2>&1 || echo "(plugin update returned non-zero — cache may already be current)"
  elif [[ -n "$plugin_name" ]]; then
    echo "Plugin: $plugin_name (marketplace unknown)"
    claude plugin update "$plugin_name" 2>&1 || echo "(plugin update returned non-zero — cache may already be current)"
  else
    echo "WARN: could not detect plugin name. Run 'claude plugin update <name>@<marketplace>' manually."
  fi
}

_verify() {
  local clone_path="$1"
  [[ -d "$clone_path/.git" ]] || _die "not a git repo: $clone_path"

  echo "=== Verification ==="
  local local_head remote_head
  local_head=$(git -C "$clone_path" rev-parse HEAD 2>/dev/null)

  local branch
  branch=$(git -C "$clone_path" symbolic-ref --short HEAD 2>/dev/null || echo "")
  if [[ -z "$branch" ]]; then
    branch="main"
  fi

  remote_head=$(git -C "$clone_path" rev-parse "origin/$branch" 2>/dev/null || echo "?")

  local pj version=""
  pj=$(find "$clone_path" -name "plugin.json" -path "*/.claude-plugin/*" -maxdepth 3 2>/dev/null | head -1)
  [[ -n "$pj" ]] && version=$(_py "import json; print(json.load(open('$pj'))['version'])" 2>/dev/null || echo "?")

  echo "  Local HEAD:  ${local_head:0:7}"
  echo "  Remote HEAD: ${remote_head:0:7}"
  echo "  Version:     ${version:-unknown}"

  if [[ "$local_head" == "$remote_head" ]]; then
    echo "  Status:      IN SYNC"
  else
    echo "  Status:      BEHIND (local != remote)"
  fi
}

_all() {
  local filter="${1:-}"
  local branch="${2:-main}"

  echo "=== Scanning plugin marketplaces ==="
  echo ""

  [[ -d "$MARKETPLACE_DIR" ]] || _die "marketplace dir not found: $MARKETPLACE_DIR"
  for dir in "$MARKETPLACE_DIR"/*/; do
    [[ -d "$dir/.git" ]] || continue
    local name
    name=$(basename "$dir")
    if [[ -z "$filter" || "$name" == *"$filter"* ]]; then
      echo ">>> $name ($dir)"
      _sync "$dir" "$branch"
      _verify "$dir"
      echo ""
    fi
  done
}

case "${1:-}" in
  locate)  _find_plugin_clones "${2:-}" ;;
  sync)    _sync "${2:?clone-path required}" "${3:-main}" ;;
  verify)  _verify "${2:?clone-path required}" ;;
  all)     _all "${2:-}" "${3:-main}" ;;
  *)       _usage "$0" \
             "locate [filter]         — find plugin clones in marketplaces/" \
             "sync <path> [branch]    — pull latest + refresh cache" \
             "verify <path>           — compare local vs remote" \
             "all [filter] [branch]   — locate+sync+verify all" ;;
esac
