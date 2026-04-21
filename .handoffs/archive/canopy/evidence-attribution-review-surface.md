# Canopy: Evidence Attribution Review Surface

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/...`
- **Cross-repo edits:** `none`
- **Non-goals:** changing cortina capture or bridge behavior
- **Verification contract:** run the repo-local commands below and `bash .handoffs/archive/canopy/verify-evidence-attribution-review-surface.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Problem

Even with richer evidence refs attached, operators still need a stable review
surface in `canopy` that makes causal chains visible and readable.

## What exists (state)

- **Evidence listing:** [app.rs](../../canopy/src/app.rs), [commands.rs](../../canopy/src/app/commands.rs), and [tools/evidence.rs](../../canopy/src/tools/evidence.rs) already support evidence listing.
- **Evidence storage:** `canopy` already stores typed `EvidenceRef` rows and can render them in CLI/JSON flows.

## What needs doing (intent)

Add or extend a Canopy evidence review surface so causal relationships on evidence
refs are visible to operators and testable in repo-local CLI output.

## Scope

- **Primary seam:** Canopy evidence listing / operator review output
- **Allowed files:** `canopy/src/app.rs`, `canopy/src/app/commands.rs`, `canopy/src/tools/evidence.rs`, `canopy/src/store/...`, tests
- **Explicit non-goals:**
- Do not change Cortina in this handoff.
- Do not invent new evidence producer behavior here.

## Files To Modify

- `canopy/src/app.rs`
- `canopy/src/app/commands.rs`
- `canopy/src/tools/evidence.rs`
- tests as needed

## Verification

```bash
cd canopy && cargo test --workspace 2>&1 | tail -10
bash .handoffs/archive/canopy/verify-evidence-attribution-review-surface.sh
```

## Checklist

- [x] Canopy renders evidence attribution / causal links in a reviewable surface
- [x] multiple evidence types appear distinctly in the operator output
- [x] tests cover the causal rendering behavior

## Verification Evidence

```text
test verified_parent_auto_completes_when_all_children_complete ... ok

test result: ok. 22 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.20s

   Doc-tests canopy

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

```text
PASS: canopy evidence files exist
PASS: review surface references evidence attribution
PASS: canopy workspace tests pass
Results: 3 passed, 0 failed
```

## Context

Child 3 of [Canopy Evidence Bridge — Attribution Completeness](../../cross-project/canopy-evidence-attribution.md). Depends on child `64b`.
