# Hymenium: Capability Dispatch Client

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/dispatch/`, `hymenium/src/commands/`, `hymenium/src/workflow/`, `hymenium/tests/`, `hymenium/README.md`, `hymenium/AGENTS.md`, `hymenium/CLAUDE.md`
- **Cross-repo edits:** no source edits outside `hymenium`; read `spore` capability APIs, `canopy` dispatch endpoint, and `septa/dispatch-request-v1.schema.json` as references
- **Non-goals:** no Canopy service implementation and no Stipe registry writing
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-capability-dispatch-client.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** `src/dispatch/cli.rs`, `src/dispatch/mod.rs`, `src/dispatch/orchestrate.rs`, `src/commands/dispatch.rs`, dispatch tests
- **Reference seams:** current Canopy CLI adapter, new Spore capability resolution API, Canopy dispatch endpoint handoff, `dispatch-request-v1` fixture
- **Spawn gate:** do not launch an implementer until the Canopy dispatch endpoint and Spore capability resolver API exist or are explicitly stubbed behind tests

## Problem

Hymenium should orchestrate workflows through an explicit ecosystem capability rather than treating Canopy as a bag of CLI flags. The existing CLI adapter can remain as a compatibility fallback, but it should not be the preferred integration path once a typed dispatch endpoint exists.

The CLI adapter should be treated as tactical compatibility debt. New system-to-system dispatch behavior should be implemented against the Septa contract and capability-resolved endpoint first.

## What exists

- **Dispatch adapter:** Hymenium has code that shells out to Canopy.
- **Workflow engine:** Hymenium owns workflow lifecycle, phase gating, retry, and recovery.
- **Septa dispatch request:** the desired intake shape already exists.

## What needs doing

Add a dispatch client that resolves `workflow.dispatch.v1` through Spore, sends `dispatch-request-v1` to the resolved Canopy endpoint, and falls back to the CLI adapter only when registry/service discovery is unavailable.

Minimum behavior:

- produce or adapt all workflow dispatch input into `dispatch-request-v1`
- resolve `workflow.dispatch.v1` with Spore before trying direct CLI calls
- send the payload to Canopy's typed endpoint when available
- preserve CLI fallback only as an isolated compatibility adapter with explicit warnings or telemetry so drift is visible
- make fallback usage observable enough that dogfood runs can prove whether the typed path is actually being used
- link or create a replacement handoff before adding any new CLI-only integration path
- test endpoint success, discovery absence, stale lease, and CLI fallback paths
- keep phase activation and gating behavior aligned with the existing `orchestration-dispatch-contracts` handoff

## Scope

- **Primary seam:** Hymenium dispatch client from workflow intent to Canopy capability endpoint
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no Canopy endpoint implementation, no registry writer, no new workflow template system

## Verification

```bash
cd hymenium && cargo test dispatch
cd hymenium && cargo test workflow
cd hymenium && cargo clippy -- -D warnings
cd hymenium && cargo fmt --check
bash .handoffs/hymenium/verify-capability-dispatch-client.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Hymenium builds or adapts dispatch input into `dispatch-request-v1`
- [ ] dispatch client resolves `workflow.dispatch.v1` through Spore
- [ ] typed endpoint path is preferred over CLI fallback
- [ ] CLI fallback remains tested, isolated, and visibly marked as compatibility behavior
- [ ] fallback usage is observable in logs, telemetry, or status output
- [ ] stale or absent runtime lease does not break dispatch when CLI fallback is available
- [ ] docs describe the new integration hierarchy
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Child handoff of [Cross-Project: Capability Ecosystem Control Plane](../cross-project/capability-ecosystem-control-plane.md). This should be sequenced after the Spore registry resolver and Canopy dispatch endpoint exist.
