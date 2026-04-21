# Mycelium Dead Code Cleanup

## Problem

45 `#[allow(dead_code)]` suppressions across 27 files, including 2 entire modules
(`plugin` and `tee`) suppressed in `lib.rs`. This is the highest dead code count in
the ecosystem and actively hides the compiler's ability to surface unused fields.

## What exists (state)

- 45 `#[allow(dead_code)]` across 27 files
- `lib.rs:11-16`: entire `plugin` and `tee` modules marked dead
- Major concentrations: filter structs, tracking structs, config types, discovery types
- Most are JSON deserialization structs where only some fields are read

## What needs doing (intent)

Audit each `#[allow(dead_code)]` and either remove the dead code or document why
the suppression is necessary (e.g., `#[allow(dead_code, reason = "JSON schema field")]`).

---

### Step 1: Audit and clean up

**Project:** `mycelium/`
**Effort:** 1 hour

For each suppression:
1. If the item is truly unused and not needed for deserialization → remove it
2. If needed for serde deserialization → add `reason = "serde deserialization"` to the allow
3. If the entire module is dead (`plugin`, `tee`) → either wire it up or remove the module

**Checklist:**
- [ ] Each remaining `#[allow(dead_code)]` has a `reason` field
- [ ] Dead modules either removed or connected to callers
- [ ] `#[allow(dead_code)]` count reduced by at least 50%
- [ ] All 1,444 tests pass

## Context

Found during global ecosystem audit (2026-04-04), Layer 1+2 audits of mycelium.
