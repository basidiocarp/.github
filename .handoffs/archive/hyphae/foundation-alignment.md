# Hyphae Foundation Alignment

## Problem

`hyphae` already has one of the strongest structures in the ecosystem, which is exactly why it needs a foundation-alignment pass before more product surfaces land. Memory, retrieval, analytics, ingest, and contract work all want to collect in the center, and without deliberate alignment the clean crate story can drift into a large conceptual catch-all.

## What exists (state)

- **`hyphae`** already has a strong workspace split and clear central crate
- **`hyphae-core`** is currently the conceptual center
- **Future handoffs** will add passive resources and richer artifact types, which increase domain-sprawl risk

## What needs doing (intent)

Reinforce:

- `hyphae-core` stays narrow
- transport and operator concerns stay out of the core
- contracts stay explicit and versioned
- larger store or tool behavior tests move out of hotspot files where needed

---

### Step 1: Align docs and crate-boundary guidance

**Project:** `hyphae/`
**Effort:** 1-2 hours
**Depends on:** nothing

Clarify what belongs in `hyphae-core` and what belongs in surrounding crates such as store, ingest, MCP, or CLI surfaces.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] docs state narrow-core expectations clearly
- [ ] docs reinforce transport and operator separation
- [ ] build passes

---

### Step 2: Add lightweight contract and boundary guards

**Project:** `hyphae/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add a lightweight guard so future work keeps contracts explicit and avoids convenience imports into the core.

#### Verification

```bash
cd hyphae && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] boundary or contract guard exists for future work
- [ ] tests still pass

---

### Step 3: Split larger store/tool tests from hotspot files

**Project:** `hyphae/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Where store or tool modules are growing, move larger behavior tests into separate files or `tests/` rather than inflating already-complex implementation files.

#### Verification

```bash
cd hyphae && cargo test --workspace 2>&1 | tail -40
bash .handoffs/hyphae/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] larger behavior tests are split from hotspot files where needed
- [ ] inline tests remain for small local invariants only
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hyphae/verify-foundation-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/hyphae/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Companion standards:

- `docs/foundations/rust-workspace-architecture-standards.md`
- `docs/foundations/rust-workspace-standards-applied.md`
