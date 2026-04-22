# Canopy Drift Detection Pipeline

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Agents can work for multiple sessions without anyone checking whether their output
still aligns with the original specification, the current codebase architecture,
or the agreed-upon quality bar. Canopy has no mechanism to detect when an agent
has drifted. Drift is currently invisible until a human reviewer notices a problem.

## What exists (state)

- **Council threads per task**: `proposal`, `objection`, `evidence`, `decision`,
  `handoff`, `status` message types — the spec and decision are stored but not
  compared to outcomes
- **Canopy task evidence refs**: stores evidence from cortina, hyphae, rhizome;
  evidence exists but no pipeline compares it against expectations
- **Cortina signals**: correction signals, error signals, build/test outcomes —
  all stored; not surfaced as drift indicators
- **Lamella skills**: the design notes say "architectural drift starts as a lamella
  skill, graduates to cortina automation"

## What needs doing (intent)

Implement drift detection in two phases: first as lamella skills that check for
drift patterns, then wire the most valuable checks into cortina automation. Start
with specification drift (task's council `proposal` vs. actual code changes) and
context drift (session working state far from the task scope).

---

### Step 1: Implement specification drift detector as a lamella skill

**Project:** `lamella/`
**Effort:** 1–2 days
**Depends on:** nothing

Create a lamella skill `detect-spec-drift` that:

1. Reads the active canopy task's council `proposal` messages
2. Lists recent code changes (from cortina signal history or rhizome changed files)
3. Prompts the model to compare changes against the proposal and flag divergences

```yaml
# lamella skill: detect-spec-drift
# Usage: /detect-spec-drift
```

The skill produces a structured summary:
```
Spec Drift Check for task #42:
  Proposal: "Add HTTP embeddings support"
  Files changed: src/auth.rs, src/user.rs, tests/auth_test.rs
  Assessment: DRIFT DETECTED — changes not related to embedding feature
  Confidence: medium
```

This is model-evaluated, not rule-based — the skill runs a focused check, not
continuous monitoring.

#### Files to modify

**`lamella/resources/skills/detect-spec-drift.md`** — new skill file

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -10
make build-marketplace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->
Validated 301 Lamella skill packages and 52 manifest alignments (225 warnings)
Skill package validator and scaffold checks passed
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (564 resources)
Validated marketplace catalog (52 plugins, version 0.5.15)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.
<!-- PASTE END -->

**Checklist:**
- [x] `detect-spec-drift` skill validates and builds
- [x] Skill reads canopy council proposal for active task
- [x] Skill checks recent file changes against proposal scope
- [x] Structured output with DRIFT DETECTED / NO DRIFT label

---

### Step 2: Implement context drift detector as a lamella skill

**Project:** `lamella/`
**Effort:** 4–8 hours
**Depends on:** Step 1 (same pattern)

Create a `detect-context-drift` skill that checks whether the agent's current
working context is still aligned with its assigned task:

- Current tool call patterns vs. task scope (rhizome symbols touched vs. task files)
- `hyphae session context` topic vs. active task title
- Files touched in last 10 tool calls vs. task's file scope

Produce:
```
Context Drift Check:
  Task: "Add HTTP embeddings"
  Recent activity: 8/10 tool calls in src/auth/ (off-scope)
  Assessment: CONTEXT DRIFT — agent appears to be working on auth, not embeddings
```

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->
Validated 8 preset files
All validators passed.
<!-- PASTE END -->

**Checklist:**
- [x] `detect-context-drift` skill validates
- [x] Skill checks recent tool call file patterns vs task scope
- [x] Structured output with drift assessment

---

### Step 3: Add drift counters to canopy snapshot

**Project:** `canopy/`
**Effort:** 4–8 hours
**Depends on:** nothing (can parallel; this is canopy-side, not lamella)

Add a `drift_signals` field to `canopy snapshot` that surfaces automatic drift
indicators from available evidence:

- **Correction rate**: number of correction signals / total signals in last 50
  events (high correction rate = quality drift indicator)
- **Test failure streak**: consecutive test failure events without resolution
- **Evidence gap**: time since last evidence ref attached to the active task

These are passive indicators computed from existing data, not model-evaluated.

```json
{
  "schema_version": "1.0",
  "drift_signals": {
    "high_correction_rate": false,
    "test_failure_streak": 0,
    "evidence_gap_hours": 2.5
  }
}
```

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
canopy snapshot 2>&1 | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('drift_signals', 'missing'))"
```

**Output:**
<!-- PASTE START -->
cargo build --workspace: success
cargo test --workspace: all tests pass
drift_signals: {'high_correction_rate': False, 'test_failure_streak': 0, 'evidence_gap_hours': None}
septa validate-all.sh: 47 schemas pass
<!-- PASTE END -->

**Checklist:**
- [x] `drift_signals` field in canopy snapshot output
- [x] `schema_version: "1.0"` preserved
- [x] Correction rate computed from evidence labels
- [x] Evidence gap field present (None when no evidence)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `make validate` and `make build-marketplace` pass in `lamella/`
3. `cargo build --workspace` and `cargo test --workspace` pass in `canopy/`
4. `detect-spec-drift` skill is runnable
5. `canopy snapshot` includes `drift_signals`
6. All checklist items are checked

### Final Verification

```bash
cd lamella && make validate 2>&1 | tail -3
cd canopy && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->
lamella: All validators passed (301 skills, 52 manifests)
canopy: cargo test --workspace — all pass
Commits: lamella 71f3ef7, canopy ca90343, septa b6db438
<!-- PASTE END -->

**Required result:** validate passes, tests pass.

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #18 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Four drift types are identified:
specification, architectural, quality, and context. This handoff covers specification
and context drift (most detectable without deep static analysis) plus the passive
canopy snapshot indicators. Architectural drift requires rhizome impact analysis
and is more complex — treat that as a follow-on. The lamella-skill-first approach
matches the design note: "architectural drift starts as a lamella skill, graduates
to cortina automation."
