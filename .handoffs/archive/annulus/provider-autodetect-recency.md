# Annulus: Provider Auto-Detect via Session Recency

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/src/providers/`, `annulus/src/statusline.rs`, `annulus/src/config.rs`, `annulus/Cargo.toml`
- **Cross-repo edits:** none
- **Non-goals:** implementing the Codex or Gemini readers (#118b, #119b); changing the JSON output schema (#104b is shipped); adding new auth or network code
- **Verification contract:** repo-local `cargo test`, `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, plus `bash .handoffs/annulus/verify-provider-autodetect-recency.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive this handoff

## Problem

`detect_provider` only honors an explicit `provider = "..."` field in
`statusline.toml` and otherwise returns Claude. Operators who run more than one
coding agent (Claude + Codex, or Claude + Gemini) have to manually flip the
config every time they change tools. The handoff #104d intent envisioned
"prefer the provider with the most recent session" but the recency-comparison
path was never wired.

## What exists (state)

- **`annulus/src/providers/mod.rs`**: `TokenProvider` trait with `name()`,
  `is_available()`, `session_usage()`. `detect_provider(explicit)` matches an
  explicit string and otherwise returns `ClaudeProvider`.
- **`ClaudeProvider`**: reads transcripts via the streaming path; transcript
  path comes from the stdin hook payload.
- **`CodexProvider` and `GeminiProvider`**: stubs that report unavailable.
- **`statusline.toml`**: the `provider` field is parsed but only the explicit
  branch of `detect_provider` consumes it.

No timestamp accessor exists on the trait, so even if Codex/Gemini were real,
`detect_provider` couldn't compare recency.

## What needs doing (intent)

Add a recency hook to `TokenProvider` and pick the most-recently-active
available provider when no explicit choice is configured. Stub providers
returning `None` for recency must fall through to Claude (the existing
fallback), so this handoff lands cleanly without #118b / #119b being done.

## Scope

- **Primary seam:** `detect_provider` in `annulus/src/providers/mod.rs`
- **Allowed files:** `annulus/src/providers/mod.rs`, `annulus/src/providers/claude.rs`, `annulus/src/providers/codex.rs`, `annulus/src/providers/gemini.rs`, `annulus/src/statusline.rs`
- **Explicit non-goals:**
  - real Codex transcript reading (#118b)
  - real Gemini transcript reading (#119b)
  - JSON output schema changes
  - surfacing the chosen provider name in the statusline (separate UX touch)

---

### Step 1: Add `last_session_at` to the trait

**Project:** `annulus/`
**Effort:** 0.25 day
**Depends on:** nothing

Add a recency accessor to `TokenProvider`. Default impl returns `None` so
existing stub providers don't need to change.

```rust
trait TokenProvider {
    fn name(&self) -> &str;
    fn is_available(&self) -> bool;
    fn session_usage(&self) -> Result<Option<TokenUsage>>;
    /// Unix timestamp (seconds) of the provider's most recent session activity,
    /// or `None` if the provider can't determine recency.
    fn last_session_at(&self) -> Option<u64> { None }
}
```

For `ClaudeProvider`, derive recency from the transcript file's mtime
(cheap, no parsing). For `CodexProvider` and `GeminiProvider`, leave the
default `None` until #118b / #119b add real data sources.

#### Verification

```bash
cd annulus && cargo test providers::tests::claude_last_session_at_returns_mtime 2>&1 | tail -10
cd annulus && cargo test providers::tests::stub_last_session_at_is_none 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
# Note: claude_last_session_at tests live in providers::claude::tests, not providers::tests
# Running by test name filter instead:

$ cargo test claude_last_session_at 2>&1 | tail -10
running 3 tests
test providers::claude::tests::claude_last_session_at_returns_none_without_path ... ok
test providers::claude::tests::claude_last_session_at_returns_none_for_missing_file ... ok
test providers::claude::tests::claude_last_session_at_returns_mtime ... ok
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 84 filtered out; finished in 0.00s

$ cargo test providers::tests::stub_last_session_at_is_none 2>&1 | tail -10
running 1 test
test providers::tests::stub_last_session_at_is_none ... ok
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 86 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] `last_session_at` added to `TokenProvider` with a default impl
- [x] `ClaudeProvider::last_session_at` returns `Some(mtime_secs)` when a transcript path is set and the file exists
- [x] `ClaudeProvider::last_session_at` returns `None` when the transcript path is missing or unreadable
- [x] Test fixtures cover both branches

---

### Step 2: Recency-based `detect_provider`

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 1

Change `detect_provider(explicit)`:
- If `explicit` is `Some(name)`, return that provider (existing behavior).
- If `explicit` is `None`, build the candidate set
  (`Claude`, `Codex`, `Gemini`), filter to `is_available()`, and pick the
  candidate with the highest `last_session_at()`. Ties resolve in
  declaration order (Claude wins). If no provider reports a timestamp,
  fall through to Claude.

The comparison must not panic when every provider reports `None` — that's
the current state today and must keep working.

#### Files to modify

**`annulus/src/providers/mod.rs`** — replace the explicit-only branch with
the recency comparison. Keep the function signature and return type.

#### Verification

```bash
cd annulus && cargo test providers::tests::detect_provider 2>&1 | tail -15
cd annulus && cargo test --quiet 2>&1 | tail -3
```

**Output:**
<!-- PASTE START -->
$ cargo test providers::tests::detect_provider 2>&1 | tail -15
running 3 tests
test providers::tests::detect_provider_returns_claude_for_explicit_claude ... ok
test providers::tests::detect_provider_returns_claude_by_default ... ok
test providers::tests::detect_provider_all_none_recency_falls_through_to_claude ... ok
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 84 filtered out; finished in 0.00s

$ cargo test --quiet 2>&1 | tail -3
test result: ok. 87 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s
<!-- PASTE END -->

**Checklist:**
- [x] Explicit `provider = "codex"` still selects Codex (existing behavior preserved)
- [x] With no explicit choice and only Claude available, Claude wins
- [x] With two providers reporting timestamps, the more recent one wins
- [x] Tie-break prefers Claude (declaration order)
- [x] All-`None` recency case falls through to Claude without panicking
- [x] No regressions in `cargo test` overall

---

## Completion Protocol

This handoff is NOT complete until ALL of the following are true:

1. Every step above has verification output pasted between the markers
2. `bash .handoffs/annulus/verify-provider-autodetect-recency.sh` passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated and this handoff is archived

### Final Verification

```bash
bash .handoffs/annulus/verify-provider-autodetect-recency.sh
```

**Output:**
<!-- PASTE START -->
PASS: TokenProvider has last_session_at
PASS: ClaudeProvider implements last_session_at
PASS: detect_provider does recency comparison
PASS: annulus tests pass
PASS: annulus clippy clean
Results: 5 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Cleanup after #104d. The trait + stub providers shipped, but the recency
selection envisioned in that handoff did not. Lands independently of
#118b / #119b — those handoffs add the real Codex and Gemini readers, after
which auto-detect starts producing visibly different selections.
