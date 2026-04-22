# Phase 5 Pass 2 — Inter-Tool Interaction Deep Review

Date: 2026-04-22
Pass: Deep Review (agent-driven)

## Summary

Phase 5 Pass 1 verdict (FAIR) confirmed. Six critical gaps investigated; most are real but narrow. Key refinement: the async hook signal loss (rated FRAGILE in P1) is actually PARTIAL — the SessionEnd hook is synchronous, meaning signals are preserved on normal exit. Cap→Canopy FRAGILE confirmed, but a trivial fix (wrap with existing `cachedAsync()` helper) would move it to PARTIAL. One new issue found: cortina has no internal timeout on its hyphae subprocess write.

---

## Triage Results

### Task 1: Cap→Canopy FRAGILE — Confirmed with quick mitigation path

**Code evidence:**
- `cap/server/routes/canopy.ts:18-43` — snapshot endpoint calls `canopy.getSnapshot()` with no caching layer
- `cap/server/canopy.ts:171-204` — `getSnapshot()` reads directly from CLI, no fallback
- `cap/server/lib/cache.ts:12-31` — `cachedAsync<T>()` helper exists but is NOT used on snapshot

**Findings:**
1. Dashboard returns HTTP 500 (not blank crash; React shows error boundary page) but completely unusable for operators
2. Cache utility is already in the codebase but not wired to the snapshot endpoint
3. Wrapping `getSnapshot()` with `cachedAsync(60)` would make dashboard serve stale data for up to 60 seconds on canopy downtime — trivial 2-line change

**Verdict:** FRAGILE confirmed. Mitigation exists and is trivial — cache utility already written.

---

### Task 2: Session state orphaning — Reuse path confirmed

**Code evidence:**
- `cortina/src/utils/session_scope.rs:270-281` — when `hyphae session end` fails, `fs::remove_file()` only executes on success (line 288)
- `cortina/src/utils/session_scope.rs:155-172` — on next session start, existing state file is loaded; `match_active_session()` called for liveness; if liveness fails (hyphae unavailable), new session created but stale file persists

**Conditions for orphaning:**
1. Session 1: hyphae works, session created, state file written
2. Session 1 ends: `hyphae session end` fails → state file persists
3. Session 2 starts in same worktree: stale file found, liveness check returns None (hyphae still down) → new session created, stale file persists on disk indefinitely

**Impact in practice:** Narrow window — requires hyphae to fail exactly during session-end write. Multi-worktree setups are most vulnerable since each worktree maintains its own state file.

**Verdict:** PARTIAL confirmed (P1 was correct). Fix: delete state file on session-end failure.

---

### Task 3: Async hook execution — Stop/SessionEnd are SYNCHRONOUS

**Code evidence from `lamella/resources/hooks/hooks.json`:**
- Line 177 (PostToolUse): `"async": true` — cortina write runs in background
- Line 86 (UserPromptSubmit): `"async": true` — cortina write runs in background
- Line 219 (Stop): NO `"async"` field → defaults to synchronous
- Line 245 (SessionEnd): NO `"async"` field → synchronous; comment: "must complete before exit"

**Revised assessment:** P1 rated this FRAGILE. Signal loss is actually bounded to crash scenarios only. On normal session exit (user Ctrl-C, timeout), SessionEnd fires synchronously — signals always persisted.

**Verdict:** DOWNGRADED from FRAGILE to PARTIAL. Signal loss only on process crash, which is unavoidable by design in any hook system.

---

### Task 4: Volva timeouts — Confirmed values, no user warning

**Code evidence from `volva/crates/volva-runtime/src/context.rs`:**
- Line 21: `const MEMORY_PROTOCOL_TIMEOUT: Duration = Duration::from_millis(250);`
- Line 23: `const SESSION_RECALL_TIMEOUT: Duration = Duration::from_millis(500);`
- Line 205: Timeout fires, child killed, `None` returned — no warning logged
- Line 262: Same pattern for session recall — silent `None`
- Lines 200, 257: `warn!()` only on `try_wait()` error, not on timeout

**Config options:** Timeouts are hardcoded constants; no environment variable to override.

**Verdict:** CONFIRMED. Values are as reported. Warning is missing on timeout — user unaware of context loss. Fix: add `tracing::warn!("volva: hyphae protocol timeout after {}ms", MEMORY_PROTOCOL_TIMEOUT.as_millis())`.

---

### Task 5: Hyphae unseamed responses — Low practical risk

**Code evidence:**
- `hyphae/crates/hyphae-mcp/src/memory_protocol.rs:40-92` — `MemoryProtocolSurface` struct with `schema_version: "1.0"`, `recall`, `store`, `resources` fields
- `volva/crates/volva-runtime/src/context.rs:123-151` — volva defines same-named struct; deserializes at line 195 via `serde_json::from_str::<MemoryProtocolSurface>(stdout.trim()).ok()?`
- No `hyphae-protocol-v1.schema.json` or `hyphae-session-context-v1.schema.json` in septa (checked all 47 schemas)
- Session recall returned as human-readable text — no formal schema

