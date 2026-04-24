# Skill Management And Council Adoption Plan

Date: 2026-04-07
Re-assessed: 2026-04-23
Scope: phased adoption plan for a Lamella/Stipe skill manager and a Canopy/Cap council workflow

## Re-assessment notes (2026-04-23)

The plan is still structurally correct. Three updates apply:

**Track A (Skill Management):** W2b (lamella/skill-progressive-disclosure.md) covers part of Phase 1. The overlap is the authoring discipline work — progressive disclosure and scaffold tooling address the same lamella gap. Check W2b before duplicating effort. Phase 2 (stipe skill doctor + install safety) has no current handoff and remains open.

**Track B (Council) — ECC Council skill vs. full infrastructure:** The everything-claude-code re-audit (2026-04-23) found a concrete Council skill implementation: 4-voice deliberation (Architect, Skeptic, Pragmatist, Critic) with context-isolated subagents as an anti-anchoring mechanism. This is a **lamella skill borrow** — a SKILL.md document for ambiguous decisions. It is NOT the full canopy council-session infrastructure described in Track B. Do both: borrow the ECC Council skill into lamella first (fast, independent of Track B), then build the canopy session record as Track B Phase 1.

**Track B Phase 1 has no handoff:** The canopy council-session record (council_session record attached to a task, participant roster, timeline, verdict storage) is ready to be promoted from near-miss-findings.md to a handoff. The near-miss entry notes it as "ready to promote if desired." The ECC Council skill provides a concrete 4-voice implementation reference for what a lamella role bundle looks like (Track B Phase 2).

**Guardrails section:** Still correct. No changes needed.

Related docs:

- [.audit/external/audits/skill-manager-ecosystem-borrow-audit.md](/Users/williamnewton/projects/basidiocarp/.audit/external/audits/skill-manager-ecosystem-borrow-audit.md)
- [.audit/external/audits/council-ecosystem-borrow-audit.md](/Users/williamnewton/projects/basidiocarp/.audit/external/audits/council-ecosystem-borrow-audit.md)
- [.audit/external/synthesis/project-examples-ecosystem-synthesis.md](/Users/williamnewton/projects/basidiocarp/.audit/external/synthesis/project-examples-ecosystem-synthesis.md)

## One-paragraph read

Both ideas are worth doing, but only if they land in the repos that already own the relevant concerns. Skill management should be split between `lamella` for authoring and packaging discipline and `stipe` for install, update, doctor, and rollback. Council should be introduced as a constrained task-linked workflow in `canopy` and `cap`, with `lamella` packaging role bundles, `stipe` checking prerequisites, `cortina` capturing lifecycle signals, and `hyphae` storing the resulting artifacts. The wrong move is turning either idea into a new monolith.

## Decisions

### 1. Skill management is a split feature, not one tool

- `lamella` owns:
  - validation
  - scaffolding
  - manifest or metadata checks
  - package assembly
- `stipe` owns:
  - install
  - update
  - rollback
  - doctor
  - host mutation
  - backup and audit

Reason:

- This preserves the existing boundary where Lamella is source and packaging, while Stipe is setup and repair.

### 2. Council is a task workflow, not a general chat product

- `canopy` owns:
  - council-session records
  - task linkage
  - participant roster
  - timeline
  - result storage
- `cap` owns:
  - live council UI
  - summon controls
  - timeline and roster display
- `lamella` owns:
  - packaged role bundles
  - structured response conventions
- `stipe` owns:
  - prerequisite checks
  - installed CLI and model checks
- `cortina` owns:
  - lifecycle capture
- `hyphae` owns:
  - durable council artifacts and retrieval

Reason:

- This keeps council attached to task execution and evidence instead of creating a second coordination system.

## Non-goals

- No standalone skill-manager product inside this workspace.
- No standalone council desktop or free-form group-chat product.
- No Lamella-owned runtime installation logic.
- No Stipe-owned authoring or packaging logic.
- No Canopy-owned prompt packs or package metadata.

## Phased plan

## Track A: Skill Management

### Phase 1: Authoring discipline

Owner: `lamella`

Deliver:

- `validate-skills` command
- `scaffold-skill` command
- manifest or metadata linting for packaged skills and related plugin surfaces
- machine-readable validation output

Success criteria:

- Lamella can fail invalid skill metadata before packaging
- new skill scaffolds match current Lamella conventions
- validation output is precise enough for CI and local authoring

### Phase 2: Safe install and repair

Owner: `stipe`

Deliver:

- `doctor skills`
- install-skill-pack flow
- backup before mutation
- rollback support
- audit log for installs and updates

Success criteria:

- skill installs are reversible
- host mutation is visible and diagnosable
- broken or partial installs can be repaired without manual digging

### Phase 3: Contract alignment

Owners: `lamella`, `stipe`

Deliver:

- alignment tests between Lamella package metadata and Stipe install expectations
- drift detection for installed vs packaged state
- host-specific checks for declared capabilities

Success criteria:

- packaged skill metadata and install logic cannot silently diverge
- declared capabilities are enforced or at least verified during doctor flows

## Track B: Council

### Phase 1: Minimal task-linked summon

Owners: `canopy`, `cap`

Deliver:

- council-session record attached to a task
- summon two fixed roles, for example `reviewer` and `architect`
- shared task context and worktree
- council timeline stored on the task

Success criteria:

- a task can request two perspectives without leaving the task context
- outputs are attached to the task and readable later
- no free-form council chat surface exists yet

### Phase 2: Packaged roles and prerequisite checks

Owners: `lamella`, `stipe`

Deliver:

- packaged council role bundles
- structured response conventions
- prerequisite checks for installed CLIs, allowed tools, and model availability

Success criteria:

- the summon flow uses reusable packaged roles
- operator failures are surfaced before summon runs

### Phase 3: Lifecycle capture and retrieval

Owners: `cortina`, `hyphae`

Deliver:

- capture council lifecycle signals
- store council artifacts in durable retrieval surfaces
- allow follow-up task context to recall prior council outcomes

Success criteria:

- council state survives beyond the immediate UI session
- prior council advice can be recalled in later task work

### Phase 4: Better operator UX

Owners: `cap`, `canopy`

Deliver:

- roster and timeline views
- task-linked council status
- role-specific response rendering

Success criteria:

- council feels like a task feature, not a sidecar
- timeline and participant state are visible without opening raw logs

## Recommended order

Do first:

- Lamella validation and scaffolding
- Stipe skill doctor and install safety
- Canopy minimal council-session record

Do second:

- Lamella role bundles for council
- Stipe summon prerequisite checks
- Hyphae council artifact storage

Do later:

- richer Cap council UI
- stricter capability enforcement for packaged roles and skills
- broader role library once the minimal flow is stable

## Risks

- `lamella` absorbs runtime install logic and becomes oversized
- `stipe` absorbs authoring and packaging semantics and becomes a junk drawer
- `canopy` grows a free-form council system that competes with task-first coordination
- packaged role bundles proliferate before validation and install discipline exist

## Guardrails

- Packaging stays in `lamella`
- Host mutation stays in `stipe`
- Runtime capture stays in `cortina`
- Durable retrieval stays in `hyphae`
- Task-linked coordination stays in `canopy`
- Operator UI stays in `cap`

## Final read

Do both.

Do them as split features inside the repos that already own the relevant boundaries.

Start small: validate and scaffold skills first, then safe install; task-linked summon first, then packaged roles and retrieval.
