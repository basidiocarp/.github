# Cortina Foundation Alignment

## Problem

`cortina` already has the right adapter-first direction, but it is easy for host quirks, policy, lifecycle capture, and downstream memory concerns to blur together. Before more lifecycle and contract work lands, the repo should be aligned to keep host parsing at the edge and keep forwarding logic narrow.

## What exists (state)

- **`cortina`** already owns adapter-first lifecycle capture
- **Best-effort persistence** and fail-open behavior are the right base model
- **Future handoffs** will expand lifecycle coverage and normalized event contracts

## What needs doing (intent)

Reinforce:

- adapters own host parsing
- policy remains explicit
- forwarding to downstream systems stays narrow
- larger behavior tests move out of hotspot files

---

### Step 1: Align boundary docs

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** nothing

Clarify that:

- host-specific quirks belong in adapters
- `cortina` captures and classifies but does not become a memory or orchestration system
- fail-open behavior is intentional and cross-host

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] docs state adapter-first ownership clearly
- [ ] docs state fail-open behavior explicitly
- [ ] build passes

---

### Step 2: Add a lightweight boundary guard

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add a lightweight guard so future work keeps host parsing and downstream forwarding separated.

#### Verification

```bash
cd cortina && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] boundary guard exists for future work
- [ ] tests still pass

---

### Step 3: Split larger lifecycle tests out of hotspot files

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Move larger behavior tests out of hook/lifecycle hotspot files into separate test files where needed.

#### Verification

```bash
cd cortina && cargo test 2>&1 | tail -40
bash .handoffs/cortina/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] larger lifecycle tests are split out where needed
- [ ] inline tests remain only for small invariants
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cortina/verify-foundation-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cortina/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Companion standards:

- `docs/foundations/rust-workspace-architecture-standards.md`
- `docs/foundations/rust-workspace-standards-applied.md`
