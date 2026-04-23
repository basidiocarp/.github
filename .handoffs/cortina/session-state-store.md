# Cortina: Session State Store

## ⚠ STOP — READ BEFORE STARTING ANYTHING

This handoff requires a design decision before any implementation begins. Do not write code, modify files, or spawn subagents until the question in the "Decision Required" section has been answered by the human engineer.

Read this entire handoff, then ask the questions in "Decision Required." Implementation starts only after the human has chosen an approach.

---

## Handoff Metadata

- **Dispatch:** `umbrella — do not send to implementer directly`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/utils/session_scope.rs` and any new session state module
- **Cross-repo edits:** none
- **Non-goals:** changing how hyphae stores memories; changing hook behavior; changing cortina's capture logic — only the session state persistence layer
- **Verification contract:** a session that ends with a hyphae write failure does not leave a stale state file; the next session in the same worktree starts with a clean session ID
- **Completion update:** update dashboard after decision is made and implementation is verified

## Context

Phase 5 Pass 2 confirmed a session state orphaning bug in cortina:

- When `hyphae session end` fails (disk full, locked DB, hyphae unavailable), `cortina/src/utils/session_scope.rs:288` only calls `fs::remove_file()` on success — the state file persists on disk if the hyphae write fails.
- On the next session start in the same worktree, the stale file is found; a liveness check is attempted; if hyphae is still unavailable, a new session is created but the stale file persists indefinitely.
- Under multi-worktree setups, multiple stale files can accumulate, and session identity tracking becomes unreliable.

Root cause: the current model uses the filesystem as a state store with no TTL, no transactional semantics, and cleanup only on success — not on failure.

Audit findings: `.handoffs/campaigns/ecosystem-health-audit/phase5-interaction/findings-p2.md` (Task 2)

---

## Decision Required

Before any implementation, the human engineer must choose **one** of the following approaches. Each changes the fundamental model of how cortina tracks session state.

---

### Option A: Minimal fix — clean up state file on failure (lowest risk)

**What it does:** Adds state file deletion to the failure path in `session_scope.rs:280-288`. If `hyphae session end` fails, the state file is deleted before returning.

**How it works:**
```rust
// session_scope.rs — current (broken):
match hyphae_session_end(session_id) {
    Ok(()) => { let _ = fs::remove_file(&state_path); }
    Err(e) => { tracing::warn!("cortina: session end failed: {e}"); } // stale file remains
}

// Fixed:
match hyphae_session_end(session_id) {
    Ok(()) => { let _ = fs::remove_file(&state_path); }
    Err(e) => {
        tracing::warn!("cortina: session end failed: {e} — cleaning up state file");
        let _ = fs::remove_file(&state_path); // clean up regardless
    }
}
```

**Tradeoffs:**
- ✅ Minimal change — 3 lines of code
- ✅ Fixes the specific orphaning bug
- ✅ No new dependencies or infrastructure
- ❌ Doesn't change the underlying model — state file is still the store, still no TTL
- ❌ A crash (SIGKILL) before cleanup still leaves a stale file
- ❌ Doesn't prevent future similar bugs in adjacent code

**When to pick this:** You want the narrowest safe fix with minimal risk. Accept that crash-recovery is a future concern.

---

### Option B: TTL-based state file expiry

**What it does:** The session state file includes a `created_at` or `last_seen_at` timestamp. On session start, if an existing state file is found but its timestamp is older than a configurable TTL (e.g., 24 hours), it is treated as stale and replaced.

**How it works:**
```rust
#[derive(Serialize, Deserialize)]
struct SessionState {
    session_id: String,
    worktree: PathBuf,
    created_at: DateTime<Utc>,
    last_seen_at: DateTime<Utc>,  // new field
}

