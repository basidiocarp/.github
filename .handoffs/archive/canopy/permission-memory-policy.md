# Canopy: Permission Memory as Runtime Policy

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/tools/policy.rs`, `canopy/src/store/`, `canopy/src/tools/mod.rs`
- **Cross-repo edits:** none
- **Non-goals:** does not add a UI surface for managing rules (cap work); does not change MCP tool registration; does not replace the existing dispatch policy evaluation
- **Verification contract:** run the repo-local commands below and the paired verify script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by forgecode's `policy.rs` / `tool_registry.rs` pattern (audit: `.audit/external/audits/forgecode/borrow-matrix.md`):

> "Permission memory as first-class runtime policy. Their policy service turns one-off approvals into reusable rules and persists them cleanly. That is better than leaving approval state implicit in prompts or session memory."

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:**
  - `src/tools/policy.rs` — existing dispatch policy; extend to consult a persistent rule table
  - `src/store/schema.rs` — add `permission_rules` table
  - `src/store/permission_rules.rs` — new CRUD module for rules
  - `src/store/traits.rs` — extend `CanopyStore` trait with rule query/upsert methods
  - `src/tools/mod.rs` — after the existing `log_policy_event` call, optionally query persisted rules
- **Reference seams:**
  - `src/store/policy_events.rs` — just-shipped pattern for a single-purpose store module
  - `src/tools/policy.rs:evaluate()` — the existing evaluation function to extend
- **Spawn gate:** seam confirmed — policy_events.rs is the direct model; exact line identified

## Problem

Dispatch policy decisions in canopy are stateless. Each call to `dispatch_tool` re-evaluates the policy from scratch, with no memory of previous decisions. If an operator approved a tool for a specific agent, that approval is lost when the session ends. This forces either re-approval on every session or hard-coding approvals into the static policy — both bad outcomes.

Forgecode's solution: a `permission_rules` table where one-time approvals can be upserted as persistent rules. The policy evaluator consults this table first, then falls through to the default static policy.

## What exists (state)

- **`src/tools/policy.rs`**: `DispatchPolicy::Default.evaluate(name, annotations)` — purely static, no persistent state
- **`src/store/policy_events.rs`**: just added; shows the exact module pattern to follow
- **`src/store/traits.rs`**: `PolicyEventStore` supertrait; add a second supertrait `PermissionRuleStore`
- **`policy_events` table**: already in schema — the `permission_rules` table follows the same migration pattern

## What needs doing (intent)

Add a `permission_rules` SQLite table. Add CRUD operations for rules. Extend the dispatch policy to check persisted rules before falling through to the static default. Rules are keyed by `(agent_id, tool_name)` and have an action (`allow` or `deny`) plus a `scope` (session vs permanent). The evaluator should: check persisted allow rule → return Proceed; check persisted deny rule → return FlagForReview; fall through to static policy.

## Scope

- **Allowed files:** `canopy/src/store/schema.rs`, `canopy/src/store/permission_rules.rs` (new), `canopy/src/store/mod.rs`, `canopy/src/store/traits.rs`, `canopy/src/tools/policy.rs`, `canopy/src/tools/mod.rs`
- **Explicit non-goals:**
  - No API surface for creating/deleting rules — rules are written by canopy internally when operators approve; external write surface is future work
  - No UI for rule management — that belongs in cap
  - No changes to how static policy annotations work

---

### Step 1: Add `permission_rules` table

**Project:** `canopy/`
**Effort:** small
**Depends on:** nothing

Add to `src/store/schema.rs` `BASE_SCHEMA` and `migrate_schema()`:

```sql
CREATE TABLE IF NOT EXISTS permission_rules (
    rule_id     TEXT PRIMARY KEY,          -- ULID
    agent_id    TEXT NOT NULL,             -- '*' for wildcard
    tool_name   TEXT NOT NULL,             -- exact tool name
    action      TEXT NOT NULL CHECK(action IN ('allow', 'deny')),
    scope       TEXT NOT NULL CHECK(scope IN ('session', 'permanent')),
    reason      TEXT NOT NULL DEFAULT '',
    created_at  INTEGER NOT NULL,
    expires_at  INTEGER                    -- NULL for permanent
);
CREATE INDEX IF NOT EXISTS idx_permission_rules_lookup
    ON permission_rules(agent_id, tool_name);
