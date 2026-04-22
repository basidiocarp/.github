# Typed Artifact Storage in Hyphae

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `hyphae`
- **Allowed write scope:** none directly; dispatch child handoffs only
- **Cross-repo edits:** child handoffs decide
- **Non-goals:** direct implementation from this umbrella handoff
- **Verification contract:** complete the child handoffs, keep their paired verify scripts green, and keep dashboard links current
- **Completion update:** when all child handoffs are complete, update `.handoffs/HANDOFFS.md` and archive the umbrella if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** child handoffs own the execution seams for this umbrella
- **Likely files/modules:** none directly; identify the file set inside the selected child handoff before spawning
- **Reference seams:** use the child handoffs as the execution source of truth rather than dispatching this umbrella directly
- **Spawn gate:** do not launch an implementer from this umbrella; pick a child handoff and complete seam-finding there first

This umbrella handoff is decomposed. Do not dispatch it directly.

Use these smaller handoffs instead:

1. [artifact-model.md](/Users/williamnewton/projects/basidiocarp/.handoffs/hyphae/artifact-model.md)
2. [compact-summary-artifacts.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/compact-summary-artifacts.md)
3. [council-record-artifacts.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/council-record-artifacts.md)

Suggested order:

1. `hyphae/artifact-model`
2. `cross-project/compact-summary-artifacts`
3. `cross-project/council-record-artifacts`

Intent preserved from the original umbrella:

- add typed artifact storage to Hyphae
- route compact summaries into typed artifacts
- route council session records into typed artifacts

Completion for the original umbrella means the three child handoffs above are complete.
