# Three-Arm Eval Harness

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** skill content creation, CI skill sync (separate handoff #124), or production measurement infrastructure
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-three-arm-eval-harness.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** new `evals/` directory or extension of existing test/validation infrastructure
- **Reference seams:** caveman `evals/llm_run.py:64-101` and `evals/measure.py:48-106` for the three-arm design; existing lamella `make validate` for integration
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Any lamella skill evaluation that compares "with skill" against "no prompt" is measuring the wrong delta. The improvement observed may be due to the general effect of brevity or clarity instructions, not the skill content itself. Caveman demonstrates the correct design: a three-arm eval with baseline (no prompt), terse control ("Answer concisely"), and skill (terse prompt + SKILL.md). The meaningful delta is skill arm versus terse control arm, not skill arm versus baseline. Without this control arm, no lamella skill measurement is reliable.

## What exists (state)

- **`lamella`:** has `make validate` for structural validation but no eval harness for measuring skill effectiveness
- **caveman reference:** a working three-arm eval with offline measurement, committed snapshots, and correct delta calculation (arm 3 vs arm 2, not arm 3 vs arm 1)

## What needs doing (intent)

1. Define an eval framework that runs three arms for any lamella skill: baseline, terse control, and skill.
2. The terse control arm applies a generic brevity/clarity instruction without the skill content.
3. Measurement compares the skill arm against the terse control arm to isolate the skill's actual contribution.
4. Results are captured in a structured format (e.g., TSV or JSON) that can be committed as snapshots.

## Scope

- **Primary seam:** skill quality measurement with correct control-arm methodology
- **Allowed files:** `lamella/evals/` or equivalent
- **Explicit non-goals:**
  - Do not build production monitoring or dashboards in this handoff
  - Do not modify skill content based on eval results in this handoff
  - Do not require CI integration in this handoff (that can follow once the harness is proven)

---

### Step 1: Define eval schema and three-arm structure

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** nothing

Define the eval schema: what metrics are captured per arm (token count, response quality indicators, task completion), how the three arms are parameterized, and what the output format looks like. Create a runner that can execute all three arms for a given skill and task pair.

#### Verification

```bash
cd lamella && ls evals/ 2>&1
```

**Checklist:**
- [ ] Three arms are defined: baseline, terse control, skill
- [ ] Output schema captures per-arm metrics
- [ ] Runner accepts a skill path and task description

---

### Step 2: Implement delta calculation

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** Step 1

Implement the measurement logic that computes the correct delta: skill arm minus terse control arm. The baseline arm is recorded for context but the primary comparison is always against the control. Document why this is the correct methodology.

#### Verification

```bash
cd lamella && ls evals/ 2>&1
```

**Checklist:**
- [ ] Delta is skill vs control, not skill vs baseline
- [ ] Methodology is documented in the eval directory
- [ ] Results are written in a structured, committable format

---

### Step 3: Add snapshot support

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** Step 2

Add the ability to commit eval snapshots and compare against previous runs. This enables tracking skill quality over time and catching regressions when skill content changes.

#### Verification

```bash
cd lamella && ls evals/snapshots/ 2>/dev/null || echo "snapshot dir pending"
```

**Checklist:**
- [ ] Snapshots are saved in a structured, diffable format
- [ ] Comparison against previous snapshots is supported
- [ ] Eval can run offline without API calls (using cached responses)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-three-arm-eval-harness.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-three-arm-eval-harness.sh
```

## Context

Source: caveman ecosystem borrow audit (2026-04-14) section "Three-arm eval harness." See `.audit/external/audits/caveman-ecosystem-borrow-audit.md` for the reference eval design.

Related handoffs: #124 CI Single-Source Skill Sync (prerequisite — you cannot measure skill quality if the skill content has drifted). Also informed by autoresearch audit's "frozen evaluation boundary" pattern — the eval metric should be stable and agent-inaccessible.
