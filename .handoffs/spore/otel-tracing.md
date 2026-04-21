# OpenTelemetry Tracing in Spore

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `spore`
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

1. [otel-foundation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/spore/otel-foundation.md)
2. [otel-trace-propagation.md](/Users/williamnewton/projects/basidiocarp/.handoffs/cortina/otel-trace-propagation.md)
3. [otel-execution-root-span.md](/Users/williamnewton/projects/basidiocarp/.handoffs/volva/otel-execution-root-span.md)
4. [otel-trace-receiver.md](/Users/williamnewton/projects/basidiocarp/.handoffs/hyphae/otel-trace-receiver.md)
5. [otel-evidence-trace-receiver.md](/Users/williamnewton/projects/basidiocarp/.handoffs/canopy/otel-evidence-trace-receiver.md)

Suggested order:

1. `spore/otel-foundation`
2. `cortina/otel-trace-propagation`
3. `volva/otel-execution-root-span`
4. `hyphae/otel-trace-receiver`
5. `canopy/otel-evidence-trace-receiver`

Intent preserved from the original umbrella:

- add a feature-gated OTel foundation to `spore`
- propagate trace context across the signal chain
- instrument key producer and receiver boundaries incrementally

Completion for the original umbrella means the five child handoffs above are complete.
