# Annulus Aggregation Data-Source Alignment

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** statusline customization or config loading (#116), JSON output surface (#104b), Cap panel rendering, pricing logic
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only

## Problem

Even with `statusline --json`, the aggregation path can still drift if Annulus
reads different sources than the tool CLIs. The alignment work deserves its own
handoff because it mixes several segment seams.

Additionally, annulus currently only reads Claude session data. Operators using
Codex CLI, Gemini CLI, or Copilot alongside Claude get no visibility into those
sessions. A provider abstraction would let the statusline render token usage from
whichever coding agent is active. And when annulus needs to aggregate across
sessions (e.g. daily cost totals), the current full-buffer transcript parsing
will not scale — stream-based JSONL processing is needed.

## What exists (state)

- **`statusline.rs`**: Reads Claude transcript JSONL by buffering all lines, reads
  mycelium SQLite for savings, shells out to `git` for branch. No provider
  abstraction — Claude paths are hardcoded.
- **`read_transcript_usage()`**: Opens file, iterates all lines with
  `BufReader::lines()`, parses each as JSON. Adequate for single-session reads
  but allocates per-line and does not support streaming or deduplication.
- **`mycelium_db_path()`**: Uses `spore::paths::db_path()` — already aligned.
- **No hyphae or cortina segments**: These data sources are not yet wired.
- **No Codex/Gemini/Copilot support**: Only Claude transcript format is parsed.

## What needs doing (intent)

1. Audit and tighten existing segment data sources so annulus reads from the same
   paths the tool CLIs write to.
2. Add a provider trait so token reads can come from Claude, Codex, Gemini, or
   other coding agents.
3. Add stream-based JSONL processing for efficient cross-session transcript
   aggregation.
4. Wire hyphae and cortina segments with proper degradation.

## Scope

- **Primary seam:** segment data-source pipeline in `annulus/src/statusline.rs`
  and related modules
- **Allowed files:** `annulus/src/statusline.rs`, `annulus/src/providers/` (new),
  `annulus/src/segments/` (new if not created by #116), `annulus/Cargo.toml`
- **Explicit non-goals:**
  - Config file format or segment ordering (#116)
  - JSON output surface (#104b)
  - Cap panel rendering
  - OAuth or API-key-based provider auth (read local files only)

---

### Step 1: Audit and align existing segment data sources

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** nothing

Verify that each existing segment reads from the canonical path its tool writes
to. Fix any drift.

| Segment | Source | Discovery |
|---------|--------|-----------|
| Mycelium savings | `history.db` | `spore::paths::db_path("mycelium", ...)` |
| Git branch | `git rev-parse` | Shell exec in workspace dir |
| Workspace name | Path basename | From stdin `current_dir` |
| Token usage | Transcript JSONL | Path from stdin `transcript_path` |

Add stubs for:

| Segment | Source | Discovery |
|---------|--------|-----------|
| Hyphae health | `hyphae.db` | `spore::paths::db_path("hyphae", ...)` |
| Cortina status | (no direct data seam yet) | Explicit unavailable stub |

#### Files to modify

**`annulus/src/statusline.rs`**:

- Add hyphae segment stub that reads memory count or returns unavailable
- Add cortina segment stub that returns unavailable with a reason
- Verify mycelium path uses `spore::paths`

#### Verification

```bash
cd annulus && cargo build 2>&1 | tail -5
cd annulus && cargo test segment 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Compiling annulus v0.3.0
Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.47s

running 14 tests — all pass (segment filter)
test result: ok. 14 passed; 0 failed; 0 ignored; 0 measured; 62 filtered out
<!-- PASTE END -->

**Checklist:**
- [x] Mycelium segment uses `spore::paths` or equivalent shared discovery
- [x] Hyphae segment exists and degrades gracefully when hyphae.db is missing
- [x] Cortina segment exists as explicit unavailable stub
- [x] Segment tests cover at least one unavailable case per new segment

---

### Step 2: Provider trait for multi-source token reads

**Project:** `annulus/`
**Effort:** 1 day
**Depends on:** Step 1

Add a provider abstraction so annulus can read token usage from multiple coding
agents, not just Claude.

Design (informed by CodexBar's provider-descriptor pattern):

```rust
/// A coding agent whose session data annulus can read.
trait TokenProvider {
    /// Short name for display and config ("claude", "codex", "gemini").
    fn name(&self) -> &str;

    /// Whether this provider's data source is currently available.
    fn is_available(&self) -> bool;

    /// Read token usage for the current or most recent session.
    fn session_usage(&self) -> Result<Option<TokenUsage>>;
}
```

Built-in providers:

| Provider | Data source | Detection |
|----------|-------------|-----------|
| `claude` | Transcript JSONL at `transcript_path` | Stdin provides path |
| `codex` | `~/.codex/usage.json` or equivalent | File existence check |
| `gemini` | `~/.gemini-cli/` state files | File existence check |

Provider selection:

- Default: `claude` (current behavior, backwards compatible)
- Auto-detect: check which providers have data available, prefer the one with
  the most recent session
- Explicit: configurable via `provider = "codex"` in statusline.toml (#116 config)

The provider trait is internal — not a plugin API. Adding a new provider means
adding a Rust impl, not loading an external module.

Keep the Claude provider as the exact current implementation, just behind the
trait. Codex and Gemini providers can start as stubs that return unavailable
until their file formats are documented.

#### Files to modify

**`annulus/src/providers/mod.rs`** (new):

- `TokenProvider` trait
- `ClaudeProvider` — wraps existing `read_transcript_usage()`
- `CodexProvider` — stub, returns unavailable
- `GeminiProvider` — stub, returns unavailable
- `detect_provider()` — returns the first available provider or Claude as default

**`annulus/src/statusline.rs`**:

- Use `detect_provider()` or explicit provider in `statusline_view()`
- Token usage and cost segments read from the provider, not directly from
  `read_transcript_usage()`

#### Verification

```bash
cd annulus && cargo build 2>&1 | tail -5
cd annulus && cargo test provider 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Finished `dev` profile [unoptimized + debuginfo] target(s)

running 19 tests — all pass (provider filter)
test result: ok. 19 passed; 0 failed; 0 ignored; 0 measured; 57 filtered out
<!-- PASTE END -->

**Checklist:**
- [x] `TokenProvider` trait defined with `name()`, `is_available()`, `session_usage()`
- [x] `ClaudeProvider` wraps existing transcript parsing (behavior unchanged)
- [x] `CodexProvider` stub returns unavailable
- [x] `GeminiProvider` stub returns unavailable
- [x] `detect_provider()` returns Claude by default
- [x] Default statusline output is unchanged (backwards compatible)
- [x] Tests cover provider detection and unavailable fallback

---

### Step 3: Stream-based JSONL processing

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 2

Refactor `read_transcript_usage()` to support stream-based processing for
efficient cross-session aggregation. The current implementation works for
single-session reads but won't scale when annulus needs to aggregate across
multiple transcript files (e.g. daily cost reporting, session history).

Design (informed by ccusage's stream-based JSONL processor):

- Replace line-by-line string allocation with a streaming JSON deserializer
  that processes entries without buffering the full file
- Add session-boundary detection: identify session breaks by time gaps
  (5-hour windows, matching ccusage's heuristic) or explicit session markers
- Add deduplication: when aggregating across files, detect and skip duplicate
  entries by message ID or timestamp
- Keep the single-session path fast — streaming should not add overhead for the
  common case of reading one transcript

Concrete changes:

```rust
/// Stream-process a transcript file, calling the visitor for each usage entry.
fn stream_transcript_usage<F>(path: &str, mut visitor: F) -> Result<()>
where
    F: FnMut(&TranscriptEntry),
{
    // Use serde_json::StreamDeserializer for zero-copy line processing
    // ...
}

/// Aggregate usage across multiple transcript files.
fn aggregate_transcript_usage(paths: &[&str]) -> Result<TranscriptUsage> {
    // Stream each file, deduplicate by message_id, sum usage
    // ...
}
```

The existing `read_transcript_usage()` should delegate to `stream_transcript_usage`
so there is one code path.

#### Files to modify

**`annulus/src/statusline.rs`** or **`annulus/src/providers/claude.rs`**:

- Add `stream_transcript_usage()` with visitor pattern
- Add `aggregate_transcript_usage()` for multi-file aggregation
- Refactor `read_transcript_usage()` to use the streaming path
- Add session-boundary detection heuristic

#### Verification

```bash
cd annulus && cargo test transcript 2>&1 | tail -10
cd annulus && cargo test aggregate 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
transcript tests: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 71 filtered out
aggregate tests:  ok. 3 passed; 0 failed; 0 ignored; 0 measured; 73 filtered out
<!-- PASTE END -->

**Checklist:**
- [x] `stream_transcript_usage()` processes entries without buffering the full file
- [x] `aggregate_transcript_usage()` handles multiple files with deduplication
- [x] Single-session read performance is not regressed
- [x] Session-boundary detection identifies gaps > 5 hours
- [x] `read_transcript_usage()` delegates to the streaming path
- [x] Tests cover single file, multiple files, deduplication, and session boundaries

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/annulus/verify-aggregation-data-source-alignment.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/annulus/verify-aggregation-data-source-alignment.sh
```

**Output:**
<!-- PASTE START -->
PASS: mycelium segment uses shared path discovery
PASS: hyphae degradation path exists
PASS: cortina segment or stub exists
PASS: cargo segment tests pass
Results: 4 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

Informed by external audit of reference tools:

- **CodexBar** (Swift macOS): provider-descriptor pattern with pluggable data
  sources, runtime/source mode separation, fetch strategy chains. Adapted here
  as a Rust trait with file-based detection instead of OAuth/PTY chains.
- **ccusage** (TypeScript): stream-based JSONL processing with deduplication,
  session-block detection (5-hour windows), multi-source aggregation. Adapted
  here as a streaming visitor pattern with `serde_json::StreamDeserializer`.

Related handoffs:

- #104a (Unified Output Principles): documentation prerequisite for this handoff
- #104b (Statusline JSON Surface): JSON output, depends on this alignment work
- #116 (Statusline Customization): config and segment registry, complementary scope
