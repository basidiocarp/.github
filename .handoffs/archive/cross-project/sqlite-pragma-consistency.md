# SQLite PRAGMA Consistency

## Problem

Only canopy has the full SQLite safety triple (WAL mode + busy_timeout + foreign_keys).
Mycelium sets zero PRAGMAs. Hyphae is missing busy_timeout despite its CLAUDE.md claiming
exponential backoff retry. Under concurrent access (multiple hooks firing simultaneously),
databases can encounter SQLITE_BUSY errors with no recovery.

## What exists (state)

| Project | WAL | busy_timeout | foreign_keys |
|---------|-----|-------------|--------------|
| canopy | Yes | 5000ms | Yes |
| hyphae | Yes | **NO** | Yes |
| mycelium | **NO** | **NO** | **NO** |
| cortina | **NO** | **NO** | **NO** (reads mycelium DB) |

## What needs doing (intent)

Add consistent SQLite PRAGMAs to all projects that use SQLite.

---

### Step 1: Add PRAGMAs to mycelium

**Project:** `mycelium/`
**Effort:** 15 min
**Depends on:** nothing

#### Files to modify

**`mycelium/src/tracking/schema.rs`** (or wherever the connection is opened) — add after
connection open:

```rust
conn.execute_batch("
    PRAGMA journal_mode = WAL;
    PRAGMA busy_timeout = 5000;
    PRAGMA foreign_keys = ON;
")?;
```

#### Verification

```bash
cd mycelium && cargo test tracking 2>&1 | tail -5
```

**Checklist:**
- [ ] WAL mode set
- [ ] busy_timeout = 5000 set
- [ ] foreign_keys = ON set
- [ ] Existing tests pass

---

### Step 2: Add busy_timeout to hyphae

**Project:** `hyphae/`
**Effort:** 10 min
**Depends on:** nothing

#### Files to modify

**`hyphae/crates/hyphae-store/src/store/mod.rs`** — add `PRAGMA busy_timeout = 5000;`
alongside existing WAL and foreign_keys PRAGMAs.

Update CLAUDE.md to remove "retry with exponential backoff" claim if that's not what
busy_timeout does (it's a simple wait, not exponential backoff).

#### Verification

```bash
cd hyphae && cargo test 2>&1 | tail -5
```

**Checklist:**
- [ ] busy_timeout = 5000 set
- [ ] CLAUDE.md failure mode description is accurate
- [ ] Existing tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. All steps have verification output pasted
2. All 3 SQLite-using projects have WAL + busy_timeout + foreign_keys

## Context

Found during global ecosystem audit (2026-04-04), Layer 3 cross-project consistency.
See `ECOSYSTEM-AUDIT-2026-04-04.md` H2.
