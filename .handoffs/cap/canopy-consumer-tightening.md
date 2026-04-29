# Cap: Canopy Consumer Tightening (F2.6 + F2.7 + F2.9)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/canopy.ts`, `cap/server/__tests__/canopy-validators.test.ts` (or `cap/server/__tests__/canopy.test.ts` if that's the local convention — extend whichever exists)
- **Cross-repo edits:** none — septa schemas are authoritative and current
- **Non-goals:** does not modify any septa schema, does not change `validateEvidenceRefs` behavior beyond what extending the parent validators requires, does not touch SQLite read paths beyond the notification event_type enum check
- **Verification contract:** `bash .handoffs/cap/verify-canopy-consumer-tightening.sh`
- **Completion update:** Stage 1 + Stage 2 → commit → dashboard

## Implementation Seam

- **Likely files/modules:**
  - `cap/server/canopy.ts:142-148` (`validateCanopySnapshot`) — needs `attention`, `sla_summary`, `drift_signals` added (F2.6)
  - `cap/server/canopy.ts:150-161` (`validateCanopyTaskDetail`) — needs `attention`, `sla_summary` added (F2.7)
  - `cap/server/canopy.ts:80-95` (`listNotifications`) — needs `event_type` enum check at the read boundary (F2.9)
- **Reference seams:**
  - `septa/canopy-snapshot-v1.schema.json:7` required = `["schema_version","attention","sla_summary","tasks","evidence","drift_signals"]`
  - `septa/canopy-task-detail-v1.schema.json:7` required = `["schema_version","task","attention","sla_summary","allowed_actions","evidence"]`
  - `septa/canopy-notification-v1.schema.json:14-27` `event_type` enum is closed (9 values)
- **Spawn gate:** locations are precise; can dispatch directly

## Problem

Three findings on the cap canopy consumer:

- **F2.6** — `validateCanopySnapshot` only checks `schema_version`, `tasks`, `evidence`. The schema requires `attention`, `sla_summary`, `drift_signals` as well. If canopy regresses and drops any of these, cap silently accepts the payload but downstream UI panels reading them crash later.
- **F2.7** — `validateCanopyTaskDetail` only checks `schema_version`, `task`, `allowed_actions`, `evidence`. Schema also requires `attention`, `sla_summary`. Same silent-failure shape as F2.6.
- **F2.9** — `listNotifications` reads SQLite rows and treats `event_type` as opaque `string`. The septa schema declares it a closed 9-value enum. Unknown values pass through; the UI then has to switch on string-typed values without compile-time guarantees.

## Scope

- **Primary seam:** the canopy consumer validators in `cap/server/canopy.ts`
- **Allowed files:** `cap/server/canopy.ts`, `cap/server/__tests__/canopy-validators.test.ts` (or the equivalent existing test file — confirm before writing)
- **Explicit non-goals:**
  - Modifying any septa schema
  - Validating field types deeper than presence (e.g. don't validate `attention.unread_count` is a number; just validate `attention` is a record)
  - Changing the SQLite query path or write paths
  - Refactoring `validateEvidenceRefs`

---

### Step 1: Tighten `validateCanopySnapshot`

**Project:** `cap/`
**Effort:** small

In `cap/server/canopy.ts:142-148`, extend the validator to also require `attention`, `sla_summary`, `drift_signals`. Use the existing `asRecord(record.attention) !== null` pattern for object fields, `Array.isArray(record.drift_signals)` for arrays.

Inspect the schema first to confirm whether `attention` and `sla_summary` are objects or arrays, and `drift_signals` is an array, before writing the predicate.

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && jq '.required, .properties.attention.type, .properties.sla_summary.type, .properties.drift_signals.type' canopy-snapshot-v1.schema.json)
```

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -A 14 "function validateCanopySnapshot" server/canopy.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `attention` presence/type checked
- [ ] `sla_summary` presence/type checked
- [ ] `drift_signals` presence/type checked
- [ ] Existing checks (`schema_version`, `tasks`, `evidence`) preserved
- [ ] Failure path still throws `'Invalid payload from canopy api snapshot'`

---

### Step 2: Tighten `validateCanopyTaskDetail`

**Project:** `cap/`
**Effort:** small (mirrors Step 1)

Same pattern in `cap/server/canopy.ts:150-161`: add `attention`, `sla_summary` requirements. Confirm types from the schema first.

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && jq '.required, .properties.attention.type, .properties.sla_summary.type' canopy-task-detail-v1.schema.json)
```

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -A 14 "function validateCanopyTaskDetail" server/canopy.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `attention` checked
- [ ] `sla_summary` checked
- [ ] Existing checks preserved
- [ ] Failure path still throws `'Invalid payload from canopy api task'`

