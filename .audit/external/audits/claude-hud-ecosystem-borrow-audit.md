# Claude HUD Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `claude-hud` (github.com/jarrodwatts/claude-hud)
Lens: segment composition, configuration schema, transcript parsing, and rendering pipeline

## One-paragraph read

`claude-hud` is a zero-dependency, single-pass TypeScript statusline plugin for Claude Code that reads native stdin JSON and parses JSONL transcripts to display context usage, tool activity, agent status, todo progress, and rate-limit windows in the terminal. The architecture is clean and narrow: one entry point, a flat render pipeline, individually composable line modules, a merge-group layout system, and a configuration schema with 30+ typed display toggles backed by graceful defaults. The strongest ideas are the buffered context percentage calculation (with autocompaction awareness), the file-mtime-keyed transcript cache, the external usage snapshot contract for operator-supplied usage data, and the color resolution system that accepts named presets, 256-color indices, and hex strings in one resolver. The primary fit is `annulus`, which already owns the statusline rendering surface. Secondary touches reach `septa` (for the external usage snapshot contract) and `cortina` (for the transcript parsing model). Nothing here suggests a new tool.

## What claude-hud is doing that is solid

### 1. Buffered context percentage that accounts for autocompaction

The naïve context percentage (used tokens / context limit) is misleading in Claude sessions because the model compacts before the hard limit. `claude-hud` computes a buffered percentage that scales with reported usage: 0% usage maps to 0% buffer, ~50% usage maps to roughly 10% added buffer, producing an operator-visible "real available headroom" that tracks autocompaction behavior. A second function (`getContextPercent`) returns the raw value so both readings are available.

Evidence:
- `src/stdin.ts`: `getBufferedPercent()` and `getContextPercent()`, both consuming `StdinData`
- `src/types.ts`: `StdinData` with `context_window_tokens`, `context_window_percentage`, `total_input_tokens`

Why this matters: `annulus` currently uses a straight token ratio for its `context-bar` segment. The autocompaction-aware buffer is a concrete improvement applicable directly to `annulus/src/statusline.rs` where context percentage is computed before rendering.

### 2. File-mtime-keyed transcript cache with session isolation

The transcript parser caches its output to disk keyed by SHA-256 of the canonical transcript path. On each invocation it compares the cached mtime and file size against the current values; if either changed, it re-parses. Cache files sweep automatically at 1% probability per run, with a 7-day TTL and a 100-file cap. Session isolation is per-transcript-path hash so concurrent Claude Code instances do not collide.

Evidence:
- `src/transcript.ts`: `parseTranscript()` with mtime/size validation before cache use
- `src/context-cache.ts`: `writeCache()` (3-second write throttle), `sweepCacheDir()`, `isSuspiciousZero()` and `applyCachedContext()` for zero-value recovery

Why this matters: `annulus` reads Claude transcripts on every statusline invocation (every 300ms or so). It does not appear to cache parsed results. A mtime-keyed cache at the `annulus` NDJSON reader level in `annulus/src/providers/claude.rs` would avoid redundant parse work on unchanged transcripts. The suspicious-zero recovery pattern is also applicable: the same class of bug (native usage reporting zero for a session with accumulated input tokens) could surface in `annulus`.

### 3. External usage snapshot contract for operator-supplied usage data

`claude-hud` defines a minimal JSON schema for an operator or companion tool to write usage snapshots that the statusline will read with a configurable freshness window:

```json
{
  "updated_at": "2026-04-20T12:00:00.000Z",
  "five_hour": { "used_percentage": 42, "resets_at": "2026-04-20T15:00:00.000Z" },
  "seven_day":  { "used_percentage": 84, "resets_at": "2026-04-27T12:00:00.000Z" }
}
```

The reader validates the timestamp, checks freshness against `externalUsageFreshnessMs`, constrains percentages to 0-100, and returns `null` on any failure. This decouples the statusline from any one usage API implementation.

Evidence:
- `src/external-usage.ts`: `getUsageFromExternalSnapshot()` with freshness check and range clamping
- `src/config.ts`: `display.externalUsagePath` and `display.externalUsageFreshnessMs` toggles
- README configuration table: both options documented with defaults

