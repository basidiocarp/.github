# Septa: Orchestration Contract Reset

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** `septa/...`
- **Cross-repo edits:** docs-only alignment in `docs/research/orchestration/...` if a contract rename needs a matching note
- **Non-goals:** Hymenium runtime implementation, Canopy storage changes, or preserving old orchestration contract shapes just because they already exist
- **Verification contract:** run the repo-local commands below and `bash .handoffs/septa/verify-orchestration-contract-reset.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** `dispatch-request-v1.schema.json`; `workflow-status-v1.schema.json`; new `task-packet-v1.schema.json`; new `workflow-outcome-v1.schema.json`; matching fixtures; `README.md`
- **Reference seams:** existing Canopy and workflow contracts in `septa/` and their example fixtures
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact schema files and fixture files to update

## Problem

The current orchestration contracts are thinner than the orchestration model you actually want. They do not carry a real task packet, they under-specify workflow outcomes, and their workflow status model is narrower than the reset target.

## What exists (state)

- **`dispatch-request-v1`:** workflow intake exists but is missing the phase/task packet details
- **`workflow-status-v1`:** status exists but mirrors the thin live state model
- **`septa` fixtures:** can validate new contracts once they are made real

## What needs doing (intent)

Reset the orchestration contract layer so Septa becomes the single source of truth for:

- workflow intake
- workflow runtime status
- task or phase packet shape
- workflow outcome and failure reporting

## Scope

- **Primary seam:** orchestration schema and fixture reset
- **Allowed files:** `septa/*.schema.json`, `septa/fixtures/*.json`, `septa/README.md`
- **Explicit non-goals:**
  - Do not implement Hymenium runtime logic
  - Do not add compatibility shims
  - Do not widen contracts for future templates beyond the canonical `impl-audit` flow

---

### Step 1: Rewrite the workflow intake and status contracts

**Project:** `septa/`
**Effort:** 0.5 day
**Depends on:** [Cross-Project: Authoritative Orchestration ADR](../cross-project/authoritative-orchestration-adr.md)

Rewrite `dispatch-request-v1` and `workflow-status-v1` so they match the authoritative ownership split and the richer workflow lifecycle expected by the reset.

#### Verification

```bash
cd septa && bash validate-all.sh
```

**Checklist:**
- [ ] `dispatch-request-v1` matches the reset intake model
- [ ] `workflow-status-v1` exposes the states the reset actually needs
- [ ] Updated fixtures validate cleanly

---

### Step 2: Add the canonical task and outcome contracts

**Project:** `septa/`
**Effort:** 0.5 day
**Depends on:** Step 1

Add:

- `task-packet-v1`
- `workflow-outcome-v1`

The task packet should carry goal, constraints, dependencies, acceptance criteria, capability requirements, context budget, and escalation conditions. The workflow outcome should carry failure type, attempt count, route taken, confidence, and root-cause layer.

#### Verification

```bash
cd septa && bash validate-all.sh
```

**Checklist:**
- [ ] `task-packet-v1` exists with a validating fixture
- [ ] `workflow-outcome-v1` exists with a validating fixture
- [ ] Contract names and descriptions are documented in `septa/README.md`

---

### Step 3: Remove obsolete orchestration fields and notes

**Project:** `septa/`
**Effort:** 2-4 hours
**Depends on:** Step 2

Delete or tighten orchestration fields that no longer fit the reset model instead of preserving them as compatibility baggage.

#### Verification

```bash
cd septa && bash validate-all.sh
```

**Checklist:**
- [ ] Obsolete orchestration fields are removed rather than deprecated in place
- [ ] The README inventory reflects the reset contracts
- [ ] All fixtures still validate

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. The orchestration schemas and fixtures are updated
2. `bash .handoffs/septa/verify-orchestration-contract-reset.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/septa/verify-orchestration-contract-reset.sh
```

## Context

This is the contract foundation for the reset. Hymenium runtime work and Canopy ledger alignment should not proceed on ad hoc packet shapes once this handoff starts.
