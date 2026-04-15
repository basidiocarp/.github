# Message Schemas

## Base Envelope

```json
{
  "message_id": "uuid",
  "task_id": "string",
  "from": "role",
  "to": "role",
  "timestamp": "iso8601",
  "state": "string",
  "payload": {},
  "metadata": {
    "attempt": 1,
    "priority": "low|medium|high",
    "risk": "low|medium|high"
  }
}
```

---

## Task Packet

```json
{
  "task_id": "string",
  "goal": "string",
  "inputs": [],
  "constraints": [],
  "expected_output": {},
  "acceptance_criteria": [],
  "tier": "small|medium|large"
}
```

---

## Execution Result

```json
{
  "task_id": "string",
  "status": "success|fail|partial",
  "artifacts": [],
  "confidence": 0.0
}
```

---

## Verification Report

```json
{
  "task_id": "string",
  "result": "pass|fail",
  "failure_type": "ENUM",
  "confidence": 0.0
}
```

---

## Repair Report

```json
{
  "task_id": "string",
  "changes": [],
  "reason": "string"
}
```