// On session start, if state file found:
if state.last_seen_at < Utc::now() - Duration::hours(24) {
    tracing::warn!("cortina: session state file is stale (>24h), replacing");
    // create new session
}
```

Cortina would update `last_seen_at` periodically (e.g., on each hook fire) so active sessions don't expire.

**Tradeoffs:**
- ✅ Survives crashes — stale state files self-expire within the TTL window
- ✅ Makes "what is an active session?" answerable without querying hyphae
- ✅ No new dependencies
- ❌ TTL window (24h) is a judgment call — too short causes false expiry, too long allows long-lived orphans
- ❌ Requires updating `last_seen_at` on each hook, which adds overhead
- ❌ More code than Option A (~50 lines vs. 3 lines)
- ❌ Clock skew between sessions (unlikely on single machine but possible with sleep/hibernate)

**When to pick this:** You want a self-healing model that doesn't require hyphae to be available for session cleanup, and you're willing to pick a reasonable TTL.

---

### Option C: SQLite-backed session state store

**What it does:** Replaces the file-based session state with a SQLite table in a cortina-owned database. Session entries have a `session_id`, `worktree`, `status` (`active`/`ended`/`orphaned`), and `last_seen_at`. Cortina marks sessions as `ended` on clean shutdown; an age-based query identifies orphans.

**How it works:**
```sql
CREATE TABLE IF NOT EXISTS sessions (
    session_id TEXT PRIMARY KEY,
    worktree   TEXT NOT NULL,
    status     TEXT NOT NULL DEFAULT 'active',  -- 'active', 'ended', 'orphaned'
    created_at TEXT NOT NULL,
    last_seen_at TEXT NOT NULL
);
```

```rust
// On session start:
// - Query for active sessions in this worktree
// - Sessions with last_seen_at > 24h ago are marked 'orphaned'
// - Create new 'active' session

// On session end (success):
// - UPDATE status = 'ended' WHERE session_id = ?

// On session end (failure):
// - UPDATE status = 'orphaned' WHERE session_id = ?
```

**Tradeoffs:**
- ✅ Rich query model — "list all sessions in this worktree," "show orphaned sessions"
- ✅ Transactional — status update is atomic even on partial failure
- ✅ Historical record of sessions (useful for debugging)
- ✅ Consistent with ecosystem pattern (hyphae, canopy already use SQLite)
- ❌ cortina CLAUDE.md says "does not own long-term memory (hyphae does)" — a session DB is borderline
- ❌ Significantly more code than Options A or B
- ❌ cortina Cargo.toml already has `rusqlite` declared but currently appears unused — would actually use it
- ❌ New schema = new migration concern if the schema needs to change

**When to pick this:** You want the full picture — historical sessions, operator visibility into orphaned state, and a model that matches the rest of the ecosystem. Accept higher implementation effort and the semantic question of whether session state is "memory" (hyphae's domain) or "operational state" (cortina's domain).

---

### Option D: In-memory only (no persistence)

**What it does:** Removes the state file entirely. Cortina tracks session state only in memory for the duration of the process. If cortina restarts, the session state is gone — the next hook that fires starts a new session.

**Tradeoffs:**
- ✅ Eliminates the stale file bug by eliminating files
- ✅ Simplest implementation
- ❌ Cortina restarts (e.g., during stipe update, crash recovery) lose session identity — hyphae gets orphaned sessions without knowing it
- ❌ Multi-session worktree setups lose continuity across restarts
- ❌ Moves the problem to hyphae (orphaned sessions with no cortina-side cleanup)

**When to pick this:** Only if you're willing to accept session identity being lost on any cortina process restart and are confident that's acceptable for your usage pattern.

---

## Questions for the Human Engineer

Before implementation starts, answer:

1. **Which option?** (A, B, C, or D)
2. **Is crash recovery (SIGKILL, power loss) a real concern?** If yes, Option A is insufficient and B or C is needed.
3. **Do you want an operator view of historical/orphaned sessions?** If yes, Option C is the only one that provides it.
4. **Is the `rusqlite` dependency in cortina Cargo.toml actually intentional?** If cortina was planning to use SQLite anyway, Option C fits naturally.
5. **Does "session state" belong to cortina or hyphae?** If it belongs to hyphae, should cortina call `hyphae session-create` at start and `hyphae session-update` at end, delegating all persistence to hyphae?

---

## Implementation Seam (after decision)

- **Likely repo:** `cortina`
- **Likely files:** `cortina/src/utils/session_scope.rs` (all options); optionally a new `cortina/src/utils/session_store.rs` for Options B/C
- **Reference seams:** if Option C, read how canopy uses rusqlite before writing cortina's schema
- **Spawn gate:** do not spawn implementer until the human has answered the decision questions above

---

## Verification (after implementation)

```bash
# Simulate hyphae session-end failure:
cd cortina && cargo test session
# Should demonstrate: stale file not present after failed session end (Options A/B/C)
# Should demonstrate: next session gets new ID (all options)

cd cortina && cargo test && cargo clippy -- -D warnings
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `hyphae session end` failure leaves no stale state
- [ ] Next session in same worktree gets a fresh session ID
- [ ] No new clippy warnings
- [ ] `cargo test` passes

## Completion Protocol

1. Decision questions answered by human
2. Implementation matches chosen option
3. Tests added for failure-mode scenarios
4. Dashboard updated
