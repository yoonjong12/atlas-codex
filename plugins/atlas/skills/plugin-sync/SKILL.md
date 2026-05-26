---
name: plugin-sync
description: "Sync plugins from remote to local. Pull latest from marketplace clones, refresh cache, verify. Git-host agnostic. Trigger on: 'plugin sync', 'plugin update', '플러그인 싱크', '플러그인 업데이트', 'sync plugin', 'pull plugin', '플러그인 최신화'"
---

# Plugin Sync — Plugin marketplace sync

Pull latest from remote into marketplace clone directories, refresh plugin cache, verify.

Single source of truth: marketplace plugin clone directories. Git-host agnostic (GitHub, Bitbucket, any git remote).

## Steps

1. **Locate.** List all plugin clones:
   ```bash
   bash ${CODEX_PLUGIN_ROOT}/scripts/bb_plugin_sync.sh locate [filter]
   ```

2. **Sync.** Pull latest + refresh cache:
   ```bash
   bash ${CODEX_PLUGIN_ROOT}/scripts/bb_plugin_sync.sh sync <clone-path> [branch]
   ```

3. **Verify.** Compare local vs remote:
   ```bash
   bash ${CODEX_PLUGIN_ROOT}/scripts/bb_plugin_sync.sh verify <clone-path>
   ```

## One-shot (all plugins)

```bash
bash ${CODEX_PLUGIN_ROOT}/scripts/bb_plugin_sync.sh all [filter] [branch]
```

## Notes

- This is inbound pull (opposite of outbound push/publish).
- After sync, reload plugins if session is active.
