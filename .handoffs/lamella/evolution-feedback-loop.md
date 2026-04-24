# Lamella: Evolution Feedback Loop

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/resources/skills/evolve-skill.md` (new skill doc), `lamella/resources/commands/` or equivalent (new `/evolve-skill` command doc)
- **Cross-repo edits:** `hyphae` (store evolution lessons via the hyphae CLI or MCP tool — no source edits to hyphae)
- **Non-goals:** no automated skill rewriting; no CI gate on evolution deltas; no ML-based diff classification; human review only
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by harness Wave 2 audit and wave2-ecosystem-synthesis Theme 9 (skill evolution and practice alignment):

> "The `/harness:evolve` command is the most underrated feature in the harness ecosystem. It closes the loop that every other skill system leaves open: what the skill said to do versus what the operator actually shipped. Accumulated deltas are the real training signal."
> — harness Wave 2 audit, evolution feedback section

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:**
  - `resources/skills/` — add `evolve-skill.md` as a new skill document
  - `resources/commands/` (or wherever lamella houses slash-command docs) — add `/evolve-skill` command document
- **Cross-repo boundary:**
  - `hyphae` — evolution lessons are stored via `hyphae memory store` (CLI) or `mcp__hyphae__hyphae_memory_store` (MCP tool); no source edits to hyphae are needed
- **Reference seams:**
  - Read two or three existing lamella skill documents to understand the expected frontmatter and body structure before writing `evolve-skill.md`
  - Read existing lamella command documents (if any) to understand the expected format for `/evolve-skill`
  - Read `lamella/Makefile` to check whether command documents are validated or built separately from skill documents
- **Spawn gate:** do a short seam-finding pass first — identify where command documents live, what frontmatter is required for skill docs, and whether hyphae is available via CLI in the lamella build environment, then spawn

## Problem

Every lamella skill describes what an operator should do. But skills drift from practice: operators adapt, extend, and skip steps based on local context, and none of that signal flows back to the skill author. The skill stays frozen while the actual workflow evolves around it.

The harness `/harness:evolve` pattern closes this loop: snapshot what the skill produced, capture what actually landed in the commit or PR, compare the delta, and store the diff as a lesson. Accumulated lessons let skill authors see — concretely — where their skill diverges from how operators actually work.

## What needs doing (intent)

Add an evolution feedback loop to lamella:

1. Write an `/evolve-skill` command document that operators can invoke after completing a skill-guided task
2. The command reads: the skill that was active, the output the skill guided the operator to produce, and the actual changes committed (via `git diff HEAD~1` or a named commit range)
3. It produces a structured delta report: additions (operator added beyond the skill), removals (operator skipped from the skill), modifications (operator changed the skill's suggested approach)
4. It stores the delta in hyphae as a lesson under topic `skill-evolution/{skill-name}` with importance level `medium`
5. Write an `evolve-skill.md` skill document that describes the evolution workflow so operators know when and how to use `/evolve-skill`

## Delta Report Format

The `/evolve-skill` command produces a plain-text or Markdown delta report:

```
## Skill Evolution Delta — {skill-name} — {date}

### Additions (operator added, skill did not suggest)
- ...

### Removals (operator skipped, skill suggested)
- ...

### Modifications (operator changed the skill's approach)
- Original: ...
  Actual: ...

