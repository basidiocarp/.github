# Failure Routing

## Failure Types
- SPEC_AMBIGUITY
- TASK_TOO_LARGE
- MISSING_DEPENDENCY
- EXECUTION_INCOMPLETE
- SCOPE_VIOLATION
- CONTRACT_MISMATCH

## Routing Table

| Failure | Action |
|--------|--------|
| SPEC_AMBIGUITY | escalate to B1/A |
| TASK_TOO_LARGE | recompile via B2 |
| MISSING_DEPENDENCY | fix in B1 |
| EXECUTION_INCOMPLETE | retry in C |
| SCOPE_VIOLATION | fail in V2 |
| CONTRACT_MISMATCH | fail + escalate |
| MINOR_DEFECT | send to R |
