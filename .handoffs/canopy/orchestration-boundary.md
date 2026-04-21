# Canopy: Resolve orchestration logic boundary with hymenium

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy` (primary); `hymenium` (if logic moves there)
- **Allowed write scope:** canopy/..., hymenium/... (if relocating)
- **Cross-repo edits:** hymenium only if resolution is to move logic there
- **Non-goals:** council atomicity, task completion guard (separate handoffs)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

Canopy's CLAUDE.md states: "Does not orchestrate workflows or manage dispatch decisions (Hymenium owns that)." Three areas violate this.

### 1 — pre_dispatch_check makes dispatch decisions
`src/runtime.rs:143-209`

`DispatchDecision` enum and `pre_dispatch_check` call `cortina audit-handoff`, parse the response, and return `Proceed` or `FlagForReview`. This is dispatch orchestration. Called from `app.rs:882` and `tools/import.rs:250`.

### 2 — Orchestration state machine in store layer
`src/store/helpers/orchestration.rs`

Full workflow state machine: queue states, worktree bindings, review cycles, queue lanes (ready/claimed/active/blocked/review/closed), and `sync_task_workflow_in_connection` orchestrating state transitions across three joined records. This is a workflow execution engine embedded in canopy's store layer.

### 3 — DispatchPolicy with annotation-aware routing
`src/tools/policy.rs`

`DispatchPolicy::evaluate()` makes proceed/flag decisions based on tool annotations. This is dispatch policy logic under a different name.

## Decision needed

For each area, choose:
- **Move to hymenium**: the natural owner for workflow dispatch and phase gating
- **Reclassify as coordination state** (not dispatch): if the behavior is genuinely read-model assembly or coordination bookkeeping rather than active dispatch decisions, document why it belongs in canopy
- **Accept with explicit contract**: update canopy's CLAUDE.md to declare these as intentional responsibilities and add septa schemas for the cross-tool payloads

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy
cargo test --all 2>&1 | tail -5

# If logic moves to hymenium:
cd /Users/williamnewton/projects/basidiocarp/hymenium
cargo build 2>&1 | tail -3
cargo test 2>&1 | tail -5
```

## Checklist

- [ ] Decision documented for each of the three areas
- [ ] If moving: logic relocated to hymenium with tests
- [ ] If keeping: canopy CLAUDE.md updated with explicit rationale
- [ ] All tests pass in affected repos
