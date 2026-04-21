# Cortina: Quality fixes (byte slicing, DefaultHasher, budget_memories, transcript)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none
- **Non-goals:** recall-boundary, boundary-expansion (separate handoffs)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Byte-index slicing panics on non-ASCII (HIGH)
`src/hooks/post_tool_use/bash.rs:207-208,231-232`, `src/hooks/post_tool_use/edits.rs:173-174`

Six sites use `&command[..command.len().min(200)]` — byte-index slicing that panics if
a multi-byte UTF-8 character straddles the cut point. The `truncate()` helper in
`post_tool_use.rs` already does this correctly via `.chars().take(limit).collect()`.
Replace all six byte-index sites with `truncate(value, limit)`.

### 2 — `scope_hash` uses non-deterministic `DefaultHasher` (MEDIUM)
`src/utils/state.rs:93-100`

`DefaultHasher` is explicitly not stable across Rust versions. The hash is used as
a filename component for temp state files (`cortina-session-{hash}.json`). After a
toolchain upgrade the hash of the same `cwd` changes, orphaning all in-flight state
files and losing session identity. `stable_identity_hash` (FNV-1a) already exists in
the same file for exactly this purpose. Switch `scope_hash` to use it.

### 3 — `budget_memories` silently drops oversized first memory (MEDIUM)
`src/hooks/user_prompt_submit.rs:376-388`

When a single memory exceeds `RECALL_CHAR_BUDGET` (2000 chars) it is dropped entirely
rather than truncated. The result is zero recall injection when any memory is large,
defeating the feature. The budget loop should either include the first entry
unconditionally (capped to budget) or explicitly truncate it.

### 4 — Transcript error counting inflated by non-error exit codes (MEDIUM)
`src/hooks/stop/transcript.rs:102`

`transcript_tool_result_has_error` marks any non-zero exit code as an error. Tools
like `grep` (exit 1 = no match) and `diff` (exit 1 = differences) produce false
positives. The inflated `errors_encountered` count feeds `session_outcome_feedback`
classification, marking valid sessions as failures. Add an allowlist of exit codes
(or a content-based check) before incrementing the counter.

### 5 — Low items
- `src/hooks/pre_tool_use.rs:352-364` — `advisory_allowed` falls back to `true` on
  IO failure, disabling rate-limiting entirely when state file is unwritable
- `src/hooks/stop/tool_usage_emit.rs:40-90` — hand-rolled `ms_to_iso8601` has a
  post-2100 century-leap-year bug; replace with `chrono`/`humantime` if available

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina
cargo test 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [ ] Byte-index slicing replaced with `truncate()` at all six sites
- [ ] `scope_hash` uses `stable_identity_hash` instead of `DefaultHasher`
- [ ] `budget_memories` truncates or unconditionally includes first memory
- [ ] Transcript error counter filters non-error exit codes
- [ ] Low items addressed
- [ ] `cargo test` and `cargo clippy` pass