Why this matters: `annulus` currently reads usage from the native stdin payload directly. The external snapshot contract lets a companion process (or `cortina`) write usage to a file that any statusline can read without needing OAuth or host config access. This is a clean separation that belongs in `septa` as a named contract.

### 4. Color resolution that unifies named presets, 256-color indices, and hex strings

The color resolver accepts a `ColorValue` union (`'dim' | 'red' | ... | number | `#${string}`` ) and resolves it to an ANSI escape sequence through a single `resolveAnsi()` function. Named presets map to standard ANSI codes. Integer values produce 256-color sequences (`\x1b[38;5;${n}m`). Hex strings are parsed into truecolor sequences via `hexToAnsi()`. The same resolver feeds every segment; no segment hardcodes colors.

Evidence:
- `src/render/colors.ts`: `resolveAnsi()`, `hexToAnsi()`, `ANSI_BY_NAME`, `quotaBar()`, `coloredBar()`
- `src/config.ts`: `ColorValue` type and per-key color defaults in the config schema

Why this matters: `annulus` renders with hardcoded ANSI codes in segment renderers. A unified color resolver at the `annulus` level (even if it only supports named presets initially) would allow the config to control colors without touching renderer code.

### 5. Segment ordering via declarative `elementOrder` array with merge groups

Segments are not rendered in a fixed sequence. The operator configures an `elementOrder` string array; the render pipeline iterates that array, calling each segment's renderer and assembling the output. A `display.mergeGroups` setting controls which segments appear on the same physical line. When merged segments exceed terminal width, the renderer falls back to stacking them vertically. Each segment renderer returns `null` when it has no data, which removes it from the line without any special casing.

Evidence:
- `src/config.ts`: `HudElement` enum, `elementOrder` default, `display.mergeGroups` default `[["context","usage"]]`
- `src/render/index.ts`: `renderExpanded()` iterating `elementOrder`, merge group logic, width-aware stacking
- `src/render/lines/`: each line module (`identity.ts`, `project.ts`, `usage.ts`, `memory.ts`, etc.) returns `string | null`

Why this matters: `annulus` has a `segments` array in its config (`src/config.rs`), but the render loop is currently fixed-order inside `render_and_print_terminal`. The merge-group model, where two segments can be requested to share a line but gracefully stack on overflow, is worth adopting in `annulus` for multi-segment layouts.

### 6. Typed configuration with per-field toggles, defaults, and graceful merge

The configuration type defines 30+ typed boolean, enum, and numeric fields, each with a default. The `mergeConfig()` function runs per-field validator functions that clamp or reset invalid values rather than rejecting the whole file. A legacy migration shim converts the deprecated `layout` key to `lineLayout`. If the config file is missing or unparseable, `loadConfig()` returns the full defaults without error.

Evidence:
- `src/config.ts`: `HudConfig` interface, `DEFAULT_CONFIG`, `mergeConfig()` validators, `loadConfig()` with try-catch fallback
- Migration shim: `layout` → `lineLayout` + `showSeparators` in `mergeConfig()`

Why this matters: `annulus` currently reads a TOML config with a small `segments` array and a `context-limits` map (`src/config.rs`). There is no per-field validation, no migration path, and no recovery shim. As annulus grows more segments, the lack of a `mergeConfig`-style approach will become a maintenance burden.

## What to borrow directly

### Borrow: autocompaction-aware buffered context percentage

The math in `getBufferedPercent()` is self-contained and grounded in the real behavior of Claude's autocompaction system. Copy the buffer scaling logic into `annulus/src/statusline.rs` where the `context_pct` field is computed. The raw percentage remains available as a fallback for hosts that do not trigger autocompaction.

Best fit: `annulus`.

### Borrow: file-mtime-keyed transcript parse cache

The pattern is simple: hash the canonical file path, store `{mtime, size, parsed_result}`, re-parse only when either changes, sweep stale entries probabilistically. Apply this to `annulus/src/providers/claude.rs` at the NDJSON transcript reader level. The suspicious-zero recovery pattern (detect a session with nonzero total tokens but zero reported context usage, restore from last good snapshot) is directly applicable to annulus as well.

Best fit: `annulus` (providers/claude.rs).

### Borrow: external usage snapshot contract (with septa ownership)

The JSON schema for usage snapshots is clean and minimal. Borrow it as a `septa`-owned contract so that `cortina`, companion scripts, or future tools can write usage to a shared file path and `annulus` reads it with the standard freshness check. The schema fits inside septa's existing named contract structure.

Best fit: `septa` (contract definition), `annulus` (reader), `cortina` (writer candidate).
Needs septa contract: yes.

### Borrow: per-segment null-return pattern

Each renderer returns `null` when it has nothing to show. The caller skips null segments rather than rendering empty lines or placeholder text. This is already implicit in `annulus` but not systematically enforced; making it explicit across all segment renderers would improve layout consistency.

Best fit: `annulus`.

## What to adapt, not copy

### Adapt: declarative segment ordering and merge groups

The `elementOrder` + `mergeGroups` model is the right direction, but `annulus` should own this in TOML rather than JSON, and the Rust render loop should handle the merge logic. The adaptation is: expand `StatuslineConfig` in `annulus/src/config.rs` to accept an ordered segments list with an optional `merge_with` field, and update `render_and_print_terminal` in `annulus/src/statusline.rs` to iterate that order instead of a fixed sequence.

Do not copy the TypeScript width-aware stacking code directly — rewrite it in Rust against annulus's existing terminal width utilities.

Best fit: `annulus`.

### Adapt: unified color resolution

The resolver approach (union type → ANSI code) is the right model. Adapt it in Rust: a `ColorSpec` enum with `Named`, `Index256(u8)`, and `Hex(u8, u8, u8)` variants, deserialized from TOML in annulus's config, resolved to ANSI escape sequences at render time. Do not replicate the full 16+ named preset list verbatim; start with the subset annulus already uses and expand on demand.

Best fit: `annulus`.

### Adapt: config validation with per-field recovery

The pattern of running per-field validators that clamp or default rather than reject the whole config is worth adopting in annulus. The Rust adaptation is simpler — parse the TOML into a `RawConfig` struct, then apply range checks and defaults to produce the final `StatuslineConfig`. A migration shim for renamed keys can live alongside `load_config()` in `annulus/src/config.rs`.

Best fit: `annulus`.

### Adapt: agent/todo segment data model

The `AgentEntry` and `TodoItem` types in `src/types.ts` are well-scoped. Annulus doesn't yet render agent or todo segments; if it adds them, the transcript parsing logic in `src/transcript.ts` is a good reference for how to extract `TodoWrite`, `TaskCreate`, and `TaskUpdate` operations from NDJSON and maintain stateful todo lists across transcript entries. The adaptation requires translating the JSONL parsing into Rust's serde model.

Best fit: `annulus`.

## What not to borrow

### Skip: Node.js plugin packaging and stdin update loop design

`claude-hud` uses Claude Code's native plugin API (`~/.claude/plugins/claude-hud/`) with a single-pass stdin execution model — Claude Code invokes the plugin process each time it updates the statusline and passes data via stdin. `annulus` is a standalone Rust binary invoked directly by the host shell. The packaging model, plugin manifest, and invocation contract are all Claude Code-specific. Do not adopt the plugin packaging or the `commands/` directory layout.

### Skip: i18n system

The internationalization layer (`src/i18n/`) supporting English and Chinese label translations is product-specific scope inflation for a statusline. `annulus` should remain English-only until there is a concrete operator need.

### Skip: JavaScript transcript parsing verbatim

The `src/transcript.ts` logic for parsing JSONL is useful as a reference, but annulus already has a working NDJSON transcript reader in `annulus/src/providers/claude.rs`. Do not adopt the JS implementation as a script dependency; use it as a structural reference for future Rust additions.

### Skip: config stored at `~/.hud/config.json`

`claude-hud` writes its config to a product-specific path outside `.claude`. `annulus` already owns `~/.config/annulus/statusline.toml` as its config location. This is the right path for annulus; do not introduce a competing config location.

## How claude-hud fits the ecosystem

### Best fit by repo

**annulus**: Primary fit across almost everything valuable here. The rendering model, segment ordering, configuration schema, and transcript caching all belong in annulus. The existing `annulus/src/statusline.rs` segment renderer and `annulus/src/providers/claude.rs` transcript reader are the direct landing zones.

**septa**: The external usage snapshot schema is the only clear septa candidate. It is a minimal, shared contract that decouples usage producers (cortina, companion tools) from usage consumers (annulus). Defining it in septa gives it a stable home with validation fixtures.

**cortina**: A natural writer for usage snapshots once the septa contract is defined. The transcript parsing patterns in `src/transcript.ts` are also reference material for any cortina signal-capture work that reads JSONL.

**cap**: No direct fit. `claude-hud` has no UI surface beyond terminal rendering.

**stipe**: No direct fit. `claude-hud` manages its own install via the Claude Code plugin API; nothing here is relevant to stipe's host injection model.

**canopy/hymenium/volva**: No fit.

### Needs septa contract?

Yes, for the external usage snapshot schema. One entry in `septa/` with a JSON Schema definition and a fixture JSON file would let `cortina` write and `annulus` read usage data through a stable, validated contract.

## What claude-hud suggests improving in your ecosystem

### 1. annulus should add autocompaction-aware context percentage

The current `context-bar` segment computes a straight token ratio. The buffered percentage from `getBufferedPercent()` is a concrete, tested improvement that matches how Claude actually behaves under compaction pressure. This is a near-term annulus improvement, not a future consideration.

### 2. annulus should cache parsed transcript results

Re-reading and re-parsing the full NDJSON transcript on every invocation is avoidable. A mtime-keyed disk cache in `annulus/src/providers/claude.rs` would reduce steady-state parsing cost, especially for long sessions with large transcript files.

### 3. septa lacks a usage snapshot contract

`claude-hud` ships an operator-accessible file format for usage data that any tool can write and any statusline can read. `annulus` currently reads usage only from native stdin. A `septa` contract for the snapshot format would let `cortina` emit standardized usage data that `annulus` reads, decoupling the statusline from the API-access concern.

### 4. annulus config should grow merge-group and color-resolution capabilities as segments expand

The current config (`~/.config/annulus/statusline.toml`) supports segment ordering by name but not merge groups or per-segment color overrides. As annulus adds agent and todo segments (both feasible given the transcript reader already exists), the config will need the same evolution `claude-hud` went through — typed color specs, per-segment toggles, and merge-group declarations. Plan for this before the segment list grows past the current nine.

### 5. The suspicious-zero transcript recovery pattern deserves a place in annulus

Context usage reporting zero for a session with nonzero accumulated input tokens is a known Claude Code bug class. `context-cache.ts` addresses it with a last-good-value snapshot. `annulus` should adopt an equivalent recovery mechanism so the `context-bar` segment does not silently drop to zero mid-session.

## Verification context

This audit was based on reading the claude-hud repository source code, README, configuration reference, and TypeScript source files. Files read directly include `src/types.ts`, `src/stdin.ts`, `src/transcript.ts`, `src/context-cache.ts`, `src/config.ts`, `src/external-usage.ts`, `src/git.ts`, `src/render/index.ts`, `src/render/colors.ts`, `src/render/lines/usage.ts`, `src/render/tools-line.ts`, `src/render/agents-line.ts`, `src/render/todos-line.ts`, and `package.json`. Cross-referenced against `annulus/src/statusline.rs`, `annulus/src/config.rs`, and `annulus/src/providers/mod.rs`. No local build or execution was performed.

## Final read

**Borrow directly**: autocompaction-aware buffered context percentage into annulus's context-bar segment; file-mtime-keyed transcript parse cache into annulus's Claude provider; external usage snapshot schema into septa; per-segment null-return discipline into annulus.

**Adapt**: declarative segment ordering with merge groups (TOML config + Rust render loop); unified color resolution (Rust enum + TOML deserialization); config validation with per-field recovery; agent/todo segment types as reference for future annulus additions.

**Skip**: Node.js plugin packaging, Claude Code plugin invocation contract, i18n system, config path at `~/.hud/config.json`.

The external usage snapshot schema is the only new septa candidate. Everything else lands in `annulus`. No new tool is warranted.
