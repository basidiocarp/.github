# Cross-Project: Graceful Degradation Classification

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

1. [degradation-taxonomy.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/degradation-taxonomy.md)
2. [degradation-behavior-audit.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/degradation-behavior-audit.md)
3. [availability-probes.md](/Users/williamnewton/projects/basidiocarp/.handoffs/spore/availability-probes.md)
4. [degradation-status-surfaces.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/degradation-status-surfaces.md)
5. [service-health-panel.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/service-health-panel.md)

Suggested order:

1. `cross-project/degradation-taxonomy`
2. `cross-project/degradation-behavior-audit`
3. `spore/availability-probes`
4. `annulus/degradation-status-surfaces`
5. `cap/service-health-panel`

Intent preserved from the original umbrella:

- define one shared degradation taxonomy
- document the current ecosystem behavior against that taxonomy
- add a probe surface in `spore`
- surface the resulting status in Annulus and Cap

Completion for the original umbrella means the child handoffs above are complete.
