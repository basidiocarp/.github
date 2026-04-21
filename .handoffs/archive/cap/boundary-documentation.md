# Cap Boundary Documentation

<!-- Save as: .handoffs/cap/boundary-documentation.md -->
<!-- Create verify script: .handoffs/cap/verify-boundary-documentation.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Cap's documentation still describes the backend as read-only overall, but the
actual server exposes write-through surfaces for Hyphae memories, Rhizome
project switching and symbol edits, settings writes, Canopy actions, and LSP
installation. The API reference and architecture notes also omit several route
groups.

## What exists (state)

- `cap/CLAUDE.md` still says the backend is read-only by default
- `cap/README.md` still frames Cap as read-only in multiple places
- `cap/docs/API.md` only documented Hyphae before this update
- `cap/docs/INTERNALS.md` listed an outdated route count and omitted `canopy`
- The real server mounts 9 API namespaces: `canopy`, `hyphae`, `lsp`,
  `mycelium`, `rhizome`, `settings`, `status`, `telemetry`, and `usage`

## What needs doing (intent)

Update the Cap docs so they accurately describe the boundary: Hyphae DB access
remains read-only, but the server is not read-only overall because it brokers
explicit write-through actions and config updates.

---

### Step 1: Refresh Boundary Language

**Project:** `cap/`
**Effort:** 30 min
**Depends on:** nothing

Update the user-facing and operator-facing docs to replace the blanket
read-only claim with boundary-accurate language.

#### Files to modify

**`cap/CLAUDE.md`** - describe Cap as a boundary broker with read-heavy
behavior, not a fully read-only backend.

**`cap/README.md`** - update the product summary and key capability bullets to
mention write-through surfaces.

**`cap/docs/INTERNALS.md`** - fix the route count and note the `canopy`
namespace.

### Step 2: Complete the API Reference

**Project:** `cap/`
**Effort:** 45 min
**Depends on:** Step 1

Expand `docs/API.md` so it documents the full route surface instead of only the
Hyphae read endpoints.

#### Files to modify

**`cap/docs/API.md`** - add the missing route groups and summarize the write
surfaces for Hyphae, Canopy, Rhizome, Settings, LSP, Status, Telemetry, and
Usage.

#### Verification

```bash
bash .handoffs/cap/verify-boundary-documentation.sh
```

**Output:**
<!-- PASTE START -->
PASS: CLAUDE.md describes write-through boundaries
PASS: CLAUDE.md no longer claims the backend is fully read-only
PASS: README.md describes the boundary accurately
PASS: README.md no longer calls the backend read-only overall
PASS: API reference covers the missing route groups
PASS: API reference includes Hyphae write endpoints
PASS: Internal notes include the canopy namespace and current route count
Results: 7 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] Cap docs no longer describe the backend as fully read-only
- [x] API reference covers the full route surface
- [x] Internal architecture notes match the actual route namespaces

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-boundary-documentation.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-boundary-documentation.sh
```

**Output:**
<!-- PASTE START -->
PASS: CLAUDE.md describes write-through boundaries
PASS: CLAUDE.md no longer claims the backend is fully read-only
PASS: README.md describes the boundary accurately
PASS: README.md no longer calls the backend read-only overall
PASS: API reference covers the missing route groups
PASS: API reference includes Hyphae write endpoints
PASS: Internal notes include the canopy namespace and current route count
Results: 7 passed, 0 failed

<!-- PASTE END -->

## Context

This handoff closes the boundary-documentation drift called out by the Cap deep
audit and the cross-project CLAUDE.md accuracy pass.
