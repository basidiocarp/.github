# Spore: Local Service Transport Primitives

<!-- Save as: .handoffs/spore/local-service-transport-primitives.md -->
<!-- Create verify script: .handoffs/spore/verify-local-service-transport-primitives.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `spore`
- **Allowed write scope:** `spore/src/transport/`, `spore/src/discovery.rs`, `spore/src/paths.rs`, `spore/src/types.rs`, `spore/src/lib.rs`, `spore/tests/`, `spore/README.md`, `spore/docs/`
- **Cross-repo edits:** none; read Septa endpoint and capability contracts as references
- **Non-goals:** no Canopy dispatch endpoint implementation and no Stipe registry writer
- **Verification contract:** run the repo-local commands below and `bash .handoffs/spore/verify-local-service-transport-primitives.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `spore`
- **Likely files/modules:** local socket/HTTP transport helpers, JSON-RPC client helpers, endpoint descriptor parsing, capability resolver output types
- **Reference seams:** existing Spore JSON-RPC helpers, path helpers, discovery APIs, capability registry discovery handoff
- **Spawn gate:** do not launch an implementer until the Septa endpoint descriptor contract is stable enough to consume

## Problem

Spore is the right place for shared discovery and transport primitives, but callers still need to implement their own local socket or endpoint client behavior. That encourages each repo to fall back to CLI calls because the typed service path is more work than shelling out.

## What exists (state)

- **Discovery:** Spore has tool discovery primitives.
- **Transport:** Spore has lower-level shared helpers, but not a clear local service endpoint client abstraction tied to capability resolution.
- **Contracts:** endpoint descriptor and runtime lease contracts are planned in Septa.

## What needs doing (intent)

Add reusable local service client primitives that make endpoint calls the easy path:

- parse Septa endpoint descriptors or runtime leases into typed endpoint candidates
- support Unix socket JSON-RPC where available
- support loopback HTTP or platform fallback where Unix sockets are unavailable
- provide timeout, health/version probe, and structured error behavior
- expose a small API for "call capability endpoint with request and response types"
- keep CLI fallback metadata visible but outside the preferred transport path

## Scope

- **Primary seam:** Spore local service transport and endpoint resolution
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no daemon, no Canopy-specific dispatch logic, no registry writing

## Verification

```bash
cd spore && cargo test transport
cd spore && cargo test capability discovery
cd spore && cargo clippy -- -D warnings
cd spore && cargo fmt --check
bash .handoffs/spore/verify-local-service-transport-primitives.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Spore parses endpoint descriptors or runtime leases into endpoint candidates
- [ ] Unix socket JSON-RPC client behavior is covered where the platform supports it
- [ ] loopback or platform fallback is documented and tested where practical
- [ ] health/version probe and timeout behavior are covered
- [ ] API returns structured errors suitable for CLI-fallback decisions
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 inter-app communication architecture decision. This handoff makes typed local service endpoints practical for callers like Hymenium, Cap, and future ecosystem tools.

