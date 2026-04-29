# Cross-Project: System-To-System Communication Boundary

<!-- Save as: .handoffs/cross-project/system-to-system-communication-boundary.md -->
<!-- Create verify script: .handoffs/cross-project/verify-system-to-system-communication-boundary.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `AGENTS.md`, `docs/foundations/`, `septa/`, `spore/`, `stipe/`, `canopy/`, `hymenium/`, repo-local docs and tests needed to enforce the boundary
- **Cross-repo edits:** allowed only for contract, discovery, and integration-boundary enforcement; avoid unrelated feature work
- **Non-goals:** no monolithic supervisor process and no removal of human-facing CLIs
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-system-to-system-communication-boundary.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** cross-project policy plus targeted changes in `septa`, `spore`, `canopy`, and `hymenium`
- **Likely files/modules:** workspace guidance, Septa contract inventory, Spore capability resolver, Hymenium dispatch clients, Canopy service endpoints
- **Reference seams:** capability control plane handoffs, `dispatch-request-v1`, Spore JSON-RPC helpers, Stipe tool registry
- **Spawn gate:** do not launch an implementer until the parent agent narrows this to one concrete repo slice; this handoff is a boundary/policy item, not a single code change

## Problem

Basidiocarp still has integrations where one tool shells out to another tool's CLI. That makes CLIs part of the system-to-system API even though they should be human/operator surfaces. CLI coupling creates flag drift, stdout parsing, weak typing, unclear versioning, ambient PATH trust, and late runtime failures.

## What exists (state)

- **Septa:** owns cross-tool payload contracts but does not yet state the integration hierarchy as a rule.
- **Spore:** owns shared discovery and transport primitives.
- **Stipe:** owns install, update, doctor, and capability registration.
- **Canopy/Hymenium:** dispatch currently has a CLI compatibility path, while capability endpoint/client handoffs define the stronger replacement.
- **AGENTS.md:** explains repo boundaries and Septa ownership, but does not explicitly ban new system-to-system CLI coupling.

## What needs doing (intent)

Make the ecosystem boundary explicit: CLIs are for humans and operators. Tools should integrate through library calls, Septa-typed local service endpoints, or capability-resolved transports. CLI fallbacks are allowed only as temporary compatibility adapters with visible warnings and a replacement handoff.

Implementation should land through the concrete child handoffs now tracked in the dashboard:

- Septa local service endpoint contracts
- Spore local service transport primitives
- Canopy dispatch request service endpoint
- Hymenium capability dispatch client
- cross-project CLI coupling exemption audit

## Scope

- **Primary seam:** cross-tool integration policy and enforcement points
- **Allowed files:** workspace rules, foundations docs, Septa integration docs, Spore discovery docs/tests, Hymenium/Canopy dispatch boundary tests
- **Explicit non-goals:** no centralized always-on process, no removal of existing CLIs, no Cap UI work

## Verification

```bash
cd septa && bash validate-all.sh
cd spore && cargo test capability discovery transport
cd canopy && cargo test dispatch
cd hymenium && cargo test dispatch
bash .handoffs/cross-project/verify-system-to-system-communication-boundary.sh
```

**Output:**
<!-- PASTE START -->
PASS: AGENTS states CLI is not preferred system-to-system protocol
PASS: contracts or foundations document the integration hierarchy
PASS: Canopy dispatch endpoint handoff treats CLI as operator surface
PASS: Hymenium capability client handoff treats CLI as fallback only
PASS: dashboard tracks the communication boundary handoff
Results: 5 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] workspace guidance states that CLI is a human/operator interface, not the preferred system-to-system protocol
- [x] Septa or foundations docs define the integration hierarchy
- [x] endpoint contracts and transport primitives have repo-owned handoffs
- [x] any retained CLI fallback is marked compatibility-only and has a replacement handoff
- [x] new system-to-system dispatch path uses a typed contract or library/service API
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run and follow-up architecture discussion. This generalizes the lesson beyond Hymenium and Canopy.
