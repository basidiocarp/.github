# Cortina: Stop Hook Extensions

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/hooks/stop.rs` (extend), `cortina/src/hooks/fp_check.rs` (new), `cortina/src/hooks/trigger_word.rs` (new)
- **Cross-repo edits:** none
- **Non-goals:** no full transcript parsing ML; no cross-session FP tracking; trigger words are prefix-match only; no changes to other hook types
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Two independent Wave 3 audit signals:

- **fp-check pattern**: extracted from Trail of Bits skills Wave 3 audit — a Stop hook pass that captures unresolved false-positive findings before session end, preventing silent drops.
- **Trigger-word routing**: extracted from context-engineering-kit Wave 3 audit — a Stop hook that routes in-band model signals (e.g. `MEMORIZE:`) to hyphae at session end, reducing end-of-session tool call overhead.

Both patterns target the same hook point (Stop/SubagentStop) and are bundled here as a single cortina extension.

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:**
  - `src/hooks/stop.rs` — existing Stop hook handler, extend with processor dispatch
  - `src/hooks/fp_check.rs` (new) — `FpCheckProcessor` and `FpMarker` types
  - `src/hooks/trigger_word.rs` (new) — `TriggerWordProcessor` and `TriggerWordPayload` types
- **Reference seams:**
  - `cortina/src/hooks/stop.rs` — read existing Stop handler before extending; understand how the transcript is threaded in
  - `cortina/src/hooks/` — read the full module to understand processor trait or dispatch pattern already in use
- **Spawn gate:** read cortina's existing stop hook and hook dispatch before spawning

## Problem

Cortina's Stop hook currently runs a single pass at session end. Two useful behaviors have no home: (1) unresolved false-positive markers flagged during a session are silently dropped when the session closes, and (2) the model has no lightweight in-band mechanism to request memory persistence without requiring a hyphae tool call in the final turn. Adding two focused processors to the Stop hook dispatch fixes both gaps without touching the rest of the cortina pipeline.

## What needs doing (intent)

1. Extend `cortina/src/hooks/stop.rs` to dispatch to a list of processors at Stop and SubagentStop events
2. Add `FpCheckProcessor`: scans the session transcript for unresolved FP marker strings, emits a structured summary if any are found
3. Add `TriggerWordProcessor`: scans the final assistant message for configured trigger-word prefixes (`MEMORIZE:`, `HYPHAE_STORE:`), extracts the payload, and calls hyphae store
4. Define `FpMarker` and `TriggerWordPayload` data types
5. Add configuration for which trigger words to watch (default: `MEMORIZE`, `HYPHAE_STORE`)

## Data model

```rust
/// A false-positive marker found in the session transcript.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct FpMarker {
    /// The marker text as it appeared in the transcript.
    pub text: String,
    /// Source file or context where the marker was flagged, if available.
    pub file: Option<String>,
    /// Line number in the transcript where the marker appeared, if available.
    pub line: Option<usize>,
    /// Timestamp at which the marker was flagged.
    pub flagged_at: chrono::DateTime<chrono::Utc>,
}

/// A trigger-word payload extracted from the final assistant message.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct TriggerWordPayload {
    /// The trigger keyword matched (e.g. "MEMORIZE", "HYPHAE_STORE").
    pub keyword: String,
    /// The content following the keyword and its delimiter.
    pub content: String,
}

/// Configuration for the TriggerWordProcessor.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct TriggerWordConfig {
    /// Keywords to watch for. Default: ["MEMORIZE", "HYPHAE_STORE"].
    pub keywords: Vec<String>,
}

