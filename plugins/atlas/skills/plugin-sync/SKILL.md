---
name: plugin-sync
description: "Explicit-only atlas skill. Invoke by name as atlas:plugin-sync, @plugin-sync, or a direct request for the plugin-sync skill."
disable-model-invocation: true
user-invocable: true
---

# Plugin Sync — Plugin marketplace sync

Pull latest from remote into marketplace clone directories, refresh plugin cache, verify.

Single source of truth: marketplace plugin clone directories. Git-host agnostic (GitHub, Bitbucket, any git remote).

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

- This is inbound pull (opposite of outbound push/publish).
- After sync, reload plugins if session is active.
