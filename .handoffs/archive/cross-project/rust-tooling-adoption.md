# Cross-Project Rust Tooling Adoption

## Problem

The Rust repos have grown large enough that test execution speed, benchmark discipline,
and performance investigation ergonomics now matter, but the workspace does not yet
have a consistent story for `cargo-nextest`, `criterion`, or whole-command timing.

Without an explicit adoption plan, these tools either never get used or get added
ad hoc in one repo at a time with inconsistent verification and docs.

## What exists (state)

- **Test execution:** there is partial `cargo-nextest` adoption already.
  `mycelium` has a `cargo nextest` command surface and output filter, and `stipe`
  already recognizes `cargo-nextest` as a developer tool, but the ecosystem does
  not yet have a standardized repo-by-repo adoption and documentation plan.
- **Benchmarks:** there is no established benchmark harness in the Rust repos.
- **Performance investigation:** there is no documented fallback workflow for whole-command timing in the ecosystem docs.
- **Stipe UI:** `stipe` currently uses `dialoguer` and `indicatif`, not a full TUI.

## What needs doing (intent)

Adopt the low-bloat Rust tooling that improves developer workflow across the ecosystem,
while keeping product-facing TUI questions separate.

## Compile-Info Findings To Carry Into This Work

The compile-info audit already identified where benchmarking and profiling are most
likely to pay off, and where tooling changes should stay documentation-only until
there is a concrete target.

- **`mycelium`** — strong first-wave benchmark target.
  The compile-info audit calls out binary size pressure from bundled SQLite and
  explicitly notes missing `[profile.dev]` tuning in
  [`.audit/workspace/compile-info/mycelium.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/mycelium.md).
  This reinforces that Mycelium filtering and token-shaping paths are worth
  measuring with Criterion.
- **`rhizome`** — strong first-wave benchmark and profiling target.
  The compile-info audit identifies a 33 MB binary with major grammar-driven cost,
  narrowed Tokio feature opportunities, and missing `[profile.dev]` tuning in
  [`.audit/workspace/compile-info/rhizome.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/rhizome.md).
  Parser, index, and search paths are valid hot-path candidates.
- **`hyphae`** — optional benchmark scope, but compile-info points more toward
  feature and dependency trimming than obvious first-wave benchmarks.
  See [`.audit/workspace/compile-info/hyphae.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/hyphae.md).
- **`stipe`**, **`cortina`**, **`canopy`**, **`spore`**, and **`volva`** —
  nextest and performance investigation guidance are still useful, but the compile-info audit
  mostly points to dependency, profile, and packaging fixes rather than immediate
  Criterion adoption.
- **Cross-cutting** — the audit’s shared summary in
  [`.audit/workspace/compile-info/cross-cut.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/cross-cut.md)
  should be treated as prioritization input when choosing where benchmarks and
  profiling guidance land first.

This means the first implementation wave should bias toward `mycelium/` and
`rhizome/`, with `hyphae/` remaining optional and the other repos staying
documentation-only unless a concrete benchmark target is named.

## Repo-Owned Follow-Ups

This umbrella handoff coordinates the shared plan. Repo-local implementation should
land in the follow-up handoffs below, not drift back into one giant cross-project
 note.

