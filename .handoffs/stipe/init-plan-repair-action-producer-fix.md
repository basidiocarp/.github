# Stipe: Init-Plan Repair Action Producer Fix (F2.16)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/init/plan.rs` (or wherever `RepairAction::manual` lives), `stipe/src/commands/init/repair.rs` (or equivalent), and any test fixtures that build `RepairAction::manual` instances
- **Cross-repo edits:** none — septa schema and cap consumer (already updated by C1/F2.4) stay unchanged
- **Non-goals:** does not modify septa schemas; does not change cap; does not address F2.2 schema-level shape unification (that's an open design question)
- **Verification contract:** `bash .handoffs/stipe/verify-init-plan-repair-action-producer-fix.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem

Lane 2 of the 2026-04-30 audit (F2.16) found that stipe's `RepairAction::manual(...)` factory:

1. Emits `tier: "manual"` — **not in** the init-plan schema's enum (`["primary", "secondary", "destructive"]`).
2. Omits `action_key` entirely — **required** by `septa/stipe-init-plan-v1.schema.json`.

Real call sites: `host_setup_repair_action`, `cargo_install_action`, and any other invocation of `RepairAction::manual` in stipe's init plan path.

The C1/F2.4 fix (committed 2026-04-29 as `a27941f`) made cap's `isInitPlanRepairAction` require `action_key`. **The next time stipe init produces a manual repair_action, cap's settings panel will throw `'Invalid stipe init plan payload'` and the route fails.**

This is a Tier A regression-risk fix.

Note: doctor's `repair_action.tier` enum is `["primary","secondary","manual"]` — different from init-plan's `["primary","secondary","destructive"]`. The "manual" tier is valid for doctor but not for init-plan. F2.2 is the open design question of whether to unify; THIS handoff just makes the init-plan producer match its own schema, not the unification.

## Scope

- **Allowed files:**
  - `stipe/src/commands/init/plan.rs` (RepairAction definition / `RepairAction::manual` constructor)
  - `stipe/src/commands/init/repair.rs` or wherever `host_setup_repair_action` / `cargo_install_action` live
  - Any in-tree tests that build manual repair actions
- **Explicit non-goals:**
  - Schema changes (init-plan and doctor schemas stay as-is)
  - F2.2 unification work (separate, design-bound)
  - Doctor's repair_action emission paths

## Step 1 — Find the call sites

```bash
grep -rn "RepairAction::manual\|RepairAction { tier" stipe/src/ --include='*.rs'
grep -rn "host_setup_repair_action\|cargo_install_action" stipe/src/ --include='*.rs'
```

Confirm every site that produces an init-plan repair_action.

## Step 2 — Add `action_key` and adjust tier

Two minimum changes:

1. **`action_key`**: every manual repair_action needs a stable, unique key. Choose a naming convention (e.g. snake_case derived from the action's purpose: `"host_setup_macos"`, `"cargo_install_rust_analyzer"`, `"repair_perms_<host>"`). Add it to `RepairAction::manual(...)` as a required parameter (not optional — schema requires it).
2. **Tier enum**: replace `tier: "manual"` with one of init-plan's actual enum values:
   - `"primary"` — the user's main repair option for that issue.
   - `"secondary"` — alternative remediation.
   - `"destructive"` — wipes/reinstalls something.
   Most "manual" repair_actions are operator-facing primary instructions (e.g. "install rust-analyzer manually"). `"primary"` is the most likely correct mapping; pick per-call-site based on the action's intent.

## Step 3 — Adjust call sites

Update every call to `RepairAction::manual(...)` to pass an explicit `action_key` and a valid `tier`. If the constructor signature changes (likely), the compiler will surface every call site.

## Step 4 — Tests

Add a test that:
- Constructs a representative manual repair_action.
- Serializes to JSON.
- Asserts `action_key` is a non-empty string AND `tier` is one of `primary`/`secondary`/`destructive`.

If stipe has a schema-validation test path (using `jsonschema` Rust crate or similar), validate the serialized output against `septa/stipe-init-plan-v1.schema.json`'s `repair_actions[]` shape.

## Step 5 — Run the existing stipe test suite

```bash
cd /Users/williamnewton/projects/personal/basidiocarp/stipe && cargo test --release
cd /Users/williamnewton/projects/personal/basidiocarp/stipe && cargo clippy
```

## Style Notes

- `action_key` should be stable across runs (same purpose ⇒ same key) — operators may match against it for filtering.
- Don't introduce a new tier value beyond the existing init-plan enum.
- The doctor `repair_action.tier` enum still includes `"manual"` — leave doctor paths alone.
- If you find a call site where neither `primary`, `secondary`, nor `destructive` fits, raise it as a finding (likely it should be `primary` as a default; the operator decision is then which subset of repair_actions to highlight in the UI).

## Verify Script

`bash .handoffs/stipe/verify-init-plan-repair-action-producer-fix.sh` confirms:
- No remaining `tier: "manual"` literal in init-plan call sites
- `action_key` is referenced in `RepairAction::manual` (or its replacement)
- `cargo test` passes
- septa stipe schemas unchanged

## Context

Closes lane 2 blocker F2.16 from the 2026-04-30 ecosystem drift follow-up audit. Production-blocking. Pairs (loosely) with C1/F2.4 cap consumer fix (committed 2026-04-29 as `a27941f`).
