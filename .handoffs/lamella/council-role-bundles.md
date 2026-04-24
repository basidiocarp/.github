# Lamella: Council Role Bundles

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/resources/skills/council.md` (new), `lamella/resources/skills/council-roles/` (new directory), `lamella/resources/presets/` (new council-roles preset)
- **Cross-repo edits:** none
- **Non-goals:** no canopy API changes; no cap UI; no cross-agent message passing protocol; no lamella build pipeline changes
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Two converging signals from 2026-04-23:

- **skill-management-and-council-adoption-plan Track B Phase 2**: "lamella owns packaged role bundles — structured skill documents that canopy can reference when spawning council participants."
- **ECC everything-claude-code Council skill re-audit**: 4-voice deliberation pattern (Architect, Skeptic, Pragmatist, Critic) with context-isolated subagents as an anti-anchoring mechanism. Canopy already has `CouncilSession`, `CouncilParticipant`, and `CouncilParticipantRole`. Lamella needs the packaged content layer.

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:**
  - `lamella/resources/skills/council.md` (new) — top-level Council skill adapting the ECC 4-voice pattern
  - `lamella/resources/skills/council-roles/council-architect.md` (new)
  - `lamella/resources/skills/council-roles/council-skeptic.md` (new)
  - `lamella/resources/skills/council-roles/council-pragmatist.md` (new)
  - `lamella/resources/skills/council-roles/council-critic.md` (new)
  - `lamella/resources/presets/council-roles.json` (new) — preset bundling all four role files
- **Reference seams:**
  - `lamella/resources/skills/` — read 2–3 existing skill documents to understand the frontmatter and body conventions before writing new ones
  - `lamella/resources/presets/` — read an existing preset to understand the bundle format
  - `lamella/resources/hooks/` — read to understand if any hook registration is needed for skills
- **Spawn gate:** read existing skill and preset examples before spawning; the role bundle format must match what lamella's existing validate target expects

## Problem

Canopy has the runtime infrastructure for council sessions (`CouncilSession`, `CouncilParticipant`, `CouncilParticipantRole`) but has no content to load. Without packaged role definitions, operators must write their own council voice instructions from scratch each time, and there is no shared vocabulary for the four deliberation voices. Lamella is the right owner for this content: it already packages skills, hooks, and presets for distribution. This handoff adds the council content layer that canopy's existing infrastructure can reference.

## What needs doing (intent)

1. Borrow and adapt ECC's Council skill: create `lamella/resources/skills/council.md` documenting the 4-voice deliberation pattern with context-isolated subagents as the anti-anchoring mechanism
2. Define role bundle frontmatter format: YAML with `role: council_role`, `voice:`, `focus:`, `response_format:` fields
3. Create four role bundle skill documents under `lamella/resources/skills/council-roles/`
4. Add a `council-roles` preset to `lamella/resources/presets/` bundling all four role files
5. Verify with `make validate`

## Role bundle frontmatter format

Each role bundle is a lamella skill document with YAML frontmatter followed by a Markdown body:

```yaml
---
role: council_role
voice: architect          # one of: architect | skeptic | pragmatist | critic
focus: >
  One sentence describing the primary question this voice focuses on.
response_format: >
  One sentence describing how this voice structures its response.
