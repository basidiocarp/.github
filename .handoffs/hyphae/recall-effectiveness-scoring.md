# Recall Effectiveness Scoring

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless a child handoff explicitly says otherwise
- **Non-goals:** dispatching this umbrella directly
- **Verification contract:** use the paired child handoff verifier, not this umbrella file
- **Completion update:** update `.handoffs/HANDOFFS.md` as child handoffs complete; archive this umbrella only after the child queue is finished

## Implementation Seam

- **Likely repo:** child handoffs own the execution seams for this umbrella
- **Likely files/modules:** none directly; identify the file set inside the selected child handoff before spawning
- **Reference seams:** use the child handoffs as the execution source of truth rather than dispatching this umbrella directly
- **Spawn gate:** do not launch an implementer from this umbrella; pick a child handoff and complete seam-finding there first

## Status Audit

This handoff is no longer safe to dispatch directly.

Parts of the original problem statement are already implemented in `hyphae`:

- `recall_effectiveness` storage and schema already exist
- recall effectiveness scoring already runs from outcome and session signals
- hybrid search already applies recall-effectiveness bias
- store-level tests already cover recency weighting and hybrid ranking bias

The remaining work is narrower than the original handoff claimed. Dispatching the
old umbrella encourages agents to wander or re-implement shipped behavior.

## Child Handoffs

Dispatch these instead:

1. [Recall Effectiveness Recompute CLI](recall-effectiveness-recompute-cli.md)
2. [Recall Effectiveness Evaluate Surface](recall-effectiveness-evaluate-surface.md)

## Notes

- `retrieval-benchmarks.md` remains the measurement companion for this area.
- Do not re-open the already-shipped scoring and ranking internals unless a child
  handoff explicitly proves a bug in the current implementation.
