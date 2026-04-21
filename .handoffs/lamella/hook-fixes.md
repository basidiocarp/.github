# Lamella: Fix SessionEnd hook timeout and async

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** lamella/...
- **Cross-repo edits:** none
- **Non-goals:** eval harness fixes (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — SessionEnd hook has no timeout and is synchronous
`resources/hooks/hooks.json:258-271`

Every other cortina hook in the file (`PreCompact`, `UserPromptSubmit`, `PostToolUse`) carries `"timeout": 10`. The SessionEnd hook has no timeout field. A hanging cortina will stall session teardown indefinitely.

Additionally, `UserPromptSubmit` and `PostToolUse` are async (`"async": true`). SessionEnd is synchronous. If blocking at exit is intentional, add a comment explaining why. If not, add `"async": true` to match the pattern.

Fix: add `"timeout": 10` to the SessionEnd hook entry. Review whether `"async": true` should also be added and document the decision either way.

### 2 — token-efficiency SKILL.md describes non-existent injection
`resources/skills/core/token-efficiency/SKILL.md:84-96`

The skill states: "What gets injected: A conciseness instruction block (500 tokens) appended to the base system prompt." No hook or cortina adapter implements this injection. This is either aspirational documentation or a mechanism that was removed. Update the SKILL.md to describe what actually happens, or create a tracking note that this injection is planned but not yet implemented.

### 3 — agent-introspection-debugging skill CLI dependency undocumented
`resources/skills/core/agent-introspection-debugging/SKILL.md:69`

The skill body instructs agents to run `hyphae memory store --topic errors/resolved` but does not document the minimum hyphae version required for that subcommand/flag. Add a version note or a `requires` frontmatter entry.

## Implementation Seam

- `resources/hooks/hooks.json:258-271` — add timeout, decide on async
- `resources/skills/core/token-efficiency/SKILL.md:84-96` — correct or caveat the injection claim
- `resources/skills/core/agent-introspection-debugging/SKILL.md` — add version note

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/lamella
make validate 2>&1 | tail -5
```

## Checklist

- [ ] SessionEnd hook has `"timeout": 10`
- [ ] Async decision made and documented
- [ ] token-efficiency SKILL.md injection claim corrected or marked as planned
- [ ] agent-introspection-debugging skill documents hyphae CLI dependency
- [ ] `make validate` passes
