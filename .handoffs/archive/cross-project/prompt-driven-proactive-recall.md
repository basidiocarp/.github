# Cross-Project: Prompt-Driven Proactive Recall

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

1. [prompt-driven-recall-injection.md](/Users/williamnewton/projects/basidiocarp/.handoffs/volva/prompt-driven-recall-injection.md)
2. [prompt-driven-recall-injection.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/prompt-driven-recall-injection.md)

Suggested order:

1. `volva/prompt-driven-recall-injection`
2. `cortina/prompt-driven-recall-injection`

Intent preserved from the original umbrella:

- make recall injection prompt-aware rather than project-generic
- enforce token-budgeted and deduplicated recall in the real injection hosts

Completion for the original umbrella means the two child handoffs above are complete.
