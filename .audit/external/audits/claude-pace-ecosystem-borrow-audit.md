# claude-pace Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `claude-pace` by Astro-Han (github.com/Astro-Han/claude-pace)
Lens: burn rate calculation, rate limit pacing model, cache safety, segment format, and test discipline in a single-file Bash statusline

## One-paragraph read

`claude-pace` is a single 270-line Bash + jq statusline for Claude Code that reads quota data from stdin `rate_limits` (available on Claude Code 2.1.80+) and computes a pace delta — the difference between actual usage percentage and the fraction of the window that has elapsed. A pace delta of ⇡15% means you are burning 15% faster than sustainable; ⇣15% means you have headroom. The script handles two quota windows (5-hour and 7-day), git diff stats, effort level glyphs, context window percentage, a symmetric two-line layout with pipe alignment, and a private-directory cache (XDG_RUNTIME_DIR or ~/.cache/claude-pace, mode 700) with atomic writes, symlink rejection, and TTL-gated git refresh. The pace delta formula is the sharpest idea: `delta = used_pct - ((window_minutes - remaining_minutes) * 100 / window_minutes)`. The cache hardening is the most production-quality part of the implementation. The test suite (33+ regression cases) covers expired cache rejection, null/empty rate_limits, symlink injection, unreadable cache files, and per-effort-level glyph alignment. The primary ecosystem fit is annulus, which does not yet model rate limit windows or burn rate at all.

## What claude-pace is doing that is solid

### 1. Pace delta formula — the core differentiator

The burn rate calculation is a single arithmetic expression that converts two percentages and one duration into an actionable signal:

```bash
d=$((u - (w - rm) * 100 / w))
```

Where `u` is used percentage, `w` is window width in minutes, and `rm` is minutes remaining. This gives the difference between "what you have spent" and "what you should have spent by now if evenly distributed." Positive is overspend (red ⇡), negative is headroom (green ⇣). The formula is correct, branchless, and requires no floating-point math. It works equally well for the 5-hour window (w=300) and the 7-day window (w=10080) with no special-casing.

Evidence: `_usage()` function in `claude-pace.sh` lines 185-205, applied as `$(_usage "$U5" "$RM5" 300)` and `$(_usage "$U7" "$RM7" 10080)`.

### 2. Cache safety without shared /tmp

The cache layer makes a set of correct decisions: choose XDG_RUNTIME_DIR first, fall back to ~/.cache/claude-pace, create mode 700, reject symlinks (`[ ! -L "$1" ]`), reject files not owned by the current user (`[ -O "$1" ]`), write atomically via mktemp + mv, and disable caching entirely if no safe root is available rather than silently falling back to /tmp. Cache invalidation checks both reset timestamps before accepting a cached quota snapshot — if either reset time has already passed, the whole snapshot is rejected.

Evidence: `_cache_dir_ok()`, `_write_cache_record()`, `_valid_quota_snapshot()`, and the stale-check in the git cache path (5s TTL). CHANGELOG 0.7.1 documents the migration away from shared /tmp as an intentional security fix.

### 3. Quota cache graceful degradation on stdin gaps

When Claude Code omits `rate_limits` from the stdin payload (older versions, or certain run contexts), claude-pace checks its private cache for a previously valid snapshot. If the cached reset times are still in the future, the cached percentages are served as if live. If either reset time has expired, the full snapshot is rejected and session cost is displayed as a fallback. This makes the statusline useful across Claude Code versions without requiring a network call.

Evidence: the `SHOW_COST` logic and cache read path at lines ~145-175 of `claude-pace.sh`; CHANGELOG 0.8.1 explicitly describes this behavior; test cases 26-31 cover the expired/null/empty-object/null-value branches.

### 4. Single jq call to parse both stdin and settings.json

All data extraction from stdin and from `~/.claude/settings.json` happens in a single `jq --slurpfile cfg` invocation. This is significant: the statusline is polled at ~300ms intervals, and jq process overhead is the dominant cost. Collapsing it into one call (reading 11 fields via `@tsv`) avoids repeated process spawning while keeping the parse logic auditable in one place.

Evidence: the `IFS=$'\t' read -r MODEL DIR PCT CTX COST EFF HAS_RL U5 U7 R5 R7 < <(jq -r ...)` block; the comparison table in the README showing ~10ms execution vs ~90ms for Node-based alternatives.

### 5. Pipe alignment via ANSI-stripped width measurement