```

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build` succeeds

---

### Step 2: Add `permission_rules.rs` store module

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 1

Create `src/store/permission_rules.rs` following the `policy_events.rs` pattern:

```rust
use super::StoreResult;
use rusqlite::Connection;

pub struct PermissionRule {
    pub rule_id: String,
    pub agent_id: String,
    pub tool_name: String,
    pub action: String,   // "allow" | "deny"
    pub scope: String,    // "session" | "permanent"
    pub reason: String,
    pub created_at: i64,
    pub expires_at: Option<i64>,
}

/// Look up the first matching rule for (agent_id, tool_name).
/// Checks exact agent match before wildcard '*'.
pub fn lookup_rule(
    conn: &Connection,
    agent_id: &str,
    tool_name: &str,
    now_ms: i64,
) -> StoreResult<Option<PermissionRule>> {
    let mut stmt = conn.prepare(
        "SELECT rule_id, agent_id, tool_name, action, scope, reason, created_at, expires_at
         FROM permission_rules
         WHERE (agent_id = ?1 OR agent_id = '*')
           AND tool_name = ?2
           AND (expires_at IS NULL OR expires_at > ?3)
         ORDER BY agent_id DESC  -- exact match before wildcard
         LIMIT 1"
    )?;
    let result = stmt.query_row(
        rusqlite::params![agent_id, tool_name, now_ms],
        |row| Ok(PermissionRule {
            rule_id: row.get(0)?,
            agent_id: row.get(1)?,
            tool_name: row.get(2)?,
            action: row.get(3)?,
            scope: row.get(4)?,
            reason: row.get(5)?,
            created_at: row.get(6)?,
            expires_at: row.get(7)?,
        }),
    );
    match result {
        Ok(rule) => Ok(Some(rule)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e.into()),
    }
}

pub fn upsert_rule(conn: &Connection, rule: &PermissionRule) -> StoreResult<()> {
    conn.execute(
        "INSERT OR REPLACE INTO permission_rules
             (rule_id, agent_id, tool_name, action, scope, reason, created_at, expires_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
        rusqlite::params![
            rule.rule_id, rule.agent_id, rule.tool_name,
            rule.action, rule.scope, rule.reason,
            rule.created_at, rule.expires_at,
        ],
    )?;
    Ok(())
}
```

Add `mod permission_rules; pub use permission_rules::{PermissionRule, lookup_rule, upsert_rule};` to `src/store/mod.rs`.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build` succeeds

---

### Step 3: Add `PermissionRuleStore` trait

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 2

In `src/store/traits.rs`, add a `PermissionRuleStore` trait alongside the existing `PolicyEventStore`:

```rust
pub trait PermissionRuleStore {
    /// Look up a persisted permission rule for this (agent, tool) pair.
    fn lookup_permission_rule(&self, agent_id: &str, tool_name: &str) -> StoreResult<Option<PermissionRule>>;
    /// Persist an allow or deny rule.
    fn upsert_permission_rule(&self, rule: &PermissionRule) -> StoreResult<()>;
}
```

Add the blanket impl for `Store`:
```rust
impl PermissionRuleStore for Store {
    fn lookup_permission_rule(&self, agent_id: &str, tool_name: &str) -> StoreResult<Option<PermissionRule>> {
        let now_ms = now_ms();
        crate::store::lookup_rule(&self.conn, agent_id, tool_name, now_ms)
    }
    fn upsert_permission_rule(&self, rule: &PermissionRule) -> StoreResult<()> {
        crate::store::upsert_rule(&self.conn, rule)
    }
}
```

Add `PermissionRuleStore` to the `CanopyStore` supertrait bound.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build` succeeds
- [ ] `CanopyStore` now includes both `PolicyEventStore` and `PermissionRuleStore`

---

### Step 4: Extend dispatch policy to consult persisted rules

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 3

In `src/tools/mod.rs`, before the existing `store.log_policy_event(...)` call, add a persisted-rule check:

