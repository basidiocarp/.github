# Spore: Capability Registry Discovery

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `spore`
- **Allowed write scope:** `spore/src/paths.rs`, `spore/src/discovery.rs`, `spore/src/config.rs`, `spore/src/types.rs`, `spore/src/lib.rs`, `spore/tests/`, `spore/README.md`, `spore/docs/`
- **Cross-repo edits:** no source edits outside `spore`; read `septa/capability-registry-v1.schema.json` and `septa/capability-runtime-lease-v1.schema.json` as references
- **Non-goals:** no Stipe registry writing, no Canopy service implementation, and no transport daemon
- **Verification contract:** run the repo-local commands below and `bash .handoffs/spore/verify-capability-registry-discovery.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `spore`
- **Likely files/modules:** `src/paths.rs`, `src/discovery.rs`, a new registry/capability module if needed, public exports in `src/lib.rs`, integration tests
- **Reference seams:** current `discover` API, availability probe types, platform path helpers, JSON-RPC transport types
- **Spawn gate:** do not launch an implementer until the parent agent confirms the Septa schema fields and the desired API names for resolving capabilities

## Problem

Spore can discover binaries and provide shared transport primitives, but ecosystem callers need a higher-level question: "which installed or live tool can satisfy this capability?" Without that API, tools keep probing PATH or reconstructing sibling CLIs directly.

## What exists

- **Discovery:** Spore already centralizes tool discovery and PATH-oriented lookup.
- **Paths:** Spore already owns platform path primitives.
- **Availability:** Spore already models tool availability and degraded capabilities, but not a persistent installed registry plus runtime leases.

## What needs doing

Add registry primitives that let downstream repos consume Stipe-managed registration without depending on Stipe internals.

Minimum API shape:

- locate the Basidiocarp registry file and runtime lease directory
- parse `capability-registry-v1`
- parse `capability-runtime-lease-v1`
- resolve capability id to a preferred endpoint or binary fallback
- expose enough typed information for callers to decide between live API, stdio, and CLI fallback
- degrade gracefully when registry files are absent, invalid, stale, or refer to missing binaries

## Scope

- **Primary seam:** shared capability discovery and endpoint resolution primitives
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no install/update/uninstall policy, no UI, no hard dependency on Canopy or Hymenium

## Verification

```bash
cd spore && cargo test capability
cd spore && cargo test discovery
cd spore && cargo clippy -- -D warnings
cd spore && cargo fmt --check
bash .handoffs/spore/verify-capability-registry-discovery.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Spore exposes registry and runtime lease path helpers
- [ ] Spore can parse valid Septa registry and lease fixtures
- [ ] missing registry degrades without panicking
- [ ] stale runtime lease does not override a healthy binary fallback
- [ ] public API can resolve `workflow.dispatch.v1` to an endpoint candidate
- [ ] README or docs explain Stipe writes and Spore reads
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Child handoff of [Cross-Project: Capability Ecosystem Control Plane](../cross-project/capability-ecosystem-control-plane.md). This should wait until the Septa capability contracts are stable enough to consume.
