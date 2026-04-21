# Annulus: Initial Build

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `annulus`
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

1. [crate-scaffold.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/crate-scaffold.md)
2. [statusline-extraction.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/statusline-extraction.md)
3. [hook-path-validator.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/hook-path-validator.md)
4. [ecosystem-wiring.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/annulus-ecosystem-wiring.md)
5. [contract-followup.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/annulus-contract-followup.md)

Suggested order:

1. `annulus/crate-scaffold`
2. `annulus/statusline-extraction`
3. `annulus/hook-path-validator`
4. `cross-project/annulus-ecosystem-wiring`
5. `cross-project/annulus-contract-followup` if still needed

Intent preserved from the original umbrella:

- create the `annulus` crate
- move statusline out of `cortina`
- move hook-path validation to the right home
- wire Annulus into the broader ecosystem in a controlled follow-up

Completion for the original umbrella means the child handoffs above are complete.
