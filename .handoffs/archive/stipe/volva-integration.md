# Stipe Volva Integration

## Problem

`volva` is now a real repo with a published binary and `spore` can already
discover `Tool::Volva`, but `stipe` still does not know about it. That leaves
Volva outside the managed install, status, ecosystem, and doctor surfaces, so
operators have to reason about it ad hoc instead of through the shared
ecosystem manager.

## What exists (state)

- **`spore`:** `Tool::Volva` exists and `discover_all()` can find the `volva` binary
- **`stipe/src/commands/tool_registry/specs.rs`:** managed tool inventory includes mycelium, hyphae, rhizome, canopy, cortina, cap, and stipe, but not volva
- **`stipe/src/commands/tool_registry/probe.rs`:** `spore_tool()` maps existing managed binaries to `spore::Tool`, but not `volva`
- **`volva`:** CLI already exposes `backend status` and `backend doctor`

## What needs doing (intent)

Add Volva to `stipe` as a first-class managed tool so `stipe status`,
`stipe ecosystem status`, install/update flows, and doctor output all understand
it.

---

### Step 1: Add Volva to the managed tool registry

**Project:** `stipe/`
**Effort:** 45 min
**Depends on:** nothing

Add a `ToolSpec` for Volva and wire it into the registry and spore probe path.

Recommended shape:
- `name`: `volva`
- `binary_name`: `volva`
- `release_repo`: `volva`
- `installable`: `true`
- `include_in_status`: `true`
- `include_in_ecosystem`: `true`
- `include_in_update_all`: `true`
- `include_in_uninstall_all`: `true`
- `doctor_coverage`: `Optional`
- `install_profiles`: include at least `FullStack`
- `smoke_test_args`: prefer a lightweight host-safe path such as `["backend", "status"]`

#### Files to modify

**`stipe/src/commands/tool_registry/specs.rs`** — add the Volva tool spec and
decide which install profiles should include it.

**`stipe/src/commands/tool_registry/probe.rs`** — map `"volva"` to
`spore::Tool::Volva` and extend the probe tests.

**`stipe/src/commands/tool_registry/tests.rs`** — update inventory expectations
so Volva appears in the correct status, ecosystem, install, and doctor sets.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd stipe && cargo test tool_registry 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `ToolSpec` for `volva` exists
- [ ] `spore_tool("volva") == Some(spore::Tool::Volva)`
- [ ] Registry tests reflect Volva in the intended inventory surfaces

---

### Step 2: Surface Volva in doctor and operator guidance

**Project:** `stipe/`
**Effort:** 45 min
**Depends on:** Step 1

Ensure Volva shows up sanely in `stipe doctor` and related operator output.

The goal is:
- `stipe doctor` can report Volva when installed or missing
- missing Volva has a repair hint
- Volva does not get treated as a required blocker unless you intentionally make it one

If `backend doctor` proves too environment-sensitive for the first slice, keep
the smoke path lighter and document the follow-up.

#### Files to modify

**`stipe/src/commands/doctor/tool_checks.rs`** — make sure Volva’s missing or
broken state renders correctly with useful repair hints.

**`stipe/src/commands/tool_registry/model.rs`** — update model assumptions only
if the current doctor categories need a new expectation for Volva.

#### Verification

```bash
cd stipe && cargo test doctor 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` includes Volva in the intended coverage set
- [ ] Missing Volva has a repair hint
- [ ] Volva does not break existing doctor expectations for other tools

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-volva-integration.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/stipe/verify-volva-integration.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: 3 passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

This closes the ecosystem gap after:
- `volva` became its own repo
- `spore` gained `Tool::Volva`

Without this step, Volva remains discoverable at the library layer but invisible
to the operator-facing install and doctor layer.
