# Cross-Project: Capability Ecosystem Control Plane

## Handoff Metadata

- **Dispatch:** `umbrella`
- **Owning repo:** `multiple`
- **Allowed write scope:** none directly; dispatch child handoffs only
- **Cross-repo edits:** child handoffs decide
- **Non-goals:** no direct implementation from this umbrella and no monolithic host process that owns every tool
- **Verification contract:** complete the child handoffs, keep their paired verify scripts green, and keep dashboard links current
- **Completion update:** when all child handoffs are complete, update `.handoffs/HANDOFFS.md` and archive this umbrella if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** child handoffs own the execution seams for this umbrella
- **Likely files/modules:** none directly; identify the file set inside the selected child handoff before spawning an implementer
- **Reference seams:** `septa/README.md`, `spore/src/discovery.rs`, `spore/src/paths.rs`, `stipe/src/commands/tool_registry/`, `hymenium/src/dispatch/`, `canopy/src/`
- **Spawn gate:** do not launch an implementer from this umbrella; pick a child handoff and complete seam-finding there first

## Problem

Basidiocarp tools can be used independently, but ecosystem-mode communication still relies too much on CLI flags, PATH probing, and informal knowledge of sibling tools. That makes cross-tool integrations fragile: flag drift, endpoint drift, and capability drift are discovered at runtime instead of at contract or compile time.

Architectural rule: CLIs are human/operator surfaces. Ecosystem-mode system-to-system calls should use library APIs, Septa-typed service endpoints, or Spore-resolved capabilities. CLI adapters may remain as compatibility fallbacks only when the typed path does not exist yet.

## What exists

- **Septa:** owns payload contracts such as `dispatch-request-v1`, workflow status, read models, and tool-specific fixtures.
- **Spore:** owns shared discovery, paths, JSON-RPC, subprocess, and config primitives.
- **Stipe:** owns install profiles, managed tool inventory, host setup, doctor, and repair.
- **Canopy/Hymenium:** currently need tighter dispatch boundaries so orchestration can move away from reconstructing CLI flags by hand.

## What needs doing

Introduce a capability control plane where standalone tools can register ecosystem capabilities without being loaded into one central process.

The intended split is:

- `septa` defines portable registry and lease payloads.
- `spore` reads registry and runtime leases, resolves capabilities, and exposes typed helpers.
- `stipe` writes installed capability registry entries during install/update/uninstall/doctor flows.
- `canopy` exposes an ecosystem dispatch endpoint that accepts `dispatch-request-v1`.
- `hymenium` resolves the dispatch capability through Spore and uses the typed endpoint before falling back to CLI compatibility.
- cross-tool integrations stop treating CLI flags and stdout as the contract between tools.

## Child Handoffs

Suggested order:

1. [Septa: Capability Registry Contracts](../septa/capability-registry-contracts.md)
2. [Septa: Local Service Endpoint Contracts](../septa/local-service-endpoint-contracts.md)
3. [Spore: Local Service Transport Primitives](../spore/local-service-transport-primitives.md)
4. [Spore: Capability Registry Discovery](../spore/capability-registry-discovery.md)
5. [Stipe: Capability Registration Manager](../stipe/capability-registration-manager.md)
6. [Canopy: Dispatch Request Service Endpoint](../canopy/dispatch-request-service-endpoint.md)
7. [Hymenium: Capability Dispatch Client](../hymenium/capability-dispatch-client.md)
8. [Cross-Project: System-To-System Communication Boundary](system-to-system-communication-boundary.md)
9. [Cross-Project: CLI Coupling Exemption Audit](cli-coupling-exemption-audit.md)

## Completion Criteria

- `septa` contains versioned installed-registry and runtime-lease contracts with fixtures.
- `septa` contains a reusable local service endpoint contract or documents why the runtime lease contract fully owns that shape.
- `docs/foundations/inter-app-communication.md` remains the architecture standard for tool-to-tool communication.
- `spore` exposes local service transport primitives that make typed endpoint calls easier than shelling out.
- `spore` can locate, parse, validate, and resolve capabilities from the registry and leases.
- `stipe` writes and repairs registry entries for managed tools without making standalone tool use impossible.
- `canopy` has a typed dispatch endpoint that accepts `dispatch-request-v1`.
- `hymenium` dispatches through Spore capability resolution and treats the CLI adapter as a compatibility fallback.
- workspace rules and integration docs state that new system-to-system CLI coupling is disallowed unless it is an isolated compatibility shim with a replacement handoff.
- existing Basidiocarp-to-Basidiocarp CLI calls are inventoried as operator surfaces, temporary compatibility fallbacks, hook-time exceptions, or replacement bugs.
- `.handoffs/HANDOFFS.md` reflects the child handoff state.

## Context

This handoff captures the capability ecosystem direction discussed on 2026-04-25: tools remain useful as standalone CLIs, while ecosystem-mode integration is coordinated through explicit capabilities, Septa contracts, Spore discovery, and Stipe-managed registration.
