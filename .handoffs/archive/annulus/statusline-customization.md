# Annulus Statusline Customization

<!-- Save as: .handoffs/annulus/statusline-customization.md -->
<!-- Create verify script: .handoffs/annulus/verify-statusline-customization.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** multi-provider data sources (covered by #104d), JSON output surface (#104b), Cap panel rendering, Codex/Gemini provider support
- **Verification contract:** run the repo-local commands named in the handoff and `bash .handoffs/annulus/verify-statusline-customization.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Problem

The annulus statusline has hardcoded segment order, a fixed two-line layout, flat
pricing that understates cost above 200k tokens, and no context window fill
indicator. Operators cannot reorder, hide, or theme segments without editing Rust
source. The context percentage number exists but there is no visual progress bar
showing how close the session is to compaction.

Three reference tools (ccstatusline, CodexBar, ccusage) demonstrate patterns that
solve these gaps: config-driven widget registries, context window progress bars
with model-aware limits, and tiered pricing with input-token thresholds. This
handoff brings those patterns into annulus.

## What exists (state)

- **`statusline.rs`**: Hardcoded segment rendering with `StatuslineView` struct.
  Segments: context %, token usage, cost, model name, mycelium savings, git
  branch, workspace name. Two-line layout with `│` separators. Color via ANSI
  escape codes. `pricing_for_model()` uses flat per-million rates.
- **`main.rs`**: `statusline` subcommand with `--no-color` flag.
- **`~/.config/annulus/config.toml`**: Referenced in CLAUDE.md as future config
  path, not yet implemented.
- **No segment trait or registry**: Each segment is an inline block in
  `render_statusline()`.

## What needs doing (intent)

1. Add a config file that controls segment visibility, ordering, and context
   window limits per model.
2. Refactor segment rendering into a trait-based registry so segments are
   discoverable, reorderable, and individually toggleable.
3. Add a context window progress bar segment that shows visual fill with
   model-aware max token limits.
4. Fix pricing to use tiered rates with a 200k-token input threshold matching
   Claude's actual billing.

## Scope

- **Primary seam:** statusline rendering pipeline in `annulus/src/statusline.rs`
- **Allowed files:** `annulus/src/statusline.rs`, `annulus/src/config.rs` (new),
  `annulus/src/main.rs`, `annulus/src/segments/` (new directory if needed),
  `annulus/Cargo.toml`
- **Explicit non-goals:**
  - Multi-provider support (Codex, Gemini) — that is #104d
  - JSON output mode — that is #104b
  - Powerline or Nerd Font theme support — complexity for minimal CLI gain
  - TUI or interactive mode
  - Persisting config on behalf of the user (read-only)

---

### Step 1: Config file loading

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** nothing

Add `annulus/src/config.rs` that loads `~/.config/annulus/statusline.toml`. The
config controls segment visibility, ordering, and model-specific context limits.

The config file format:

```toml
# ~/.config/annulus/statusline.toml

# Segment ordering — segments render in this order.
# Omitted segments use defaults. Set enabled = false to hide.
[[segments]]
name = "context"
enabled = true

[[segments]]
name = "usage"
enabled = true

[[segments]]
name = "cost"
enabled = true

[[segments]]
name = "model"
enabled = true

[[segments]]
name = "savings"
enabled = true

[[segments]]
name = "branch"
enabled = true

[[segments]]
name = "workspace"
enabled = true

[[segments]]
name = "context-bar"
enabled = true

# Model-specific context window sizes (tokens).
# Used by context % and context-bar segments.
[context-limits]
opus = 200000
sonnet = 200000
haiku = 200000
```

Design:

- Missing config file: use built-in defaults (all segments enabled, current order,
  200k context limits). No error, no file creation.
- Malformed config file: warn on stderr, fall back to defaults.
- Unknown segment names: ignored with a stderr warning.
- Config struct should derive `Deserialize` and `Default`.
- Add `toml` to `Cargo.toml` dependencies (already in ecosystem at version `1`).

#### Files to modify

**`annulus/src/config.rs`** (new):

- `StatuslineConfig` struct with `segments: Vec<SegmentEntry>` and
  `context_limits: HashMap<String, usize>`
- `SegmentEntry` struct with `name: String` and `enabled: bool`
- `load_config() -> StatuslineConfig` that reads the TOML or returns defaults
- `StatuslineConfig::context_limit_for_model(&self, model: &str) -> usize`

**`annulus/Cargo.toml`**:

- Add `toml = "1"` to `[dependencies]`

#### Verification

```bash
cd annulus && cargo build 2>&1 | tail -5
cd annulus && cargo test config 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.04s
test config::tests::test_context_limit_for_model_case_insensitive ... ok
test config::tests::test_load_config_missing_file_returns_defaults ... ok
test config::tests::test_default_config_has_all_segments ... ok
test config::tests::test_parse_malformed_config_returns_defaults ... ok
test config::tests::test_unknown_segments_are_kept ... ok
test config::tests::test_parse_valid_config ... ok
test statusline::tests::statusline_view_uses_custom_context_limit_from_config ... ok

test result: ok. 8 passed; 0 failed; 0 ignored; 0 measured; 29 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] `StatuslineConfig` loads from `~/.config/annulus/statusline.toml`
- [x] Missing file returns defaults without error
- [x] Malformed file warns on stderr and returns defaults
- [x] `context_limit_for_model` returns model-specific limit or 200k default
- [x] `toml` dependency added to Cargo.toml
- [x] Unit tests cover missing file, valid file, malformed file, and model lookup

