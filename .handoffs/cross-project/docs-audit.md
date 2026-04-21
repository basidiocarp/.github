# Documentation Audit

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

1. [docs-audit-core-rust.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/docs-audit-core-rust.md)
2. [docs-audit-platform-rust.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/docs-audit-platform-rust.md)
3. [docs-audit-interface-and-authoring.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/docs-audit-interface-and-authoring.md)

Suggested order:

1. `cross-project/docs-audit-core-rust`
2. `cross-project/docs-audit-platform-rust`
3. `cross-project/docs-audit-interface-and-authoring`

Intent preserved from the original umbrella:

- audit user-facing docs against the real CLI, MCP, and config surfaces
- fix drift in smaller repo-grouped waves instead of one broad ecosystem pass

Completion for the original umbrella means the three child handoffs above are complete.
