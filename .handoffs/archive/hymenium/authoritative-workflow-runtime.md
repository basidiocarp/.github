# Hymenium: Authoritative Workflow Runtime

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/...`
- **Cross-repo edits:** `septa/...` only if a named orchestration contract must be consumed in the same change
- **Non-goals:** Canopy storage changes, Cap UI work, or broad multi-template generalization
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-authoritative-workflow-runtime.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** `src/main.rs`; `src/workflow/engine.rs`; `src/workflow/template.rs`; `src/dispatch/orchestrate.rs`; `src/store.rs`; `src/dispatch/cli.rs`
- **Reference seams:** current workflow engine, dispatch modules, and store boundary
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact modules to change and the exact repo-local verification commands

## Problem

Hymenium is supposed to be the orchestrator, but the public CLI is still mostly stubbed and the runtime does not yet own the full workflow lifecycle. The result is a mismatch between the intended authority model and the actual execution surface.

## What exists (state)

- **Workflow engine:** has real phase and gate logic but a narrower state model than the reset requires
- **Dispatch path:** can create Canopy tasks but still degrades phase work into thin freeform descriptions
- **CLI:** `dispatch`, `status`, and `cancel` are still not real runtime commands

## What needs doing (intent)

Turn Hymenium into the actual orchestration runtime for one canonical workflow, `impl-audit`, with persisted workflow instances, real command surfaces, structured phase packets, and explicit runtime seams for claim, resume, and later watchdog integration.

## Scope

- **Primary seam:** authoritative workflow lifecycle and runtime commands
- **Allowed files:** `hymenium/src/...`, `hymenium/tests/...`, `hymenium/docs/...`
- **Explicit non-goals:**
  - Do not add more workflow templates yet
  - Do not push workflow ownership into Canopy
  - Do not add repair automation beyond what the typed failure model can support

---

### Step 1: Rewrite the workflow state model around the canonical flow

**Project:** `hymenium/`
**Effort:** 0.5-1 day
**Depends on:** [Septa: Orchestration Contract Reset](../septa/orchestration-contract-reset.md)

Expand the workflow runtime so it can represent compilation, verification, escalation, and the canonical end-to-end `impl-audit` path without collapsing those states into generic `failed` or `completed`.

#### Verification

```bash
cd hymenium && cargo test workflow 2>&1
```

**Checklist:**
- [ ] Workflow states match the reset model rather than the thin pre-reset model
- [ ] `impl-audit` is the only required canonical template for this handoff
- [ ] Transition tests cover the intended happy path and gated failure paths

---

### Step 2: Implement real dispatch, status, and cancel commands

**Project:** `hymenium/`
**Effort:** 0.5-1 day
**Depends on:** Step 1

Replace the CLI stubs with real command handlers that create workflow instances, report workflow status, and cancel workflows cleanly.

The command and dispatch path should also make room for:

- explicit workflow identity on creation
- explicit claim or assignment state rather than implicit "someone picked this up"
- session-threading fields when work resumes from an earlier runtime or workdir
- clean composition with the separate runtime sweeper handoff instead of burying liveness logic in ad hoc retry code

#### Verification

```bash
cd hymenium && cargo test 2>&1
```

**Checklist:**
- [ ] `hymenium dispatch` is a real command
- [ ] `hymenium status` is a real command
- [ ] `hymenium cancel` is a real command
- [ ] Workflow creation and status can expose assignment or claim context explicitly
- [ ] Dispatch and status can preserve prior-session or prior-workdir threading when present

---

### Step 3: Replace freeform phase descriptions with structured packets and persistence

**Project:** `hymenium/`
**Effort:** 0.5-1 day
**Depends on:** Step 2

Use the canonical task packet contract when dispatching work and persist workflow instances and transitions so Hymenium can be queried as the source of execution truth.

#### Verification

```bash
cd hymenium && cargo check 2>&1
cd hymenium && cargo test 2>&1
cd hymenium && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Dispatch uses structured packets instead of only freeform phase strings
- [ ] Workflow instances and transitions are durably stored
- [ ] Stored workflow state can preserve runtime, session, or workdir resume metadata where available
- [ ] Clippy and tests pass without new warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Hymenium owns the canonical workflow lifecycle in practice
2. `bash .handoffs/hymenium/verify-authoritative-workflow-runtime.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/hymenium/verify-authoritative-workflow-runtime.sh
```

## Context

This is the runtime core of the reset. Once this handoff lands, Canopy can be simplified around the assumption that Hymenium is authoritative for workflow lifecycle and phase progression. The `multica` audit is especially useful here for explicit claim, sweeper, and session-threading seams, but the runtime sweeper itself still belongs in the separate [Runtime Sweeper](runtime-sweeper.md) handoff.
