# GH Filter Quality Migration

<!-- Save as: .handoffs/mycelium/gh-filter-quality.md -->
<!-- Verify script: .handoffs/mycelium/verify-gh-filter-quality.sh -->
<!-- Parent: .handoffs/mycelium/filter-redesign.md (Step 5, gh item) -->

## Problem

The `gh` commands (`gh pr view`, `gh issue list`, `gh run list`, `gh repo view`,
`gh api`) use a dedicated parser/formatter pipeline in `src/vcs/gh_cmd/` and
`src/vcs/gh_pr/` that does not route through `route_or_filter`. This means:

- gh filter output has no `FilterQuality` signal
- The validation layer (empty fallback, savings threshold, degraded check) doesn't apply
- Token tracking via `FilterResult` is bypassed
- gh was the #1 friction source in the original filter-redesign handoff

The rest of the filter pipeline (cargo, git, curl, docker, runner) now reports
honest quality via `FilterResult::full()`, `FilterResult::degraded()`, and
`FilterResult::passthrough()`.

## Context

Split from [filter-redesign.md](filter-redesign.md) Step 5, which migrated all
`route_or_filter` callers but could not migrate gh because gh uses its own
architecture.

## Architecture

The gh pipeline works differently from other filters:

```
Other commands:
  run command → capture raw → route_or_filter(raw, closure) → FilterResult

GH commands:
  run gh command → custom parser (GhIssueListParser, etc.) → formatted output → println
```

Key files:
- `src/vcs/gh_cmd/mod.rs` — dispatch and entry points
- `src/vcs/gh_cmd/parsers.rs` — structured parsers for gh JSON output
- `src/vcs/gh_cmd/run.rs` — workflow run handlers
- `src/vcs/gh_pr/view.rs` — PR view formatting
- `src/vcs/gh_pr/checks.rs` — PR checks formatting
- `src/vcs/gh_pr/actions.rs` — PR create/merge/etc.

## Design Options

### Option A: Route gh through `route_or_filter`

Capture raw gh output, pass it through `route_or_filter` with the existing
parser as the filter closure. This gets validation, quality tracking, and
Hyphae routing for free.

**Pros:** Uniform pipeline, all benefits of FilterResult
**Cons:** Requires refactoring gh handlers to separate "run command" from "format output"

### Option B: Add FilterResult tracking alongside existing pipeline

Keep the gh parser pipeline but add `FilterResult` construction at the output
point. Track quality based on whether the parser understood the output format.

**Pros:** Minimal refactor, preserves existing gh architecture
**Cons:** Doesn't get validation layer or Hyphae routing

### Option C: Hybrid — route large gh output through `route_or_filter`

Only route gh output through `route_or_filter` when it exceeds the Hyphae
threshold. Small/medium gh output uses the existing parser directly.

**Pros:** Gets Hyphae routing for large output, minimal disruption
**Cons:** Two code paths, quality tracking only for large output

**Recommended:** Option A for new gh handlers, Option B as a quick win for existing ones.

## Implementation

### Step 1: Add FilterResult tracking to gh parsers

**Effort:** 45 minutes

For each gh handler that formats output, wrap the formatted result in
`FilterResult` with quality detection:

- If the parser successfully parsed structured data → `Full`
- If the parser fell back to raw text formatting → `Degraded`
- If the output was passed through unchanged → `Passthrough`

### Step 2: Route gh output through validation

**Effort:** 30 minutes

Add `validate_filter_output` calls at gh output points so the same
empty-fallback, savings-threshold, and degraded-savings rules apply.

### Step 3: Route large gh output through Hyphae

**Effort:** 30 minutes

For gh commands that can produce large output (`gh api`, `gh pr view` with
many comments), route through `route_or_filter` for Hyphae chunked storage.

## Verification

```bash
bash .handoffs/mycelium/verify-gh-filter-quality.sh
```

**Checklist:**
- [x] gh pr handlers return/track FilterResult (view, checks, list, actions)
- [x] gh issue handlers return/track FilterResult (list, view)
- [x] gh run handlers return/track FilterResult (list, filter_run_view_output)
- [x] Parser detects format mismatch → Degraded/Passthrough quality
- [x] Large gh output routes through Hyphae when available (pr view, issue view, run view, api, pr diff)
- [x] `cargo test` passes (1444 tests, 0 failures)
- [x] `cargo clippy` clean (0 warnings)

**Status: Complete.** All 3 steps implemented — quality tracking, validation, and Hyphae routing.
