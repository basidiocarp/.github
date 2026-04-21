# Canopy: Notification Lifecycle and Attention Signaling

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `canopy`
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

1. [notification-model-and-storage.md](/Users/williamnewton/projects/basidiocarp/.handoffs/canopy/notification-model-and-storage.md)
2. [canopy-notification-contract.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cross-project/canopy-notification-contract.md)
3. [task-lifecycle-notification-emission.md](/Users/williamnewton/projects/basidiocarp/.handoffs/canopy/task-lifecycle-notification-emission.md)
4. [canopy-notification-panel.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cap/canopy-notification-panel.md)
5. [canopy-notification-surfaces.md](/Users/williamnewton/projects/basidiocarp/.handoffs/annulus/canopy-notification-surfaces.md)

Suggested order:

1. `canopy/notification-model-and-storage`
2. `cross-project/canopy-notification-contract`
3. `canopy/task-lifecycle-notification-emission`
4. `cap/canopy-notification-panel`
5. `annulus/canopy-notification-surfaces`

Intent preserved from the original umbrella:

- add a durable notification model inside Canopy
- define one shared notification contract for downstream consumers
- emit lifecycle notifications at the right Canopy seams
- surface the same unread notifications in Cap and Annulus

Completion for the original umbrella means the child handoffs above are complete.
