# Per-Provider Usage Scanner

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** chart rendering (cap concern); dashboard UI; changes to existing statusline providers
- **Verification contract:** run the repo-local commands below and `bash .handoffs/annulus/verify-per-provider-usage-scanner.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** `src/providers/` — existing per-provider token readers; new `src/usage/` or `src/scanner/` module for aggregation and storage
- **Reference seams:** multica per-provider usage scanning with rows keyed by (runtime, date, model); five chart-ready output shapes
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Annulus already has per-provider token readers (Claude, Codex, Gemini) but does not aggregate usage into per-runtime, per-date, per-model rows suitable for chart rendering. Multica has working scanner implementations that produce this shape: per-provider scanners emit rows keyed by (runtime, date, model) with token counts and cost. Five chart types consume this data: daily token volume, daily cost, hourly activity heatmap, model distribution, and per-runtime breakdown. Without this aggregation layer, annulus can report current-session usage but not historical trends or cross-session analytics.

## What exists (state)

- **`annulus`:** per-provider token readers for Claude, Codex, and Gemini exist; they report current-session usage but do not produce persistent per-date, per-model rows
- **multica reference:** per-provider scanners emit `(runtime, date, model, prompt_tokens, completion_tokens, cache_tokens, cost_usd)` rows; an append-only or SQLite storage layer accumulates them across sessions

## What needs doing (intent)

1. Define a `UsageRow` struct: `runtime_id`, `date`, `model`, `prompt_tokens`, `completion_tokens`, `cache_tokens`, `cost_usd`.
2. Define a `UsageScanner` trait that each provider implements: `scan(runtime_path) -> Vec<UsageRow>`.
3. Implement scanners for Claude, Codex, and Gemini that read from the existing provider transcript files and produce `UsageRow` batches.
4. Add a storage layer (append-only file or SQLite) that accumulates rows across sessions.

## Scope

- **Primary seam:** `annulus/src/` providers and new usage module
- **Allowed files:** `annulus/src/` — existing provider modules and new usage/scanner module
- **Explicit non-goals:**
  - Do not build chart rendering (cap concern)
  - Do not build a dashboard UI
  - Do not change the existing statusline providers — the scanner is an additional aggregation layer, not a replacement

---

### Step 1: Define UsageRow and UsageScanner trait

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** nothing

Define a `UsageRow` struct with fields: `runtime_id: String`, `date: chrono::NaiveDate` (or equivalent), `model: String`, `prompt_tokens: u64`, `completion_tokens: u64`, `cache_tokens: u64`, `cost_usd: f64`. Define a `UsageScanner` trait with a single method `scan(runtime_path: &Path) -> Vec<UsageRow>`. Place these in a new `src/usage/` or `src/scanner/` module.

#### Verification

```bash
cd annulus && cargo check 2>&1
```

**Checklist:**
- [ ] `UsageRow` struct is defined with all seven fields
- [ ] `UsageScanner` trait is defined with `scan` method
- [ ] Module is reachable from `src/lib.rs` or the crate root
- [ ] No existing tests regress

---

### Step 2: Implement Claude scanner from existing provider code

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 1

Implement `UsageScanner` for Claude by reading from the existing Claude provider transcript files. The scanner must parse transcript entries and produce one `UsageRow` per (date, model) pair encountered. Reuse the existing provider reader where possible rather than reimplementing the transcript format. Add unit tests that cover at least one fixture transcript.

#### Verification

```bash
cd annulus && cargo test claude 2>&1
cd annulus && cargo test scanner 2>&1
```

**Checklist:**
- [ ] Claude scanner implements the `UsageScanner` trait
- [ ] Scanner reads from transcript files produced by the existing Claude provider
- [ ] Scanner produces `UsageRow` values keyed by (date, model)
- [ ] At least one unit test covers a fixture transcript
- [ ] No existing tests regress

---

### Step 3: Implement Codex and Gemini scanners

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 2

Implement `UsageScanner` for Codex and for Gemini using the same trait. Follow the same pattern as the Claude scanner: read from the existing provider transcript files, parse per (date, model) pairs, and emit `UsageRow` batches. Add unit tests for each scanner.

#### Verification

```bash
cd annulus && cargo test codex 2>&1
cd annulus && cargo test gemini 2>&1
```

**Checklist:**
- [ ] Codex scanner implements `UsageScanner`
- [ ] Gemini scanner implements `UsageScanner`
- [ ] Both scanners produce `UsageRow` values keyed by (date, model)
- [ ] Unit tests cover at least one fixture per scanner
- [ ] No existing tests regress

---

### Step 4: Add storage layer

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 3

Add a storage layer that accumulates `UsageRow` values across sessions. Use an append-only file (JSONL or CSV) or SQLite. The storage layer must support: appending new rows, reading all rows, and deduplicating rows with identical (runtime_id, date, model) keys on read. Add a test that round-trips at least one row through storage.

#### Verification

```bash
cd annulus && cargo test 2>&1
cd annulus && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Storage layer appends `UsageRow` values durably across sessions
- [ ] Reading back rows produces the same values that were stored
- [ ] Duplicate (runtime_id, date, model) rows are deduplicated on read
- [ ] A round-trip test passes
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/annulus/verify-per-provider-usage-scanner.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/annulus/verify-per-provider-usage-scanner.sh
```

## Context

Source: multica audit (per-provider usage scanning with rich charts). See `.audit/external/audits/multica-ecosystem-borrow-audit.md` section "Per-provider usage scanning."

Related handoffs: #129 Annulus Flag-File State Bridge, #114db Annulus Tool Adoption Statusline. This handoff adds the aggregation layer that cap will eventually consume for chart rendering; it is intentionally scoped to data production only.
