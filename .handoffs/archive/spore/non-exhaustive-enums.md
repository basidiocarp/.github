# Spore Non-Exhaustive Enums

## Problem

`Tool`, `Editor`, `SporeError`, and `Framing` are public enums without
`#[non_exhaustive]`. Adding a new tool or editor forces all downstream consumers
with exhaustive matches to update simultaneously, making it a semver-breaking change.
The ecosystem has 6 tools and 10 editors — growth is inevitable.

## What exists (state)

- `Tool` enum: `spore/src/types.rs:8` — 6 variants
- `Editor` enum: `spore/src/editors.rs:17` — 10 variants
- `SporeError` enum: `spore/src/error.rs:15` — 10 variants
- `Framing` enum: `spore/src/subprocess.rs` — 2 variants
- Zero `#[non_exhaustive]` annotations in the crate

## What needs doing (intent)

Add `#[non_exhaustive]` to all four public enums. Update downstream consumers
(mycelium, hyphae, rhizome, cortina, stipe, canopy) to add wildcard match arms.

---

### Step 1: Annotate enums and update consumers

**Project:** `spore/` + all consumers
**Effort:** 30 min

Add `#[non_exhaustive]` to `Tool`, `Editor`, `SporeError`, `Framing`.
Then grep all consumers for exhaustive matches on these types and add `_ => ...` arms.

**Checklist:**
- [ ] All 4 enums annotated with `#[non_exhaustive]`
- [ ] All 6 consumer projects compile without errors
- [ ] All consumer tests pass

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of spore.
Per project convention `api-non-exhaustive`: "Use `#[non_exhaustive]` on public enums
and structs for forward compatibility."