---

### Step 3: Add `event_type` enum check to `listNotifications`

**Project:** `cap/`
**Effort:** small

Define the closed enum (read from `septa/canopy-notification-v1.schema.json:14-27`) as a TypeScript constant in `canopy.ts` near the top of the notifications section. In `parseNotificationRow` (the helper above `listNotifications` — find it via grep), reject rows whose `event_type` is not in the enum.

Behavior on unknown enum value:
- The function should NOT throw and crash the route — instead, log a warning via `logger` and skip the row (or coerce to a sentinel value if the UI needs every row). Match the existing degradation style for SQLite reads in this file. Choose whichever the existing patterns suggest; if unclear, log + skip is the safer default.

Add the enum constant near the existing `CANOPY_API_SCHEMA_VERSION`:

```typescript
const CANOPY_NOTIFICATION_EVENT_TYPES = new Set([
  // 9 values from septa/canopy-notification-v1.schema.json:14-27 — copy them verbatim
])
```

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -nE "CANOPY_NOTIFICATION_EVENT_TYPES|event_type" server/canopy.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Enum constant defined with all 9 values (no typos vs schema)
- [ ] `parseNotificationRow` checks `event_type` against the enum
- [ ] Unknown values handled gracefully (log + skip, or matched to existing pattern)
- [ ] Frontend type `CanopyNotificationRow.event_type` could optionally be tightened to a union type but is NOT required for this handoff

---

### Step 4: Tests

**Project:** `cap/`
**Effort:** medium

Confirm the existing test file location:

```bash
ls /Users/williamnewton/projects/personal/basidiocarp/cap/server/__tests__/canopy*.test.ts
```

Add tests:

1. **F2.6** — Snapshot payload missing `attention` → throws.
2. **F2.6** — Snapshot payload missing `sla_summary` → throws.
3. **F2.6** — Snapshot payload missing `drift_signals` → throws.
4. **F2.6** — Full snapshot with all required fields → passes.
5. **F2.7** — Task detail missing `attention` → throws.
6. **F2.7** — Task detail missing `sla_summary` → throws.
7. **F2.7** — Full task detail with all required fields → passes.
8. **F2.9** — Notification row with valid event_type passes through `parseNotificationRow`.
9. **F2.9** — Notification row with invalid event_type is filtered/sentinel'd per the chosen handling pattern (and a warning is logged — verify via spy if the existing test pattern uses logger spies; otherwise just assert behavior).

If `validateCanopySnapshot` and `validateCanopyTaskDetail` are not directly exported, route tests through whatever public API exposes them (e.g. through the consumer fetch functions higher in the file). If they ARE exported, prefer testing them directly.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -cE "attention|sla_summary|drift_signals|event_type" server/__tests__/canopy*.test.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] At least 9 new test cases covering F2.6, F2.7, F2.9
- [ ] Existing tests in the file untouched

---

### Step 5: Lint + typecheck

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- biome check server/canopy.ts server/__tests__/canopy*.test.ts)
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- tsc --noEmit -p server/tsconfig.json)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Biome clean
- [ ] tsc clean

---

## Completion Protocol

1. All steps verified
2. `bash .handoffs/cap/verify-canopy-consumer-tightening.sh` passes
3. Stage 1 + Stage 2 pass
4. Commit + dashboard

### Final Verification

```bash
bash .handoffs/cap/verify-canopy-consumer-tightening.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Closes F2.6, F2.7, F2.9 from lane 2 of the post-execution audit. All three findings live in the same file and are validator-tightening of the same shape (consumer is too lax against the schema).

## Style Notes

- Match the existing `asRecord(record.X) !== null` and `Array.isArray(record.Y)` patterns for presence/type checks.
- Don't validate field internals (e.g. don't recurse into `attention.unread_count`).
- For F2.9, prefer log-and-skip over throw-and-crash unless the existing notification reads in cap show a different convention.
- Don't tighten the frontend type for `event_type` — that's frontend-side scope creep.
