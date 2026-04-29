# Cross-Project: Summary + Detail-on-Demand Pattern

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `multiple`
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

1. [summary-storage-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/summary-storage-contract.md)
2. [command-output-summary-mode.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/command-output-summary-mode.md)
3. [hyphae-command-output-storage-bridge.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/hyphae-command-output-storage-bridge.md)

Suggested order:

1. `cross-project/summary-storage-contract`
2. `mycelium/command-output-summary-mode`
3. `mycelium/hyphae-command-output-storage-bridge`

Intent preserved from the original umbrella:

- define the summary and storage protocol
- add summary mode in `mycelium`
- bridge the full output into `hyphae` for on-demand retrieval

Completion for the original umbrella means the three child handoffs above are complete.
