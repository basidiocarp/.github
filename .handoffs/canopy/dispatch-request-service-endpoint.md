# Canopy: Dispatch Request Service Endpoint

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/`, `canopy/CLAUDE.md`, canopy local tests
- **Cross-repo edits:** `septa/` for new dispatch endpoint schema if needed; no other repos
- **Non-goals:** no removal of existing human-facing CLI; no Cap UI changes
- **Verification contract:** `cd canopy && cargo test dispatch`
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

Hymenium currently dispatches work to Canopy via CLI invocation (`canopy task create`, `canopy task assign`). The CLI is a human/operator surface, not the preferred system-to-system protocol. This creates flag-drift risk, weak typing, and stdout parsing at the dispatch boundary.

**Classification:** temporary compatibility — the current CLI-based dispatch path is a compatibility fallback only. It must not be extended with new functionality.

## What needs doing

Replace the hymenium → canopy CLI dispatch with a typed local service endpoint:

1. Define or reference a `canopy-dispatch-endpoint-v1` descriptor in `septa/` (unix-socket or TCP)
2. Implement a typed dispatch endpoint in `canopy` that accepts `dispatch-request-v1` payloads
3. (Handled by companion handoff) Hymenium will be updated separately via `.handoffs/hymenium/capability-dispatch-client.md` to call the typed endpoint instead of shelling out; do not edit hymenium source from this handoff
4. Retain the CLI path as a backward-compatible operator surface (human-readable output); do not route system calls through it

## Integration Hierarchy

This migration follows the ecosystem integration rule:

- **Preferred for cross-binary calls:** typed local service endpoint (`local-service-endpoint-v1.schema.json`)
- **CLI path retained for:** human/operator use only (dashboard, shell, manual dispatch)

See `docs/foundations/inter-app-communication.md` for the full integration hierarchy.

## Context

Created as part of C8 (system-to-system communication boundary). References:
- C5: `septa/local-service-endpoint-v1.schema.json` — endpoint descriptor schema
- C6: `spore/src/transport.rs` — transport client
- C7: `septa/integration-patterns.md` CLI Coupling Classification (row: hymenium → canopy, "temporary compatibility")
- C8: `docs/foundations/inter-app-communication.md` — integration hierarchy policy
