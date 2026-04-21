# Cross-Project: Cache-Friendly Context Layout

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

1. [cache-friendly-assembly-guidance.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/cache-friendly-assembly-guidance.md)
2. [cache-friendly-context-ordering.md](/Users/williamnewton/projects/basidiocarp/.handoffs/lamella/cache-friendly-context-ordering.md)
3. [cache-friendly-context-ordering.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/cache-friendly-context-ordering.md)

Suggested order:

1. `cross-project/cache-friendly-assembly-guidance`
2. `lamella/cache-friendly-context-ordering`
3. `cortina/cache-friendly-context-ordering`

Intent preserved from the original umbrella:

- define the cache-friendly context assembly order
- apply the ordering in the main context-assembly repos without bundling them together

Completion for the original umbrella means the three child handoffs above are complete.
