# Cap: Stipe Validators Accept Null (F2.1 + F2.3)

<!-- Save as: .handoffs/cap/stipe-validators-accept-null.md -->
<!-- Verify script: .handoffs/cap/verify-stipe-validators-accept-null.sh -->
<!-- Index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/routes/settings/shared.ts` and `cap/server/__tests__/stipe-contract.test.ts` (or sibling test file under `cap/server/__tests__/` if a new one is created)
- **Cross-repo edits:** none — septa schemas are already correct (this is consumer-side drift)
- **Non-goals:** does not address F2.2 (schema-level repair_action shape mismatch between doctor and init plan), does not address F2.4 (missing `action_key` validation), does not change any septa schema or fixture, does not touch other validators
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cap/verify-stipe-validators-accept-null.sh`
- **Completion update:** after Stage 2 review passes and verification is green, commit, update `.handoffs/HANDOFFS.md` to mark this handoff done

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:**
  - `cap/server/routes/settings/shared.ts:49-58` (`isRepairAction` — rejects null `description`)
  - `cap/server/routes/settings/shared.ts:83-85` (`isInitStep` — rejects null/missing `detail`)
  - `cap/server/__tests__/stipe-contract.test.ts` (existing test file consuming these validators)
- **Reference seams:**
  - `cap/server/routes/settings/shared.ts:62-67` (`isDoctorCheck` already shows the correct pattern: `(typeof value.message === 'string' || value.message === null)`)
  - The septa schemas at `septa/stipe-doctor-v1.schema.json` and `septa/stipe-init-plan-v1.schema.json` are the contract being honored
- **Spawn gate:** locations are precise; can dispatch directly

## Problem

Cap's `isRepairAction` and `isInitStep` validators reject schema-permitted `null` values. The septa contracts mark `repair_action.description` as `["string", "null"]` and `step.detail` as `["string", "null"]`, but the cap consumers require `typeof === 'string'`. The moment stipe emits a valid payload with either field set to `null`, cap throws `"Invalid stipe doctor payload"` (or init plan equivalent) and `/api/settings/stipe/run` returns 500, breaking the dashboard's settings panel.

This is a latent runtime failure: today's fixture happens to populate both fields with strings, so `validate-all.sh` and `cap` tests stay green. The bug is real but invisible until stipe emits a valid `null`.

## What exists (state)

- **`isRepairAction` (line 49-58)**: requires `typeof value.description === 'string'`. Schema permits `null`.
- **`isInitStep` (line 83-85)**: requires `typeof value.detail === 'string'`. Schema permits `null` (and the field is optional via `["string", "null"]`).
- **`isDoctorCheck` (line 62-67)**: already does the right thing for `message` — `(typeof value.message === 'string' || value.message === null)` — proves the pattern is in use elsewhere in this file.
- **Test coverage**: `cap/server/__tests__/stipe-contract.test.ts` consumes the existing fixtures. No test currently asserts null-acceptance.

## What needs doing (intent)

1. Change `isRepairAction` to accept `description: string | null`.
2. Change `isInitStep` to accept `detail: string | null` (and treat missing as equivalent to null per schema).
3. Add tests asserting that:
   - A `stipe-doctor-v1` payload with `repair_actions[].description = null` parses successfully.
   - A `stipe-init-plan-v1` payload with `steps[].detail = null` parses successfully.
   - A `stipe-init-plan-v1` payload with `steps[].detail` omitted parses successfully (schema makes it optional).
   - Existing happy-path payloads still parse (regression check).

## Scope

