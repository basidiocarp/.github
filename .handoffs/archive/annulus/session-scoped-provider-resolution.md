# Session-Scoped Provider Resolution

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** host adapter hooks (cortina/lamella concern), historical usage aggregation (#140), dashboard UI, changes to the existing auto-detect fallback behavior when no stdin identity is provided
- **Verification contract:** run the repo-local commands below and `bash .handoffs/annulus/verify-session-scoped-provider-resolution.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** `src/statusline.rs` (`StatuslineInput`, `statusline_view`); `src/providers/mod.rs` (`detect_provider`); `src/providers/codex.rs` (`CodexProvider`); `src/providers/gemini.rs` (`GeminiProvider`)
- **Reference seams:** `src/providers/claude.rs:391-394` — `ClaudeProvider` already has an optional `transcript_path` field that scopes it to a specific session when populated from stdin; this is the pattern to extend to Codex and Gemini
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Annulus selects one global provider via `detect_by_recency()` which compares the most recent session file across Claude, Codex, and Gemini. When a user has Claude open in terminal A and Codex in terminal B, both terminals see the same provider's data — whichever had the most recent activity globally. Within the same provider, two Codex sessions or two Gemini sessions also show identical data because both providers always read the globally most recent session file.

Claude partially avoids this because Claude Code passes `transcript_path` via stdin JSON, and `statusline_view` injects it into `ClaudeProvider`. But Codex and Gemini providers have no equivalent session-scoping mechanism.

The root cause is that provider selection and session targeting are global when they should be per-invocation. The stdin JSON already carries session context for Claude — extending this pattern to all providers makes each statusline invocation self-identifying.

## What exists (state)

- **`StatuslineInput`** (`src/statusline.rs:16-23`): accepts `transcript_path`, `model`, `workspace` from stdin JSON. No `provider` or `session_path` field.
- **`statusline_view`** (`src/statusline.rs:161-258`): reads `config.provider` for explicit override or calls `detect_by_recency()`. For Claude, injects `input.transcript_path` into the provider after detection.
- **`ClaudeProvider`** (`src/providers/claude.rs:391-394`): has `transcript_path: Option<String>` — already session-scoped when populated.
- **`CodexProvider`** (`src/providers/codex.rs:298-301`): has `codex_home: Option<PathBuf>` only. Always reads the globally most recent session file via `most_recent_session()`.
- **`GeminiProvider`** (`src/providers/gemini.rs:147-149`): has `tmp_dir: Option<PathBuf>` only. Always reads the globally most recent session file via `most_recent_session()`.
- **`detect_provider`** (`src/providers/mod.rs:83-91`): accepts `Option<&str>` for explicit name. No session path parameter.
- **`detect_by_recency`** (`src/providers/mod.rs:98-138`): creates default providers with no session scoping.

## What needs doing (intent)

1. Extend `StatuslineInput` to accept optional `provider` and `session_path` fields from stdin JSON.
2. Add session-path constructors to `CodexProvider` and `GeminiProvider` so they can target a specific session file instead of scanning for the most recent one.
3. Update `statusline_view` to use stdin `provider` for provider selection (overriding both config and auto-detect when present) and pass `session_path` to the selected provider.
4. Preserve the existing fallback chain: stdin provider > config provider > auto-detect by recency. When no stdin identity is provided, behavior is unchanged.

## Scope

- **Primary seam:** `StatuslineInput` extension, provider session-path constructors, `statusline_view` wiring
- **Allowed files:** `annulus/src/` — statusline module and provider modules
- **Explicit non-goals:**
  - Do not implement the host adapter hooks that pass session identity (cortina/lamella concern — see #142)
  - Do not change the auto-detect fallback behavior when no stdin identity is provided
  - Do not change the `TokenProvider` trait interface
  - Do not add a new CLI flag — session identity comes from stdin JSON, matching the existing Claude Code integration pattern

---

### Step 1: Extend StatuslineInput and provider constructors

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** nothing

Extend `StatuslineInput` with two new optional fields:
- `provider: Option<String>` — explicit provider name from the calling host ("claude", "codex", "gemini")
- `session_path: Option<String>` — path to the specific session file the host is running

Add session-path-aware constructors:
- `CodexProvider::with_session_file(path: PathBuf)` — reads only this file, not the globally most recent
- `GeminiProvider::with_session_file(path: PathBuf)` — same pattern

The existing `with_home` / `with_tmp_dir` constructors remain unchanged. The new constructors add a `session_file: Option<PathBuf>` field that, when `Some`, bypasses `most_recent_session()` in `session_usage()` and `last_session_at()`.

#### Verification

```bash
cd annulus && cargo check 2>&1
cd annulus && cargo test provider 2>&1
```

**Checklist:**
- [ ] `StatuslineInput` has `provider` and `session_path` fields
- [ ] `CodexProvider` has a `with_session_file` constructor that targets a specific file
- [ ] `GeminiProvider` has a `with_session_file` constructor that targets a specific file
- [ ] When `session_file` is set, `session_usage()` reads that file only
- [ ] When `session_file` is set, `last_session_at()` returns that file's mtime
- [ ] When `session_file` is `None`, existing behavior is unchanged
- [ ] Unit tests cover both explicit-session and default paths for each provider

---

### Step 2: Wire session identity through statusline_view

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 1

Update `statusline_view` to implement this provider resolution order:
1. If `input.provider` is set in stdin, use that provider name (overrides config and auto-detect)
2. Else if `config.provider` is set, use that (existing behavior)
3. Else auto-detect by recency (existing behavior)

When constructing the selected provider, pass `input.session_path` (or `input.transcript_path` for Claude) to the session-path-aware constructor. This replaces the current ad-hoc injection of `transcript_path` for Claude with a uniform pattern across all providers.

#### Verification

```bash
cd annulus && cargo test statusline 2>&1
cd annulus && cargo test 2>&1
```

**Checklist:**
- [ ] `statusline_view` reads `input.provider` and prefers it over config and auto-detect
- [ ] `statusline_view` passes `input.session_path` to Codex/Gemini providers
- [ ] `statusline_view` still passes `input.transcript_path` to Claude provider (backward compat)
- [ ] When `input.provider` is absent, existing config/auto-detect chain is unchanged
- [ ] Unit tests verify the three-level priority chain (stdin > config > auto-detect)

---

### Step 3: Add multi-session integration tests

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 2

Add integration tests in `tests/` that verify the multi-session scenario:
- Two concurrent Codex sessions with different session files produce different usage data
- Stdin provider override selects the specified provider regardless of recency
- Stdin session_path targets the specified file, not the global most-recent
- Backward compatibility: empty stdin still auto-detects as before

#### Verification

```bash
cd annulus && cargo test 2>&1
cd annulus && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Integration test: two Codex session files with different data, each session_path returns correct usage
- [ ] Integration test: stdin provider="codex" overrides auto-detect even when Claude is more recent
- [ ] Integration test: empty stdin defaults to existing behavior
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/annulus/verify-session-scoped-provider-resolution.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/annulus/verify-session-scoped-provider-resolution.sh
```

## Context

Source: user report — running Claude in one terminal and Codex in another, both see the same statusline data. Root cause: `detect_by_recency()` picks one global winner; Codex/Gemini providers have no session scoping.

Related handoffs: #129 Annulus Flag-File State Bridge, #140 Annulus Per-Provider Usage Scanner, #142 Annulus Multi-Session Host Adapter Contract. This handoff makes annulus capable of session-scoped display; #142 documents the contract so host adapters know what to pass.
