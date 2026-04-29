# Cap: Mycelium Gain Validates Weekly/Monthly (F2.5)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/mycelium/gain.ts`, `cap/server/mycelium/types.ts`, `cap/server/__tests__/mycelium.test.ts` (extend existing if any; create new test file if none — name `cap/server/__tests__/mycelium-gain.test.ts`)
- **Cross-repo edits:** none — septa schema is already authoritative
- **Non-goals:** does not modify `septa/mycelium-gain-v1.schema.json`; does not touch `gain` summary, history, daily, by_command, by_project paths beyond what the new `weekly`/`monthly` validation requires
- **Verification contract:** `bash .handoffs/cap/verify-mycelium-gain-weekly-monthly.sh`
- **Completion update:** Stage 1 + Stage 2 → commit → dashboard

## Implementation Seam

- **Likely files/modules:**
  - `cap/server/mycelium/gain.ts:89-101` (`isGainCliOutput`) — currently validates `summary, by_command, daily, history, by_project` but skips `weekly` and `monthly`
  - `cap/server/mycelium/types.ts:9-18` declares `weekly?` and `monthly?` on `GainCliOutput` but no validator runs over them
- **Reference seams:**
  - `septa/mycelium-gain-v1.schema.json` lines 96-131 define optional `weekly` and `monthly` arrays with required item shapes (each item has at minimum a `period` and `saved_tokens` analogue per the schema; reference the schema directly for the actual required keys)
  - `isGainDailyStats`, `isGainHistoryEntry` at `cap/server/mycelium/gain.ts` — the existing pattern for per-item predicates
- **Spawn gate:** locations are precise; can dispatch directly

## Problem

Cap's `isGainCliOutput` doesn't validate `weekly` or `monthly` arrays. The schema defines them as optional, with required item shapes. If mycelium ships malformed weekly/monthly entries, Cap silently accepts them; if the dashboard ever renders them the UI degrades silently. F1 #2 says the consumer must reject schema-violating payloads at the boundary.

## What exists (state)

- Schema declares `weekly` and `monthly` as optional arrays with required item structure (open `septa/mycelium-gain-v1.schema.json` lines 96-131 for the exact item shape).
- Cap consumer skips both. `types.ts` declares them optional but with no runtime check.

## What needs doing (intent)

1. Add `isGainWeeklyEntry` and `isGainMonthlyEntry` per-item predicates matching the schema's item shapes (or a single unified `isGainPeriodEntry` if the two shapes are identical).
2. Extend `isGainCliOutput` to validate `weekly` and `monthly` when present, mirroring the existing `daily`/`history`/`by_project` pattern.
3. Add tests covering: present-and-valid, present-but-bad-item, present-but-missing-required-field, absent.

## Scope

- **Primary seam:** `isGainCliOutput` and surrounding per-item predicates
- **Allowed files:** see Handoff Metadata
- **Explicit non-goals:** schema changes, UI changes, telemetry changes

---

### Step 1: Inspect the schema's weekly/monthly item shapes

**Project:** `septa/`
**Effort:** read-only (informational)

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && jq '.properties.weekly, .properties.monthly' mycelium-gain-v1.schema.json)
```

Capture the required keys and types per item — implementation must match them exactly.

#### Output

<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Required field set captured for both arrays
- [ ] Type for each field captured

---

### Step 2: Add per-item predicates

**Project:** `cap/`
**Effort:** small

Add `isGainWeeklyEntry` (and `isGainMonthlyEntry` if the shape differs) following the existing per-item predicate style in `cap/server/mycelium/gain.ts`. If the shapes are identical, a single shared predicate is fine; name it something neutral like `isGainPeriodEntry`.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -nE "isGainWeeklyEntry|isGainMonthlyEntry|isGainPeriodEntry" server/mycelium/gain.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Predicate(s) added
- [ ] Each schema-required field is checked

---

### Step 3: Extend `isGainCliOutput`

**Project:** `cap/`
**Effort:** trivial

Mirror the existing `daily`/`history`/`by_project` pattern:

```typescript
(record.weekly === undefined || (Array.isArray(record.weekly) && record.weekly.every(isGainWeeklyEntry))) &&
(record.monthly === undefined || (Array.isArray(record.monthly) && record.monthly.every(isGainMonthlyEntry)))
```

Update `cap/server/mycelium/types.ts` types if needed to reflect the validated shape.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -A 14 "function isGainCliOutput" server/mycelium/gain.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `weekly` validated when present
- [ ] `monthly` validated when present
- [ ] Pattern matches `daily`/`history`/`by_project` exactly

---

### Step 4: Tests

**Project:** `cap/`
**Effort:** small

Extend or create the mycelium gain test file with at least:

1. Payload with valid `weekly` array → passes
2. Payload with valid `monthly` array → passes
3. Payload with valid `weekly` AND `monthly` → passes
4. Payload with `weekly: [{...invalid item missing required field...}]` → throws
5. Payload omitting `weekly` and `monthly` → still passes (regression)

Use the existing per-test fixture style.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -lE "weekly|monthly" server/__tests__/mycelium*.test.ts 2>/dev/null)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] At least 4 new test cases
- [ ] Existing tests untouched

---

### Step 5: Lint + typecheck

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- biome check server/mycelium/ server/__tests__/mycelium*.test.ts)
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
2. `bash .handoffs/cap/verify-mycelium-gain-weekly-monthly.sh` passes
3. Stage 1 + Stage 2 review pass
4. Commit + dashboard

### Final Verification

```bash
bash .handoffs/cap/verify-mycelium-gain-weekly-monthly.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Closes lane 2 concern F2.5. F1 #2: consumer must reject schema-violating payloads at the boundary.

## Style Notes

- Match the existing per-item predicate naming (`isGainDailyStats`, `isGainHistoryEntry`, `isGainProjectStats`).
- If weekly and monthly entry shapes are identical, use one predicate with the neutral name `isGainPeriodEntry` rather than two.
- Don't change types.ts shape declarations beyond what the validator forces.