- **Primary seam:** the stipe consumer validators in `cap/server/routes/settings/shared.ts`
- **Allowed files:**
  - `cap/server/routes/settings/shared.ts`
  - `cap/server/__tests__/stipe-contract.test.ts` (or a new `cap/server/__tests__/stipe-null-shape.test.ts` if the existing file shouldn't be expanded)
- **Explicit non-goals:**
  - Refactoring the doctor vs init-plan repair_action shape mismatch (F2.2 — separate handoff)
  - Adding `action_key` validation to init-plan repair_actions (F2.4 — separate handoff)
  - Modifying any septa schema or fixture
  - Touching annulus, mycelium, canopy validators (other handoffs cover those)
  - Refactoring `runStipeJson`, the cli runner, or the surrounding routes

---

### Step 1: Update `isRepairAction`

**Project:** `cap/`
**Effort:** trivial
**Depends on:** nothing

Change `cap/server/routes/settings/shared.ts:49-58` to allow `description: string | null`. Match the existing pattern from `isDoctorCheck`.

#### Files to modify

**`cap/server/routes/settings/shared.ts`** — adjust `isRepairAction`:

```typescript
function isRepairAction(value: unknown): boolean {
  return (
    isRecord(value) &&
    typeof value.command === 'string' &&
    (typeof value.description === 'string' || value.description === null) &&
    typeof value.label === 'string' &&
    Array.isArray(value.args) &&
    typeof value.tier === 'string'
  )
}
```

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -n "value.description" server/routes/settings/shared.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `value.description` predicate now allows null
- [ ] Other `isRepairAction` fields unchanged

---

### Step 2: Update `isInitStep`

**Project:** `cap/`
**Effort:** trivial
**Depends on:** nothing (independent of Step 1)

Change `cap/server/routes/settings/shared.ts:83-85` to allow `detail: string | null | undefined`. Schema makes the field nullable; consumer should accept either null or omitted (treat missing as null).

#### Files to modify

**`cap/server/routes/settings/shared.ts`** — adjust `isInitStep`:

```typescript
function isInitStep(value: unknown): boolean {
  return (
    isRecord(value) &&
    typeof value.title === 'string' &&
    (typeof value.detail === 'string' || value.detail === null || value.detail === undefined) &&
    typeof value.status === 'string'
  )
}
```

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -n "value.detail" server/routes/settings/shared.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `value.detail` predicate accepts string, null, or undefined
- [ ] `value.title` and `value.status` predicates unchanged

---

### Step 3: Add null-acceptance tests

**Project:** `cap/`
**Effort:** small
**Depends on:** Steps 1-2

Add tests covering null and missing-field cases. Place them in `cap/server/__tests__/stipe-contract.test.ts` to keep the contract surface in one place.

Required cases:

1. `parseStipeDoctorReport` accepts a payload where `repair_actions[0].description = null`.
2. `parseStipeDoctorReport` accepts a payload where `checks[0].repair_actions[0].description = null` (nested case — exercises the same `isRepairAction` reuse).
3. `parseStipeInitPlan` accepts a payload where `steps[0].detail = null`.
4. `parseStipeInitPlan` accepts a payload where `steps[0]` omits `detail` entirely.
5. (Regression) existing happy-path fixtures still parse.

Tests should use minimal inline payloads constructed from the schema's required fields, not deep-copies of full fixtures, to keep failure modes legible.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm run test:server -- stipe-contract)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All four new tests pass
- [ ] Existing tests in stipe-contract.test.ts still pass
- [ ] No tests added that depend on F2.2 or F2.4 fixes

---

### Step 4: Lint + typecheck + full suite

**Project:** `cap/`
**Effort:** trivial
**Depends on:** Step 3

Confirm the change doesn't break lint, types, or the full test suite.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- biome check server/routes/settings/shared.ts server/__tests__/stipe-contract.test.ts)
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- tsc --noEmit -p server/tsconfig.json)
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm test)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Biome clean on touched files
- [ ] tsc --noEmit (server) passes
- [ ] `npm test` exits 0

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cap/verify-stipe-validators-accept-null.sh`
3. All checklist items are checked
4. Stage 1 + Stage 2 review have run and passed (per `CLAUDE.md` delegation contract)
5. The change is committed and `.handoffs/HANDOFFS.md` reflects completion

### Final Verification

```bash
bash .handoffs/cap/verify-stipe-validators-accept-null.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

This handoff closes lane 2 blocker findings F2.1 and F2.3 from the [Post-Execution Boundary Compliance Audit (2026-04-29)](../campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-septa-contract-accuracy.md). The two findings share a file and a fix pattern; bundling them into one handoff respects the delegation contract's "no overlapping ownership inside one repo" rule. F2.2 (schema-level shape mismatch) and F2.4 (missing `action_key` validation) live in the same file and surface but require independent design choices and so are tracked as separate handoffs.

## Style Notes

- Match the existing `isDoctorCheck` pattern for nullable fields. Don't introduce a new helper.
- Keep tests narrow — one assertion per case. The point is contract parity, not exhaustive coverage.
- No backward-compat shims, no comments explaining the change beyond what the diff itself shows.
