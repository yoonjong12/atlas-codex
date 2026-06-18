---
name: plugin-sync
description: "Sync plugins from remote. Trigger: 'plugin sync', 'plugin update', '플러그인 싱크', '최신화'"
argument-hint: "[plugin-name or marketplace-clone-path]"
---

# Plugin Sync — Codex CLI plugin marketplace sync

Pull latest from remote into `~/.codex/.tmp/marketplaces/<name>/`, refresh Codex CLI plugin cache, verify.

Single source of truth: `~/.codex/.tmp/marketplaces/`. Git-host agnostic (GitHub, Bitbucket, any git remote).

## Steps

1. **Locate.** List all plugin clones:
   ```bash
   bash ${PLUGIN_ROOT}/scripts/bb_plugin_sync.sh locate [filter]
   ```

2. **Sync.** Pull latest + refresh cache:
   ```bash
   bash ${PLUGIN_ROOT}/scripts/bb_plugin_sync.sh sync <clone-path> [branch]
   ```

3. **Verify.** Compare local vs remote:
   ```bash
   bash ${PLUGIN_ROOT}/scripts/bb_plugin_sync.sh verify <clone-path>
   ```

## One-shot (all plugins)

```bash
bash ${PLUGIN_ROOT}/scripts/bb_plugin_sync.sh all [filter] [branch]
```

## Notes

- Opposite of `codex-plugin-dev:publish` (outbound push). This is inbound pull.
- After sync, tell user to run restart Codex CLI if session is active.
