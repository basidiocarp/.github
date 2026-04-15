# Cost and Latency Model

This document defines how to reason about the operational cost and latency of the multi-agent pipeline.

## Goals

The system should optimize for:
1. correctness
2. bounded cost
3. predictable latency
4. sustainable throughput

Do not optimize purely for raw speed or lowest per-call cost. A cheap but failure-prone path is often more expensive end-to-end.

---

## Sources of Cost

### 1. Planning Cost
- large-model reasoning in B1
- cross-task reconciliation
- ambiguity handling

### 2. Compilation Cost
- task packet generation
- context trimming
- schema generation
- dependency packaging

### 3. Execution Cost
- medium coordinator overhead
- small executor fan-out
- repeated subtasks
- retries

### 4. Verification Cost
- decomposition review
- output verification
- re-verification after repair

### 5. Repair Cost
- localized fixes
- re-checking repaired outputs
- repair loops

### 6. Coordination Cost
- queueing
- scheduling
- state tracking
- aggregation overhead

---

## Sources of Latency

### 1. Queue Wait Time
Time spent waiting for an available agent or compute slot.

### 2. Critical Path Length
Longest dependency chain in the DAG.

### 3. Verification Gates
Blocking checks on high-risk work.

### 4. Retry / Repair Loops
Repeated execution increases tail latency.

### 5. Over-Decomposition
Too many tiny tasks increase coordination delays.

---

## Simple Cost Model

Per task:

```text
Total Task Cost =
  planning_cost
+ compilation_cost
+ execution_cost
+ verification_cost
+ repair_cost
+ coordination_cost
```

For a workflow:

```text
Workflow Cost =
  Σ(task costs across all nodes)
+ queue overhead
+ storage/logging overhead
```

A useful derived metric:

```text
Cost Per Successful Task = Total Cost / Number of Tasks Completed Without Human Escalation
```

---

## Simple Latency Model

Per task:

```text
Task Latency =
  queue_wait
+ assignment_time
+ execution_time
+ verification_time
+ repair_time_if_any
```

For a DAG:

```text
Workflow Latency ≈ Critical Path Latency + Coordination Overhead
```

Parallel branches improve throughput but do not reduce the critical path unless dependencies are removed.

---

## What Actually Drives Cost Up

### 1. Large-model overuse
Using large models for work that could be done by medium or small agents.

### 2. Bad decomposition
Poor task boundaries create:
- retries
- rework
- repair load
- duplicate work

### 3. Weak contracts
Ambiguous outputs make verification expensive.

### 4. Excessive verification
Auditing everything equally adds tax without proportional value.

### 5. Hidden repair
Silent cleanup masks true failure rates and distorts optimization.

---

## Optimization Levers

### 1. Improve decomposition quality
Best leverage point. Good B1/B2 outputs reduce downstream waste everywhere.

### 2. Push cheap checks earlier
Reject bad task packets before execution.

### 3. Use progressive assurance
Apply strict verification only where justified by risk.

### 4. Route by capability, not size
Assign the cheapest agent that can meet the task requirements reliably.

### 5. Limit retries
Repeated low-value retries create cost explosions.

### 6. Bound repair
Repair should be local and rare, not the default completion path.

---

## Recommended Metrics

Track these at minimum:

| Metric | Why it matters |
|--------|----------------|
| cost per completed task | baseline efficiency |
| cost per task class | identifies expensive work shapes |
| p50 / p95 / p99 latency | reveals queueing and tail issues |
| retry rate | indicates weak execution or poor tasking |
| repair rate | indicates contract or execution instability |
| escalation rate | indicates upstream ambiguity |
| verification failure rate | indicates decomposition or output quality problems |
| cost by agent tier | catches large-model overuse |

---

## Budgeting Model

Each task packet should include:

```json
{
  "task_id": "string",
  "risk_level": "low|medium|high",
  "cost_ceiling": "low|medium|high",
  "latency_budget_ms": 5000,
  "max_retries": 2,
  "repair_allowed": true
}
```

The scheduler should reject or downgrade plans that exceed:
- workflow budget
- latency SLO
- tier utilization caps

---

## SLO-Oriented Design

Example service targets:

- p95 task latency under 8 seconds for low-risk bounded tasks
- p99 verification latency under 5 seconds
- less than 10 percent of tasks entering repair
- less than 2 percent human escalation on well-formed specs

These numbers are examples. They should be tuned from actual workload data.

---

## Tradeoffs

### Faster
- less verification
- larger task packets
- more parallelism

### Safer
- more verification
- smaller task packets
- tighter contracts

### Cheaper
- smaller/medium agents
- lower audit intensity
- reduced repair budget

The right operating point depends on:
- task risk
- user expectations
- failure cost
- throughput requirements

---

## Summary

The system should optimize end-to-end economics, not per-call cheapness.

The main rule:
> a call that appears cheap but increases retries, repair, or escalation is not actually cheap.

Good decomposition, strong contracts, and selective verification have the highest leverage on both cost and latency.
