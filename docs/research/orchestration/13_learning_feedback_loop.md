# Learning Feedback Loop

This document defines how the system should improve over time using structured outcomes from execution, verification, repair, and escalation.

## Purpose

Without a feedback loop, the system repeats the same decomposition and routing mistakes forever.
The goal is to use failures as training signals for:
- better planning
- better task compilation
- better routing
- better verification policies

This is not about model fine-tuning only. It is primarily about improving orchestration policy.

---

## Core Principle

Every failure or repair should answer:
- what failed
- where it failed
- why it failed
- whether the failure was preventable upstream

If the system only records “task failed,” it learns almost nothing.

---

## Feedback Sources

### 1. Decomposition Verification
Signals that B1/B2 produced:
- oversized tasks
- missing dependencies
- overlapping scopes
- ambiguous contracts

### 2. Execution Results
Signals that C1/C2:
- could not complete the work
- drifted out of scope
- lacked required context
- produced low-confidence results

### 3. Output Verification
Signals that:
- acceptance criteria were insufficient
- execution quality was poor
- task packets were underspecified

### 4. Repair Logs
Signals that:
- certain task classes are unstable
- certain agent tiers are misassigned
- repeated localized defects are predictable

### 5. Human Escalations
Strongest signal that:
- spec clarity is insufficient
- decomposition policy is wrong
- automation limits were exceeded

---

## Feedback Record Schema

```json
{
  "task_id": "string",
  "task_class": "string",
  "assigned_role": "string",
  "assigned_tier": "small|medium|large",
  "outcome": "success|retry|repair|escalate|fail",
  "failure_type": "ENUM|null",
  "root_cause_layer": "A|B1|B2|C1|C2|V1|V2|R|unknown",
  "repair_performed": true,
  "attempt_count": 2,
  "latency_ms": 3400,
  "cost_bucket": "low|medium|high",
  "confidence": 0.62,
  "notes": "string"
}
```

---

## What the System Should Learn

### 1. Better decomposition boundaries
If a task class frequently:
- exceeds context budget
- requires repair
- retries twice
then B2 should split it differently next time.

### 2. Better capability routing
If small executors repeatedly fail on a task class:
- upgrade routing to medium
If large agents are succeeding on work that medium agents could do:
- downgrade routing to reduce cost

### 3. Better acceptance contracts
If verification keeps catching the same omission:
- strengthen the task template
- require more evidence
- add explicit completion checks

### 4. Better escalation heuristics
If repair rarely succeeds on a failure type:
- skip repair and escalate earlier

### 5. Better spec guidance to humans
If A frequently produces ambiguous inputs in a category:
- provide spec templates
- require missing fields
- improve authoring guidance

---

## Aggregation Windows

Analyze outcomes at multiple levels:

### Short window
- recent 100 tasks
- catches regressions quickly

### Medium window
- recent 1,000 tasks
- stabilizes trend detection

### Long window
- historical by task class
- informs policy changes

---

## Policy Update Examples

### Example 1
Observed:
- task class `code_refactor_small`
- small tier repair rate 28 percent
- medium tier repair rate 6 percent

Action:
- route this class to medium by default

### Example 2
Observed:
- verification repeatedly flags missing edge-case tests

Action:
- add edge-case test requirement to acceptance criteria template

### Example 3
Observed:
- tasks over 3 dependencies have high retry rate

Action:
- B2 splits them into smaller dependency groups

---

## Guardrails

### 1. Do not learn from silent repair
If repair is not explicitly recorded, the system will optimize on fake success.

### 2. Do not overfit to recent noise
Require statistically meaningful trends before changing global policy.

### 3. Separate task-class issues from agent-specific outages
A temporary bad model day should not permanently rewrite routing policy.

### 4. Keep a rollback path for orchestration changes
Policy updates can make the system worse. Roll them back safely.

---

## Recommended Metrics

Track by:
- task class
- agent tier
- role
- risk level
- spec source/template

Important metrics:
- repair rate
- retry rate
- escalation rate
- verification disagreement rate
- latency drift
- cost drift
- first-pass success rate

---

## Closed-Loop Improvement Process

1. collect structured outcome records
2. aggregate by task class and routing path
3. identify repeated failure patterns
4. propose routing/template/policy updates
5. test on a limited slice
6. compare against baseline
7. promote or roll back

This should be treated like any other production control loop.

---

## Summary

A strong feedback loop turns the architecture from:
- static workflow orchestration

into:
- adaptive orchestration with measurable improvement

The highest-value learning targets are:
- decomposition quality
- routing fit
- contract quality
- escalation policy