The two-line layout aligns the `|` separator by measuring the plain-text width of each left section independently (stripping color codes), then padding the shorter side. This keeps the layout correct regardless of model name length, effort glyph, or context bar content.

Evidence: `L1_PLAIN`/`L2_PLAIN` measurement and `PAD1`/`PAD2` computation before final output; `assert_aligned` tests in `test.sh` run for every effort level.

### 6. Regression test suite covering adversarial cache states

The test suite (33+ cases by 0.8.3) goes beyond happy-path coverage. It explicitly tests: symlink injection into the quota cache path, unreadable cache files (chmod 000), empty-object vs null rate_limits, explicit null rate_limits, expired R5 only, expired R7 only, empty stdin, and absent settings.json fallback. Each test variant is isolated in its own temp directory with a controlled HOME and XDG_RUNTIME_DIR.

Evidence: `test.sh` tests 26-34; the README comparison table notes that security hardening was an intentional design axis, not an afterthought.

## What to borrow directly

### Borrow: pace delta formula as an annulus segment (annulus)

annulus has no rate limit awareness at all. The septa `annulus-statusline-v1.schema.json` `usage-value` definition tracks `input_tokens`, `output_tokens`, `cache_read_tokens`, and `cache_creation_tokens` — nothing about quota windows, used percentages, or reset times. The pace delta formula is pure arithmetic with no dependencies and translates directly into Rust:

```rust
fn pace_delta(used_pct: u8, window_minutes: u64, remaining_minutes: u64) -> i64 {
    let elapsed_pct = (window_minutes - remaining_minutes) * 100 / window_minutes;
    used_pct as i64 - elapsed_pct as i64
}
```

This belongs in annulus as a new segment — `rate-limit` or `quota-pace` — that reads `rate_limits` from the statusline stdin JSON and emits pace delta, used percentage, and countdown for each window. The segment should live beside `UsageSegment` in `statusline.rs`.

### Borrow: private-directory cache pattern for git stats (annulus)

annulus currently reads git branch and diff stats on each statusline poll. claude-pace's approach — SHA-based cache key derived from the workspace dir, 5s TTL, atomic write via mktemp + mv, XDG_RUNTIME_DIR first — is the right pattern for this. annulus should adopt the same cache safety conventions for any per-poll I/O.

### Borrow: single-call jq invocation pattern (annulus, cortina)

The `--slurpfile cfg` pattern for reading settings alongside stdin in one process is a micro-optimization that compounds at 300ms poll intervals. Anywhere annulus or cortina parses structured input alongside config, this pattern avoids redundant process spawning.

### Borrow: adversarial cache test patterns (annulus)

The test cases for symlink injection (test 32), unreadable files (test 33), expired partial snapshots (tests 26-27), and null vs empty-object disambiguation (tests 30-31) are directly reusable as a test template for any annulus cache layer.

## What to adapt, not copy

### Adapt: quota window schema into septa

claude-pace encodes the rate_limits shape implicitly in its jq expression: `.rate_limits.five_hour.used_percentage`, `.rate_limits.five_hour.resets_at`, `.rate_limits.seven_day.*`. This is the shape Claude Code 2.1.80+ emits. septa does not have a `claude-rate-limits` contract yet. The right move is to define a `claude-rate-limits-v1.schema.json` in septa that captures `five_hour` and `seven_day` as typed objects with `used_percentage: integer` and `resets_at: integer (unix epoch)`. This makes the shape explicit for annulus (consumer), cortina (signal emitter if it captures usage events), and cap (dashboard display). Do not copy the Bash inline schema; add a real septa contract.

### Adapt: graceful degradation model for absent data (annulus)

claude-pace's three-tier degradation (live stdin → cached snapshot with future resets → session cost fallback → `--`) is the right user experience. Adapt this state machine into annulus's segment availability model: a segment can be `available: true` with live data, `available: true` with cached data (annotate the staleness), or `available: false` with a reason. The exact code does not transfer (Bash to Rust), but the degradation states do.

### Adapt: effort level glyph system (annulus)

The five-step circle family (`◌ ○ ◎ ◉ ●`) for effort levels (low/medium/high/xhigh/max) is a clean visual design with consistent cell width. annulus currently handles `effortLevel` from settings. Adopt the same glyph set rather than inventing a parallel system.

## What not to borrow

### Skip: the Bash runtime itself

The script is bash + jq precisely because it has no build step and zero npm. annulus is a compiled Rust binary. The script approach is appropriate for claude-pace's install-anywhere goal; it adds nothing for annulus, which already has a faster and more maintainable implementation path.

