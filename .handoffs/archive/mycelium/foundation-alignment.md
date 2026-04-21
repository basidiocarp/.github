# Mycelium Foundation Alignment

## Problem

`mycelium` is healthy as a single-package tool, but it is the repo most at risk of becoming an internal monolith. Dispatch, filtering, tracking, and sibling integrations can all expand in one place unless the current boundaries are made more explicit and larger behavior tests are moved out of hotspot files early.

## What exists (state)

- **`mycelium`** already has a good internal module split for a single-package tool
- **output shape and filtering** are still the right product center
- **Future handoffs** may add declarative extensions and richer operator-facing reporting

## What needs doing (intent)

Reinforce:

- command and filtering boundaries remain explicit
- dispatch does not become a policy or composition dump
- integrations with `hyphae` or `rhizome` stay isolated
- larger behavior tests move out of hotspot files where needed

---

### Step 1: Align docs around single-package boundaries

**Project:** `mycelium/`
**Effort:** 1-2 hours
**Depends on:** nothing

Clarify in repo-local docs:

- what belongs in dispatch versus command modules
- how sibling-tool integrations should stay isolated
- why one-package does not mean one-file

#### Verification

```bash
cd mycelium && cargo build 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] docs reinforce the internal module boundary story
- [ ] docs call out dispatch as a hotspot to protect
- [ ] build passes

---

### Step 2: Add a lightweight hotspot guard

**Project:** `mycelium/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add a lightweight guard so future work does not let dispatch or shared modules quietly absorb unrelated policy and orchestration.

#### Verification

```bash
cd mycelium && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] a future-work hotspot guard exists
- [ ] tests still pass

---

### Step 3: Split larger behavior tests from hotspot files

**Project:** `mycelium/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Move larger behavior tests out of hotspot files into separate files or `tests/` where needed, especially around dispatch, summaries, and learning/reporting paths.

#### Verification

```bash
cd mycelium && cargo test 2>&1 | tail -40
bash .handoffs/mycelium/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] larger behavior tests are split where needed
- [ ] inline tests remain only for small invariants
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/mycelium/verify-foundation-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/mycelium/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Companion standards:

- `docs/foundations/rust-workspace-architecture-standards.md`
- `docs/foundations/rust-workspace-standards-applied.md`