---

### Step 2: Segment trait and registry

**Project:** `annulus/`
**Effort:** 1 day
**Depends on:** Step 1

Refactor the hardcoded segment blocks in `render_statusline()` into a segment
trait and registry. Each segment implements a common interface so the config can
control ordering and visibility.

Design:

```rust
/// A named statusline segment that can render itself.
trait Segment {
    /// Registry name matching config file names.
    fn name(&self) -> &str;

    /// Render the segment text. Returns None if data is unavailable.
    fn render(&self, view: &StatuslineView, color: bool) -> Option<String>;

    /// Which line this segment belongs to (1 or 2). Default: 1.
    fn line(&self) -> u8 { 1 }
}
```

Built-in segments (matching current behavior):

| Name | Line | Current function |
|------|------|-----------------|
| `context` | 1 | Context % text |
| `usage` | 1 | Token counts |
| `cost` | 1 | Dollar cost |
| `model` | 2 | Compact model name |
| `savings` | 2 | Mycelium savings |
| `branch` | 2 | Git branch |
| `workspace` | 2 | Workspace name |

The registry is a `Vec<Box<dyn Segment>>` built from the config's segment order.
`render_statusline()` iterates the registry, calls `render()`, filters `None`,
and joins with `│`.

Do not change the default output. An operator with no config file should see the
exact same statusline as today.

#### Files to modify

**`annulus/src/statusline.rs`**:

- Add `Segment` trait
- Implement trait for each existing segment
- Refactor `render_statusline()` to iterate the registry
- Accept `&StatuslineConfig` in `render_and_print()` and `statusline_view()`

#### Verification

```bash
cd annulus && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
test statusline::tests::read_transcript_usage_ignores_assistant_entries_without_usage_payload ... ok
test statusline::tests::read_transcript_usage_sums_assistant_usage ... ok
test statusline::tests::statusline_view_uses_latest_turn_for_context_pct ... ok
test statusline::tests::statusline_view_uses_custom_context_limit_from_config ... ok
test statusline::tests::mycelium_session_savings_reads_sqlite ... ok

test result: ok. 37 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] `Segment` trait defined with `name()`, `render()`, `line()`
- [x] All 7 existing segments implement the trait
- [x] `render_statusline()` uses the registry, not hardcoded blocks
- [x] Default output (no config) is byte-identical to current output
- [x] Existing tests pass without modification
- [x] Config-driven ordering changes segment order in output

---

### Step 3: Context window progress bar segment

**Project:** `annulus/`
**Effort:** 0.5 day
**Depends on:** Step 1, Step 2

Add a `context-bar` segment that renders a visual progress bar showing how full
the context window is. Uses model-aware limits from config.

Rendering format:

```
[ctx ████████░░░░ 67%]     # normal (green)
[ctx ██████████░░ 83%]     # warning (yellow, >= 60%)
[ctx ████████████ 97%]     # critical (red, >= 85%)
[ctx ░░░░░░░░░░░░ --]     # no data
```

Design:

- Bar width: 12 characters (fixed, fits in narrow terminals)
- Fill character: `█` (U+2588), empty: `░` (U+2591)
- Color thresholds match existing `context_pct` logic: green < 60%, yellow
  60-84%, red >= 85%
- Uses `context_limit_for_model()` from config instead of hardcoded 200k
- Segment is on line 1, after the existing `context` segment
- When no usage data is available, renders empty bar with `--`
- Default: enabled. Can be disabled in config.

#### Files to modify

**`annulus/src/statusline.rs`**:

- Add `ContextBarSegment` implementing `Segment`
- Register it in the default segment list

#### Verification

```bash
cd annulus && cargo test context_bar 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
test statusline::tests::context_bar_renders_empty_when_no_data ... ok
test statusline::tests::context_bar_renders_progress_at_normal_level ... ok
test statusline::tests::context_bar_renders_warning_zone ... ok
test statusline::tests::context_bar_renders_critical_at_eighty_five_percent ... ok

