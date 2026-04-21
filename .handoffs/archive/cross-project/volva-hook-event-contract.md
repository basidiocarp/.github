# Volva Hook Event Contract

Status: completed in 2026-04. The contract now exists at
`contracts/volva-hook-event-v1.schema.json`; Volva emits `schema_version: "1.0"`
and Cortina validates it.

## Problem

`cortina adapter volva hook-event` is a new cross-tool payload boundary — volva
is a new producer, cortina's volva adapter is the new receiver — but it has no
entry in `contracts/`, no `schema_version`, no schema file, and no consumer
validation test. The contracts README explicitly states that new cross-tool
interfaces should go through the contracts system before new producers depend on
them. A change to what volva sends or what cortina expects will break silently.

## What existed at handoff creation time

- **Volva adapter:** `cortina adapter volva hook-event` wired in cortina v0.2.6
- **Contracts directory:** `contracts/` with `README.md`, existing schema files
- **No entry:** `volva-hook-event` did not appear in the contracts inventory
- **No schema:** `contracts/volva-hook-event-v1.schema.json` did not exist yet
- **No fixture:** no consumer validation test for the volva payload shape
- **Existing contracts:** `evidence-ref-v1`, canopy snapshot, task-detail all versioned

## What needs doing (intent)

Document the volva hook event payload shape as a versioned contract, add it to
the contracts inventory, and add a consumer validation test in cortina.

---

### Step 1: Inspect current payload shape

**Project:** `cortina/`, `volva/`
**Effort:** 30 min

Read `cortina/src/adapters/volva.rs` (or equivalent) and `volva/src/hooks/` to
determine the current payload shape that volva sends to `cortina adapter volva
hook-event`. Document every field and its type.

#### Verification

```bash
grep -rn "hook.event\|HookEvent\|volva.*hook" cortina/src/ --include="*.rs" | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Payload fields and types documented
- [ ] Which fields are required vs optional noted

---

### Step 2: Add schema file and contracts entry

**Project:** `contracts/`
**Effort:** 30 min
**Depends on:** Step 1

Create `contracts/volva-hook-event-v1.schema.json` with the payload shape from
Step 1. Add an entry to `contracts/README.md` inventory table:

```
| volva-hook-event-v1 | volva → cortina volva adapter | contracts/volva-hook-event-v1.schema.json |
```

The schema should include `schema_version: "1.0"` as a required field so future
changes are detectable.

**Checklist:**
- [ ] Schema file exists at `contracts/volva-hook-event-v1.schema.json`
- [ ] `schema_version` is a required field in the schema
- [ ] contracts/README.md inventory updated

---

### Step 3: Add consumer validation in cortina

**Project:** `cortina/`
**Effort:** 1 hour
**Depends on:** Step 2

Add a test in cortina's volva adapter that deserializes a fixture payload against
the schema and verifies required fields are present. Use the same test pattern
as other contract tests in the repo.

#### Verification

```bash
cd cortina && cargo test volva 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Contract test exists for volva hook event shape
- [ ] Test fails if required fields are absent
- [ ] `schema_version: "1.0"` validated in cortina volva adapter

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. `contracts/` inventory includes `volva-hook-event-v1`

## Outcome

- `contracts/volva-hook-event-v1.schema.json` added
- `contracts/fixtures/volva-hook-event-v1.example.json` added
- `contracts/README.md` and `contracts/INTEGRATION-PATTERNS.md` updated
- Volva hook payloads now include `schema_version: "1.0"`
- Cortina validates the schema version and accepts the shared fixture

## Context

`IMPROVEMENTS-OBSERVATION-V3.md` identified this gap. The contracts remediation
plan (see `ECOSYSTEM-COMMUNICATION-REMEDIATION-PLAN.md`) specifically calls out
that new cross-tool interfaces should go through contracts before producers depend
on them. The volva adapter shipped in cortina v0.2.6 without this step.
