# Cross-Project: Capability Routing Alignment

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `canopy/...`, `hymenium/...`
- **Cross-repo edits:** only the named repos above
- **Non-goals:** multi-provider scheduling policy, Cap UI, or replacing tier hints with an unbounded capability ontology
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-capability-routing-alignment.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `canopy` first, with `hymenium` dispatch integration in the same change if needed
- **Likely files/modules:** `canopy/src/models.rs`; `canopy/src/store/mod.rs`; `canopy/src/store/tasks.rs`; `hymenium/src/dispatch/orchestrate.rs`
- **Reference seams:** existing task requirement fields in Canopy and current tier assignment in Hymenium decomposition
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact files to change in both repos and the exact verification commands

## Problem

The reset wants routing by task shape, not only by effort-derived model tier, but today the worker selection path is still underpowered. Canopy can already store capability-like requirements, while Hymenium still mostly emits role and tier hints.

## What exists (state)

- **Canopy:** already has task requirement and agent capability primitives
- **Hymenium:** still tends to derive tier from effort or step count
- **Research baseline:** expects the cheapest capable worker rather than always the largest tier

## What needs doing (intent)

Align Hymenium and Canopy around a small, explicit capability model so dispatched work carries:

- required capabilities
- tier as a recommendation rather than the primary routing key
- clear assignment and claim behavior when capability requirements are unmet
- constrained tool or role bundles where the task shape requires them

## Scope

- **Primary seam:** capability requirements at dispatch and claim time
- **Allowed files:** `canopy/src/...`, `hymenium/src/...`, relevant tests
- **Explicit non-goals:**
  - Do not build a large policy engine
  - Do not treat every attribute as a new capability
  - Do not remove tier hints entirely

---

### Step 1: Normalize the capability vocabulary

**Project:** `canopy/`, `hymenium/`
**Effort:** 2-4 hours
**Depends on:** [Hymenium: Authoritative Workflow Runtime](../hymenium/authoritative-workflow-runtime.md)

Choose a small stable vocabulary for capability requirements and document how it differs from coarse tier hints.

This step should also decide whether any capabilities imply a constrained tool palette or role bundle. Keep that vocabulary intentionally small. Do not recreate a giant agent-brand matrix.

#### Verification

```bash
rg -n "required_capabilities|capabilities_match|agent_tier|tier_from_effort" canopy/src hymenium/src
```

**Checklist:**
- [ ] One small capability vocabulary is named and documented
- [ ] Capability requirements are distinct from tier recommendations
- [ ] Any constrained tool-palette or role-bundle requirements are expressed in the same small vocabulary
- [ ] Both repos use the same vocabulary

---

### Step 2: Make Hymenium emit capability requirements

**Project:** `hymenium/`
**Effort:** 0.5 day
**Depends on:** Step 1

Update dispatch so structured task packets and created tasks carry `required_capabilities` in addition to any tier recommendation.

#### Verification

```bash
cd hymenium && cargo test 2>&1
```

**Checklist:**
- [ ] Dispatch emits capability requirements explicitly
- [ ] Tier remains available as a recommendation
- [ ] Tests cover at least one packet with capabilities and one without

---

### Step 3: Enforce capability-aware assignment in Canopy

**Project:** `canopy/`
**Effort:** 0.5 day
**Depends on:** Step 2

Make claim and assignment flows use the capability requirements rather than only freeform or role-level matching.

#### Verification

```bash
cd canopy && cargo test 2>&1
cd canopy && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Capability-aware assignment works for the reset path
- [ ] Mismatches fail clearly instead of silently drifting
- [ ] If a task requires a constrained tool bundle, the mismatch is visible and actionable
- [ ] Clippy and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Hymenium and Canopy share one capability vocabulary
2. `bash .handoffs/cross-project/verify-capability-routing-alignment.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/cross-project/verify-capability-routing-alignment.sh
```

## Context

This handoff is intentionally smaller and cleaner than the older broad capability-routing idea. It aligns the reset path first instead of trying to build a generalized multi-model orchestration product in one shot. The `council` and `vibe-kanban` audits are useful guardrails here: prefer readable, constrained routing concepts over a sprawling model or vendor roster taxonomy.
