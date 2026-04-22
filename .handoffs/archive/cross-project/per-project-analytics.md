# Per-Project Analytics in Mycelium and Cap

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

1. [project-savings-scope.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/project-savings-scope.md)
2. [project-gain-json.md](/Users/williamnewton/projects/basidiocarp/.handoffs/mycelium/project-gain-json.md)
3. [project-analytics-panel.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/project-analytics-panel.md)

Suggested order:

1. `mycelium/project-savings-scope`
2. `mycelium/project-gain-json`
3. `cap/project-analytics-panel`

Intent preserved from the original umbrella:

- add project scoping to Mycelium analytics
- expose a stable machine-facing JSON contract
- surface per-project breakdowns in Cap only after the Mycelium contract exists

Completion for the original umbrella means the three child handoffs above are complete.
