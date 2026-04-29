# Lamella→Cortina Boundary Cleanup — Phase 2

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

1. [session-end-shim.md](/Users/williamnewton/projects/basidiocarp/.handoffs/lamella/session-end-shim.md)
2. [session-end-path-validation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/session-end-path-validation.md)
3. [session-end-direct-hook-cutover.md](/Users/williamnewton/projects/basidiocarp/.handoffs/lamella/session-end-direct-hook-cutover.md)

Suggested order:

1. `lamella/session-end-shim`
2. `cortina/session-end-path-validation`
3. `lamella/session-end-direct-hook-cutover`

Intent preserved from the original umbrella:

- replace the legacy lamella session-end behavior with a cortina-delegating shim
- validate the cortina-owned session-end path
- remove the shim and point lamella hooks directly at cortina

Completion for the original umbrella means the three child handoffs above are complete.
