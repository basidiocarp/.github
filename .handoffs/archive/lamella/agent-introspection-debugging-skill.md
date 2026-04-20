# Agent Introspection Debugging Skill

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** implementing automatic failure detection in cortina or volva, building runtime enforcement, or changing any infrastructure tool
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-agent-introspection-debugging-skill.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** `lamella/resources/skills/agent-introspection-debugging.md` for the skill content
- **Reference seams:** ECC `agent-introspection-debugging` skill with four-phase self-repair loop (Failure Capture → Root-Cause Diagnosis → Contained Recovery → Introspection Report) and failure-pattern classification table
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

When an agent gets stuck — in a loop, hitting context overflow, rate-limited, or applying stale diffs — it typically either fails silently or retries the same failing action. ECC's `agent-introspection-debugging` skill provides a structured four-phase self-repair loop and a failure-pattern table that classifies common stuck states. Lamella has no equivalent meta-level self-management skill. Without it, basidiocarp agents have no systematic protocol for diagnosing and recovering from stuck states, and no structured format for reporting what went wrong so the session history is useful after recovery.

## What exists (state)

- **`lamella`:** has `make validate` and `make build-marketplace`; no agent introspection or self-repair skill exists
- **ECC reference:** `agent-introspection-debugging` skill with a failure-pattern classification table (loop detection, context overflow, 429 rate limit, stale diff, permission denied) and a four-phase recovery protocol (Failure Capture → Root-Cause Diagnosis → Contained Recovery → Introspection Report)
- **Ecosystem tools available:** annulus for context usage percentage, cortina for lifecycle signals, hyphae for session memory

## What needs doing (intent)

1. Author an `agent-introspection-debugging` skill for lamella following the canonical skill authoring convention (#130).
2. The skill provides a failure-pattern classification table and a four-phase recovery protocol.
3. Adapt for basidiocarp: reference annulus for context percentage, cortina for lifecycle signals, hyphae for session memory and prior error patterns.
4. Define a structured introspection report format that agents produce at the end of each recovery attempt.

## Scope

- **Primary seam:** skill content authoring with failure-pattern table and recovery protocol
- **Allowed files:** `lamella/resources/skills/agent-introspection-debugging.md` and any supporting docs
- **Explicit non-goals:**
  - Do not implement automatic failure detection in cortina or volva
  - The skill is agent-side guidance, not runtime enforcement
  - Do not change hyphae's storage schema to accommodate introspection reports

---

### Step 1: Author the agent-introspection-debugging skill

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** #130 Skill Authoring Convention (canonical format must be defined first)

Create `lamella/resources/skills/agent-introspection-debugging.md` following the format defined in #130. Required sections:

- **YAML frontmatter:** `name: agent-introspection-debugging`, `description`, `origin: ECC agent-introspection-debugging (adapted)`
- **When to Activate:** activate when the agent detects it is stuck — three or more retries of the same action, unexpected silence, or an error pattern repeating
- **How It Works:** four phases — (1) Failure Capture: record the exact error, action, and state; (2) Root-Cause Diagnosis: classify against the failure-pattern table; (3) Contained Recovery: apply the recovery action for the matched pattern; (4) Introspection Report: emit a structured summary before resuming
- **Operating Contract:** this is an autonomous self-repair skill; include NEVER STOP declaration, loop invariants (must produce a report before resuming), and the escalation path when all recovery actions are exhausted
- **Handoff Pointers:** #130 Skill Authoring Convention, #134 Strategic Compact Skill (context overflow recovery involves compaction)

#### Verification

```bash
cd lamella && test -f resources/skills/agent-introspection-debugging.md && echo "skill file exists"
cd lamella && grep -q "When to Activate" resources/skills/agent-introspection-debugging.md && echo "required section present"
cd lamella && grep -q "Operating Contract" resources/skills/agent-introspection-debugging.md && echo "operating contract present"
```

**Checklist:**
- [ ] Skill file exists at `lamella/resources/skills/agent-introspection-debugging.md`
- [ ] YAML frontmatter includes `name`, `description`, `origin`
- [ ] "When to Activate" section specifies stuck-detection trigger conditions
- [ ] "How It Works" section has all four phases
- [ ] "Operating Contract" section is present (required — this is an autonomous skill)
- [ ] Operating Contract includes loop invariants and NEVER STOP declaration
- [ ] "Handoff Pointers" section references #134

---

### Step 2: Define the failure-pattern classification table

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Step 1

Add the failure-pattern table to the skill. The table must classify at minimum these five patterns and specify the recovery action for each:

| Pattern | Detection signal | Recovery action |
|---|---|---|
| Loop detection | Same action repeated 3+ times | Break loop, emit capture, diagnose |
| Context overflow | annulus context % > threshold | Compact per strategic-compact decision table |
| 429 rate limit | HTTP 429 or rate-limit error text | Exponential back-off, emit capture |
| Stale diff | Patch apply failure citing line mismatch | Re-read affected file, regenerate diff |
| Permission denied | FS or API permission error | Check scope, surface to user, do not retry |

Adapt detection signals to reference basidiocarp tools: annulus for context percentage, cortina lifecycle signals where relevant.

#### Verification

```bash
cd lamella && grep -q "Loop detection\|loop\|rate.limit\|stale.diff\|permission" resources/skills/agent-introspection-debugging.md && echo "failure table present"
```

**Checklist:**
- [ ] All five failure patterns are present in the table
- [ ] Each pattern has a detection signal and a recovery action
- [ ] Context overflow row references annulus for the percentage metric
- [ ] Stale diff row specifies re-reading the affected file before regenerating

---

### Step 3: Define the introspection report format

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Steps 1 and 2

Add an "Introspection Report Format" section to the skill that defines the structured output an agent must emit after every recovery attempt. The report must include:

- **Failure pattern matched:** which table entry was matched
- **Detection signal observed:** the exact error or repeated action
- **Recovery action taken:** what the agent did
- **Outcome:** recovered / escalated / timed out
- **Context snapshot:** annulus context % at time of failure, message count
- **Stored in hyphae:** yes/no, with the hyphae topic key if stored

The format should be expressible as a Markdown block so it is readable in session history and storable in hyphae.

#### Verification

```bash
cd lamella && grep -q "Introspection Report\|report format\|hyphae" resources/skills/agent-introspection-debugging.md && echo "report format present"
```

**Checklist:**
- [ ] Introspection Report Format section exists
- [ ] Report includes failure pattern, detection signal, recovery action, and outcome
- [ ] Context snapshot fields (annulus %, message count) are included
- [ ] Hyphae storage guidance is included
- [ ] Report format is valid Markdown

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-agent-introspection-debugging-skill.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-agent-introspection-debugging-skill.sh
```

## Context

Source: ECC ecosystem borrow audit (2026-04-14) section "agent-introspection-debugging skill." See `.audit/external/audits/` for the reference skill, failure-pattern table, and four-phase protocol. The failure-pattern table should be extended over time as new stuck states are observed in basidiocarp sessions — treat the five initial patterns as the minimum viable set.

Related handoffs: #130 Skill Authoring Convention (prerequisite — canonical format must exist before authoring this skill), #134 Strategic Compact Skill (context overflow recovery in Phase 3 invokes the compact decision table), #125 Three-Arm Eval Harness (can measure recovery effectiveness once the harness exists).
