# Canopy Foundation Alignment

## Problem

`canopy` already has a strong transport-neutral coordination shape, but it is vulnerable to operator-facing feature pressure. As council, queue, evidence, and richer UI-oriented reads grow, the repo needs a foundation-alignment pass so coordination state does not blur into memory, presentation, or ad hoc product policy.

## What exists (state)

- **`canopy`** already owns coordination state, references, and operator-facing tools
- **store/tools/mcp split** is already the right high-level shape
- **Future handoffs** will likely add council-session and queue-oriented behavior

## What needs doing (intent)

Reinforce:

- coordination state stays distinct from memory
- evidence contracts stay explicit
- operator read models do not drag presentation policy into core logic
- larger tool/store tests move out of hotspot files where needed

---

### Step 1: Align docs and coordination boundaries

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** nothing

Clarify what belongs in `canopy` versus `hyphae`, `cap`, and `lamella`, especially around coordination state, evidence, and operator read models.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] docs state coordination-vs-memory boundaries clearly
- [ ] docs state evidence contract expectations clearly
- [ ] build passes

---

### Step 2: Add a lightweight boundary guard

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add a lightweight guard so future operator-facing features stay attached to task and evidence semantics rather than drifting into presentation-first logic.

#### Verification

```bash
cd canopy && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] boundary guard exists for future council/queue/operator work
- [ ] tests still pass

---

### Step 3: Split larger store/tool tests from hotspots

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Move larger behavior tests out of store/tool hotspot files into separate files or `tests/` where needed.

#### Verification

```bash
cd canopy && cargo test 2>&1 | tail -40
bash .handoffs/canopy/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] larger store/tool tests are split where needed
- [ ] inline tests remain only for small invariants
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/canopy/verify-foundation-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/canopy/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Companion standards:

- `docs/foundations/rust-workspace-architecture-standards.md`
- `docs/foundations/rust-workspace-standards-applied.md`