### Skip: the symmetric pipe alignment via string measurement

annulus renders segments as JSON objects (via `annulus statusline --json`) and delegates final terminal rendering to the operator or shell prompt. The ANSI-stripped width measurement and PAD computation are specific to claude-pace's direct terminal output. annulus's segment model separates data from rendering, so this layout technique does not apply.

### Skip: npx installer / plugin manifest

The `.claude-plugin` marketplace integration and `npx claude-pace` one-step install are distribution mechanisms for an end-user CLI tool. annulus ships as part of the basidiocarp ecosystem via stipe. The distribution strategy does not transfer.

### Skip: worktree identity heuristic

claude-pace detects Claude Code worktrees by matching `/.claude/worktrees/` in the project dir path and extracts the repo name from the parent. This is a fragile string-match heuristic. annulus should derive worktree identity from the actual git object model, not path parsing.

## How claude-pace fits the ecosystem

### Best fit by repo

- **annulus**: Primary fit. The pace delta segment, rate limit window model, and cache safety patterns all belong here. annulus has the segment infrastructure; it needs the rate-limit data path.
- **septa**: Moderate fit. A `claude-rate-limits-v1` contract formalizes the stdin shape that annulus and cortina both need to handle.
- **cortina**: Weak fit. If cortina captures lifecycle signals on session end, a rate-limit usage snapshot (used percentages at close) is a useful signal. The degradation model is reference material for cortina's signal-absent fallbacks.
- **cap**: Weak fit. If cap renders a quota dashboard, the pace delta calculation and two-window display model are good references for the UI logic. No code transfer; concept transfer only.
- **spore**: No fit. The caching and cache-safety patterns are runtime behavior in annulus, not shared library primitives.

## What claude-pace suggests improving in your ecosystem

### 1. annulus has no rate limit segment

The annulus `usage-value` schema tracks token counts from the transcript file. It has no concept of the `rate_limits` object that Claude Code 2.1.80+ emits in the statusline stdin JSON. claude-pace shows that this data is available, actionable, and frequently the thing operators actually want to see. annulus needs a `quota-pace` segment that reads `rate_limits` from stdin, computes pace delta for both windows, and emits used percentages, countdown, and delta direction.

### 2. septa has no `claude-rate-limits` schema

The shape of `.rate_limits.five_hour` and `.rate_limits.seven_day` is currently undocumented in septa. Two tools — claude-pace externally, and any future annulus segment internally — are independently parsing the same undocumented Claude Code payload. A `claude-rate-limits-v1.schema.json` in septa makes this shape a first-class contract with a validated fixture.

### 3. annulus cache safety is not yet specified

annulus does not yet have a cache layer for the git stats it reads on each poll. claude-pace's cache design (XDG_RUNTIME_DIR first, mode 700, symlink rejection, atomic writes, TTL per data type) is a complete and security-reviewed answer to the problem annulus will encounter when it adds polling-frequency I/O. The pattern should be adopted proactively, not retrofitted after a bug.

### 4. Effort level glyph divergence risk

annulus handles `effortLevel` but the glyph mapping may diverge from claude-pace's established five-step circle family. Given that operators may run both tools side-by-side or compare outputs, consistent glyphs matter. Locking annulus to the same set now avoids a cosmetic inconsistency that would be visible to users of both.

## Verification context

This audit was based on reading `claude-pace.sh` (the full script), `README.md`, `CHANGELOG.md`, `test.sh` (tests 26-34), and the `.claude-plugin` manifest via the GitHub API. annulus source at `/Users/williamnewton/projects/basidiocarp/annulus/src/statusline.rs` and `septa/annulus-statusline-v1.schema.json` were read to confirm the gap. No build or execution was performed. The pace delta formula was verified by manual substitution against the example scenarios in the README.

## Final read

**Borrow directly**: pace delta formula (annulus `quota-pace` segment), private-directory cache pattern (annulus git cache layer), single-call jq + config parse pattern (annulus and cortina), adversarial cache test templates (annulus test suite).

**Adapt**: quota window schema into a septa `claude-rate-limits-v1` contract; three-tier degradation model into annulus segment availability states; effort level glyph set into annulus's existing effort display.

**Skip**: Bash runtime, terminal pipe alignment via string measurement, npx/plugin distribution, worktree path-parsing heuristic.

The strongest single contribution is the pace delta formula: it is correct, dependency-free, and directly implementable in Rust as an annulus segment. The second strongest is the cache safety model, which annulus will need the moment it adds any per-poll I/O beyond the transcript read it already does.
