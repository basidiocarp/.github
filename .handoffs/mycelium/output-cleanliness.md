# Mycelium: Output Cleanliness

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/hyphae.rs`, `mycelium/src/tracking/`, `mycelium/src/dispatch*`, `mycelium/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no Hyphae protocol redesign and no filter output format redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/mycelium/verify-output-cleanliness.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** `src/hyphae.rs`, command dispatch paths that decide what is user-visible, tests around Hyphae fallback
- **Reference seams:** existing tracing/logging behavior and snapshot tests for filtered output
- **Spawn gate:** do not launch an implementer until the parent agent identifies the exact fallback branch that writes warnings

## Problem

Mycelium's product is clean command-output shaping. The audit found optional Hyphae chunking failures can write warnings directly to stderr before falling back, which can contaminate output consumed by agents and scripts.

## What needs doing

1. Route optional Hyphae fallback warnings through tracing/debug logging rather than direct stderr by default.
2. Preserve explicit verbose/debug surfacing for operators who request it.
3. Add a test proving Hyphae failure fallback does not add unexpected user-visible output.

## Verification

```bash
cd mycelium && cargo test hyphae
bash .handoffs/mycelium/verify-output-cleanliness.sh
```

**Output:**
<!-- PASTE START -->
PASS: hyphae fallback avoids direct eprintln
PASS: diagnostics use tracing or verbosity
PASS: hyphae tests pass
Results: 3 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] optional Hyphae fallback does not use direct `eprintln!` by default
- [x] verbose/debug mode still exposes useful diagnostics
- [x] fallback output remains clean
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: medium.