### Notes
(free-form operator annotation)
```

The delta is stored in hyphae verbatim as the memory content, with:
- `topic`: `skill-evolution/{skill-name}`
- `importance`: `medium`
- `project`: the owning repo of the task (not `lamella`)

## Scope

- **Allowed files:**
  - `lamella/resources/skills/evolve-skill.md` (new)
  - `lamella/resources/commands/evolve-skill.md` (new, or equivalent path per lamella's command doc convention)
- **Explicit non-goals:**
  - No automated skill rewriting based on deltas
  - No CI gate that blocks on evolution delta accumulation
  - No ML-based diff classification or pattern extraction
  - No source edits to hyphae — interaction is via the hyphae CLI or MCP tool only

---

### Step 1: Read the lamella skill and command seam

**Project:** `lamella/`
**Effort:** tiny (read-only)
**Depends on:** nothing

Before writing any documents, read:
- Two or three existing skill documents in `resources/skills/` — note required vs optional frontmatter fields, body structure, and activation conventions
- Any existing command documents (check `resources/commands/`, `commands/`, or equivalent) — note format differences from skill docs
- `Makefile` — does `make validate` or `make build-marketplace` process command documents separately?

Do not write any code or documents in this step.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] Skill document frontmatter fields identified
- [ ] Command document location and format identified (or absence confirmed)
- [ ] `make validate` baseline behavior understood

---

### Step 2: Write `evolve-skill.md` skill document

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 1

Create `resources/skills/evolve-skill.md`. The skill document must:
- Follow the frontmatter conventions identified in Step 1
- Describe when to invoke `/evolve-skill`: after completing any skill-guided task where the operator deviated from the skill's guidance
- Describe the activation trigger: operator runs `/evolve-skill` at the end of a task, with optional arguments for skill name and commit range
- Describe what the skill does: compares skill output against committed changes, produces a delta report, stores it in hyphae
- Include a short example showing a realistic delta report

The skill document is the operator-facing description of the capability. It does not contain executable code — it describes the workflow.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] `evolve-skill.md` present in `resources/skills/`
- [ ] Frontmatter matches required fields
- [ ] `make validate` still passes (no new MUST-level findings)

---

### Step 3: Write `/evolve-skill` command document

**Project:** `lamella/`
**Effort:** small
**Depends on:** Step 2

Create the `/evolve-skill` command document at the path identified in Step 1 (e.g., `resources/commands/evolve-skill.md`). If lamella does not have a `commands/` directory, create `resources/commands/evolve-skill.md` and note this in the step verification.

The command document must specify:

**Invocation:**
```
/evolve-skill [skill-name] [commit-range]
```

**Arguments:**
- `skill-name` (optional): the name of the skill that guided the task; if omitted, infer from the most recently invoked skill in the session
- `commit-range` (optional): git commit range to diff against; defaults to `HEAD~1..HEAD`

**Steps the command executes:**
1. Resolve the active skill document from `skill-name` or session context
2. Run `git diff {commit-range}` to get the actual changes
3. Compare the skill's guidance (step-by-step instructions) against the diff — identify additions, removals, and modifications
4. Render the delta report in the format specified above
5. Prompt the operator for optional free-form notes
6. Store the complete delta report in hyphae:
   ```
   hyphae memory store \
     --topic "skill-evolution/{skill-name}" \
     --importance medium \
     --project "{owning-repo}" \
     --content "{delta-report}"
   ```
7. Confirm storage with the hyphae memory ID returned

**Output:** the delta report rendered to the operator's terminal, plus confirmation of hyphae storage.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -10
```

**Checklist:**
- [ ] Command document present at the correct path
- [ ] All seven execution steps documented
- [ ] Delta report format matches the spec above
- [ ] Hyphae storage call documented with correct topic pattern
- [ ] `make validate` still passes

---

### Step 4: Verify hyphae CLI availability

**Project:** `lamella/` (read-only check)
**Effort:** tiny
**Depends on:** Step 3

Confirm that `hyphae` is available in the environment where operators run lamella commands:

```bash
hyphae --version 2>&1 || echo "hyphae not on PATH"
hyphae memory store --help 2>&1 | head -10
```

If `hyphae` is not on PATH, note the fallback: operators can use `mcp__hyphae__hyphae_memory_store` via the Claude Code MCP tool instead. Document this fallback in the command document (edit Step 3 output if needed).

#### Verification

```bash
hyphae --version 2>&1 || echo "hyphae not on PATH — MCP fallback applies"
```

**Checklist:**
- [ ] Hyphae availability confirmed or fallback documented
- [ ] Command document updated with fallback if needed

---

### Step 5: Full suite

```bash
cd lamella && make validate 2>&1 | tail -10
cd lamella && make build-marketplace 2>&1 | tail -10
```

**Checklist:**
- [ ] `make validate` passes with no new MUST-level findings
- [ ] `make build-marketplace` succeeds
- [ ] Both new documents (`evolve-skill.md` skill and command) are present

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `make validate` and `make build-marketplace` both pass
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

## Follow-on

- Add a `hyphae search --topic "skill-evolution/{skill-name}"` review workflow to the skill-authoring guide so authors know how to query accumulated deltas
- Add an aggregate `/evolve-skill:report` command that fetches all stored deltas for a skill and renders a trend summary
- Once enough deltas accumulate for a skill, feed them into a skill refinement session — a human reviews the top divergences and updates the skill document
- Wire `/evolve-skill` invocation as an optional post-task hook in lamella's hook manifest

## Context

Spawned from harness Wave 2 audit (2026-04-23) and wave2-ecosystem-synthesis Theme 9. The core insight from harness is that skill quality improves only when authors can see where operators diverged from the guidance. Without a feedback loop, skills drift from practice silently. The `/harness:evolve` pattern is the simplest possible implementation: diff what the skill said against what landed in git, store the delta in persistent memory, let authors query it. Lamella's implementation follows the same design — two documents (skill + command), hyphae for storage, no automated rewriting, human review only.
