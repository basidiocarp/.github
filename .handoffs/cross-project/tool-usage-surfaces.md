# Cross-Project: Tool Usage Surfaces

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

1. [tool-adoption-panel.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/tool-adoption-panel.md)
2. [tool-adoption-statusline.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/tool-adoption-statusline.md)

Suggested order:

1. `cap/tool-adoption-panel`
2. `annulus/tool-adoption-statusline`

Intent preserved from the original umbrella:

- expose `canopy` tool-adoption scores in the operator-facing `cap` task surface
- add a compact adoption indicator in `annulus`

Completion for the original umbrella means the two child handoffs above are complete.
