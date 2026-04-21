# Volva Stub Crates and OAuth Constant Deduplication

## Problem

5 of 10 volva crates are stubs with zero tests. OAuth beta header constants are duplicated
between `volva-api` and `volva-auth` with no shared source of truth. Dead type alias
`SessionId` exists but is never used.

## What exists (state)

- **Stub crates:** volva-bridge (23L), volva-adapters (4L), volva-tools (35L),
  volva-compat (17L), volva-core partially
- **Duplicated constants:** `OAUTH_BETA_HEADER_NAME` + `OAUTH_BETA_HEADER_VALUE` in both
  `volva-api/src/lib.rs:12-13` and `volva-auth/src/anthropic/oauth.rs:14-15`
- **Dead code:** `pub type SessionId = String` in `volva-core/src/lib.rs:5` — zero imports
- **Missing `#[non_exhaustive]`** on `BackendKind`, `AuthProvider`, `HookPhase`, etc.

## What needs doing (intent)

Consolidate OAuth constants, clean up dead code, and either document or remove stub crates.

---

### Step 1: Move OAuth constants to volva-core

**Project:** `volva/`
**Effort:** 15 min

Move `OAUTH_BETA_HEADER_NAME` and `OAUTH_BETA_HEADER_VALUE` to `volva-core`.
Update `volva-api` and `volva-auth` to import from `volva-core`.

### Step 2: Clean up dead code

- Remove `pub type SessionId = String` from `volva-core/src/lib.rs`
- Add `#[non_exhaustive]` to `BackendKind`, `AuthProvider`, `AuthTarget`, `AuthMode`,
  `HookPhase`, `HookAdapterState`

### Step 3: Document stub crate status

In the new `volva/CLAUDE.md` (from claude-md-accuracy handoff), clearly mark which
crates are stubs vs active. If any stubs are abandoned, consider removing them from
the workspace members list.

**Checklist:**
- [ ] OAuth constants exist in exactly one location (volva-core)
- [ ] `SessionId` type alias removed
- [ ] Public enums have `#[non_exhaustive]`
- [ ] All 73 tests pass

## Context

Found during global ecosystem audit (2026-04-04), Layer 1+2 audits of volva.