test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 33 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] `context-bar` segment renders progress bar with correct fill ratio
- [x] Color thresholds match: green < 60%, yellow 60-84%, red >= 85%
- [x] Uses model-aware context limit from config
- [x] Empty bar rendered when no usage data
- [x] Tests cover normal, warning, critical, and no-data states
- [x] Default output includes context bar (enabled by default)

---

### Step 4: Tiered pricing

**Project:** `annulus/`
**Effort:** 2 hours
**Depends on:** nothing

Fix `pricing_for_model()` and `cost_for_usage()` to use Claude's actual tiered
pricing. Input tokens above 200k are billed at a higher rate.

Current flat rates (Sonnet example):

| Token type | Rate / M |
|------------|----------|
| Input | $3.00 |
| Output | $15.00 |
| Cache read | $0.30 |
| Cache write | $3.75 |

Tiered rates (Sonnet, tokens above 200k input threshold):

| Token type | Base rate / M | Above 200k / M |
|------------|---------------|-----------------|
| Input | $3.00 | $3.00 |
| Output | $15.00 | $15.00 |
| Cache read | $0.30 | $0.30 |
| Cache write | $3.75 | $3.75 |

For Opus and Haiku, the threshold is also 200k, and the tiered rates apply to
cache read and cache write tokens:

**Opus:**

| Token type | Base rate / M | Above 200k / M |
|------------|---------------|-----------------|
| Input | $15.00 | $15.00 |
| Output | $75.00 | $75.00 |
| Cache read | $1.50 | $2.50 |
| Cache write | $18.75 | $25.00 |

**Sonnet:**

| Token type | Base rate / M | Above 200k / M |
|------------|---------------|-----------------|
| Input | $3.00 | $3.00 |
| Output | $15.00 | $15.00 |
| Cache read | $0.30 | $0.50 |
| Cache write | $3.75 | $5.00 |

**Haiku:**

| Token type | Base rate / M | Above 200k / M |
|------------|---------------|-----------------|
| Input | $0.80 | $0.80 |
| Output | $4.00 | $4.00 |
| Cache read | $0.08 | $0.13 |
| Cache write | $1.00 | $1.30 |

Design:

- Extend `Pricing` struct with `cache_read_above_threshold` and
  `cache_creation_above_threshold` fields
- `cost_for_usage()` splits cache tokens at the 200k boundary: base rate for
  tokens up to 200k total input, tiered rate for tokens beyond
- The threshold applies to total prompt tokens (input + cache_read +
  cache_creation)
- When total prompt tokens <= 200k, use base rates throughout
- Update existing pricing tests

#### Files to modify

**`annulus/src/statusline.rs`**:

- Extend `Pricing` struct
- Update `pricing_for_model()` with tiered rates
- Update `cost_for_usage()` with threshold logic

#### Verification

```bash
cd annulus && cargo test pricing 2>&1 | tail -10
cd annulus && cargo test cost 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
test statusline::tests::cost_for_usage_above_threshold_uses_tiered_rates ... ok
test statusline::tests::cost_for_usage_below_threshold_uses_base_rates ... ok
test statusline::tests::cost_for_usage_at_threshold_uses_base_rates ... ok

test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 34 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] `Pricing` struct has tiered cache fields
- [x] `pricing_for_model()` returns tiered rates for Opus, Sonnet, Haiku
- [x] `cost_for_usage()` applies base rate below 200k, tiered above
- [x] Cost for a session entirely below 200k matches current flat-rate behavior
- [x] Cost for a session crossing 200k is higher than flat rate
- [x] Tests cover below-threshold, at-threshold, and above-threshold cases

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/annulus/verify-statusline-customization.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/annulus/verify-statusline-customization.sh
```

**Output:**
<!-- PASTE START -->
PASS: config module exists
PASS: config loads toml with defaults
PASS: toml dependency in Cargo.toml
PASS: segment trait defined
PASS: context-bar segment exists
PASS: tiered pricing fields exist
PASS: cargo build succeeds

running 37 tests
.....................................
test result: ok. 37 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s

PASS: cargo tests pass
Results: 8 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: 8 passed, 0 failed`

All checks pass successfully. No failures.

## Context

Informed by external audit of three reference tools:

- **ccstatusline** (TypeScript/React): widget registry pattern, config-driven
  segment ordering, context bar with progress fill, multi-line flex layout
- **CodexBar** (Swift macOS): provider descriptor pattern with pluggable data
  sources (multi-provider patterns moved to #104d)
- **ccusage** (TypeScript): tiered pricing with 200k threshold, stream-based
  JSONL processing (moved to #104d)

Related handoffs:

- #104a (Unified Output Principles): documentation prerequisite for #104b
- #104b (Statusline JSON Surface): structured JSON output, blocked on #104a
- #104d (Aggregation Data-Source Alignment): multi-provider and JSONL patterns
