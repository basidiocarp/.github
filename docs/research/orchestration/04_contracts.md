# Task Contract Schema

```json
{
  "task_id": "string",
  "parent_task_id": "string",
  "goal": "string",
  "inputs": ["..."],
  "constraints": ["..."],
  "dependencies": ["..."],
  "expected_output": "string/schema",
  "acceptance_criteria": ["..."],
  "assigned_model_tier": "small|medium|large",
  "capability_required": ["..."],
  "context_budget": "token limit",
  "escalation_conditions": ["..."]
}
```

## Notes
- Must be machine-parseable
- Avoid freeform outputs
- Define strict completion criteria
