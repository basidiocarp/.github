# Septa: Local Service Endpoint Contracts

<!-- Save as: .handoffs/septa/local-service-endpoint-contracts.md -->
<!-- Create verify script: .handoffs/septa/verify-local-service-endpoint-contracts.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** `septa/*endpoint*.schema.json`, `septa/*transport*.schema.json`, `septa/fixtures/*endpoint*.json`, `septa/fixtures/*transport*.json`, `septa/README.md`, `septa/CROSS-TOOL-PAYLOADS.md`, `septa/integration-patterns.md`, `septa/scripts/`, `septa/validate-all.sh`, `docs/foundations/inter-app-communication.md`
- **Cross-repo edits:** docs only outside `septa`
- **Non-goals:** no Spore transport implementation and no Canopy/Hymenium dispatch code
- **Verification contract:** run the repo-local commands below and `bash .handoffs/septa/verify-local-service-endpoint-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** endpoint descriptor schema, service request/response envelope schema, fixtures, integration inventory, validation scripts
- **Reference seams:** `dispatch-request-v1.schema.json`, `capability-registry-v1`, `capability-runtime-lease-v1`, `workflow-status-v1`, `integration-patterns.md`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether endpoint metadata belongs inside runtime leases or as a separate reusable endpoint descriptor contract

## Problem

The architecture now says separate local apps should communicate through typed service endpoints, but Septa does not yet define the reusable endpoint and response contract shape. Without that, each tool can invent its own socket metadata, health response, error envelope, and version negotiation.

## What exists (state)

- **Septa payloads:** many request/read-model schemas already exist.
- **Capability contracts:** installed registry and runtime lease work has a handoff.
- **Integration docs:** `integration-patterns.md` inventories current cross-tool calls, including legacy CLI paths.
- **Foundation rule:** `docs/foundations/inter-app-communication.md` defines the communication hierarchy.

## What needs doing (intent)

Create the minimum shared contracts needed for local service endpoints:

- endpoint descriptor fields for transport, address, capability id, contract ids, health method, and timeout hints
- common response/error envelope fields for local service calls
- fixtures for Unix socket JSON-RPC and loopback HTTP-style endpoints
- docs explaining when to use endpoint descriptors versus capability runtime leases
- integration inventory updates marking CLI paths as exceptions or compatibility debt

## Scope

- **Primary seam:** Septa endpoint/transport contract definitions
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no service runtime implementation, no registry writer, no dashboard UI

## Verification

```bash
cd septa && bash validate-all.sh
cd septa && bash scripts/check-cross-tool-payloads.sh
bash .handoffs/septa/verify-local-service-endpoint-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] local service endpoint descriptor schema exists and validates fixtures
- [ ] local service response/error envelope schema exists or the decision to reuse JSON-RPC is documented
- [ ] fixtures cover at least Unix socket and loopback service descriptors
- [ ] integration-patterns documents CLI exceptions and typed endpoint preference
- [ ] foundation standard links to the Septa contracts
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 inter-app communication architecture decision. This is the contract layer that makes "CLI is not the system API" enforceable.

