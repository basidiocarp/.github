# Annulus: Codex Provider Implementation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/src/providers/codex.rs`, `annulus/src/providers/mod.rs`, `annulus/Cargo.toml`, `annulus/tests/codex_provider.rs` (new)
- **Cross-repo edits:** none
- **Non-goals:** discovering or documenting the Codex format (#118a owns that); changing the `TokenProvider` trait surface; modifying Claude or Gemini providers; touching the JSON output schema
- **Verification contract:** repo-local `cargo test`, `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`, plus `bash .handoffs/annulus/verify-codex-provider-impl.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive this handoff

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `annulus` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`CodexProvider` returns `Ok(None)` for everything. Operators using Codex
alongside Claude get no statusline visibility into Codex sessions. The format
spec from #118a documents where Codex writes session data and how to parse it;
this handoff implements the reader.

## What exists (state)

- **`annulus/src/providers/codex.rs`**: stub provider, `is_available()` returns
  false, `session_usage()` returns `Ok(None)`
- **`annulus/docs/providers/codex.md`** (from #118a): on-disk path, format,
  token fields, session-boundary heuristic, edge cases
- **`annulus/tests/fixtures/codex/`** (from #118a): real-format fixture file
  plus README

## What needs doing (intent)

Replace the stub with a real reader that:

- Resolves the Codex session-data path per the spec (env override → XDG → home)
- Parses the documented format and accumulates token usage
- Implements `is_available()` based on file existence
- Implements `last_session_at()` (mtime or in-file timestamp, per spec)
- Tolerates the edge cases the spec calls out — partial writes, missing
  fields, log rotation, multiple sessions

## Scope

- **Primary seam:** `annulus/src/providers/codex.rs`
- **Allowed files:** `annulus/src/providers/codex.rs`, `annulus/Cargo.toml` (only if a parser dep is genuinely needed), `annulus/tests/codex_provider.rs` (new integration test), `annulus/src/providers/mod.rs` (only to expose new helpers if needed)
- **Explicit non-goals:**
  - touching Claude or Gemini providers
  - changing `TokenProvider` trait
  - format spec discovery (covered by #118a)
  - JSON output schema changes

---

### Step 1: Path resolution

**Project:** `annulus/`
**Effort:** 0.25 day
**Depends on:** #118a complete

Implement the path-resolution chain documented in the spec. Order of
precedence is whatever the spec specifies; typically:

1. `CODEX_SESSION_DIR` (or whatever env var the spec names)
2. XDG cache/data dir
3. `~/.codex/...` fallback

Return `None` (not an error) when no candidate path exists — the provider
is just unavailable, not broken.

#### Verification

```bash
cd annulus && cargo test providers::codex::tests::path_resolution 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Env-var override beats XDG and home
- [ ] XDG path beats home fallback
- [ ] Returns `None` cleanly when no path is set and no file exists
- [ ] Tests use `tempfile` rather than the real home directory

---

### Step 2: Reader implementation against the fixture

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 1

Read the format the spec documents. Aggregate per-turn token counts into the
`TokenUsage` struct the trait already returns. Skip malformed entries
silently (mirror the Claude reader's tolerance), but never panic.

`session_usage()` must:
- Open the path resolved in Step 1
- Iterate entries (streaming if the format is NDJSON; single-parse if it's
  one big JSON; query if it's SQLite — driven by the spec)
- Deduplicate if the spec calls for it
- Return `Ok(None)` when the file exists but contains zero usable entries

`is_available()` returns `true` when path resolution succeeds AND the file
exists.

#### Files to modify

**`annulus/src/providers/codex.rs`** — replace the stub body.

#### Verification

```bash
cd annulus && cargo test providers::codex 2>&1 | tail -15
cd annulus && cargo test --test codex_provider 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Reader correctly aggregates the fixture entries
- [ ] `is_available()` returns false when the resolved path is missing
- [ ] `is_available()` returns true when the fixture is present
- [ ] Malformed entries don't crash the read
- [ ] At least one test exercises the multi-entry aggregation path
- [ ] No new `unwrap()` or `panic!` in production code

---

### Step 3: Recency

**Project:** `annulus/`
**Effort:** 0.25 day
**Depends on:** Step 2; depends on #117 having added `last_session_at` to the trait

Implement `last_session_at()` so #117's `detect_provider` recency comparison
will pick Codex when its session is newer than Claude's. Source the timestamp
from whatever the spec recommends — file mtime if the format has no internal
timestamps, otherwise the latest in-file timestamp.

If #117 is not yet complete, this step degrades to a no-op (the default
trait impl already returns `None`); skip it and re-open the handoff after #117
lands.

#### Verification

```bash
cd annulus && cargo test providers::codex::tests::last_session_at 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `last_session_at()` returns `Some(secs)` when the fixture file exists
- [ ] Returns `None` when the path is unresolved
- [ ] Tests pin a known mtime via `filetime` or equivalent so the assertion is deterministic

---

## Completion Protocol

This handoff is NOT complete until ALL of the following are true:

1. Every step above has verification output pasted between the markers
2. `bash .handoffs/annulus/verify-codex-provider-impl.sh` passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated and this handoff is archived

### Final Verification

```bash
bash .handoffs/annulus/verify-codex-provider-impl.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `annulus` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsDownstream of #118a (format spec). Pairs with #117 (auto-detect): once both
land, an operator with a recent Codex session and an idle Claude transcript
will see Codex usage in the statusline without changing config. Mirrored by
#119b for Gemini.
