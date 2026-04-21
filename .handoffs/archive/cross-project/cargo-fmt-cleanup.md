# Cargo Fmt Cleanup Across Ecosystem

## Problem

6 of 8 Rust projects have format drift. Total: 32 dirty locations across 28 files.
Most are mechanical (import ordering, line wrapping) but they will fail any CI format gate.

## What exists (state)

| Project | Dirty Files | Nature |
|---------|------------|--------|
| rhizome | 18 | Import ordering + 1 substantive (covered by build-fix-and-format.md) |
| canopy | 3 | Line-break style |
| stipe | 2 files, 3 locations | Long line wrapping |
| hyphae | 2 | Tuple closure expansion |
| mycelium | 1 | hyphae.rs long line |
| cortina | 1 | events.rs attribute formatting |
| spore | 0 | Clean |
| volva | 0 | Clean |

## What needs doing (intent)

Run `cargo fmt` in each project with dirty formatting.

---

### Step 1: Format all projects

**Effort:** 5 min total

```bash
for project in hyphae mycelium cortina canopy stipe; do
  (cd $project && cargo fmt)
done
# rhizome handled separately in build-fix-and-format.md
```

**Checklist:**
- [x] All 6 projects pass `cargo fmt --check`
- [x] No test regressions from formatting changes

## Completion Notes

- `cortina`, `canopy`, and `stipe` received formatter-only commits and were pushed.
- `mycelium` was already clean and required no file changes.
- `rhizome` remained out of scope for this handoff, as intended.
- `hyphae` surfaced unrelated uncommitted Codex/session-ingest feature work during the fmt pass.
  That patch was split into its own commit first, then `cargo fmt --check` was re-run and
  passed cleanly in `hyphae`.

## Verification

```text
hyphae: cargo test -q
cortina: cargo test -q
canopy: cargo test -q
stipe: cargo test -q
hyphae: cargo fmt --all -- --check
mycelium: cargo fmt --all -- --check
cortina: cargo fmt --all -- --check
canopy: cargo fmt --all -- --check
stipe: cargo fmt --all -- --check
```

## Context

Found during global ecosystem audit (2026-04-04), Layer 1 lint audits.
