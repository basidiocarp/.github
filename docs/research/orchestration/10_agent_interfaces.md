# Agent Interfaces

Defines input/output contracts and allowed behavior per role.

## A — Human Spec Authority

### Input
- None (external)

### Output
- Spec document
- Constraints
- Acceptance criteria

---

## B1 — Strategic Planner

### Input
- Spec from A

### Output
- Task graph (nodes + dependencies)

### Constraints
- Must not generate executable artifacts
- Must define complete dependency graph

---

## B2 — Task Compiler

### Input
- Task graph

### Output
- Task packets (contracts)

### Constraints
- Must enforce context budgets
- Must assign model tier

---

## V1 — Decomposition Verifier

### Input
- Task packets

### Output
- Verification report

### Constraints
- No modification of tasks
- Must classify failures

---

## C1 — Medium Coordinator

### Input
- Task packets

### Output
- Aggregated results
- Subtask dispatches

### Constraints
- May decompose further within limits
- Must not expand scope beyond parent

---

## C2 — Small Executor

### Input
- Narrow task packet

### Output
- Execution result

### Constraints
- Stateless
- No task expansion
- Must escalate on ambiguity

---

## V2 — Output Verifier

### Input
- Execution result

### Output
- Verification report

### Constraints
- No repair actions
- Strict contract validation

---

## R — Repair Agent

### Input
- Failed task + artifacts

### Output
- Repair report

### Constraints
- Must not self-verify
- Must not expand scope

---

## V3 — Re-verifier

### Input
- Repaired output

### Output
- Final verification report

### Constraints
- Independent from repair agent
- Final authority before DONE
