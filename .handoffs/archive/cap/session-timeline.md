# Cap Session Timeline View

## Problem

Cap has no session timeline. Hyphae already captures recalls, errors, fixes, test
results, exports, and session summaries — and `hyphae session timeline` CLI exists
with a contract — but cap doesn't expose it. The feedback loop data is being
generated, but operators can't interrogate it. Without the timeline, the recall
effectiveness loop is invisible: operators see only aggregate stats from
`hyphae evaluate`, which is too coarse to tell whether specific recalls helped.

## What exists (state)

- **CLI:** `hyphae session timeline --session-id <id>` — returns events in chronological order
- **`hyphae session context`:** returns recent session summaries (already consumed by cap)
- **Cap sessions page:** exists, shows session list — needs a detail/timeline drill-down
- **Events captured:** recall events, error signals, correction signals, test pass/fail,
  session start/end — all stored in hyphae

## What needs doing (intent)

Add a session detail view to cap that renders the timeline of events for a selected
session: recalls, errors, fixes, tests, exports, and summary.

**Verification status:** implemented.

---

### Step 1: Add session timeline backend route

**Project:** `cap/`
**Effort:** 1-2 hours

Add `GET /api/sessions/:id/timeline` that calls `hyphae session timeline --session-id <id>
--format json` and returns normalized events.

Follow the same pattern as other hyphae CLI read surfaces in `server/hyphae.ts`.
Each event should include: `{ type, timestamp, content, score? }` where `type` is
one of: `recall`, `error`, `correction`, `test_pass`, `test_fail`, `export`,
`summary`.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->
`npm run build`

- Passed: `✓ built in 1.18s`
<!-- PASTE END -->

**Checklist:**
- [x] `/api/sessions/:id/timeline` route exists and builds
- [x] Returns empty array gracefully when session has no events
- [x] Error when session_id not found returns 404, not 500

---

### Step 2: Add session detail / timeline UI

**Project:** `cap/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Add a session detail page (or expandable panel on the sessions list) that shows:

- Session metadata: project, worktree, duration, task
- Timeline of events in chronological order
- Each event rendered with icon + timestamp + content:
  - `recall` → book icon, query + top memory titles
  - `error` → red X, error message
  - `correction` → yellow arrow, what was corrected
  - `test_pass` / `test_fail` → check/X, test summary
  - `summary` → document icon, session summary text

#### Verification

```bash
cd cap && npm test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
`npm test`

- Passed server tests: `Test Files 27 passed (27), Tests 230 passed (230)`
- Passed frontend tests: `Test Files 26 passed (26), Tests 95 passed (95)`
<!-- PASTE END -->

**Checklist:**
- [x] Session detail renders timeline events
- [x] Empty timeline state renders cleanly (no events yet)
- [x] Each event type has distinct visual treatment
- [x] Timeline is chronological (oldest first)

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `npm run build && npm test` passes

Current result:

- Build and tests pass.
- The exact per-session backend route is implemented and mounted.
- The session detail UI is implemented with chronology, distinct event treatment, and a clean empty state.

## Context

Cap roadmap "Next" #1. `IMPROVEMENTS-OBSERVATION-V1.md` notes this should move
from Phase 2 to Phase 1 because the underlying data is already being generated.
`hyphae session timeline` CLI surface exists and has a contract. This is purely
a cap frontend/backend integration task.
