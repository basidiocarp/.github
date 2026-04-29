# Septa: Capability Registry Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** `septa/*capability*.schema.json`, `septa/fixtures/*capability*.json`, `septa/README.md`, `septa/CROSS-TOOL-PAYLOADS.md`, `septa/integration-patterns.md`, `septa/validate-all.sh`, `septa/scripts/`
- **Cross-repo edits:** none; consumers belong in follow-up handoffs
- **Non-goals:** no Spore registry reader implementation and no Stipe install behavior changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/septa/verify-capability-registry-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** new `capability-registry-v1.schema.json`, new `capability-runtime-lease-v1.schema.json`, fixtures, contract inventory docs, validation scripts
- **Reference seams:** `dispatch-request-v1.schema.json`, `workflow-participant-runtime-identity-v1.schema.json`, `stipe-doctor-v1.schema.json`, `fixtures/*.example.json`, `CROSS-TOOL-PAYLOADS.md`
- **Spawn gate:** do not launch an implementer until the parent agent confirms the schema names and whether installed registry and runtime lease stay as two separate contracts

## Problem

The capability ecosystem needs a portable contract for "what is installed" and "what is currently reachable." Without that contract, Stipe, Spore, Hymenium, Canopy, Cap, and Annulus will each invent their own registry fields.

## What exists

- **Septa:** already owns cross-tool schema and fixture governance.
- **Spore/Stipe docs:** already describe discovery, installation, and registration ownership, but no portable registry payload exists.
- **Current integration:** tools can be detected through PATH or tool-local probes, but ecosystem capabilities are not first-class payloads.

## What needs doing

Define two v1 contracts:

1. `capability-registry-v1`: stable installed capability entries written by Stipe and consumed by Spore.
2. `capability-runtime-lease-v1`: ephemeral live endpoint records written by running tools or service wrappers and consumed by Spore.

The contracts should support at least:

- tool name and version
- manager/source such as `stipe`, `manual`, or `self`
- binary path or package identity when known
- capability ids such as `workflow.dispatch.v1` and `code.graph.v1`
- related Septa contract ids such as `dispatch-request-v1`
- transport kind such as `stdio`, `unix-socket`, `tcp`, or `cli`
- endpoint or command reference where appropriate
- freshness fields for runtime leases, including pid and timestamps
- degradation or health summary fields that downstream status surfaces can display without parsing tool-specific output

## Scope

- **Primary seam:** portable capability registry and runtime lease schemas
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no implementation in `spore`, no install policy in `stipe`, no dashboard UI

## Verification

```bash
cd septa && bash validate-all.sh
cd septa && bash scripts/check-cross-tool-payloads.sh
bash .handoffs/septa/verify-capability-registry-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] installed registry and runtime lease schemas exist and are versioned
- [ ] fixtures validate against both schemas
- [ ] `README.md` contract inventory lists both contracts
- [ ] `CROSS-TOOL-PAYLOADS.md` records producers and consumers
- [ ] integration docs explain Stipe writer and Spore reader ownership
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Child handoff of [Cross-Project: Capability Ecosystem Control Plane](../cross-project/capability-ecosystem-control-plane.md). This is the first dependency for the capability registry rollout.
