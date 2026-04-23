# Canopy: Durable Policy Event Log

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/store/`, `canopy/src/tools/mod.rs`
- **Cross-repo edits:** `none`
- **Non-goals:** does not implement rate limiting (that reads from this table later); does not add a CLI query surface for policy events (future work)
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-policy-event-log.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:**
  - `src/store/schema.rs` — add `policy_events` table + migration
  - `src/store/policy_events.rs` — new file: `log_policy_event()` implementation
  - `src/store/mod.rs` — add `mod policy_events;`
  - `src/store/traits.rs` — add `fn log_policy_event()` to `CanopyStore` trait + blanket impl
  - `src/tools/mod.rs` — call `store.log_policy_event()` at the dispatch evaluation point
- **Reference seams:**
  - `src/store/tool_usage.rs` — pattern for a single-purpose store module
  - `src/store/events.rs` — pattern for event tables
  - `src/tools/mod.rs:127-139` — existing dispatch_tool where evaluate() is called
- **Spawn gate:** seam confirmed, files named above, verification commands listed below

## Problem

Dispatch policy decisions (Proceed / FlagForReview) are evaluated in memory and immediately discarded. There is no audit trail for what was allowed, blocked, or why. This makes it impossible to debug multi-agent policy disputes, derive per-agent dispatch frequency for rate limiting, or demonstrate access control correctness.

## What exists (state)

- **`src/tools/policy.rs`**: `DispatchPolicy::Default.evaluate(name, annotations)` returns `DispatchDecision::Proceed` or `DispatchDecision::FlagForReview { reason }` — result used immediately, not persisted.
- **`src/tools/mod.rs:134-138`**: the one call site where all MCP tool dispatch decisions are made. Early-returns an error on `FlagForReview`; falls through to handler on `Proceed`.
- **`src/store/schema.rs`**: existing `CREATE TABLE IF NOT EXISTS` pattern and `migrate_schema()` function used for all schema additions.
- **`src/store/tool_usage.rs`**: exemplary pattern for a single-purpose store module with `StoreResult`.

## What needs doing (intent)

Add a `policy_events` SQLite table and log every dispatch decision (both Proceed and FlagForReview) immediately after evaluation in `dispatch_tool`. The log entry captures: event_id (ULID), timestamp, agent_id, tool_name, decision, reason, and an optional task_id. Logging must be best-effort: a DB write failure must warn but must not block dispatch.

## Scope

- **Primary seam:** canopy SQLite store + MCP dispatch hook
- **Allowed files:** `canopy/src/store/schema.rs`, `canopy/src/store/policy_events.rs` (new), `canopy/src/store/mod.rs`, `canopy/src/store/traits.rs`, `canopy/src/tools/mod.rs`
- **Explicit non-goals:**
  - No CLI surface (`canopy policy list` or similar) — table exists, query surface is future work
  - No rate limiting check — this handoff only writes the log
  - No changes to `src/tools/policy.rs` evaluation logic

---

### Step 1: Add the `policy_events` table to schema

**Project:** `canopy/`
**Effort:** small
**Depends on:** nothing

Add to the `CREATE TABLE IF NOT EXISTS` block in `src/store/schema.rs`:

```sql
CREATE TABLE IF NOT EXISTS policy_events (
    event_id    TEXT PRIMARY KEY,        -- ULID
    ts          INTEGER NOT NULL,        -- unix milliseconds
    agent_id    TEXT NOT NULL,
    tool_name   TEXT NOT NULL,
    decision    TEXT NOT NULL CHECK(decision IN ('proceed', 'flag')),
    reason      TEXT NOT NULL,           -- empty string for Proceed
    task_id     TEXT                     -- nullable; associated task if known
);
```

Also add a migration entry at the bottom of `migrate_schema()` so existing databases gain the table:

```rust
conn.execute_batch(
    "CREATE TABLE IF NOT EXISTS policy_events (
        event_id    TEXT PRIMARY KEY,
        ts          INTEGER NOT NULL,
        agent_id    TEXT NOT NULL,
        tool_name   TEXT NOT NULL,
        decision    TEXT NOT NULL CHECK(decision IN ('proceed', 'flag')),
        reason      TEXT NOT NULL,
        task_id     TEXT
    );"
)?;
```

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cargo build` succeeds with no errors

---

### Step 2: Add `policy_events.rs` store module

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 1

Create `src/store/policy_events.rs`. Follow the `tool_usage.rs` pattern exactly — a module-level function that takes `&Connection`:

```rust
use super::StoreResult;
use rusqlite::Connection;

pub struct PolicyEventRow<'a> {
    pub event_id: &'a str,
    pub ts_ms: i64,
    pub agent_id: &'a str,
    pub tool_name: &'a str,
    pub decision: &'a str,   // "proceed" | "flag"
    pub reason: &'a str,     // empty for Proceed
    pub task_id: Option<&'a str>,
}

pub fn log_policy_event(conn: &Connection, row: &PolicyEventRow<'_>) -> StoreResult<()> {
    conn.execute(
        "INSERT OR IGNORE INTO policy_events
             (event_id, ts, agent_id, tool_name, decision, reason, task_id)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        rusqlite::params![
            row.event_id,
            row.ts_ms,
            row.agent_id,
            row.tool_name,
            row.decision,
            row.reason,
            row.task_id,
        ],
    )?;
    Ok(())
}
```

