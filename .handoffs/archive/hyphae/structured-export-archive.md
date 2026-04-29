# Hyphae: Structured Export and Archive

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

1. [hyphae-archive-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/hyphae-archive-contract.md)
2. [archive-export-command.md](/Users/williamnewton/projects/basidiocarp/.handoffs/hyphae/archive-export-command.md)
3. [archive-import-command.md](/Users/williamnewton/projects/basidiocarp/.handoffs/hyphae/archive-import-command.md)
4. [archive-import-validation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/hyphae/archive-import-validation.md)
5. [hyphae-pre-upgrade-backup.md](/Users/williamnewton/projects/basidiocarp/.handoffs/stipe/hyphae-pre-upgrade-backup.md)

Suggested order:

1. `cross-project/hyphae-archive-contract`
2. `hyphae/archive-export-command`
3. `hyphae/archive-import-command`
4. `hyphae/archive-import-validation`
5. `stipe/hyphae-pre-upgrade-backup`

Intent preserved from the original umbrella:

- define a versioned Hyphae archive contract in `septa`
- add focused `hyphae export` and `hyphae import` CLI surfaces
- validate imports against the contract instead of failing loosely
- add a safe pre-upgrade backup path in `stipe`

Completion for the original umbrella means the child handoffs above are complete.
