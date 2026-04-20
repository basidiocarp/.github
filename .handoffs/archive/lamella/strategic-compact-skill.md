# Strategic Compact Skill

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** implementing the compact hook in cortina, building context tracking in annulus, or changing compaction infrastructure
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-strategic-compact-skill.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** `lamella/resources/skills/strategic-compact.md` for the skill content
- **Reference seams:** ECC `strategic-compact` skill with context-usage-percentage decision table, message count heuristics, and "compact now" vs "wait" recommendations
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Every long-running agent session faces the question "when should I compact context?" Most agents either compact too early — losing useful context that would have been needed — or too late — hitting context overflow and losing work. ECC's `strategic-compact` skill provides a concrete decision table based on context usage percentage, message count, and active file count, giving agents a deterministic rule set rather than guessing. Lamella has no equivalent. Without it, basidiocarp agents must rely on intuition or hit overflow before taking action.

## What exists (state)

- **`lamella`:** has `make validate` and `make build-marketplace`; no strategic compact skill exists
- **ECC reference:** a `strategic-compact` skill with a decision table covering context usage thresholds, message count heuristics, active file count considerations, and explicit "compact now" vs "wait" recommendations
- **Cortina:** provides lifecycle signals including a PreCompact event that this skill's guidance hooks into

## What needs doing (intent)

1. Author a `strategic-compact` skill for lamella following the canonical skill authoring convention (#130).
2. The skill provides compaction-timing guidance as a system-prompt injection with a concrete decision table.
3. Adapt the decision table for the basidiocarp ecosystem: reference annulus for context usage metrics, cortina for the PreCompact hook event.
4. Include explicit "compact now" vs "wait" recommendations with threshold values for each decision axis.

## Scope

- **Primary seam:** skill content authoring with compaction-timing decision table
- **Allowed files:** `lamella/resources/skills/strategic-compact.md` and any supporting docs
- **Explicit non-goals:**
  - Do not implement the compact hook in cortina (that is #66)
  - Do not build context usage tracking in annulus
  - Do not change the compaction mechanism itself

---

### Step 1: Author the strategic-compact skill

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** #130 Skill Authoring Convention (canonical format must be defined first)

Create `lamella/resources/skills/strategic-compact.md` following the format defined in #130. Required sections:

- **YAML frontmatter:** `name: strategic-compact`, `description`, `origin: ECC strategic-compact (adapted)`
- **When to Activate:** inject at SessionStart; also consult before any explicit compact decision
- **How It Works:** decision table with three axes — (1) context usage percentage thresholds, (2) message count heuristics, (3) active file count; each combination maps to "compact now," "compact soon," or "wait"
- **Operating Contract:** not required (this is not an autonomous long-running skill)
- **Handoff Pointers:** #66 Cortina PreCompact Hook, #133 Token Efficiency Skill (adjacent token-reduction concern)

Adapt all references to basidiocarp tools: annulus for context usage percentage, cortina for the PreCompact lifecycle event. Do not use ECC-specific tool names.

#### Verification

```bash
cd lamella && test -f resources/skills/strategic-compact.md && echo "skill file exists"
cd lamella && grep -q "When to Activate" resources/skills/strategic-compact.md && echo "required section present"
```

**Checklist:**
- [ ] Skill file exists at `lamella/resources/skills/strategic-compact.md`
- [ ] YAML frontmatter includes `name`, `description`, `origin`
- [ ] "When to Activate" section is present
- [ ] "How It Works" section contains a decision table with threshold values
- [ ] "Handoff Pointers" section references #66 and #133
- [ ] No ECC-specific tool names remain in the content

---

### Step 2: Define the decision table with ecosystem-specific references

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Step 1

Expand the decision table in the skill to include concrete threshold values and ecosystem-specific references:

- **Context usage thresholds:** define "compact now" (e.g., >80%), "compact soon" (e.g., 60–80%), and "wait" (<60%) bands
- **Message count heuristics:** define message count ranges that trigger escalation independent of context usage
- **Active file count:** define a threshold above which compact-now is recommended regardless of usage percentage
- **Annulus integration:** specify which annulus metric or field provides the context usage percentage
- **Cortina integration:** specify that the PreCompact hook event is the correct integration point for automated compact decisions

#### Verification

```bash
cd lamella && grep -q "80\|60\|threshold\|annulus\|cortina" resources/skills/strategic-compact.md && echo "thresholds and ecosystem refs present"
```

**Checklist:**
- [ ] "Compact now," "compact soon," and "wait" bands have concrete percentage values
- [ ] Message count heuristic has a concrete threshold value
- [ ] Active file count threshold is defined
- [ ] Annulus is referenced as the source of context usage metrics
- [ ] Cortina PreCompact event is named as the integration point

---

### Step 3: Add hook integration guidance for cortina's PreCompact event

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Steps 1 and 2

Add a section to the skill that explains how the decision table integrates with cortina's PreCompact lifecycle event. The guidance must describe: when cortina fires PreCompact, how an agent should consult the decision table at that point, and what action to take if the table recommends "wait" but cortina has already fired the event.

#### Verification

```bash
cd lamella && grep -q "PreCompact\|pre-compact\|pre_compact" resources/skills/strategic-compact.md && echo "hook guidance present"
```

**Checklist:**
- [ ] PreCompact event is described in the hook integration section
- [ ] Agent behavior when "wait" conflicts with a PreCompact signal is addressed
- [ ] The section is clearly labeled as hook integration guidance

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-strategic-compact-skill.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-strategic-compact-skill.sh
```

## Context

Source: ECC ecosystem borrow audit (2026-04-14) section "strategic-compact skill." See `.audit/external/audits/` for the reference skill and decision table. The threshold values in the decision table should be treated as calibration starting points and updated based on observed session data once the three-arm eval harness (#125) is available.

Related handoffs: #130 Skill Authoring Convention (prerequisite — canonical format must exist before authoring this skill), #66 Cortina PreCompact Hook (the runtime integration point for automated compact decisions), #133 Token Efficiency Skill (adjacent concern — reduces token generation rather than managing compaction timing).
