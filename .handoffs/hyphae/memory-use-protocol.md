# Memory-Use Protocol

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

1. [protocol-surface.md](/Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/protocol-surface.md)
2. [memory-protocol-injection.md](/Users/williamnewton/projects/basidiocarp/.handoffs/volva/memory-protocol-injection.md)
3. [memory-protocol-session-start.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/memory-protocol-session-start.md)

Suggested order:

1. `hyphae/protocol-surface`
2. `volva/memory-protocol-injection`
3. `cortina/memory-protocol-session-start`

Intent preserved from the original umbrella:

- define an explicit Hyphae memory-use protocol
- inject it into runtime context assembly
- expose it at session start without broadening Cortina beyond its boundary

Completion for the original umbrella means the three child handoffs above are complete.
