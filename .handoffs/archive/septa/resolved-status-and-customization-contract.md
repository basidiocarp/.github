# Septa Resolved Status And Customization Contract

## Problem

The audits repeatedly pointed at a missing portable contract for statusline state, customization, and capability-aware rendering. Right now those concerns are still likely to grow as host-specific blobs, ad hoc config edits, or UI-local assumptions. Without a shared contract, `stipe`, `cortina`, `lamella`, and `cap` can all improve their own pieces while still drifting away from each other.

## What exists (state)

- **`septa/`:** already owns cross-tool payload schemas and fixtures
- **`stipe` and `cortina`:** already own host setup, repair, and lifecycle-adjacent surfaces
- **`lamella`:** already has packaging and preset-friendly content surfaces
- **`cap`:** already has operator views, but not yet a portable status/customization model to read from
- **Audit pressure:** `ccstatusline`, `ccusage`, and `1code` all pointed at portable status, customization, and repairable host views

## What needs doing (intent)

Add a schema-first contract for:

- resolved status output
- capability state for what the host can actually render
- customization bundles or presets
- origin metadata where a rendered result came from

The contract should stay portable. Host-specific injection and repair flows can depend on it, but should not replace it.

---

### Step 1: Add the first schema and example fixture

**Project:** `septa/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create a first versioned schema and example fixture for resolved status and customization state. Keep the first version small enough that `stipe`, `lamella`, and `cap` can all use it without pulling in host-specific assumptions.

#### Files to modify

**`septa/resolved-status-customization-v1.schema.json`** — define the portable contract.

**`septa/fixtures/resolved-status-customization-v1.example.json`** — add a matching example fixture.

**`septa/README.md`** — add the contract to the inventory.

#### Verification

```bash
rg -n 'resolved-status-customization-v1' septa
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] a new versioned schema exists in `septa/`
- [ ] a matching example fixture exists
- [ ] the schema is documented in the contract inventory

---

### Step 2: Name the first producer and consumer boundaries

**Project:** `septa/`, `stipe/`, `cortina/`, `lamella/`, `cap/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Document the first intended boundaries:

- `stipe` resolves and repairs host-side customization
- `cortina` can emit capability or lifecycle facts that shape the resolved state
- `lamella` packages presets or customization bundles against the contract
- `cap` previews and edits the portable shape instead of host-local config blobs

#### Files to modify

**`septa/integration-patterns.md`** — describe the producer and consumer boundaries.

**Repo-local docs** — add one short note in the first producer and first consumer repos.

#### Verification

```bash
rg -n 'resolved status|customization contract|status customization|portable status' septa stipe cortina lamella cap 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] the first producer and consumer boundaries are explicit
- [ ] docs describe a portable contract instead of a host-specific file format
- [ ] `lamella` and `cap` are described as consumers, not owners

---

### Step 3: Add one narrow validation seam

**Project:** `septa/` and one first producer or consumer repo
**Effort:** 2-3 hours
**Depends on:** Step 2

Add one narrow validation seam so the contract is not only a prose artifact. Good first options:

- fixture validation
- preset validation in `lamella`
- a typed read model in `cap`
- a `stipe` serialization or repair-path check

#### Files to modify

**`septa/`** — update schema or fixture coverage as needed.

**First producer or consumer repo** — add one validating reference to the contract.

#### Verification

```bash
bash .handoffs/archive/septa/verify-resolved-status-and-customization-contract.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] at least one producer or consumer path references the contract
- [ ] the verify script passes
- [ ] the portable contract has a real validation seam

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/septa/verify-resolved-status-and-customization-contract.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/septa/verify-resolved-status-and-customization-contract.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/ccstatusline-ecosystem-borrow-audit.md`
- `.audit/external/audits/ccusage-ecosystem-borrow-audit.md`
- `.audit/external/audits/1code-ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/ecosystem-synthesis-and-adoption-guide.md`
- `.handoffs/campaigns/external-audit-gap-map/README.md`
