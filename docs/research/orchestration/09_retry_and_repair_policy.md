# Retry and Repair Policy

Defines how failures are handled without creating infinite loops or hidden work.

## Retry Rules

- Max retries per task: 2 (configurable)
- Retry only for:
  - transient failures
  - incomplete outputs
- Do NOT retry:
  - contract mismatch
  - spec ambiguity

## Repair Rules

Send to repair (R) when:
- failure is localized
- task scope is small
- fix cost < replan cost

Do NOT repair when:
- task is ambiguous
- multiple dependencies are broken
- repeated failure detected

## Escalation Rules

Escalate to B2 when:
- TASK_TOO_LARGE
- CONTEXT_OVERFLOW

Escalate to B1 when:
- MISSING_DEPENDENCY
- INVALID_TASK_GRAPH

Escalate to A when:
- SPEC_AMBIGUITY
- conflicting constraints

## Loop Prevention

- Track attempt count in metadata
- If (retries + repairs) > threshold → escalate
- Prevent same agent from reprocessing identical task

## Confidence-Based Routing

- High confidence fail → escalate
- Low confidence fail → retry once
- Medium confidence → repair path

## Repair Constraints

- Repairs must be minimal and localized
- Must not expand scope
- Must emit structured diff of changes
