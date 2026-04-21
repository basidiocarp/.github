# Stipe Scope Name Match Deduplication

## Problem

The `HostConfigScope -> &str` match arm converting scope enum variants to string names
is repeated 8 times across 6 files instead of using the existing `host_policy::scope_name()`
function at `src/commands/host_policy.rs:152-158`. Additionally, CLAUDE.md architecture
tree shows ~8 files when actual source tree has 47 `.rs` files.

## What exists (state)

- `host_policy::scope_name()` exists at `src/commands/host_policy.rs:152-158`
- 8 inline match arms in: `ecosystem/mcp.rs` (2x), `ecosystem/configure.rs`,
  `ecosystem/clients/registration.rs` (2x), `commands/host/render.rs`,
  `commands/init/snapshot.rs`
- CLAUDE.md architecture tree is materially stale

## What needs doing (intent)

Replace inline match arms with `scope_name()` calls. Update CLAUDE.md.

---

### Step 1: Replace inline matches

**Project:** `stipe/`
**Effort:** 20 min

Search for the pattern and replace with `host_policy::scope_name(scope)` in all 6 files.

### Step 2: Update CLAUDE.md architecture tree

Add the ~39 missing files to the documented architecture tree, or restructure
the documentation to describe module groups rather than listing every file.

**Checklist:**
- [ ] `scope_name()` used in all locations (zero inline scope-to-string matches)
- [ ] CLAUDE.md architecture tree reflects actual file structure
- [ ] All 119 tests pass

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of stipe.
