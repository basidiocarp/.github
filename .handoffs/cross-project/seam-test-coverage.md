# Seam and Fix-Target Test Coverage

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** cross-project (tests added in each owning repo)
- **Allowed write scope:** `tests/` and `src/` test modules in each named repo below
- **Cross-repo edits:** yes — tests added wherever the seam lives
- **Non-goals:** fixing the bugs themselves; changing production code paths; rewriting existing tests
- **Verification contract:** `cargo test` passes in each touched repo; new tests cover the named seam failure modes
- **Completion update:** once all named seam and fix-target tests are green, update `.handoffs/HANDOFFS.md` and archive

## Context

The Phase 4 Bug Audit confirmed zero production panics and solid input validation — but it did not audit *whether* the six integration seams and 16 known-issue fix targets have regression coverage. Without tests on these paths, fixes may regress silently and the fragile seams (cap→canopy FRAGILE, cortina session state orphaning) have no safety net.

The audit findings file for reference:
- Phase 5 P1: `.handoffs/campaigns/ecosystem-health-audit/phase5-interaction/findings-p1.md`
- Phase 5 P2: `.handoffs/campaigns/ecosystem-health-audit/phase5-interaction/findings-p2.md`

## Implementation Seam

- **Likely repos:** cortina, hyphae, canopy, cap (server), volva
- **Likely files:** existing `tests/` directories and `#[cfg(test)]` modules in each
- **Reference seams:** existing test patterns in each repo — match local conventions exactly
- **Spawn gate:** do not spawn an implementer until you have read the existing test structure in the target repo and can name exactly which test module each new test belongs in

## Problem

The six integration seams identified in Phase 5 have no known regression tests for their failure modes. The highest-risk paths (cortina session-end failure → stale state file, cap 500 on canopy downtime, volva silent timeout) are currently exercised only by manual audit, not by automated tests. Future fixes could reintroduce these bugs without detection.

## What needs doing (intent)

Add regression tests for the six seam failure modes and the highest-priority fix targets. Tests should exercise the actual failure condition, not just the happy path.

## Scope

- **Primary seam:** test coverage of the six integration seams and top-8 fix items from the audit
- **Allowed files:** test modules in cortina, hyphae, canopy, cap/server, volva
- **Explicit non-goals:** production code changes; new features; rewriting passing tests

---

### Step 1: Coverage audit — what exists for each seam today

**Project:** all named repos
**Effort:** 1-2 hours
**Depends on:** nothing

Before writing new tests, read the existing test suite in each repo and document what seam behavior is already covered vs. not.

For each seam, answer:
- Is the happy path tested?
- Is the primary failure mode (hyphae unavailable, canopy down, session-end failure) tested?
- What is the test entry point (integration test, unit test, or no test)?

Seams to audit:
1. cortina session-end failure → stale state file
2. cap → canopy unavailable → HTTP 500
3. hyphae session-start → no memories → empty context
4. lamella hook → cortina unavailable → silent skip
5. rhizome export → hyphae locked → error returned
6. volva → hyphae timeout → None returned silently

#### Verification

```bash
cd cortina && cargo test -- --list 2>&1 | grep -i session
cd ../hyphae && cargo test -- --list 2>&1 | grep -i session
cd ../canopy && cargo test -- --list 2>&1 | grep -i snapshot
cd ../cap && npm test -- --listTests 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Coverage gap map produced for all 6 seams
- [ ] At least 4 of 6 seams have no failure-mode tests (expected finding)

---

### Step 2: cortina session state — add failure-mode tests

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** Step 1 (confirms gap)

Add tests for:
- Session-end failure leaves stale file (verify stale file exists after simulated hyphae failure)
- Next session-start with stale file creates new session (not reuse)
- State file is cleaned up when `hyphae session end` succeeds

Location: `cortina/src/utils/session_scope.rs` test module or `cortina/tests/session_lifecycle.rs`

#### Verification

```bash
cd cortina && cargo test session
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Test covers session-end failure → stale file scenario
- [ ] Test covers next-session-start with stale file
- [ ] All cortina tests pass

---

### Step 3: cap server — add canopy unavailability tests

**Project:** `cap/`
**Effort:** 1-2 hours
**Depends on:** Step 1 (confirms gap)

Add tests to cap's server test suite for:
- Snapshot endpoint returns 500 (or stale cache after cache is added) when canopy CLI not found
- Snapshot endpoint returns informative error body (not generic message after fix #16)
- Snapshot with missing `drift_signals` field is handled gracefully

Location: `cap/server/__tests__/canopy.test.ts` or equivalent

#### Verification

```bash
cd cap && npm test -- --testPathPattern canopy
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Test covers canopy unavailable scenario
- [ ] Test covers snapshot missing drift_signals field
- [ ] All cap server tests pass

---

### Step 4: volva — add timeout tests

**Project:** `volva/`
**Effort:** 1-2 hours
**Depends on:** Step 1 (confirms gap)

Add tests for:
- `load_memory_protocol_block()` returns `None` when subprocess times out
- Warning is logged when timeout occurs (after fix #14)
- `load_session_recall_block()` returns `None` on timeout without panicking

Location: `volva/crates/volva-runtime/src/context.rs` test module or `volva/crates/volva-runtime/tests/`

#### Verification

```bash
cd volva && cargo test context
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Timeout test exists for memory protocol block
- [ ] Timeout test exists for session recall block
- [ ] No panics on timeout path

---

### Step 5: hyphae — add session-start empty-context test

**Project:** `hyphae/`
**Effort:** 1 hour
**Depends on:** Step 1

Add test for:
- Session-start with empty memory store returns valid (empty) context, not error
- Malformed memory record is skipped, not panicked

Location: `hyphae/crates/hyphae-mcp/src/` test module or `hyphae/tests/`

#### Verification

```bash
cd hyphae && cargo test session
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Empty memory store → empty context (not error)
- [ ] Malformed memory → skipped, session continues

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Coverage gap map from Step 1 is documented
2. Failure-mode tests exist for all 6 seams
3. All new tests are green in their owning repo
4. No production code was changed (tests only)
5. Dashboard updated

### Final Verification

```bash
bash .handoffs/cross-project/verify-seam-test-coverage.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
