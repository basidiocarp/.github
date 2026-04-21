# Cross-Project Datetime Crate Consolidation

## Problem

Three different datetime crates are in use across the ecosystem with no coordination:
- `chrono` — spore, hyphae
- `jiff` — mycelium
- `time` — canopy

This fragmentation means datetime values crossing project boundaries (e.g., session
timestamps, SLA deadlines) serialize differently depending on which crate produced them.
None of these are pinned in `ecosystem-versions.toml`, so versions also drift silently.
Found in the 2026-04-04 global audit (H5).

## What exists (state)

- **spore:** `chrono` (shared infrastructure library — natural host for a shared type)
- **hyphae:** `chrono` for timestamp storage and formatting
- **mycelium:** `jiff` (modern alternative, timezone-aware)
- **canopy:** `time` for SLA deadline arithmetic
- **ecosystem-versions.toml:** no datetime entry at all

## What needs doing (intent)

Pick one datetime crate for the ecosystem, add it to `ecosystem-versions.toml`, and
migrate the two non-standard projects. Spore is the right place to expose shared
datetime utilities since all Rust projects already depend on it.

---

### Step 1: Choose the canonical datetime crate

**Project:** `docs/` or `ecosystem-versions.toml`
**Effort:** 30 min

Evaluate chrono vs jiff vs time against ecosystem needs:
- Cross-platform: all three pass
- Timezone support: jiff and chrono are stronger than time
- Maintenance: jiff is newest; chrono is most established
- Existing usage: chrono has 2 projects, jiff 1, time 1

Document the decision in `ecosystem-versions.toml` under a `[datetime]` section or
as a comment, with the chosen crate and version pinned.

**Checklist:**
- [x] Decision documented with rationale
- [x] Chosen crate and version added to `ecosystem-versions.toml`

---

### Step 2: Expose shared datetime utilities from spore

**Project:** `spore/`
**Effort:** 1 hour
**Depends on:** Step 1

Add a `spore::datetime` module (or re-export from the chosen crate) with the
utilities used across projects:
- `now_utc()` — current UTC timestamp
- `timestamp_to_rfc3339(ts: i64) -> String` — epoch millis to ISO string
- `rfc3339_to_timestamp(s: &str) -> Result<i64>` — ISO string to epoch millis

These unify the two most common cross-project datetime operations.

#### Verification

```bash
cd spore && cargo test datetime 2>&1 | tail -10
```

**Checklist:**
- [x] `spore::datetime` module added with shared utilities
- [x] Module documented with examples (doctest)
- [x] Existing spore datetime usage migrated to the new module

---

### Step 3: Migrate non-standard projects

**Project:** `mycelium/` (jiff → chosen), `canopy/` (time → chosen)
**Effort:** 1-2 hours each
**Depends on:** Step 2

For each project:
1. Replace the non-standard crate with the chosen one in `Cargo.toml`
2. Update call sites to use `spore::datetime` utilities or the canonical crate API
3. Run tests to verify no behavioral change

**Checklist:**
- [x] `mycelium` migrated — `jiff` removed, tests pass
- [x] `canopy` migrated — `time` removed, tests pass
- [x] No datetime crate other than the chosen one appears in any `Cargo.toml`
- [x] `ecosystem-versions.toml` reflects final pinned version

## Completion Note

The initial experiment briefly pointed `mycelium` and `canopy` at a workspace-local `spore` path dependency, but the reconciled final state restored standalone repo independence. The shipped result is:
- `chrono` pinned as the ecosystem datetime crate
- `spore::datetime` added as shared infrastructure
- `mycelium` and `canopy` migrated off `jiff` / `time`
- published `spore` refs preserved in standalone consumer repos

---

## Completion Protocol

1. All step checklists checked
2. `cargo test --all` passes in spore, mycelium, canopy
3. `grep -r "^chrono\|^jiff\|^time" */Cargo.toml` shows only the chosen crate

## Context

Global audit 2026-04-04, finding H5. Three crates for the same concern is silent
fragmentation — timestamps in session events and SLA deadlines cross project boundaries
and the inconsistency is only visible when tracing a value end-to-end. Spore already
provides shared infrastructure and is the right consolidation point.
