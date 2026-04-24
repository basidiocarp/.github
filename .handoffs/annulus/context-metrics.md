# Annulus: Context Window % and Pace Delta

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/src/statusline.rs`, `annulus/src/providers/mod.rs`, `annulus/src/config.rs`
- **Cross-repo edits:** none
- **Non-goals:** no real-time streaming update; context limit table is hardcoded (no API call to fetch model limits); pace delta is session-scoped only (no cross-session rate); no new segment UI beyond the data provider
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from two Wave 3 audit sources:

**claude-hud** (context window %):
> "claude-hud renders a context window percentage bar: (input_tokens / model_context_limit) × 100. It shows a warning color at 80% and blocks at 95%."

> "Best fit: `annulus` statusline — add a context window segment on top of the existing TokenUsage struct."

**claude-pace** (pace delta):
> "claude-pace tracks token consumption rate per turn (Δ tokens/hr) and compares it to period average. Operators use this to spot runaway sessions before they exhaust budget."

> "Best fit: `annulus` statusline — pace delta is a derived metric from TokenUsage and elapsed session time."

## Implementation Seam

- **Likely repo:** `annulus` (Rust statusline)
- **Likely files/modules:**
  - `src/statusline.rs` — extend `TokenUsage` struct; add `ContextMetrics` struct and helpers
  - `src/providers/mod.rs` — add `ContextMetricsProvider` or extend `TokenProvider` trait
  - `src/config.rs` — update storage path to use `XDG_CACHE_HOME`
- **Reference seams:**
  - `annulus/src/statusline.rs` — read existing `TokenUsage` struct before editing
  - `annulus/src/providers/` — read `TokenProvider` trait and existing providers (claude.rs, codex.rs, gemini.rs) before editing
  - `annulus/src/config.rs` — read existing path handling before changing to XDG
- **Spawn gate:** read all three reference seam files before spawning

## Problem

Annulus currently surfaces raw token counts (input, output, cache) via `TokenUsage` and per-provider `session_usage()`. It has no context window percentage — operators cannot tell how close a session is to hitting the model's context limit. It also has no pace delta — operators cannot tell whether token consumption is accelerating or within normal range.

claude-hud and claude-pace show both are useful early-warning signals. The context window % is the more critical one: at 80% the operator should know, at 95% they may need to act. The pace delta gives a secondary rate signal that is especially useful in long-running sessions.

## What needs doing (intent)

1. Add `context_window_limit(model: &str) -> u64` — hardcoded lookup table per model
2. Add `context_percent(usage: &TokenUsage, model: &str) -> f32` — derived percentage
3. Add `pace_delta(usage: &TokenUsage, elapsed_minutes: f64) -> f64` — tokens per hour
4. Add `ContextMetrics` struct grouping the derived metrics
5. Add a `ContextMetricsProvider` (or extend `TokenProvider`) that emits `ContextMetrics` given a session's `TokenUsage` and model name
6. Update storage path in `src/config.rs` to use `XDG_CACHE_HOME` (fallback: `~/.cache/annulus/`)

## Data model

```rust
pub struct ContextMetrics {
    pub window_pct: f32,           // 0.0–100.0
    pub pace_tokens_per_hr: f64,
    pub at_warning: bool,          // window_pct >= 80.0
}

fn context_window_limit(model: &str) -> u64 {
    match model {
        m if m.contains("claude") => 200_000,
        m if m.contains("codex")  => 128_000,
        m if m.contains("gemini") => 1_000_000,
        _                          => 128_000,
    }
}

fn context_percent(usage: &TokenUsage, model: &str) -> f32 {
    let limit = context_window_limit(model) as f32;
    if limit == 0.0 {
        return 0.0;
    }
    (usage.input_tokens as f32 / limit * 100.0).min(100.0)
}

