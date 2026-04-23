# Mycelium: Declarative Filter Extensions

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/filters/`, `mycelium/filters/` (new TOML files), `mycelium/build.rs` (if used)
- **Cross-repo edits:** none
- **Non-goals:** does not change how compiled Rust filters work; does not add a UI for managing filters; does not touch mycelium's CLI interface
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by rtk's declarative extension model (audit: `.audit/external/audits/rtk/ecosystem-borrow-audit.md`):

> "The hybrid of compiled Rust filters and declarative TOML filters is one of RTK's best ideas. It keeps the core strict while letting the long tail stay cheap."
> — rtk `src/filters/README.md` and `src/filters/turbo.toml`

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:**
  - `src/filters/` — existing compiled filter modules; add a `declarative.rs` loader alongside
  - `filters/` (new top-level directory) — TOML filter declaration files
  - `src/filters/mod.rs` — load and merge declarative filters at startup
- **Reference seams:**
  - Existing compiled filter implementations in `src/filters/`
  - rtk's `src/filters/turbo.toml` pattern
- **Spawn gate:** do a short seam-finding pass first — identify the exact `src/filters/mod.rs` registration point and what a compiled filter's interface looks like, then spawn

## Problem

Mycelium's filters are all compiled Rust. Adding a filter for a new tool's output requires touching Rust source, rebuilding, and releasing. This is the right approach for high-stakes, high-complexity filters (cargo test, git log) — but it blocks the long tail of simple transformations that operators want to add without a code change.

RTK solves this with a thin declarative layer: TOML files that declare filter name, command patterns, and simple transformation rules. The compiled Rust core handles parsing and routing; the TOML files extend coverage at zero implementation cost.

## What needs doing (intent)

Add a declarative filter layer to mycelium:

1. A TOML schema for declaring simple filters (command match pattern, line-level transformations, truncation rules)
2. A `filters/` directory where TOML filter files live
3. A loader that reads and registers TOML filters at startup alongside compiled filters
4. Compiled filters take precedence when both exist for the same command

Start with a concrete example: declare a TOML filter for `npm test` output (strip timestamps and ANSI, keep pass/fail summary).

## Scope

- **Allowed files:** `mycelium/src/filters/declarative.rs` (new), `mycelium/src/filters/mod.rs`, `mycelium/filters/*.toml` (new directory + files)
- **Explicit non-goals:**
  - No user-editable filter directory — this is for ecosystem-managed filters checked into the repo
  - No runtime hot-reload of TOML files
  - No changes to compiled filter behavior

---

### Step 1: Define the TOML filter schema

**Project:** `mycelium/`
**Effort:** small
**Depends on:** nothing (read `src/filters/mod.rs` and an existing compiled filter first)

Before writing code, read `src/filters/mod.rs` to understand:
- What interface a filter implements (trait name, method signatures)
- How filters are registered and dispatched

Then define a TOML schema. A minimal filter declaration looks like:

```toml
# filters/npm-test.toml
[filter]
name = "npm-test"
command_pattern = "npm test"  # matched as a prefix against the command string

[transform]
strip_ansi = true
strip_timestamps = true      # lines that start with a timestamp pattern

[truncate]
keep_last_n_lines = 50       # keep only the last N lines (for verbose test runners)
keep_on_match = ["PASS", "FAIL", "Tests:", "Test Suites:"]  # always keep matching lines
```

Write this schema as a Rust struct with `serde::Deserialize`:

```rust
#[derive(Debug, Deserialize)]
pub struct DeclarativeFilter {
    pub filter: FilterMeta,
    pub transform: Option<TransformConfig>,
    pub truncate: Option<TruncateConfig>,
}

#[derive(Debug, Deserialize)]
pub struct FilterMeta {
    pub name: String,
    pub command_pattern: String,
}

#[derive(Debug, Deserialize, Default)]
pub struct TransformConfig {
    #[serde(default)]
    pub strip_ansi: bool,
    #[serde(default)]
    pub strip_timestamps: bool,
}

#[derive(Debug, Deserialize, Default)]
pub struct TruncateConfig {
    pub keep_last_n_lines: Option<usize>,
    #[serde(default)]
    pub keep_on_match: Vec<String>,
}
```

#### Verification

```bash
cd mycelium && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build` succeeds
- [ ] Struct deserializes correctly with a `serde_test` or small inline test

---

### Step 2: Implement the declarative filter loader

**Project:** `mycelium/`
**Effort:** small
**Depends on:** Step 1

Create `src/filters/declarative.rs`. Implement the filter trait for `DeclarativeFilter`, applying the transform and truncate rules in sequence. Add a `load_declarative_filters(dir: &Path) -> Vec<DeclarativeFilter>` function that reads `*.toml` files from the given directory.

Key behavior:
- `strip_ansi`: strip ANSI escape sequences from each line
- `strip_timestamps`: remove leading timestamp prefixes (e.g. `HH:MM:SS.mmm `)
- `keep_last_n_lines` + `keep_on_match`: keep the last N lines OR any line matching one of the patterns, whichever is larger

#### Verification

```bash
cd mycelium && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Loader reads `*.toml` files and returns parsed filter structs
- [ ] Transform and truncate logic implemented

---

### Step 3: Register declarative filters at startup

**Project:** `mycelium/`
**Effort:** small
**Depends on:** Step 2

In `src/filters/mod.rs`, after registering compiled filters, load and register declarative filters from `filters/` (relative to the binary or a known config path). Compiled filters take precedence: if a command pattern matches both a compiled filter and a declarative filter, use the compiled one.

#### Verification

```bash
cd mycelium && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Declarative filters loaded and merged at startup
- [ ] Compiled filter precedence preserved

---

### Step 4: Add a concrete TOML filter example

**Project:** `mycelium/`
**Effort:** tiny
**Depends on:** Step 3

Create `filters/npm-test.toml` with the schema from Step 1. This proves the end-to-end path works and gives a reference for future filter authors.

#### Verification

```bash
cd mycelium && echo "fake test output" | cargo run -- --command "npm test" 2>&1 | head -20
```

(Adapt to actual mycelium CLI interface.)

**Checklist:**
- [ ] `npm-test.toml` file present and valid
- [ ] Can be exercised through mycelium end-to-end

---

### Step 5: Add unit tests

**Project:** `mycelium/`
**Effort:** small
**Depends on:** Step 4

Test the loader and filter application:
- Loader parses valid TOML correctly
- Loader ignores non-TOML files
- Transform strips ANSI and timestamps as expected
- Truncate keeps last-N + matching lines

```bash
cd mycelium && cargo test declarative 2>&1
```

**Checklist:**
- [ ] Tests pass for loader, transform, and truncate

---

### Step 6: Full suite

```bash
cd mycelium && cargo test 2>&1 | tail -20
cd mycelium && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd mycelium && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The full test suite passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

## Context

Spawned from the rtk Wave 1 re-audit (2026-04-23). The core insight is keeping compiled Rust filters for high-value, high-complexity transformations while enabling TOML declarations for the long tail of simple output filters (strip ANSI, truncate, keep matching lines). This lowers the cost of adding filter coverage for new tools from "write Rust + rebuild" to "add a TOML file."
