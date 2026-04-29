# Stipe: Capability Registration Manager

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/tool_registry/`, `stipe/src/commands/install/`, `stipe/src/commands/update.rs`, `stipe/src/commands/uninstall.rs`, `stipe/src/commands/doctor/`, `stipe/src/ecosystem/`, `stipe/tests/`, `stipe/README.md`, `stipe/docs/`
- **Cross-repo edits:** no source edits outside `stipe`; read `spore` registry APIs and `septa` capability contracts as references
- **Non-goals:** no Spore discovery implementation and no Canopy or Hymenium dispatch changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/stipe/verify-capability-registration-manager.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** `src/commands/tool_registry/model.rs`, `src/commands/tool_registry/specs.rs`, install/update/uninstall runner code, doctor tool checks, ecosystem status/config modules
- **Reference seams:** existing managed tool registry, install profile selection, doctor checks, install ownership check, Spore path helpers
- **Spawn gate:** do not launch an implementer until the parent agent confirms the Spore registry writer/reader API and the exact registry location

## Problem

Stipe already knows which tools it installs and repairs, but that inventory is not written as an ecosystem capability registry. Downstream tools cannot reliably ask "what capability is available?" without duplicating Stipe's inventory policy or probing binaries themselves.

## What exists

- **Tool registry:** Stipe has managed tool specs and probe behavior.
- **Install/update/uninstall:** Stipe controls the lifecycle of managed binaries.
- **Doctor:** Stipe can report missing or broken tools, but not as a shared capability registry payload.

## What needs doing

Make Stipe the writer and repair surface for the installed capability registry.

Minimum behavior:

- map managed tool specs to capability ids and Septa contract ids
- write `capability-registry-v1` after successful install/update
- remove or mark entries during uninstall
- repair stale binary paths during doctor or explicit repair
- preserve manually installed tools as user-managed entries when detected, without claiming Stipe ownership
- include optional runtime hints for service-capable tools, while leaving live endpoint leases to the running tool or service wrapper

## Scope

- **Primary seam:** Stipe-managed installed capability registry writes and doctor validation
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no runtime daemon, no direct Canopy service endpoint, no dashboard UI

## Verification

```bash
cd stipe && cargo test tool_registry
cd stipe && cargo test install
cd stipe && cargo test doctor
cd stipe && cargo clippy -- -D warnings
cd stipe && cargo fmt --check
bash .handoffs/stipe/verify-capability-registration-manager.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] managed tool specs include capability ids and contract ids
- [ ] install/update writes registry entries only after successful binary resolution
- [ ] uninstall removes or marks removed managed entries
- [ ] doctor detects stale capability registry entries
- [ ] manual tools are not mislabeled as Stipe-managed
- [ ] docs state that Stipe writes and Spore reads the registry
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Child handoff of [Cross-Project: Capability Ecosystem Control Plane](../cross-project/capability-ecosystem-control-plane.md). This depends on the Septa contracts and Spore path/registry primitives.