impl Default for TriggerWordConfig {
    fn default() -> Self {
        Self {
            keywords: vec!["MEMORIZE".to_string(), "HYPHAE_STORE".to_string()],
        }
    }
}
```

## Processor contract

```rust
/// Processes a Stop or SubagentStop event. Runs after the session ends.
pub trait StopProcessor {
    /// Called with the session transcript and the final assistant message.
    /// Returns a summary string if something noteworthy was found, or None.
    fn process(
        &self,
        transcript: &[TranscriptEntry],
        final_message: Option<&str>,
    ) -> Option<String>;
}
```

`FpCheckProcessor`:
- Scans every transcript entry for strings matching known FP marker patterns (e.g. `[FP]`, `FP:`, `FALSE_POSITIVE:`)
- Collects all matches into `Vec<FpMarker>`
- If non-empty, emits a structured JSON summary via cortina's signal emission path (same as existing lifecycle signals)
- If empty, no-ops silently

`TriggerWordProcessor`:
- Scans `final_message` for lines starting with `{KEYWORD}:` where `KEYWORD` is in the configured list (case-sensitive prefix match)
- For each match, extracts the trailing content as `TriggerWordPayload`
- Calls hyphae store for each payload (topic inferred from keyword: `MEMORIZE` → `"context/inline"`, `HYPHAE_STORE` → `"context/inline"`)
- Logs a warning if hyphae is unavailable; does not block session end

## Scope

- **Allowed files:** `cortina/src/hooks/stop.rs` (extend), `cortina/src/hooks/fp_check.rs` (new), `cortina/src/hooks/trigger_word.rs` (new)
- **Explicit non-goals:**
  - No ML-based transcript parsing
  - No cross-session FP tracking or deduplication
  - No trigger-word routing for non-Stop hook types
  - No changes to PreToolUse, PostToolUse, or other hook handlers
  - No changes to cortina signal emission internals

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `cortina/src/hooks/stop.rs` — what does the current Stop handler do? How is the transcript threaded in? Is there already a processor list pattern?
2. `cortina/src/hooks/` — what other hook handlers exist? Is there a shared `StopProcessor` trait or a simpler closure approach?
3. `cortina/src/` — how does signal emission work? What is the output path for lifecycle summaries?

---

### Step 1: Define FpMarker and FpCheckProcessor

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 0

Create `src/hooks/fp_check.rs` with `FpMarker` and `FpCheckProcessor`. Implement transcript scanning and structured summary emission.

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `FpMarker` compiles with serde derives
- [ ] `FpCheckProcessor` scans transcript entries for FP marker strings
- [ ] Emits summary when markers found; no-ops when transcript is clean

---

### Step 2: Define TriggerWordPayload and TriggerWordProcessor

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 1

Create `src/hooks/trigger_word.rs` with `TriggerWordPayload`, `TriggerWordConfig`, and `TriggerWordProcessor`. Implement final-message scanning and hyphae store call.

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `TriggerWordPayload` and `TriggerWordConfig` compile with serde derives
- [ ] `TriggerWordConfig::default()` returns `["MEMORIZE", "HYPHAE_STORE"]`
- [ ] Prefix-match is case-sensitive
- [ ] Hyphae unavailability logs a warning and does not panic

---

### Step 3: Wire processors into stop.rs dispatch

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 2

Extend `src/hooks/stop.rs` to call `FpCheckProcessor` and `TriggerWordProcessor` in sequence on Stop and SubagentStop events.

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
cd cortina && cargo test stop 2>&1 | tail -20
```

**Checklist:**
- [ ] Both processors are called at Stop
- [ ] Both processors are called at SubagentStop
- [ ] Processor failures do not block session end (fail-open)

---

### Step 4: Full suite

```bash
cd cortina && cargo test 2>&1 | tail -20
cd cortina && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd cortina && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] All tests pass in cortina
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output
2. Full test suite passes in cortina
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- `septa/fp-marker-v1.schema.json` — if FP marker summaries need to cross tool boundaries
- Configurable FP marker patterns (currently hardcoded strings)
- `hyphae`: store FP summaries under a dedicated topic for cross-session tracking
- `stipe doctor`: check that cortina Stop hook is registered and reachable

## Context

Spawned from Wave 3 audit program (2026-04-23). Two independent audit signals both pointed at the Stop hook as the right extension point: the Trail of Bits fp-check pattern addresses silent finding loss at session end, and the context-engineering-kit trigger-word pattern addresses in-band memory signaling without requiring a tool call. Both are narrow, fail-open, and scoped to Stop — they do not touch the rest of the cortina pipeline.
