# Skill Authoring Convention

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** creating actual skill content, migrating existing skills to the new format, or plugin manifest format changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-skill-authoring-convention.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** `lamella/docs/` for the format spec, `lamella/resources/skills/SKILL_TEMPLATE.md` for the template, `lamella/Makefile` for the lint target
- **Reference seams:** ECC skill format (YAML frontmatter + phased workflow body + "When to Activate" + handoff pointers); autoresearch `program.md` (Operating Contract section with loop invariants, crash triage, timeout policy, NEVER STOP declaration)
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Lamella skills lack a structured, consistent authoring convention. ECC demonstrates that 181 skills can follow one format — YAML frontmatter + phased workflow body + "When to Activate" + handoff pointers — and produce consistently usable system-prompt injections. Autoresearch's `program.md` shows that long-running autonomous skills also need an "Operating Contract" section covering loop invariants, crash triage, timeout policy, and an explicit NEVER STOP declaration. Without a canonical format, lamella skills drift in structure and quality, and there is no automated way to detect conformance problems before distribution.

## What exists (state)

- **`lamella`:** has `make validate` for structural validation and `make build-marketplace` for distribution, but no skill format specification and no lint target for skill conformance
- **ECC reference:** 181 skills following a consistent YAML frontmatter + phased workflow body + "When to Activate" + handoff pointers format
- **Autoresearch reference:** `program.md` Operating Contract pattern for autonomous skills (loop invariants, crash triage, timeout policy, NEVER STOP)

## What needs doing (intent)

1. Define and document a canonical skill authoring format as a spec document in `lamella/docs/`.
2. Create a skill template file at a canonical path (e.g., `lamella/resources/skills/SKILL_TEMPLATE.md`) that authors copy as the starting point for new skills.
3. Add a `make lint-skills` target that validates all skills in the repository conform to the required sections.
4. Wire `make lint-skills` into `make validate` so conformance is checked on every validation run.

## Scope

- **Primary seam:** skill format specification, template, and lint enforcement
- **Allowed files:** `lamella/docs/`, `lamella/resources/skills/SKILL_TEMPLATE.md`, `lamella/Makefile`, and any lint script under `lamella/scripts/`
- **Explicit non-goals:**
  - Do not create actual skill content in this handoff
  - Do not migrate existing skills to conform (that is follow-up work)
  - Do not change plugin manifest format or build targets beyond adding the lint step

---

### Step 1: Define the canonical skill authoring format

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** nothing

Write a format specification document at `lamella/docs/skill-authoring-convention.md`. The spec must define the required sections:

- **YAML frontmatter:** `name`, `description`, `origin` fields
- **When to Activate:** trigger conditions for system-prompt injection
- **How It Works:** phased workflow body (numbered phases or steps)
- **Operating Contract:** required for autonomous/long-running skills; covers loop invariants, crash triage, timeout policy, and NEVER STOP declaration
- **Handoff Pointers:** related skills and handoffs

Document which sections are required for all skills and which are required only for autonomous/long-running skills.

#### Verification

```bash
cd lamella && test -f docs/skill-authoring-convention.md && echo "spec exists"
```

**Checklist:**
- [ ] Spec document exists at `lamella/docs/skill-authoring-convention.md`
- [ ] Required sections are enumerated and described
- [ ] Operating Contract is documented as required for autonomous skills
- [ ] Conditional section requirements are clearly stated

---

### Step 2: Create the skill template file

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Step 1

Create `lamella/resources/skills/SKILL_TEMPLATE.md` as a copy-and-fill starting point for new skills. The template must include all required sections with placeholder content and inline comments explaining each field. Authors should be able to copy the template, fill in the placeholders, and produce a conforming skill.

#### Verification

```bash
cd lamella && test -f resources/skills/SKILL_TEMPLATE.md && echo "template exists"
```

**Checklist:**
- [ ] Template file exists at the canonical path
- [ ] All required sections are present with placeholder content
- [ ] Inline comments explain each field and section
- [ ] Operating Contract section is present (marked optional for non-autonomous skills)

---

### Step 3: Add make lint-skills and wire into make validate

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** Steps 1 and 2

Write a lint script (e.g., `lamella/scripts/lint-skills.sh`) that checks every skill file for the required sections defined in Step 1. Add a `make lint-skills` target that runs the script and fails if any skill is missing required sections. Wire `make lint-skills` into `make validate` so it runs on every validation pass.

#### Verification

```bash
cd lamella && make lint-skills 2>&1
cd lamella && make validate 2>&1
```

**Checklist:**
- [ ] `make lint-skills` target exists in `lamella/Makefile`
- [ ] Lint script checks all required sections
- [ ] `make validate` includes `lint-skills`
- [ ] Script exits non-zero if any skill is non-conforming

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-skill-authoring-convention.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-skill-authoring-convention.sh
```

## Context

Source: ECC ecosystem borrow audit (2026-04-14) section "Skill authoring conventions" and autoresearch audit section "program.md operating contract pattern." See `.audit/external/audits/` for the reference skill format and operating contract examples.

Related handoffs: #131 Cross-Agent Install Adapters (depends on canonical format being defined here), #133 Token Efficiency Skill, #134 Strategic Compact Skill, #135 Agent Introspection Debugging Skill (all three skill content handoffs assume this convention is in place).
