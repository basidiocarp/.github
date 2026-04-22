# Canopy Evidence Bridge — Attribution Completeness

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in the child handoffs
- **Cross-repo edits:** allowed only through the named child handoffs
- **Non-goals:** dispatching this umbrella directly to an implementer
- **Verification contract:** complete the repo-local commands in each child handoff and its paired `verify-*.sh` script
- **Completion update:** once every child handoff is audit-clean and green, update `.handoffs/HANDOFFS.md` and archive this umbrella with its children

## Implementation Seam

- **Likely repo:** child handoffs own the execution seams for this umbrella
- **Likely files/modules:** none directly; identify the file set inside the selected child handoff before spawning
- **Reference seams:** use the child handoffs as the execution source of truth rather than dispatching this umbrella directly
- **Spawn gate:** do not launch an implementer from this umbrella; pick a child handoff and complete seam-finding there first

## Problem

The `cortina` -> `canopy` evidence write path exists, but semantic attribution is
still shallow. Operators can see that evidence exists without getting a useful
causal chain such as "this correction fixed that earlier error" or "this
verification pass closed out that failed command."

## What exists (state)

- **Cortina evidence bridge:** [cortina/src/utils/canopy_client.rs](../../cortina/src/utils/canopy_client.rs) already writes best-effort evidence refs to the active Canopy task.
- **Cortina outcome events:** [cortina/src/events/outcome_events.rs](../../cortina/src/events/outcome_events.rs) and [cortina/src/outcomes.rs](../../cortina/src/outcomes.rs) already carry signal metadata such as `signal_type`.
- **Canopy evidence storage:** [canopy/src/store/evidence.rs](../../canopy/src/store/evidence.rs) and [canopy/src/tools/evidence.rs](../../canopy/src/tools/evidence.rs) already persist and list typed evidence refs.
- **Schema contract:** `evidence-ref-v1` already exists in `septa/` and is accepted by current consumers.

## Child Handoffs

Dispatch only these concrete children:

1. [Cortina: Canopy Evidence Causal Chaining](../cortina/canopy-evidence-causal-chaining.md)
2. [Cortina: Canopy Evidence Signal Bridge](../cortina/canopy-evidence-signal-bridge.md)
3. [Canopy: Evidence Attribution Review Surface](../canopy/evidence-attribution-review-surface.md)

## Completion Protocol

This umbrella is complete only when all child handoffs are complete, archived,
and removed from the active dashboard.

## Context

This is the critical evidence-attribution gap from the workspace review. It
unlocks more meaningful task timelines in `canopy` and gives later verification
and lifecycle work an evidence surface worth depending on.
