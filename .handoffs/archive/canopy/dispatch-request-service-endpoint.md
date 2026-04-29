# Canopy: Dispatch Request Service Endpoint

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/`, `canopy/tests/`, `canopy/README.md`, `canopy/AGENTS.md`, `canopy/CLAUDE.md`
- **Cross-repo edits:** no source edits outside `canopy`; read `septa/dispatch-request-v1.schema.json` and Spore transport primitives as references
- **Non-goals:** no Hymenium client migration and no Cap UI work
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-dispatch-request-service-endpoint.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** CLI/service entrypoints, task creation/assignment modules, dispatch/intake code, JSON-RPC or local service transport modules, task tests
- **Reference seams:** existing task CLI implementation, Canopy task ledger/store modules, `septa/dispatch-request-v1.schema.json`, Spore JSON-RPC helpers
- **Spawn gate:** do not launch an implementer until the parent agent confirms whether Canopy should expose the endpoint over stdio JSON-RPC, Unix socket, or both for v1

## Problem

Hymenium currently has to reconstruct Canopy CLI calls, which creates silent drift when Canopy flags change. Canopy should expose a typed ecosystem dispatch endpoint that accepts the Septa `dispatch-request-v1` payload directly, while keeping the CLI as a human/operator surface.

The CLI must not be treated as Canopy's system-to-system API. It remains an operator adapter over the same internal service behavior.

## What exists

- **Task CLI:** Canopy already has task creation and assignment behavior.
- **Task ledger:** Canopy owns coordination runtime state.
- **Septa dispatch request:** the intake payload already exists as a cross-tool contract.

## What needs doing

Add a service endpoint or command mode that accepts `dispatch-request-v1` directly and turns it into Canopy task/workflow state without callers manually rebuilding CLI flags.

Minimum behavior:

- parse and validate `schema_version`
- accept the canonical Septa fixture in a test
- create the same task/coordination state as the equivalent CLI path
- return a typed success or failure response suitable for Hymenium
- document that the CLI remains supported for humans/operators, but internal orchestration must prefer the typed endpoint
- keep the implementation shaped so the CLI and service endpoint share task creation logic instead of duplicating separate behavior
- if runtime leases are available, publish or document the `workflow.dispatch.v1` capability lease shape for Canopy

## Scope

- **Primary seam:** Canopy dispatch intake from Septa payload to coordination state
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no Hymenium migration, no registry writing in Stipe, no Cap read model changes

## Verification

```bash
cd canopy && cargo test dispatch
cd canopy && cargo test task
cd canopy && cargo clippy -- -D warnings
cd canopy && cargo fmt --check
bash .handoffs/canopy/verify-dispatch-request-service-endpoint.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy accepts `dispatch-request-v1` through a typed endpoint or service mode
- [ ] invalid or missing `schema_version` fails fast
- [ ] canonical Septa dispatch fixture is covered by a Canopy test
- [ ] endpoint creates equivalent coordination state to the CLI task path
- [ ] docs describe CLI as human/operator surface and service endpoint as orchestration surface
- [ ] CLI and endpoint share the same internal task creation service path
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Child handoff of [Cross-Project: Capability Ecosystem Control Plane](../cross-project/capability-ecosystem-control-plane.md). This is the producer-side counterpart to Hymenium moving away from hand-built CLI flag calls.
