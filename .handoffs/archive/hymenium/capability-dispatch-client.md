# Hymenium: Capability Dispatch Client

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/`, `hymenium/CLAUDE.md`, hymenium local tests
- **Cross-repo edits:** `septa/` for new dispatch endpoint schema if needed; no other repos
- **Non-goals:** no removal of existing human-facing CLI; no Cap UI changes
- **Verification contract:** `cd hymenium && cargo test dispatch`
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

Hymenium dispatches agents by shelling out to `canopy task create` and `canopy task assign`. This CLI path is a compatibility fallback only — the CLI is a human/operator surface, not the preferred system-to-system API. Dispatching through CLI means weak typing, flag-drift risk, stdout parsing, and no structured error propagation.

**Classification:** temporary compatibility — the CLI dispatch path must not be extended with new functionality. The typed endpoint path is preferred for all new dispatch work.

## What needs doing

Replace CLI-based dispatch with a capability-resolved typed endpoint client:

1. Implement a `CapabilityDispatchClient` in `hymenium/src/dispatch/` using `spore::LocalServiceClient`
2. Resolve the Canopy dispatch endpoint via `spore::discovery` or a configured `local-service-endpoint-v1` descriptor
3. Send `dispatch-request-v1` payloads over the typed endpoint instead of shelling out to `canopy task create`
4. Keep the CLI fallback path as a degraded mode with a visible warning when the typed endpoint is unavailable; log clearly that CLI dispatch is a compatibility fallback only

## Integration Hierarchy

This migration follows the ecosystem integration rule:

- **Preferred for cross-binary calls:** typed local service endpoint (`local-service-endpoint-v1.schema.json`)
- **CLI fallback retained for:** degraded mode only, with warning; typed endpoint preferred in all normal operation

See `docs/foundations/inter-app-communication.md` for the full integration hierarchy.

## Context

Created as part of C8 (system-to-system communication boundary). References:
- C5: `septa/local-service-endpoint-v1.schema.json` — endpoint descriptor schema
- C6: `spore/src/transport.rs` — transport client (`LocalServiceClient`, `LocalServiceEndpoint`)
- C7: `septa/integration-patterns.md` CLI Coupling Classification (row: hymenium → canopy, "temporary compatibility")
- C8: `docs/foundations/inter-app-communication.md` — integration hierarchy policy
- Canopy companion: `.handoffs/canopy/dispatch-request-service-endpoint.md`
