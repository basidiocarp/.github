# Stale Handoff Detection

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `cortina`
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

1. [handoff-path-extraction.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/handoff-path-extraction.md)
2. [session-end-stale-handoff-warning.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/session-end-stale-handoff-warning.md)
3. [audit-handoff-cli.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/audit-handoff-cli.md)
4. [canopy-stale-handoff-preflight.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/canopy-stale-handoff-preflight.md)

Suggested order:

1. `handoff-path-extraction`
2. `session-end-stale-handoff-warning`
3. `audit-handoff-cli`
4. `canopy-stale-handoff-preflight`

Intent preserved from the original umbrella:

- teach Cortina to understand referenced handoff paths and checklist state
- warn at session end when a session likely advanced an unchecked handoff
- add a pre-dispatch audit surface before agents are assigned stale work

Completion for the original umbrella means the four child handoffs above are complete.
