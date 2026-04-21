# Task Linked Council Sessions

## Problem

The audits show a repeated opportunity around structured multi-agent feedback, but the ecosystem does not yet have a clear task-linked council workflow. Today there is no first-class way to attach a “summon two roles now” discussion, participant roster, or council timeline to a task and keep the resulting artifacts retrievable later.

## What exists (state)

- **`canopy`:** already owns task records, handoffs, evidence, and operator coordination
- **`cap`:** already exposes operator task surfaces
- **`lamella`:** already packages workflows and role-style content
- **`stipe`:** already owns setup and prerequisite checks
- **`cortina`:** already captures lifecycle signals
- **`hyphae`:** already stores and retrieves durable context
- **Examples:** `council`, `1code`, and `claurst` all reinforced the same need from different angles

## What needs doing (intent)

Introduce council as a constrained task feature, not a free-form chat product:

- task-linked council-session record
- summon two fixed roles
- shared task and worktree context
- stored timeline and responses
- packaged role bundles
- prerequisite and policy checks
- later retrieval of council artifacts

---

### Step 1: Add council-session records to Canopy

**Project:** `canopy/`
**Effort:** 3-4 hours
**Depends on:** nothing

Add a first-class council-session record linked to a task and worktree. Include:

- session id
- task id
- participant roster
- state such as open or closed
- timeline or transcript reference

#### Files to modify

**`canopy/`** — add store, model, and API support for council-session records.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -20
cd canopy && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] canopy stores council-session records linked to tasks
- [ ] records include participant and lifecycle state
- [ ] build and tests pass

---

### Step 2: Add minimal summon flow in Canopy and Cap

**Project:** `canopy/` and `cap/`
**Effort:** 4-5 hours
**Depends on:** Step 1

Implement a minimal summon flow:

- summon two fixed roles, for example `reviewer` and `architect`
- attach outputs to the council session
- show roster and timeline in the operator UI

Do not add general-purpose council chat yet.

#### Files to modify

**`canopy/`** — add summon action and timeline storage.

**`cap/`** — add council timeline and roster surfaces on the task UI.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -20
cd canopy && cargo test 2>&1 | tail -40
cd cap && npm run build 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] summon flow is task-linked
- [ ] cap shows council roster and timeline
- [ ] no free-form council chat path is introduced
- [ ] canopy and cap verification pass

---

### Step 3: Add packaged roles, prerequisite checks, and retrieval

**Project:** `lamella/`, `stipe/`, `cortina/`, `hyphae/`
**Effort:** 4-6 hours
**Depends on:** Step 2

Complete the loop:

- package council role bundles in Lamella
- check prerequisites in Stipe
- capture lifecycle signals in Cortina
- store and retrieve council artifacts in Hyphae

#### Files to modify

**`lamella/`** — add packaged council role bundles and response conventions.

**`stipe/`** — add summon prerequisite and policy checks.

**`cortina/`** — add council lifecycle capture.

**`hyphae/`** — add council artifact retrieval.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
cd stipe && cargo build 2>&1 | tail -20
cd hyphae && cargo build --workspace 2>&1 | tail -20
cd cortina && cargo build 2>&1 | tail -20
bash .handoffs/archive/cross-project/verify-task-linked-council-sessions.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] lamella packages council roles
- [ ] stipe checks summon prerequisites
- [ ] cortina captures council lifecycle signals
- [ ] hyphae can retrieve council artifacts
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/cross-project/verify-task-linked-council-sessions.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/cross-project/verify-task-linked-council-sessions.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/council/ecosystem-borrow-audit.md`
- `.audit/external/audits/1code/ecosystem-borrow-audit.md`
- `.audit/external/audits/claurst/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/skill-management-and-council-adoption-plan.md`