**Drift behavior:**
- Added required field: volva deserialization silently fails → `None` → context loss, not crash
- Removed field: serde skips silently → incomplete protocol block → degraded context

**Practical risk:** LOW — both tools evolve in the same repo. Risk increases if tools are ever split into separate repos or versioned independently.

**Verdict:** CONFIRMED unseamed. Low urgency but real gap.

---

### Task 6: Uncaught error paths — Cortina subprocess hang risk

**Code evidence:**
- `rhizome/crates/rhizome-core/src/hyphae.rs:88` — `with_timeout(Duration::from_secs(10))` on hyphae subprocess ✅
- `cortina/src/utils/session_scope.rs:270` — `Command::output()` with NO internal subprocess timeout ❌

**Finding:** Cortina relies entirely on the lamella hook-level 10s timeout (hooks.json line 219) to kill it if hyphae hangs. But if the hook timeout kills cortina while the subprocess is still running, the state file is not cleaned up — increasing the orphaning risk.

**NEW ISSUE:** Cortina should add an internal 5s timeout on its hyphae write, independent of the hook timeout, so it can clean up state before the hook kills the process.

---

## Confirmed Critical Issues (from Pass 1, confirmed with code evidence)

| Issue | P1 Severity | P2 Confirmed? | Evidence |
|-------|------------|--------------|---------|
| Cap→canopy FRAGILE | High | YES | `cache.ts` helper unused; no fallback in `canopy.ts` |
| Session state orphaning | Medium | YES | `session_scope.rs:280-288` only removes on success |
| Hyphae protocol unseamed | Medium | YES | No septa schemas for `MemoryProtocolSurface` |
| Volva timeouts silent | Medium | YES | No `warn!()` on timeout at lines 205, 262 |
| Async hook signal loss | Medium | DOWNGRADED to PARTIAL | Stop/SessionEnd are synchronous |
| Hook envelope unseamed | Medium | CONFIRMED but LOW urgency | Informal JSON; only matters on Claude Code version bumps |

---

## Downgraded Issues

**Async hook signal loss (P1: FRAGILE → P2: PARTIAL)**
- SessionEnd hook is synchronous — signals preserved on all normal exits
- Loss window is only crash/SIGKILL, which is unavoidable
- No code change needed; behavior is correct

---

## New Issues Found

**Cortina hyphae write no internal timeout (NEW, Medium)**
- `cortina/src/utils/session_scope.rs:270` — `Command::output()` no timeout
- If hyphae hangs, cortina blocks until hook timeout kills it
- State file not cleaned on force-kill → orphaning risk amplified
- Fix: `Command::output_timeout(Duration::from_secs(5))` or tokio::timeout wrapper

**Cap error swallows root cause (NEW, Low)**
- `cap/server/routes/canopy.ts:40-41` catches error and returns `{ error: 'Failed to get Canopy snapshot' }`
- Actual error from canopy CLI lost (e.g., "database locked", "permission denied")
- Fix: Include `err.message` in response for operator diagnostics

---

## Revised Seam Summary

| Seam | P1 Assessment | P2 Verdict | Fix Difficulty |
|------|--------------|------------|----------------|
| cortina→hyphae→canopy | PARTIAL | PARTIAL | Low: cleanup on failure, cortina timeout |
| canopy→cap | FRAGILE | FRAGILE (trivially fixable) | Low: wrap with cachedAsync(60) |
| hyphae session-start | PARTIAL | PARTIAL | None needed |
| lamella→cortina hooks | FRAGILE | PARTIAL (downgraded) | None: SessionEnd is synchronous |
| rhizome→hyphae export | GRACEFUL | GRACEFUL | None |
| volva→cortina→hyphae | PARTIAL | PARTIAL | Low: add warn! on timeout |

---

## Overall Verdict: FAIR (unchanged)

**Verdict remains FAIR**, with a clearer action list.

The three small fixes below would move all PARTIAL seams toward GRACEFUL and eliminate the FRAGILE seam:

### Priority fixes

1. **Cap snapshot cache** — `cachedAsync(60)` wrapper on `getSnapshot()` (2 lines)
   - Moves canopy→cap from FRAGILE to PARTIAL
   - Impact: dashboard resilient to brief canopy downtime

2. **Cortina state cleanup on failure** — delete state file if `hyphae session end` fails
   - Eliminates session orphaning condition
   - Impact: worktree session IDs stay clean under degraded hyphae

3. **Cortina subprocess timeout** — add 5s internal timeout on hyphae write
   - New issue found in Pass 2
   - Impact: cortina can self-clean before hook timeout kills it

4. **Volva timeout warning** — log `warn!()` when context injection times out
   - Impact: operators see "hyphae was slow" in session output instead of silent context loss

5. **Septa schemas for hyphae protocol** — create `hyphae-protocol-v1.schema.json` and `hyphae-session-context-v1.schema.json`
   - Impact: shape drift is detectable via `septa/validate-all.sh`

6. **Cap error message passthrough** — include `err.message` in 500 response body
   - Low effort, high diagnostic value