```rust
// Check persisted permission rules first.
let persisted_decision = match store.lookup_permission_rule(agent_id, name) {
    Ok(Some(rule)) if rule.action == "allow" => Some(DispatchDecision::Proceed),
    Ok(Some(rule)) if rule.action == "deny" => Some(DispatchDecision::FlagForReview {
        reason: format!("permission rule denied: {}", rule.reason),
    }),
    Ok(_) => None,  // no rule — fall through to static policy
    Err(e) => {
        tracing::warn!(error = %e, tool = name, "failed to read permission rules");
        None  // fail open: treat rule lookup failure as no rule
    }
};

let decision = persisted_decision.unwrap_or_else(|| {
    let annotations = policy::annotations_for_tool(name);
    policy::DispatchPolicy::Default.evaluate(name, annotations)
});

// Log and dispatch as before...
```

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build` succeeds with no unused-variable warnings
- [ ] Persisted-rule path fails open on DB error (logs warn, falls to static policy)

---

### Step 5: Add unit tests

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 4

Add `#[cfg(test)]` block to `src/store/permission_rules.rs`:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use rusqlite::Connection;

    fn setup() -> Connection {
        let conn = Connection::open_in_memory().unwrap();
        conn.execute_batch(
            "CREATE TABLE permission_rules (
                rule_id TEXT PRIMARY KEY, agent_id TEXT NOT NULL,
                tool_name TEXT NOT NULL, action TEXT NOT NULL,
                scope TEXT NOT NULL, reason TEXT NOT NULL DEFAULT '',
                created_at INTEGER NOT NULL, expires_at INTEGER
            );
            CREATE INDEX idx_permission_rules_lookup ON permission_rules(agent_id, tool_name);"
        ).unwrap();
        conn
    }

    #[test]
    fn lookup_returns_none_when_no_rule() {
        let conn = setup();
        let result = lookup_rule(&conn, "agent-1", "tool_x", 1_000_000).unwrap();
        assert!(result.is_none());
    }

    #[test]
    fn upsert_and_lookup_allow_rule() {
        let conn = setup();
        upsert_rule(&conn, &PermissionRule {
            rule_id: "01HTEST".into(),
            agent_id: "agent-1".into(),
            tool_name: "canopy_task_delete".into(),
            action: "allow".into(),
            scope: "permanent".into(),
            reason: "approved by operator".into(),
            created_at: 1_000_000,
            expires_at: None,
        }).unwrap();
        let rule = lookup_rule(&conn, "agent-1", "canopy_task_delete", 1_000_001).unwrap();
        assert!(rule.is_some());
        assert_eq!(rule.unwrap().action, "allow");
    }

    #[test]
    fn wildcard_agent_matches_any() {
        let conn = setup();
        upsert_rule(&conn, &PermissionRule {
            rule_id: "01HWILD".into(),
            agent_id: "*".into(),
            tool_name: "canopy_task_list".into(),
            action: "allow".into(),
            scope: "permanent".into(),
            reason: "".into(),
            created_at: 1_000_000,
            expires_at: None,
        }).unwrap();
        let rule = lookup_rule(&conn, "any-agent", "canopy_task_list", 1_000_001).unwrap();
        assert!(rule.is_some());
    }

    #[test]
    fn expired_rule_not_returned() {
        let conn = setup();
        upsert_rule(&conn, &PermissionRule {
            rule_id: "01HEXP".into(),
            agent_id: "agent-1".into(),
            tool_name: "canopy_task_delete".into(),
            action: "allow".into(),
            scope: "session".into(),
            reason: "".into(),
            created_at: 1_000_000,
            expires_at: Some(1_000_001),  // already expired at ts 1_000_002
        }).unwrap();
        let rule = lookup_rule(&conn, "agent-1", "canopy_task_delete", 1_000_002).unwrap();
        assert!(rule.is_none());
    }
}
```

#### Verification

```bash
cd canopy && cargo test permission_rule 2>&1
```

**Checklist:**
- [ ] All 4 tests pass
- [ ] No compilation errors

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

**Checklist:**
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The full test suite passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

## Context

Spawned from the forgecode Wave 1 re-audit (2026-04-23). The policy_events table (U4b) is the prerequisite — this table sits alongside it and enables rule-based dispatch without the static-only limitation. Future work: cap surfaces for creating and managing rules; septa contract for rule serialization if other tools need to read them.
