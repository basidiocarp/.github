# Spore Add Volva to Tool Enum

## Problem

Spore's `Tool` enum and `discover_all()` don't include Volva. Every tool that
wants to check whether volva is available must do so ad hoc instead of calling
`spore::discover(Tool::Volva)`. As volva gets wired more deeply into the ecosystem
(hyphae recall injection, stipe health checks, cap visibility), this missing enum
entry causes divergence. Add it now before the surface area grows.

## What exists (state)

- **File:** `spore/src/discovery.rs` (or `spore/src/tools.rs`)
- **Enum:** `Tool` has variants for cortina, canopy, hyphae, rhizome, mycelium, stipe — not volva
- **`discover_all()`:** iterates the enum; volva excluded
- **Binary name:** `volva` (confirm in `volva/Cargo.toml`)

## What needs doing (intent)

Add `Tool::Volva` to the spore `Tool` enum and ensure `discover_all()` includes it.

---

### Step 1: Add Volva variant

**Project:** `spore/`
**Effort:** 15 min

Add `Volva` to the `Tool` enum. Add the binary name (`"volva"`) to the match arm
that maps `Tool` → binary name. Ensure `discover_all()` includes `Tool::Volva`.

#### Verification

```bash
cd spore && cargo test 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `Tool::Volva` exists in the enum
- [ ] Binary name `"volva"` mapped correctly
- [ ] `discover_all()` includes Volva
- [ ] All spore tests pass

---

## Completion Protocol

1. Verification output pasted above
2. All checklist items checked

## Context

`IMPROVEMENTS-OBSERVATION-V2.md` identified this gap. Spore v0.4.6 added cortina
and canopy; volva shipped after and was never added.
