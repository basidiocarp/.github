# Lamella→Cortina Boundary Cleanup Phase 2

## Problem

Phase 1 deleted four legacy capture scripts from lamella (errors, corrections,
test results, code changes). One remains: `session-end.js` is still active in
`resources/hooks/hooks.json` as a fallback. Cortina already owns session-end
summary storage. The wrapper exists only for environments where cortina isn't
installed, but it creates a split where session summaries flow through different
code paths depending on runtime state. Phase 2 removes the lamella wrapper once
cortina's Stop hook is the sole path.

## What exists (state)

- **File:** `lamella/resources/hooks/hooks.json` — `session-end.js` still registered
- **Cortina:** Stop hook handles session-end summary storage (`hyphae session end`)
- **Gap:** lamella `session-end.js` still references the old summary path
- **Doc:** `lamella/docs/tool-boundary-cleanup.md` — Phase 1 complete, Phase 2 pending

## What needs doing (intent)

Confirm cortina's Stop hook covers all session-end cases, then remove
`session-end.js` from hooks.json and delete the script file.

---

### Step 1: Verify cortina Stop hook coverage

**Project:** `cortina/`
**Effort:** 30 min

Confirm that `cortina`'s Stop hook:
1. Fires reliably on session end in Claude Code
2. Stores a structured session summary to hyphae
3. Does not depend on `session-end.js` being absent

```bash
grep -r "Stop\|SessionEnd\|session.end\|session_end" cortina/src/ --include="*.rs" | grep -v test | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Cortina Stop hook handles session end storage
- [ ] No dependency on lamella session-end.js

---

### Step 2: Remove session-end.js from lamella

**Project:** `lamella/`
**Effort:** 30 min
**Depends on:** Step 1

1. Remove the `session-end.js` entry from `resources/hooks/hooks.json`
2. Delete `resources/hooks/session-end.js` (or move to `completed/` archive)
3. Update `docs/tool-boundary-cleanup.md` to mark Phase 2 complete
4. Run `make validate` to confirm no broken references

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `session-end.js` removed from hooks.json
- [ ] Script file deleted
- [ ] `make validate` passes
- [ ] `docs/tool-boundary-cleanup.md` updated

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `make validate` passes

## Context

`ECOSYSTEM-OVERVIEW.md` gap #6 and cortina roadmap. Phase 1 completed 2026-04
(four scripts deleted). `IMPROVEMENTS-OBSERVATION-V3.md` confirms the Phase 2
gap is adapter surface and hook registration shape, not business logic.
