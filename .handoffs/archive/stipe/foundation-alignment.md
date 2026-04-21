# Stipe Foundation Alignment

## Problem

`stipe` is one of the repos most likely to drift because every host setup, install, doctor, repair, provider, and plugin concern wants to land there. The audit standards already say it should remain policy over shared primitives, but that boundary needs to be reinforced before more strategic feature work lands.

## What exists (state)

- **`stipe`** already has the right high-level ownership: install, init, doctor, repair, and host registration
- **Repo docs** already imply the boundary, but they do not yet act as a strong foundation-alignment gate
- **Future handoffs** like provider/MCP/plugin doctor expansion will increase the risk of ecosystem creep

## What needs doing (intent)

Tighten `stipe` around three ideas:

- policy over primitives
- explicit source-of-truth and host-boundary docs
- tests moved out of hotspot files when they begin inflating operator modules

---

### Step 1: Align docs and boundaries

**Project:** `stipe/`
**Effort:** 1-2 hours
**Depends on:** nothing

Update repo-local guidance so it says clearly:

- `stipe` owns host setup, install, doctor, repair, provider health, and registration policy
- it does not own authoring, packaging, or durable memory semantics
- shared low-level behavior should remain in shared primitives rather than being reimplemented locally

#### Verification

```bash
cd stipe && cargo build 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] docs state the policy-over-primitives boundary clearly
- [ ] docs state what `stipe` does not own
- [ ] build still passes

---

### Step 2: Add a lightweight boundary check to future work

**Project:** `stipe/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add a lightweight check or convention that keeps future handoffs honest. This can be docs, a verify script pattern, or a narrow test that asserts shared logic is not duplicated locally.

#### Verification

```bash
cd stipe && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] future work has a visible boundary guard
- [ ] build/test surface still passes

---

### Step 3: Separate larger tests from hotspot files

**Project:** `stipe/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Review operator hotspots such as doctor/init flows. Move larger behavior tests out of inline module files into separate test files or `tests/` when they start obscuring runtime code.

#### Verification

```bash
cd stipe && cargo test 2>&1 | tail -40
bash .handoffs/stipe/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] large behavior tests are split out of hotspot files where needed
- [ ] inline tests remain only for small local invariants
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-foundation-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/stipe/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Companion standards:

- `docs/foundations/rust-workspace-architecture-standards.md`
- `docs/foundations/rust-workspace-standards-applied.md`