- [`.handoffs/archive/mycelium/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/mycelium/rust-tooling-adoption.md)
- [`.handoffs/archive/rhizome/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/rhizome/rust-tooling-adoption.md)
- [`.handoffs/archive/hyphae/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/rust-tooling-adoption.md)
- [`.handoffs/archive/stipe/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/stipe/rust-tooling-adoption.md)
- [`.handoffs/archive/cortina/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/cortina/rust-tooling-adoption.md)
- [`.handoffs/archive/canopy/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/canopy/rust-tooling-adoption.md)
- [`.handoffs/archive/spore/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/spore/rust-tooling-adoption.md)
- [`.handoffs/archive/volva/rust-tooling-adoption.md`](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/volva/rust-tooling-adoption.md)

---

### Step 1: Standardize and document `cargo-nextest`

**Project:** `cross-project/` plus repo-owned follow-ups
**Effort:** 30-45 min
**Depends on:** nothing

Document the shared nextest workflow and update the repo-owned handoffs so they each
have a clear local command surface. This should be a tooling and documentation change,
not a runtime dependency.

#### Files to modify

**`docs/` plus repo-owned handoffs** — add nextest usage and scope:

```text
- how to install cargo-nextest
- which repos are first-wave adopters vs later-wave adopters
- exact commands to use locally and in CI
- how repo-local follow-ups should verify adoption
```

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cargo nextest --version
```

**Output:**
<!-- PASTE START -->
cargo-nextest 0.9.132
release: 0.9.132
host: aarch64-apple-darwin

<!-- PASTE END -->

**Checklist:**
- [x] nextest installation and usage are documented
- [x] the first-wave repos have a clear nextest command surface

---

### Step 2: Add targeted Criterion benchmarks

**Project:** `mycelium/`, `rhizome/`, optionally `hyphae/` via repo-owned follow-ups
**Effort:** 45-90 min
**Depends on:** Step 1

Add `criterion` only where it measures known hot paths. Start with the places where
throughput and latency are already important, such as Mycelium filtering/token work
and Rhizome parser/index/search work.

#### Files to modify

**Repo-local `Cargo.toml` / `benches/` plus repo-owned handoffs** — benchmark harnesses:

```text
- add criterion as a dev-only benchmark dependency
- add one or two meaningful benchmarks, not placeholder benches
- document how to run them
- keep non-benchmark repos explicitly out of scope
```

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd mycelium && cargo bench --no-run --bench tooling_hot_paths
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `bench` profile [optimized] target(s) in 0.37s
  Executable benches/tooling_hot_paths.rs (target/release/deps/tooling_hot_paths-a54e81307348afbe)

<!-- PASTE END -->

```bash
cd rhizome && cargo bench --no-run -p rhizome-treesitter --bench parse_symbols
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `bench` profile [optimized] target(s) in 0.33s
  Executable benches/parse_symbols.rs (target/release/deps/parse_symbols-eeb6ed0ba2147bde)

<!-- PASTE END -->

**Checklist:**
- [x] Criterion was added only to repos with real benchmark targets
- [x] at least one meaningful benchmark compiles in each adopted repo

---

### Step 3: Document profiling fallback guidance

**Project:** `cross-project/` plus repo-owned follow-ups
**Effort:** 20-30 min
**Depends on:** Step 2

Add a shared fallback workflow for end-to-end timing when Criterion is too narrow.
This should stay as operator tooling and documentation, not a runtime crate dependency.

#### Files to modify

**`docs/` plus repo-owned handoffs** — performance investigation guidance:

```text
- example timing commands for mycelium and rhizome
- when to use whole-command investigation vs criterion
- which repos should remain documentation-only
```

#### Verification

Summarize the adopted fallback approach and **paste it below**.
Do NOT mark this step complete until the note is pasted.

**Output:**
<!-- PASTE START -->
Use whole-command timing plus targeted tracing as the cross-repo fallback when
Criterion is too narrow.

Examples:
- `time cargo run -p rhizome-cli --bin rhizome -- symbols /absolute/path/to/file.rs`
- repo-local command timing and targeted tracing in `mycelium`

<!-- PASTE END -->

**Checklist:**
- [x] performance investigation guidance exists
- [x] docs explain where end-to-end investigation is expected to be useful in this ecosystem

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/cross-project/verify-rust-tooling-adoption.sh`
3. All checklist items are checked
4. The repo-owned follow-up handoffs are still the source of truth for repo-local work

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/cross-project/verify-rust-tooling-adoption.sh
```

**Output:**
<!-- PASTE START -->
PASS: file exists - .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern 'cargo-nextest' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern 'criterion' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern 'whole-command timing' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/mycelium/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/rhizome/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/hyphae/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/stipe/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/cortina/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/canopy/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/spore/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: pattern '\.handoffs/archive/volva/rust-tooling-adoption.md' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: checked item 'nextest installation and usage are documented' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: checked item 'the first-wave repos have a clear nextest command surface' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: checked item 'Criterion was added only to repos with real benchmark targets' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: checked item 'at least one meaningful benchmark compiles in each adopted repo' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: checked item 'performance investigation guidance exists' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: checked item 'docs explain where end-to-end investigation is expected to be useful in this ecosystem' found in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: found 5 paste blocks in .handoffs/archive/cross-project/rust-tooling-adoption.md
PASS: all 5 paste blocks contain output in .handoffs/archive/cross-project/rust-tooling-adoption.md
Results: 20 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

This handoff exists because the ecosystem is large enough to benefit from better Rust
test/benchmark/profiling workflows, but those tools should be adopted deliberately
instead of turning into cargo-cult dependencies.
