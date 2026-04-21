# Lamella: Fix hook correctness issues (round 2)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** lamella/...
- **Cross-repo edits:** none
- **Non-goals:** eval harness fixes, hook timeout/async (separate handoffs)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Dev server blocker doesn't check TMUX (HIGH)
`resources/hooks/hooks.json:10`

The PreToolUse "Block dev servers outside tmux" hook checks `process.platform !== 'win32'` but NOT `!process.env.TMUX`. It unconditionally exits with code 2 when `npm run dev`, `pnpm dev`, `yarn dev`, or `bun run dev` is invoked on Linux/macOS — even inside a tmux session. The adjacent reminder hook at line 20 correctly checks `!process.env.TMUX`. Add the same guard to the blocker.

### 2 — Makefile operator precedence bug in build target (HIGH)
`Makefile:35`

```bash
[ "$$name" = "schema" ] || [ "$$name" = "index" ] && continue
```

`&&` binds tighter than `||`, so when `name=schema` the left side is true, `||` short-circuits, and `continue` never runs. `schema.json` is incorrectly passed to the build script. Fix:

```bash
{ [ "$$name" = "schema" ] || [ "$$name" = "index" ]; } && continue
```

### 3 — Shell injection in create-hook skill template (MEDIUM)
`resources/skills/meta/create-hook/SKILL.md:109`

Template shows `"command": "prettier --write $(jq -r '.tool_input.file_path')"`. An unquoted user-controlled path in a command substitution is a shell injection vector. Replace with the safer `post-edit-format.js` pattern (execFileSync without shell) or show a properly-quoted shell alternative.

### 4 — Dead check in lint-skills.sh (MEDIUM)
`scripts/lint-skills.sh:36-39`

The `origin:` absent check at line 36 can never fire because line 21 returns early when `origin:` is absent. A file with some frontmatter but no `origin:` is silently skipped. Fix the early-return logic so files missing `origin:` are failed, not skipped.

### 5 — Low items
- `hooks.json:128-138` — PostToolUse "build analysis" hook promises "async analysis running in background" but does nothing; update the message or add a TODO comment marking it as a placeholder
- `hooks.json:171` — `comment-style-check.js` and `scripts/hooks/comment-style-check.sh` have different regex patterns; remove or reconcile the stale `.sh` version
- `run_eval.py:151` — unconditional `...` truncation suffix (also appears separately from the already-tracked stdout/JSON mixing issue)

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/lamella
make validate 2>&1 | tail -5
make build-marketplace 2>&1 | tail -5
```

## Checklist

- [ ] Dev server blocker checks `process.env.TMUX` before blocking
- [ ] Makefile build target skips `schema.json` correctly
- [ ] Hook template removes shell injection pattern
- [ ] `lint-skills.sh` `origin:` check enforces presence rather than silently skipping
- [ ] Low items addressed
- [ ] `make validate` and `make build-marketplace` pass