fn pace_delta(usage: &TokenUsage, elapsed_minutes: f64) -> f64 {
    if elapsed_minutes <= 0.0 {
        return 0.0;
    }
    let total_tokens = (usage.input_tokens + usage.output_tokens) as f64;
    total_tokens / elapsed_minutes * 60.0  // tokens per hour
}
```

## XDG cache path

```rust
fn annulus_cache_dir() -> PathBuf {
    let base = std::env::var("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            dirs::home_dir()
                .unwrap_or_else(|| PathBuf::from("."))
                .join(".cache")
        });
    base.join("annulus")
}
```

## Scope

- **Allowed files:** `annulus/src/statusline.rs` (extend `TokenUsage`, add `ContextMetrics` and helpers), `annulus/src/providers/mod.rs` (add `ContextMetricsProvider` or extend `TokenProvider`), `annulus/src/config.rs` (XDG path)
- **Explicit non-goals:**
  - No real-time streaming update of context %
  - No API call to fetch model context limits — hardcoded table only
  - No cross-session pace delta (session-scoped only)
  - No new rendered segment in this handoff — data provider only

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `annulus/src/statusline.rs` — exact shape of `TokenUsage`, existing derives and impls
2. `annulus/src/providers/mod.rs` — `TokenProvider` trait signature, how session_usage() is called
3. `annulus/src/providers/claude.rs` — concrete provider pattern to match
4. `annulus/src/config.rs` — existing path handling and storage location

---

### Step 1: Add context_window_limit, context_percent, and pace_delta helpers

**Project:** `annulus/`
**Effort:** tiny
**Depends on:** Step 0

Add the three free functions to `src/statusline.rs` (or a new `src/metrics.rs` if the module boundary is cleaner — follow the existing pattern). Add `ContextMetrics` struct with `window_pct`, `pace_tokens_per_hr`, and `at_warning` fields. Derive `Debug`, `Clone`, and `serde::Serialize` if the existing codebase uses serde on similar types.

#### Verification

```bash
cd annulus && cargo build --release 2>&1 | tail -5
```

**Checklist:**
- [ ] `ContextMetrics` struct compiles
- [ ] `context_window_limit` returns correct values for claude/codex/gemini/unknown
- [ ] `context_percent` returns 0.0–100.0 clamped value
- [ ] `pace_delta` returns tokens/hr with elapsed_minutes guard

---

### Step 2: Add unit tests for the helpers

**Project:** `annulus/`
**Effort:** tiny
**Depends on:** Step 1

Add a `#[cfg(test)]` module in the same file as the helpers. Test:
- `context_window_limit` for each known model string and unknown fallback
- `context_percent` at 0%, 50%, 80%, 100%, and over-limit (clamped)
- `pace_delta` at zero elapsed (guard), normal rate, and high rate
- `at_warning` is true at exactly 80.0 and above

#### Verification

```bash
cd annulus && cargo test context_metrics 2>&1 | tail -20
```

**Checklist:**
- [ ] All helper unit tests pass
- [ ] Edge cases (zero elapsed, over-limit input) handled without panic

---

### Step 3: Add ContextMetricsProvider

**Project:** `annulus/`
**Effort:** small
**Depends on:** Step 2

Add `ContextMetricsProvider` to `src/providers/mod.rs` (or as a separate file in `src/providers/` following the existing pattern). It takes a model name and delegates to the existing `TokenProvider::session_usage()` to get `TokenUsage`, then computes `ContextMetrics`. Expose it with the same interface pattern as `ClaudeProvider`, `CodexProvider`, and `GeminiProvider`.

#### Verification

```bash
cd annulus && cargo build --release 2>&1 | tail -5
```

**Checklist:**
- [ ] `ContextMetricsProvider` compiles and implements the required trait
- [ ] Provider can be instantiated with a model name string
- [ ] `context_metrics()` method returns `ContextMetrics` without panicking

---

### Step 4: Update storage path to XDG_CACHE_HOME

**Project:** `annulus/`
**Effort:** tiny
**Depends on:** Step 0

In `src/config.rs`, replace any hardcoded `~/.annulus/` or similar path with `annulus_cache_dir()` as specified in the data model above. Check whether the `dirs` crate is already a dependency; add it if not.

#### Verification

```bash
cd annulus && cargo build --release 2>&1 | tail -5
```

**Checklist:**
- [ ] Storage path uses `XDG_CACHE_HOME` when set
- [ ] Fallback to `~/.cache/annulus/` when `XDG_CACHE_HOME` is unset
- [ ] No hardcoded non-XDG paths remain in config.rs

---

### Step 5: Full suite

```bash
cd annulus && cargo build --release 2>&1 | tail -5
cd annulus && cargo test 2>&1 | tail -20
```

**Checklist:**
- [ ] Release build succeeds with no errors or new warnings
- [ ] All tests pass including new context_metrics tests
- [ ] No regressions in existing provider tests

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output
2. Full build and test suite pass in annulus
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- Rendered statusline segment that displays `window_pct` and `pace_tokens_per_hr` in the terminal bar
- Warning color change at 80% and hard visual block at 95%
- Cross-session pace delta (compare current rate to historical average from hyphae)
- Dynamic model limit lookup via Anthropic API instead of hardcoded table
- `ContextMetrics` exposed via annulus's MCP or operator API for cap to consume

## Context

Spawned from Wave 3 audit program (2026-04-23). Two separate sources (claude-hud and claude-pace) independently identified the same gap in annulus: no context window visibility and no token rate signal. The existing `TokenUsage` struct is the right foundation — both metrics are derivable from `input_tokens`, `output_tokens`, and session elapsed time. The XDG path change is bundled here because it is a small config fix that annulus needs regardless of this feature, and it is strictly within the same allowed write scope.
