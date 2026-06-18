# PR Conventions

Conventions for PR descriptions and review feedback responses on this project.

---

## PR Description Structure

Sections in order:

| Section | Purpose |
|---|---|
| **Summary** | 1–2 sentences. What this PR does and why in one breath. |
| **Why** | Problem being solved. What was broken or missing before. |
| **ASIS → TOBE** | Key diffs, visualized appropriately (see below). |
| **Changes** | Table of files changed + what changed. Caveman compact. |
| **Benchmark** | Perf or cost impact. If structural, verify via test mock instead of re-run. |
| **Validation** | pytest count, lint, branch state. |

### Title format

```
WAO-XXX LYZ: short description
```

- `LYZ` = sprint + subtask index (e.g. L3, L3Z = story + subtask)
- Keep title under ~60 chars

### Writing style

Write like an engineer explaining the change to a colleague. Not like an AI summarizing it.

- Lead with the point. Conclusion first, evidence after.
- Compact means cut, not chop. Trim a sentence to its core idea. Do not split one long sentence into a stack of mechanical fragments — that reads worse, not better. One dense sentence beats five clipped ones.
- Plain verbs. "is", "has", "drops" — not "serves as", "leverages", "enables", "facilitates".
- Vary the rhythm. Mix short and long sentences. Uniform same-length lines are the clearest tell of machine text.
- Be specific. Name the function, the number, the file. Not "various components" or "significantly improved".
- Changes section stays a table, caveman compact (drop articles, short synonyms).
- Strip the AI tells: em-dash and arrow spam, hedges ("it's worth noting", "notably"), infomercial hooks ("The catch?", "Here's the thing"), inflated transitions ("Moreover", "Furthermore"), Title-Case Headings, and bullet lists of bare noun phrases.
- No internal ticket codes, section symbols (§), or jargon visible to reviewers.

Keep only what the reviewer needs: the bug in one paragraph, then the one non-obvious gotcha in one paragraph. Internal rationale for why the fix is cheap or correct is not PR-worthy, so cut it. Abstract the mechanism, keep the impact number.

Reference: read `references/avoid-ai-writing.md`, the full catalog of AI-writing patterns to detect and delete (vendored verbatim, MIT, Conor Bronsdon).

### ASIS → TOBE visualization

Match the visualization to what actually changed:

| Change type | Visualization |
|---|---|
| Architecture / backend logic | Code diff block (before/after) |
| Frontend / UI use-case | Screenshot pair |
| Backend API contract | API request/response diff |

**Screenshot rules:**
- Always label the condition: what env vars were set, what file was added/removed.
- Screenshot alone is not enough — explain what's different and why it matters.
- Example label: `**Before** — THELOOP_JUDGE_RUBRICS_DIR unset; only built-in axes appear`

---

## Review Reply Convention

### Step-by-step workflow

1. **Read first** — `bb_pr.sh comments <pr_id>` + `bb_pr.sh activity <pr_id>`
2. **Find parent comment ID** — the `.id` of the reviewer's comment you're replying to
3. **Categorize each request** — Fixed / Deferred / Disagreed (with reason)
4. **Write reply** to `/tmp/reply.md` following the format below
5. **Post as thread reply** via raw Bitbucket API with `"parent": {"id": <id>}` (NOT `bb_pr.sh comment`)
6. **Verify** the reply appears nested under the reviewer's thread

> `bb_pr.sh comment` posts a standalone general comment, not a thread reply.
> Always use the raw API when replying to a reviewer's comment.

### Reply format

Lead with a one-line acknowledgment + tally, then one block per finding.

```markdown
Thank you for the review. <N> fixed, <M> follow-up.

### Important 1: <short title> — Fixed

```
Before:
# old code

After:
# new code
```

One sentence explaining what changed and why.

---

### Important 2: <short title> — Follow-up (next PR)

Agreed — out of this PR's scope. Registered in <doc/ticket>:
- <one bullet per planned step>
```

Rules:
- **Mirror the reviewer's own severity label** in the header — `### Important N`, `### Nit N`. Don't invent a generic word like "Request".
- Status suffix: `— Fixed`, `— Follow-up (next PR)`, `— Deferred`, or `— Disagree (reason)`.
- `### Additional: <title> — Fixed` for a fix you found yourself, outside the reviewer's list.
- Before/After block for every Fixed item where code changed — one fenced block, `Before:` / `After:` labels inside it.
- One sentence per Fixed item; a short bullet plan is fine for a Follow-up.
- Batch all of one reviewer's findings into a single reply.
- Writing style: caveman, no filler. "≤10 words" means compress each point to its essence — capture the core and cut the rest, not chop a long sentence into fragments at every comma.

### Re-review loop

A reviewer may re-review and raise new findings. Reply to each round in the same format — a fresh `### Important N` block per new finding, with its own lead tally — until they signal APPROVE.

### Posting the reply (raw API)

```bash
# Write payload to file to avoid shell escaping issues
python3 -c "
import json
body = open('/tmp/reply.md').read()
print(json.dumps({'content': {'raw': body}, 'parent': {'id': PARENT_ID}}))
" > /tmp/reply-payload.json

curl -s -u "${BITBUCKET_EMAIL}:${BITBUCKET_API_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d @/tmp/reply-payload.json \
  "https://api.bitbucket.org/2.0/repositories/${WORKSPACE}/${REPO_SLUG}/pullrequests/${PR_ID}/comments" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('reply id:', d['id'], '| parent:', d.get('parent',{}).get('id'))"
```

If you accidentally post as a general comment:
1. Note the comment ID from the response
2. Delete it: `curl -X DELETE ... /comments/<id>`
3. Re-post with `"parent"` field

See `references/bitbucket-api.md` → "Reply to Comment Thread" and "Delete PR Comment" for full curl commands.
