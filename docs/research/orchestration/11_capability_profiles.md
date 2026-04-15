# Capability Profiles

This document defines capability-based routing for agents. Model size alone is not a sufficient assignment strategy.
Tasks should be routed based on the combination of:
- reasoning depth
- context handling
- determinism requirements
- formatting precision
- review quality
- tool use reliability
- latency sensitivity
- cost sensitivity

## Why Capability Profiles Exist

A medium model may outperform a larger model on:
- narrow review tasks
- structured classification
- bounded transformation work

A small model may be ideal for:
- templated rewriting
- schema normalization
- deterministic formatting
- unit-test scaffolding
- extraction from already-structured input

A large model is best reserved for:
- ambiguous planning
- dependency reasoning
- reconciliation across multiple constraints
- decomposition under uncertainty
- cross-cutting design decisions

Routing by size alone causes:
- overuse of expensive models
- underuse of cheap deterministic workers
- poor fit between task shape and model behavior

---

## Capability Dimensions

### 1. Planning
Ability to:
- infer dependencies
- decompose broad goals
- reconcile ambiguous requirements
- identify missing information

### 2. Compilation
Ability to:
- convert plans into strict task packets
- trim context safely
- preserve constraints
- produce machine-parseable artifacts

### 3. Execution
Ability to:
- implement bounded tasks
- follow instructions without drift
- produce required outputs consistently

### 4. Review
Ability to:
- compare result vs contract
- detect omission or scope violation
- classify failures accurately

### 5. Repair
Ability to:
- localize faults
- apply minimal fixes
- avoid broad re-implementation

### 6. Coordination
Ability to:
- manage child tasks
- aggregate results
- decide retry vs escalate

---

## Suggested Role-to-Capability Mapping

| Role | Primary Capabilities | Secondary Capabilities | Preferred Tier |
|------|----------------------|------------------------|----------------|
| B1 Strategic Planner | planning, dependency reasoning, ambiguity handling | coordination | large |
| B2 Task Compiler | compilation, context budgeting, schema emission | review | large or strong medium |
| V1 Decomposition Verifier | review, classification, constraint checking | compilation awareness | medium |
| C1 Medium Coordinator | coordination, aggregation, local review | limited replanning | medium |
| C2 Small Executor | execution, formatting, bounded transformation | none | small |
| V2 Output Verifier | review, contract comparison, failure typing | lightweight execution checks | medium |
| R Repair Agent | repair, localized reasoning, minimal change | review | medium or large |
| V3 Re-verifier | strict review, independence, final approval | none | medium |

---

## Capability Scoring Model

Each agent profile can be scored on a 1-5 scale:

```json
{
  "agent_profile_id": "string",
  "planning": 5,
  "compilation": 4,
  "execution": 3,
  "review": 4,
  "repair": 3,
  "coordination": 5,
  "tool_reliability": 4,
  "determinism": 3,
  "latency": 2,
  "cost_efficiency": 1
}
```

Routing decisions should use:
- minimum capability thresholds
- cost ceilings
- latency budgets
- risk class

---

## Task-to-Capability Matching

Instead of:
- assign all complex work to large
- assign all small work to small

Use:
- required capabilities
- risk level
- context complexity
- dependency count
- expected output type

Example:

```json
{
  "task_id": "2.4.1",
  "required_capabilities": {
    "execution": 4,
    "review": 2,
    "determinism": 4
  },
  "risk_level": "medium",
  "latency_budget_ms": 4000,
  "cost_ceiling": "low"
}
```

A routing engine should choose the cheapest agent that meets the thresholds.

---

## Anti-Patterns

### 1. Large model as universal worker
This creates cost blowups and central bottlenecks.

### 2. Small model used for ambiguous work
This causes hallucinated assumptions and silent drift.

### 3. Reviewer chosen by cost alone
Cheap reviewers that miss contract violations increase downstream repair load.

### 4. Repairer chosen without diff sensitivity
A repair agent that rewrites too broadly creates instability.

---

## Recommended Assignment Rules

### Use large models for:
- initial decomposition
- cross-branch reconciliation
- ambiguity resolution
- high-risk repairs
- conflict analysis

### Use medium models for:
- subtree coordination
- verification
- moderate repairs
- structured reviews
- bounded synthesis

### Use small models for:
- isolated implementation steps
- normalization
- extraction
- formatting
- repetitive deterministic subtasks

---

## Feedback Loop for Capability Calibration

Track:
- success rate by task type
- repair rate by assigned tier
- verification disagreement rate
- cost per successful completion
- latency per task class

Use this to:
- promote/demote agent profiles for certain roles
- re-tune routing rules
- identify misclassified capabilities

---

## Summary

Capability profiles prevent the system from confusing:
- model size with competence
- cheap with efficient
- large with always better

The routing strategy should optimize for:
- correctness first
- then bounded cost
- then latency
- then throughput
