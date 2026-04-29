# Cap: Stipe Init Repair Action Shape (F2.2 + F2.4)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/routes/settings/shared.ts` and `cap/server/__tests__/stipe-contract.test.ts`
- **Cross-repo edits:** none — septa schemas already document the divergence; cap's job is to mirror it on the consumer side
- **Non-goals:** does not modify any septa schema; does not unify the schemas at the schema level (they're intentionally different — init plan needs `action_key` for matching, doctor doesn't); does not touch annulus, mycelium, or canopy validators
- **Verification contract:** `bash .handoffs/cap/verify-stipe-init-repair-action-shape.sh`
- **Completion update:** after Stage 2 review passes, commit and update `.handoffs/HANDOFFS.md`

## Implementation Seam

- **Likely files/modules:**
  - `cap/server/routes/settings/shared.ts:49-58` (existing `isRepairAction` — used for doctor; F2.1 already loosened `description` to allow null)
  - `cap/server/routes/settings/shared.ts:87-100` (existing `isStipeInitPlan` — currently reuses doctor's `isRepairAction` for init repair_actions, which over-requires fields)
  - `cap/server/__tests__/stipe-contract.test.ts` — extend
- **Reference seams:**
  - `septa/stipe-doctor-v1.schema.json` `$defs.repair_action` requires `["command","label","description","args","tier"]`
  - `septa/stipe-init-plan-v1.schema.json` `repair_actions[]` requires `["action_key","command","label"]` only — `args`, `tier`, `description` not required
- **Spawn gate:** locations are precise; can dispatch directly

## Problem

Cap's `isStipeInitPlan` validator reuses `isRepairAction` (the doctor-shaped predicate) for `init_plan.repair_actions[]`. Two consequences:

1. **F2.4** — `action_key` is required by `stipe-init-plan-v1` but `isRepairAction` doesn't check it; cap silently accepts init payloads missing `action_key`.
2. **F2.2** — `args`, `tier`, `description` are optional in `stipe-init-plan-v1` but `isRepairAction` requires them; cap rejects valid init payloads.

The fix is consumer-side, not schema-side: introduce a separate `isInitPlanRepairAction` predicate that matches the init-plan schema exactly.

## Scope

- **Primary seam:** the init-plan repair_action validator path
- **Allowed files:** `cap/server/routes/settings/shared.ts`, `cap/server/__tests__/stipe-contract.test.ts`
- **Explicit non-goals:**
  - Unifying schemas (the divergence is intentional)
  - Modifying any septa schema
  - Touching `isRepairAction` (the doctor shape) beyond its current state
  - Re-doing F2.1 work (already committed as B1)

---

### Step 1: Add `isInitPlanRepairAction`

**Project:** `cap/`
**Effort:** small

Add a new predicate next to `isRepairAction`. It must:
- Require `action_key` (string), `command` (string), `label` (string).
- Treat `args` as optional but, if present, must be an array.
- Treat `tier` as optional but, if present, must be one of `"primary" | "secondary" | "destructive"` (the init-plan tier enum). String-only check is acceptable if matching the doctor pattern is preferred — match the existing tier-validation laxity for now (pre-existing gap, not in this handoff's scope to fix).
- Treat `description` as optional and accept `string | null` when present (mirrors F2.1 pattern).

```typescript
function isInitPlanRepairAction(value: unknown): boolean {
  if (!isRecord(value)) return false
  if (typeof value.action_key !== 'string') return false
  if (typeof value.command !== 'string') return false
  if (typeof value.label !== 'string') return false
  if (value.args !== undefined && !Array.isArray(value.args)) return false
  if (value.tier !== undefined && typeof value.tier !== 'string') return false
  if (
    value.description !== undefined &&
    value.description !== null &&
    typeof value.description !== 'string'
  ) {
    return false
  }
  return true
}
```

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -n "isInitPlanRepairAction" server/routes/settings/shared.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] New predicate exists
- [ ] Requires `action_key`, `command`, `label` (no others required)
- [ ] `args`, `tier`, `description` checked when present, not required to be present

---

### Step 2: Switch `isStipeInitPlan` to use the new predicate

**Project:** `cap/`
**Effort:** trivial

In `isStipeInitPlan` (line 87-100), change `value.repair_actions.every(isRepairAction)` → `value.repair_actions.every(isInitPlanRepairAction)`.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -n "isInitPlanRepairAction\b" server/routes/settings/shared.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `isStipeInitPlan` uses `isInitPlanRepairAction`, not `isRepairAction`
- [ ] `isStipeDoctorReport` still uses `isRepairAction` for its repair_actions and nested check repair_actions
- [ ] No other call site changes

---

### Step 3: Tests

**Project:** `cap/`
**Effort:** small

Add tests in `cap/server/__tests__/stipe-contract.test.ts`:

1. Init plan with minimal repair_action `{action_key, command, label}` (no args/tier/description) — passes (closes F2.2).
2. Init plan with full repair_action `{action_key, command, label, args, tier, description}` — passes.
3. Init plan with repair_action missing `action_key` — throws (closes F2.4).
4. Init plan with repair_action where `description: null` — passes.
5. (Regression) Doctor with full repair_action including `tier: 'primary'` — still passes (F2.1 case, ensures we didn't break it).

Use the same minimal-inline-payload style as the existing tests in this file.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -c "isInitPlanRepairAction\|action_key" server/__tests__/stipe-contract.test.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] At least 5 new test cases covering the cases listed
- [ ] Existing tests untouched
- [ ] No tests use schema-invalid `tier` values (use `primary`/`secondary`/`destructive` for init, `primary`/`secondary`/`manual` for doctor)

---

### Step 4: Lint + typecheck

**Project:** `cap/`
**Effort:** trivial

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- biome check server/routes/settings/shared.ts server/__tests__/stipe-contract.test.ts)
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- tsc --noEmit -p server/tsconfig.json)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Biome clean
- [ ] tsc --noEmit clean

---

## Completion Protocol

1. Every step has verification output pasted
2. Verify script passes: `bash .handoffs/cap/verify-stipe-init-repair-action-shape.sh`
3. Stage 1 + Stage 2 review have run and passed
4. Commit and update `.handoffs/HANDOFFS.md`

### Final Verification

```bash
bash .handoffs/cap/verify-stipe-init-repair-action-shape.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Closes lane 2 concerns F2.2 (consumer too strict on init-plan repair_actions) and F2.4 (consumer doesn't validate `action_key`). Pairs cleanly with the already-committed F2.1+F2.3 fix in the same file. Scope-disjoint from C2 (mycelium/gain.ts) and C3 (canopy.ts).

## Style Notes

- Add `isInitPlanRepairAction` next to `isRepairAction`, not in a separate file.
- Don't add a comment explaining why two predicates exist — the names are self-explanatory.
- Don't tighten the `tier` enum check (pre-existing laxity is out of scope).
