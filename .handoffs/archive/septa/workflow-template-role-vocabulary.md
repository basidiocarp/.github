# Workflow Template Role Vocabulary

## Handoff Metadata

- **Dispatch:** `direct` (design decision first, then mechanical follow-through)
- **Owning repo:** `septa` (primary) with coordinated update to `hymenium`
- **Allowed write scope:** `septa/workflow-template-v1.schema.json`, `septa/fixtures/workflow-template-v1.example.json`, `hymenium/src/workflow/template.rs`, `hymenium/templates/*.json`, and any hymenium test fixtures that depend on role strings
- **Cross-repo edits:** hymenium enum + template files + tests; no other repos
- **Non-goals:** redesigning the phase model, renaming phases themselves, changing `AgentTier`, adjusting Canopy-side role handling beyond what the chosen vocabulary requires
- **Verification contract:** `bash .handoffs/septa/verify-workflow-template-role-vocabulary.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive

## Implementation Seam

- **Likely repos:** `septa`, `hymenium`
- **Likely files:**
  - `septa/workflow-template-v1.schema.json` (line ~37 — `role` enum)
  - `septa/fixtures/workflow-template-v1.example.json`
  - `hymenium/src/workflow/template.rs` (lines 101-122 — `AgentRole` enum + `Display` impl at lines 124-138)
  - `hymenium/templates/*.json` (any shipped workflow templates that declare `role`)
- **Reference seams:**
  - `septa/workflow-status-v1.schema.json` — status contract role field (may or may not share vocabulary; check whether the two schemas are intended to agree)
  - `canopy/src/` — grep for role string handling on the consumer side; some operator views key off role names
- **Spawn gate:** parent must confirm which direction the decision lands (widen schema vs. narrow Rust vs. two-field split) before dispatching implementation; this is a design decision first, not a mechanical fix

## Problem

`septa/workflow-template-v1.schema.json` and `hymenium/src/workflow/template.rs` disagree about what a workflow "role" means, and the two vocabularies are entirely disjoint — not merely out of sync.

- **Schema (`workflow-template-v1.schema.json:37`):** role enum is `["implementer", "auditor", "reviewer", "operator"]` — four abstract process roles that describe *what kind of work* a phase does.
- **Rust (`hymenium/src/workflow/template.rs:101-122`):** `AgentRole` is an enum of nine runtime agent names — `"Spec Author"`, `"Workflow Planner"`, `"Packet Compiler"`, `"Decomposition Checker"`, `"Workflow Coordinator"`, `"Worker"`, `"Output Verifier"`, `"Repair Worker"`, `"Final Verifier"`. These describe *specific agents in the dispatch catalog*.

None of the Rust values is present in the schema enum. None of the schema values is present in the Rust enum. Any workflow template that parses cleanly against the schema will fail to deserialize into `AgentRole`, and any Rust-written template will fail schema validation. This is a dormant bug masked by the fact that neither side currently round-trips against the other in CI.

The fixture at `septa/fixtures/workflow-template-v1.example.json` uses schema values (`"implementer"`, `"auditor"`), so `septa/validate-all.sh` passes. But if any `hymenium/templates/*.json` file were validated against the schema, it would fail — and if the example fixture were deserialized through `AgentRole`, it would fail.

## What exists (state)

- `workflow-template-v1.schema.json` and its fixture: a clean 4-role abstract vocabulary, validator-enforced.
- `hymenium/src/workflow/template.rs`: a 9-role concrete runtime vocabulary with human-readable `serde(rename)` strings and `Display` implementation.
- `hymenium/templates/*.json`: (check state — currently empty; but any shipped templates would declare concrete Rust role names, making them schema-invalid).
- **`workflow-status-v1.schema.json` (line 51) already uses the 9 Rust runtime names** (`"Spec Author"`, `"Workflow Planner"`, ..., `"Final Verifier"`). So septa already has one schema that embodies Option A's vocabulary and one schema that embodies Option B's vocabulary. This is material to the decision below.
- No existing round-trip test verifies that a schema-valid template file can be deserialized into the Rust `AgentRole`.

## What needs doing (intent)

This is a **design decision**, not a mechanical fix. Pick one of three paths, document the rationale, then apply consistently.

### Option A — Widen the schema to match Rust (document the runtime catalog)

Replace the schema enum with the nine `"Spec Author"` / `"Workflow Planner"` / ... values. Acknowledges that `role` in a workflow template identifies a specific agent in the dispatch catalog, not an abstract category.

- **Pro:** matches the actually-shipped code. Zero Rust churn.
- **Con:** ties the contract to the current 9-role catalog. Every new agent type requires a contract version bump. Abstract template sharing across ecosystems becomes harder.

### Option B — Narrow the Rust enum to match the schema (introduce a process-role layer)

Rename `AgentRole` to `AgentKind` (or similar runtime-only name) and introduce a new `ProcessRole` type with the four schema values. Template files declare `ProcessRole`; dispatch resolves `ProcessRole` → `AgentKind` via a mapping table.

- **Pro:** preserves the clean abstract contract. Makes the mapping explicit.
- **Con:** every caller that currently reads `.role` as an agent name needs to go through the mapping. Workflow template files lose the ability to pin a specific agent, which may or may not be desirable.
- **Also requires:** updating `workflow-status-v1.schema.json` role enum (line 51) to either the 4 process-role values, or adding a parallel `agent_kind` field if status consumers still want the runtime name. Otherwise the two schemas remain out of sync with Rust in opposite directions.

### Option C — Split the field (process role + agent kind)

Add `agent_role` (the nine concrete names) alongside the existing `role` (the four abstract names). The schema enforces both. Rust deserializes `agent_role` into `AgentRole`; `role` into a new `ProcessRole` type.

- **Pro:** keeps both vocabularies, each with a clear meaning. Allows templates to say "this is an auditor-style phase, specifically the Output Verifier agent."
- **Con:** two fields where one existed. More contract surface to document. Requires updating every existing template file.

### Default recommendation

**Option B** is cleanest if you believe templates should be portable across ecosystems and dispatch is a separate concern. **Option A** is fastest if the contract is really just "here is the dispatch catalog, pick one." **Option C** is correct if both meanings are genuinely present in operator/designer mental models — but verify that before adding field surface area.

Whichever path is chosen, the deliverable is the same shape: schema + Rust + templates + fixture + round-trip test all agree.

## Scope

- **Primary seam:** the chosen vocabulary, applied to schema, Rust enum, and any shipped template files
- **Allowed files:** see Allowed write scope above
- **Explicit non-goals:**
  - Do not rename `AgentTier` or touch tier vocabulary
  - Do not change phase IDs, gate semantics, or transition shapes
  - Do not bump `schema_version` beyond what the chosen path requires (Option A and B are breaking; Option C is additive and could stay at 1.0 if the new field is optional, but default to bumping to 1.1 or 2.0 since real consumers exist)
  - Do not redesign `workflow-status-v1` role vocabulary as part of this handoff; flag any drift between the two as a follow-up

---

### Step 1: Decide and document the chosen path

**Project:** `septa/` (decision-only; no code yet)
**Effort:** 0.25 day
**Depends on:** nothing

Write a short decision record (2-3 sentences in the completion note on this handoff) stating: which option was chosen, why, and the contract version implication.

**The decision record must explicitly address the `workflow-status-v1` alignment.** That schema already uses the 9 Rust runtime names at line 51; whichever option is chosen must either:

- Leave `workflow-status-v1` alone and justify why two septa schemas using different role vocabularies is intentional (Option A leaves this aligned trivially; Option C accepts coexistence; Option B must justify why only the template schema narrows), OR
- Include `workflow-status-v1` in the change scope (Option B would then widen `Allowed write scope` to cover `septa/workflow-status-v1.schema.json` and its fixture plus any hymenium code that emits it via `emit_status()`).

Grep once in `canopy/src`, `cap/src`, and `cap/server/src` for uses of the role string to confirm the blast radius before committing.

### Step 2: Apply the chosen vocabulary

**Project:** `septa/` primary, `hymenium/` secondary
**Effort:** 0.5-1 day depending on path
**Depends on:** Step 1

**Option A path:** Replace the schema enum at line 37 of `workflow-template-v1.schema.json` with the nine runtime role names (matching the `serde(rename)` attributes exactly, including capitalization and spaces). Update the fixture to use one of them. Update any `hymenium/templates/*.json` that uses `implementer` / `auditor` / `reviewer` / `operator` to the new vocabulary.

**Option B path:** In `hymenium/src/workflow/template.rs`, rename `AgentRole` → `AgentKind` (grep for all uses and update). Add a new `ProcessRole` enum with the four schema values. In `Phase`, replace `role: AgentRole` with `role: ProcessRole` and introduce a `kind: AgentKind` field that dispatch resolves (or — if templates should not pin a specific agent — drop `kind` entirely and resolve at dispatch time). Update templates accordingly.

**Option C path:** In the schema, add `agent_role` alongside `role` with the nine-value enum. Leave `role` as-is with its four-value enum. In Rust, rename the existing `AgentRole` to `AgentKind` (same rename as Option B), keep it deserializing from `agent_role`, and add a `ProcessRole` type that deserializes from `role`. Update the fixture to populate both fields. Update shipped templates.

Whichever path: re-validate. The fixture must pass the schema, and the fixture must deserialize cleanly into the Rust types.

### Step 3: Round-trip test

**Project:** `hymenium/`
**Effort:** 0.25 day
**Depends on:** Step 2

Add a test (unit or integration) in hymenium that:

1. Loads `septa/fixtures/workflow-template-v1.example.json`.
2. Deserializes it into the Rust template type.
3. Re-serializes to JSON.
4. Validates the re-serialized JSON against `septa/workflow-template-v1.schema.json` via `check-jsonschema` or the `jsonschema` crate.

This test is the thing that would have caught the original drift. Keep it checked in.

### Step 4: Re-validate the whole stack

**Project:** workspace root
**Effort:** 0.1 day
**Depends on:** Steps 1-3

```bash
cd septa && bash validate-all.sh
cd .. && bash scripts/test-integration.sh
cd hymenium && cargo test && cargo clippy -- -D warnings
```

All green. No new failures in the integration script beyond the pre-existing 6 `$ref` issues that are tracked separately.

---

## Verification Contract

```bash
cd septa && bash validate-all.sh
cd ../hymenium && cargo test && cargo clippy -- -D warnings
cd .. && bash .handoffs/septa/verify-workflow-template-role-vocabulary.sh
```

## Completion criteria

- [ ] Decision recorded (which option, why, version implication)
- [ ] Schema and Rust agree on the chosen vocabulary
- [ ] Fixture and all shipped `hymenium/templates/*.json` files validate against the schema
- [ ] Round-trip test checked in
- [ ] `septa/validate-all.sh` clean
- [ ] `cargo test` and `cargo clippy` clean in hymenium
- [ ] HANDOFFS.md updated, handoff archived
