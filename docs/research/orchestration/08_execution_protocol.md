# Execution Protocol

Defines the runtime behavior, state machine, and message formats for tasks moving through the system.

## Task Lifecycle States

- CREATED
- COMPILED
- VERIFIED_DECOMP
- READY
- ASSIGNED
- EXECUTING
- COMPLETED
- VERIFIED_OUTPUT
- REPAIR_QUEUED
- REPAIRING
- REPAIRED
- VERIFIED_REPAIR
- FAILED
- ESCALATED
- DONE

### State Transitions (simplified)

CREATED → COMPILED → VERIFIED_DECOMP → READY → ASSIGNED → EXECUTING → COMPLETED → VERIFIED_OUTPUT → DONE

Failure paths:
- VERIFIED_DECOMP (fail) → ESCALATED (to B2/B1)
- EXECUTING (fail) → RETRY or REPAIR_QUEUED
- VERIFIED_OUTPUT (fail) → REPAIR_QUEUED or ESCALATED
- REPAIRED → VERIFIED_REPAIR → DONE or ESCALATED

## Message Envelope

All inter-agent messages use a common envelope:

```json
{
  "message_id": "uuid",
  "timestamp": "iso8601",
  "task_id": "string",
  "from_role": "string",
  "to_role": "string",
  "state": "string",
  "payload": {},
  "metadata": {
    "attempt": 1,
    "priority": "low|medium|high",
    "risk_level": "low|medium|high",
    "trace_id": "string"
  }
}
```

## Payload Types

### Task Packet (B2 → C1/C2)
- Full contract (see contracts.md)
- Context bundle (trimmed)
- Dependency references

### Execution Result (C → C1/V2)
```json
{
  "task_id": "string",
  "status": "success|partial|fail",
  "artifacts": ["..."],
  "evidence": ["tests, logs, diffs"],
  "notes": "string",
  "confidence": 0.0
}
```

### Verification Report (V*)
```json
{
  "task_id": "string",
  "result": "pass|fail",
  "violations": ["..."],
  "failure_type": "ENUM",
  "confidence": 0.0
}
```

### Repair Report (R)
```json
{
  "task_id": "string",
  "changes": ["..."],
  "reason": "string",
  "confidence": 0.0
}
```

## Concurrency Model

- Tasks are organized as a DAG (directed acyclic graph)
- Nodes can execute when dependencies are DONE
- C1 may execute independent branches in parallel
- Limit concurrency per model tier to avoid saturation

## Backpressure

- Queue-based handoffs
- Rate limits per layer
- Priority queues for high-risk/high-value tasks