Add `mod policy_events;` (and `pub use policy_events::PolicyEventRow;` if needed by the trait) to `src/store/mod.rs`.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cargo build` succeeds

---

### Step 3: Add `log_policy_event` to the `CanopyStore` trait

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 2

In `src/store/traits.rs`, add to the `CanopyStore` trait:

```rust
/// Log a dispatch policy decision. Best-effort — callers should warn on error, not propagate.
fn log_policy_event(
    &self,
    agent_id: &str,
    tool_name: &str,
    decision: &str,
    reason: &str,
    task_id: Option<&str>,
) -> StoreResult<()>;
```

Add the blanket impl for `Store` by calling the module function:

```rust
fn log_policy_event(
    &self,
    agent_id: &str,
    tool_name: &str,
    decision: &str,
    reason: &str,
    task_id: Option<&str>,
) -> StoreResult<()> {
    use super::policy_events::{PolicyEventRow, log_policy_event as store_log};
    let event_id = ulid::Ulid::new().to_string();
    let ts_ms = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64;
    store_log(
        &self.conn,
        &PolicyEventRow { event_id: &event_id, ts_ms, agent_id, tool_name, decision, reason, task_id },
    )
}
```

Check that `ulid` is already a dependency in `canopy/Cargo.toml` before using it; if not, use a simple UUID or timestamp-based ID following the existing pattern in the codebase.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cargo build` succeeds
- [ ] trait method present on `CanopyStore`

---

### Step 4: Call `log_policy_event` from `dispatch_tool`

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 3

In `src/tools/mod.rs`, at the dispatch evaluation point (lines 133-139 as of audit):

```rust
// Policy check: look up the tool's annotations and evaluate the active policy.
let annotations = policy::annotations_for_tool(name);
let decision = policy::DispatchPolicy::Default.evaluate(name, annotations);

// Log the decision — best-effort, do not block dispatch on a write failure.
let (decision_str, reason_str) = match &decision {
    DispatchDecision::Proceed => ("proceed", String::new()),
    DispatchDecision::FlagForReview { reason } => ("flag", reason.clone()),
};
if let Err(e) = store.log_policy_event(agent_id, name, decision_str, &reason_str, None) {
    tracing::warn!(error = %e, tool = name, "failed to log policy event");
}

if let DispatchDecision::FlagForReview { reason } = decision {
    return ToolResult::error(format!("policy blocked: {reason}"));
}
```

This keeps the early-return behavior intact while logging both outcomes. Note: `DispatchDecision` must be `Clone` or the match must be restructured — check and adjust as needed.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cargo build` succeeds with no errors or warnings about unused variables

---

### Step 5: Add unit tests

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 4

Add tests to `src/store/policy_events.rs` (or a `#[cfg(test)]` block at the bottom):

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use rusqlite::Connection;

    fn setup() -> Connection {
        let conn = Connection::open_in_memory().unwrap();
        conn.execute_batch(
            "CREATE TABLE policy_events (
                event_id TEXT PRIMARY KEY,
                ts INTEGER NOT NULL,
                agent_id TEXT NOT NULL,
                tool_name TEXT NOT NULL,
                decision TEXT NOT NULL,
                reason TEXT NOT NULL,
                task_id TEXT
            );"
        ).unwrap();
        conn
    }

    #[test]
    fn log_proceed_event_stored() {
        let conn = setup();
        log_policy_event(&conn, &PolicyEventRow {
            event_id: "01HTEST",
            ts_ms: 1_000_000,
            agent_id: "agent-1",
            tool_name: "canopy_task_list",
            decision: "proceed",
            reason: "",
            task_id: None,
        }).unwrap();
        let count: i64 = conn
            .query_row("SELECT COUNT(*) FROM policy_events", [], |r| r.get(0))
            .unwrap();
        assert_eq!(count, 1);
    }

    #[test]
    fn log_flag_event_stored_with_reason() {
        let conn = setup();
        log_policy_event(&conn, &PolicyEventRow {
            event_id: "01HTEST2",
            ts_ms: 1_000_001,
            agent_id: "agent-2",
            tool_name: "canopy_task_delete",
            decision: "flag",
            reason: "destructive tool requires review",
            task_id: Some("task-abc"),
        }).unwrap();
        let reason: String = conn
            .query_row("SELECT reason FROM policy_events WHERE event_id = '01HTEST2'", [], |r| r.get(0))
            .unwrap();
        assert_eq!(reason, "destructive tool requires review");
    }
}
```

#### Verification

```bash
cd canopy && cargo test policy_event 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Both tests pass
- [ ] No test panics or compilation errors

---

### Step 6: Full suite

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 5

```bash
cd canopy && cargo test 2>&1 | tail -20
cd canopy && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd canopy && cargo fmt --check 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/canopy/verify-policy-event-log.sh`
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

### Final Verification

```bash
bash .handoffs/canopy/verify-policy-event-log.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Spawned from U4 auth and access control audit (2026-04-23). The audit found that policy decisions are evaluated in memory only with no durable record. This table enables:
1. Debugging: "which decisions were made and why?"
2. Rate limiting (future): query `COUNT(*) WHERE agent_id = ? AND ts > ?` instead of maintaining a separate counter
3. Operator visibility: Cap can surface policy event history per agent

The rate limiting handoff (`canopy/dispatch-rate-limiting.md`) is the intended consumer of this table.