---
```

The Markdown body contains:
- **Perspective**: a paragraph describing the worldview and analytical lens of this voice
- **Primary questions**: a short list of the questions this voice always asks
- **Response structure**: a brief description of how responses should be formatted (e.g., bullet points, structured concerns, narrative)
- **Anti-anchoring note**: a reminder that this voice must form its assessment independently before reading other voices

## Four roles

**Architect** (`council-architect.md`):
- Focus: long-term structural soundness and maintainability
- Questions: Does this fit the existing architecture? What does this make harder to change later? Are the abstractions right?
- Response format: structured assessment with a clear recommendation and the key tradeoff

**Skeptic** (`council-skeptic.md`):
- Focus: risk, edge cases, and failure modes
- Questions: What can go wrong? What assumption is most likely to be wrong? What is the worst-case outcome?
- Response format: a ranked list of concerns with severity and likelihood

**Pragmatist** (`council-pragmatist.md`):
- Focus: implementation cost, timeline, and what ships
- Questions: What is the simplest version that works? What is the delivery risk? What would we cut if we had to?
- Response format: a concrete recommendation with effort estimate and the minimum viable scope

**Critic** (`council-critic.md`):
- Focus: quality, correctness, and whether the proposal actually solves the stated problem
- Questions: Does this actually solve the problem? Is the reasoning sound? What is being glossed over?
- Response format: a direct verdict with the most important gap or flaw identified

## Council skill document (council.md)

The top-level `council.md` skill documents the 4-voice pattern as an operator-facing skill:
- When to use a council session (non-trivial decisions, architecture choices, risk assessment)
- How to invoke it (spawn four context-isolated subagents, each loaded with one role bundle)
- Anti-anchoring protocol: each subagent reads only its role bundle and the problem statement; no subagent reads another's output before forming its own assessment
- Synthesis step: after all four voices respond, a separate synthesis pass integrates the outputs

## Council-roles preset

`lamella/resources/presets/council-roles.json` bundles all four role documents so operators can install the full set with a single preset reference. Format must match the existing preset schema in `lamella/resources/presets/`.

## Scope

- **Allowed files:** `lamella/resources/skills/council.md` (new), `lamella/resources/skills/council-roles/council-architect.md` (new), `lamella/resources/skills/council-roles/council-skeptic.md` (new), `lamella/resources/skills/council-roles/council-pragmatist.md` (new), `lamella/resources/skills/council-roles/council-critic.md` (new), `lamella/resources/presets/council-roles.json` (new)
- **Explicit non-goals:**
  - No canopy source changes (the runtime already has `CouncilSession` and role types)
  - No cap UI changes
  - No cross-agent message passing protocol
  - No lamella build pipeline changes
  - No septa schema additions in this handoff

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing content, read:
1. `lamella/resources/skills/` — read 2–3 existing skill documents to understand frontmatter fields, tone, and body structure
2. `lamella/resources/presets/` — read one existing preset to understand the bundle format and required fields
3. Run `cd lamella && make validate` to confirm the baseline is green before adding anything

---

### Step 1: Write four council role bundle documents

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 0

Create `lamella/resources/skills/council-roles/` and write all four role documents using the frontmatter format above. Each document must be self-contained: an operator can hand it to a subagent without any other context and get a coherent council voice.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -5
```

**Checklist:**
- [ ] `council-roles/` directory created with four files
- [ ] Each file has valid YAML frontmatter with all required fields (`role`, `voice`, `focus`, `response_format`)
- [ ] Each file has a Markdown body with Perspective, Primary questions, Response structure, and Anti-anchoring note sections
- [ ] `make validate` passes with the new files present

---

### Step 2: Write council.md top-level skill

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 1

Create `lamella/resources/skills/council.md` documenting the 4-voice deliberation pattern. Include: when to use it, how to invoke it, anti-anchoring protocol, and synthesis step.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -5
```

**Checklist:**
- [ ] `council.md` is present and non-empty
- [ ] Frontmatter is valid (if the skill format requires it)
- [ ] Anti-anchoring protocol is clearly described
- [ ] Synthesis step is described
- [ ] `make validate` still passes

---

### Step 3: Add council-roles preset

**Project:** `lamella/`
**Effort:** tiny
**Depends on:** Step 2

Create `lamella/resources/presets/council-roles.json` referencing all four role bundle files. Match the format of existing presets exactly.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -5
```

**Checklist:**
- [ ] `council-roles.json` present in `presets/`
- [ ] All four role bundle paths are referenced
- [ ] `make validate` passes with the preset included

---

### Step 4: Full validate

```bash
cd lamella && make validate 2>&1 | tail -20
```

**Checklist:**
- [ ] `make validate` exits 0
- [ ] No warnings about new files
- [ ] All five new files (four roles + council.md) are reachable by the validate target

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output
2. `make validate` exits 0 with all new files present
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- `canopy`: map `voice` frontmatter field to `CouncilParticipantRole` enum so council sessions can load role bundles by name
- `stipe install-skills`: install the council-roles preset to the host's Claude config directory (depends on W3e skill-install-pack)
- `septa/council-role-bundle-v1.schema.json` — if role bundles need a validated schema for cross-tool use
- `cap`: surface council session history and role outputs in the operator dashboard

## Context

Spawned from skill-management-and-council-adoption-plan Track B Phase 2 and the ECC Council skill re-audit (2026-04-23). Canopy has had `CouncilSession` and `CouncilParticipant` infrastructure for some time; the missing piece is the content layer. The ECC Council skill provides a well-tested 4-voice pattern (Architect, Skeptic, Pragmatist, Critic) with context isolation as the anti-anchoring mechanism. Lamella is the natural owner for this content: it already packages skills, hooks, and presets, and the council-roles preset gives operators a single install target for the full deliberation kit.
