# CLAUDE.md Accuracy Update (8 Projects)

## Problem

7 project CLAUDE.md files plus the root CLAUDE.md contain stale information found
during the global audit. Tool counts, architecture diagrams, test counts, dependency
versions, and feature claims have drifted from reality.

## What exists (state)

| Project | Stale Claims |
|---------|-------------|
| hyphae | "~110 tests" (actual 606), "rusqlite 0.34" (actual 0.39), "37 tools" (actual 38) |
| mycelium | Architecture shows `src/filters/` (actual: `vcs/`, `cargo_filters/`, `js/`, `fileops/`) |
| rhizome | "35 tools" (actual 38), "7 edit tools" (actual 9-10) |
| canopy | "30 tools" (actual 31) |
| cap | "read-only" (false), missing 5 API route groups, stale backend file tree |
| spore | Lists 3 consumers (actual 6), says cortina/canopy "planned" (both live) |
| volva | No CLAUDE.md exists |
| root | Claims snapshot testing across all projects (only mycelium uses it) |

## What needs doing (intent)

Update each project's CLAUDE.md to match current code reality. Create volva's CLAUDE.md.
Cap's boundary fix is tracked separately in `cap/boundary-documentation.md`.

---

### Step 1: Fix hyphae CLAUDE.md

**Project:** `hyphae/`
**Effort:** 15 min

- Change test count from "~110" to "606+"
- Change rusqlite version from "0.34" to "0.39"
- Change tool count from "37" to "38"
- Update CLI command count if stale (was "29", may have grown)

**Checklist:**
- [ ] Test count accurate
- [ ] rusqlite version accurate
- [ ] Tool count accurate

---

### Step 2: Fix mycelium CLAUDE.md

**Project:** `mycelium/`
**Effort:** 20 min

- Replace architecture diagram: remove `src/filters/` directory, add actual module
  structure (`src/vcs/git_filters/`, `src/cargo_filters/`, `src/js/`, `src/fileops/`,
  `src/container_cmd/`, `src/dispatch.rs`, `src/tracking/`, `src/discover/`, `src/gain/`,
  `src/learn/`, etc.)
- Mention `dispatch.rs` as the routing backbone

**Checklist:**
- [ ] Architecture diagram matches actual file tree
- [ ] Key modules mentioned (dispatch, tracking, discover, gain)

---

### Step 3: Fix rhizome CLAUDE.md

**Project:** `rhizome/`
**Effort:** 15 min

- Change tool count from "35" to "38"
- Change edit tool count from "7" to "10" (9 in edit_tools + rename_symbol in file_tools)
- Update language count if needed (claims "10 tree-sitter + 8 generic + 14 LSP")

**Checklist:**
- [ ] Tool count = 38
- [ ] Edit tool count = 10
- [ ] Language counts verified

---

### Step 4: Fix canopy CLAUDE.md

**Project:** `canopy/`
**Effort:** 5 min

- Change tool count from "30" to "31"
- Add `canopy_check_handoff_completeness` to tool listing if present

**Checklist:**
- [ ] Tool count = 31

---

### Step 5: Fix spore CLAUDE.md

**Project:** `spore/`
**Effort:** 10 min

- Add stipe, cortina, canopy to "Consumed By" list
- Remove "Planned Consumers" section or move volva there
- Update module count from "nine" to "eleven" (add editors.rs, error.rs)
- Add Editor, EditorDescriptor, EcosystemError, SporeError to Key Types

**Checklist:**
- [ ] Consumer list includes all 6 actual consumers
- [ ] Module count accurate
- [ ] Key types listed

---

### Step 6: Create volva CLAUDE.md

**Project:** `volva/`
**Effort:** 20 min

Create `volva/CLAUDE.md` documenting:
- Project description (Claude-first CLI and runtime layer)
- 10-crate workspace structure with dependency graph
- Which crates are active vs stubs (bridge, adapters, tools, compat are stubs)
- Build & test commands
- Hook adapter contract (JSON payload shape)
- Auth flow (OAuth PKCE)
- Known gaps (5 crates with zero tests)

**Checklist:**
- [ ] CLAUDE.md exists at `volva/CLAUDE.md`
- [ ] Crate dependency graph documented
- [ ] Stub crates identified
- [ ] Build commands listed

---

### Step 7: Fix root CLAUDE.md

**Project:** workspace root
**Effort:** 10 min

- Remove or qualify "All use snapshot testing with `insta` crate" claim. Replace with
  "mycelium uses snapshot testing with insta; other projects use assertion-based tests"
- Update tool counts to match per-project actuals (hyphae 38, rhizome 38, canopy 31)
- Add cap → canopy and cap → stipe connection arrows
- Note that cap has write-through endpoints (not read-only)

**Checklist:**
- [ ] Snapshot testing claim qualified
- [ ] Tool counts match per-project CLAUDE.md files
- [ ] Connection diagram includes cap write paths

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. All 7 steps completed with checklist items checked
2. Every number in every CLAUDE.md matches current code

## Context

Found during global ecosystem audit (2026-04-04), Layers 1-4.
See `ECOSYSTEM-AUDIT-2026-04-04.md` H3.
