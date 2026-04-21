# Rhizome Build Fix and Format Cleanup

## Problem

Rhizome cannot compile. `rhizome-cli/Cargo.toml` pins `toml = "1.0"` but spore v0.4.7
requires `toml ^1.1`. Cargo cannot resolve both, blocking all builds, tests, and clippy.
Additionally, 18 source files have format drift from `cargo fmt`.

## What exists (state)

- **Build:** Completely blocked by dependency resolution failure
- **Format:** 18 files with `cargo fmt --check` diffs (mostly import ordering)
- **`rhizome-core/Cargo.toml`:** also pins `toml = "1.0"`
- **Root `Cargo.toml`:** no `[workspace.dependencies]` entry for toml

## What needs doing (intent)

Fix the toml version pin, promote to workspace dependency, and run cargo fmt.

---

### Step 1: Fix toml dependency and format

**Project:** `rhizome/`
**Effort:** 10 min
**Depends on:** nothing

#### Files to modify

**`Cargo.toml` (workspace root)** — add to `[workspace.dependencies]`:
```toml
toml = "1.1"
```

**`crates/rhizome-cli/Cargo.toml`** — change:
```toml
toml.workspace = true
```

**`crates/rhizome-core/Cargo.toml`** — change:
```toml
toml.workspace = true
```

Then run:
```bash
cd rhizome && cargo update -p toml && cargo fmt
```

#### Verification

```bash
cd rhizome && cargo build --release 2>&1 | tail -3 && cargo fmt --check 2>&1 && echo "FORMAT CLEAN"
```

**Output:**
<!-- PASTE START -->

```text
   Compiling rhizome-mcp v0.7.3 (/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-mcp)
   Compiling rhizome-cli v0.7.3 (/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-cli)
    Finished `release` profile [optimized] target(s) in 43.17s
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
FORMAT CLEAN
```

<!-- PASTE END -->

**Checklist:**
- [x] `cargo build --release` succeeds
- [x] `cargo fmt --check` exits 0
- [x] `cargo clippy --all-targets` runs (may have warnings, but doesn't fail to compile)
- [x] `cargo test --all` runs and reports pass/fail counts

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output pasted above
2. Rhizome compiles, formats clean, tests run

## Context

Found during global ecosystem audit (2026-04-04), Layer 1 lint audit of rhizome.
See `ECOSYSTEM-AUDIT-2026-04-04.md` C3. This blocks all other rhizome work.

## Completion Notes

- Verified on 2026-04-07 in `rhizome/`.
- The toml workspace dependency fix described above was already present in the current tree.
- `cargo fmt --check` initially found one remaining diff in `crates/rhizome-mcp/src/tools/mod.rs`; running `cargo fmt` resolved it.
- `cargo clippy --all-targets` completed successfully with warnings only.
- `cargo test --all` passed.
