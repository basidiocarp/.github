# Cross-Project: Unified Output Aggregation

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

1. [unified-output-principles.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/unified-output-principles.md)
2. [statusline-json-surface.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/statusline-json-surface.md)
3. [ecosystem-status-panel.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/ecosystem-status-panel.md)
4. [aggregation-data-source-alignment.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/aggregation-data-source-alignment.md)

Suggested order:

1. `cross-project/unified-output-principles`
2. `annulus/statusline-json-surface`
3. `cap/ecosystem-status-panel`
4. `annulus/aggregation-data-source-alignment`

Intent preserved from the original umbrella:

- document the one-aggregation-path principle
- make Annulus the structured aggregation host
- point Cap at the same aggregation output
- align the Annulus segments with the real tool data sources

Completion for the original umbrella means the child handoffs above are complete.
