# Token Efficiency Skill

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** implementing the eval harness (that is #125), building the hook runner in cortina, or changing session-level token accounting in annulus
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-token-efficiency-skill.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** `lamella/resources/skills/token-efficiency.md` for the skill content; `lamella/docs/` for any supporting documentation
- **Reference seams:** caveman compression persona and SessionStart hook activation pattern; ECC `strategic-compact` skill as an adjacent but distinct pattern
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Agent sessions waste tokens through verbose explanations, unnecessary summaries, and repeated context recitation. Caveman demonstrates that a compression persona injected at SessionStart can measurably reduce token usage without degrading task quality. ECC's `strategic-compact` skill addresses when to compact context but not how to reduce token generation in the first place. Lamella has no skill that addresses token efficiency as a system-prompt injection. Without this, every basidiocarp session runs at default verbosity regardless of context budget or task type.

## What exists (state)

- **`lamella`:** has `make validate` and `make build-marketplace`; no token efficiency skill exists
- **caveman reference:** a compression persona injected at SessionStart that reduces unnecessary explanations, encourages direct action over narration, and has been measured with a three-arm eval harness
- **ECC reference:** `strategic-compact` skill covering compaction timing (adjacent concern, not the same as generation verbosity)

## What needs doing (intent)

1. Author a `token-efficiency` skill for lamella following the canonical skill authoring convention (#130).
2. The skill injects conciseness and compression instructions at SessionStart: reduce unnecessary explanations and summaries, encourage direct action over narration, omit filler and throat-clearing phrases.
3. Adapt the skill content for the basidiocarp ecosystem — reference basidiocarp tools and conventions, not caveman-specific names.
4. Define eval criteria for the three-arm harness (#125) so the skill's contribution can be measured independently of general brevity instructions.

## Scope

- **Primary seam:** skill content authoring with SessionStart injection guidance
- **Allowed files:** `lamella/resources/skills/token-efficiency.md` and any supporting docs
- **Explicit non-goals:**
  - Do not implement the eval harness itself (that is #125)
  - Do not build hook runner logic in cortina
  - Do not change token accounting in annulus

---

### Step 1: Author the token-efficiency skill

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** #130 Skill Authoring Convention (canonical format must be defined first)

Create `lamella/resources/skills/token-efficiency.md` following the format defined in #130. Required sections:

- **YAML frontmatter:** `name: token-efficiency`, `description`, `origin: caveman compression persona (adapted)`
- **When to Activate:** SessionStart injection; activate for all sessions unless explicitly disabled
- **How It Works:** numbered phases — (1) suppress verbose preambles and summaries, (2) prefer direct action statements over narration of intent, (3) omit filler phrases, (4) keep code blocks and file paths but cut prose scaffolding
- **Operating Contract:** not required (this is not an autonomous long-running skill)
- **Handoff Pointers:** #125 Three-Arm Eval Harness (for measurement), #134 Strategic Compact Skill (adjacent compaction-timing concern)

Adapt all references to basidiocarp tools: reference hyphae for memory, cortina for hook events, annulus for context metrics. Do not use caveman-specific tool names.

#### Verification

```bash
cd lamella && test -f resources/skills/token-efficiency.md && echo "skill file exists"
cd lamella && grep -q "When to Activate" resources/skills/token-efficiency.md && echo "required section present"
```

**Checklist:**
- [ ] Skill file exists at `lamella/resources/skills/token-efficiency.md`
- [ ] YAML frontmatter includes `name`, `description`, `origin`
- [ ] "When to Activate" section specifies SessionStart
- [ ] "How It Works" section has numbered phases
- [ ] "Handoff Pointers" section references #125 and #134
- [ ] No caveman-specific tool names remain in the content

---

### Step 2: Define SessionStart hook integration guidance

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Step 1

Add a prose section to the skill (or a companion note in the skill's frontmatter comment) that explains how the skill integrates with cortina's SessionStart event. The guidance must describe: what the hook injects, where in the system prompt the injection lands, and how to disable the skill for a session where verbosity is desired.

#### Verification

```bash
cd lamella && grep -q "SessionStart\|cortina\|hook" resources/skills/token-efficiency.md && echo "hook guidance present"
```

**Checklist:**
- [ ] Hook integration section explains SessionStart injection
- [ ] Cortina is referenced as the hook runner
- [ ] Disable/opt-out mechanism is described

---

### Step 3: Define eval criteria for the three-arm harness

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Step 1

Add an `## Eval Criteria` section to the skill file (or a companion `token-efficiency.eval.md`) that defines the measurement dimensions for the three-arm harness (#125):

- **Baseline arm:** no prompt injection
- **Terse control arm:** generic brevity instruction without skill content
- **Skill arm:** terse instruction plus the token-efficiency skill

Define the metrics: token count per response, prose-to-action ratio (subjective), and task completion rate. The primary delta is skill arm versus terse control arm.

#### Verification

```bash
cd lamella && grep -q "eval\|Eval\|baseline\|terse" resources/skills/token-efficiency.md 2>/dev/null || \
  test -f resources/skills/token-efficiency.eval.md && echo "eval criteria present"
```

**Checklist:**
- [ ] Three arms are defined: baseline, terse control, skill
- [ ] Metrics are specified (at minimum: token count, task completion)
- [ ] Primary delta is clearly stated as skill vs terse control (not skill vs baseline)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-token-efficiency-skill.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-token-efficiency-skill.sh
```

## Context

Source: caveman ecosystem borrow audit (2026-04-14) section "Compression persona / SessionStart hook activation" and ECC audit section "strategic-compact as adjacent pattern." See `.audit/external/audits/` for reference skill content.

Related handoffs: #130 Skill Authoring Convention (prerequisite — canonical format must exist before authoring this skill), #125 Three-Arm Eval Harness (measurement infrastructure for validating the skill's contribution), #134 Strategic Compact Skill (adjacent compaction-timing concern, not the same problem).
