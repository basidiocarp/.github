# Orchestrator State Machine

## States

| State | Description |
|------|------------|
| CREATED | Task created |
| COMPILED | Task packet generated |
| VERIFIED_DECOMP | Decomposition validated |
| READY | Ready for execution |
| ASSIGNED | Assigned to agent |
| EXECUTING | In progress |
| COMPLETED | Execution finished |
| VERIFIED_OUTPUT | Output validated |
| REPAIR_QUEUED | Sent to repair |
| REPAIRING | Repair in progress |
| REPAIRED | Repair complete |
| VERIFIED_REPAIR | Repair validated |
| FAILED | Terminal failure |
| ESCALATED | Sent upstream |
| DONE | Successfully completed |

---

## Transitions

| From | To | Condition |
|------|----|----------|
| CREATED | COMPILED | B2 compiles |
| COMPILED | VERIFIED_DECOMP | V1 passes |
| VERIFIED_DECOMP | READY | valid |
| READY | ASSIGNED | scheduler assigns |
| ASSIGNED | EXECUTING | agent starts |
| EXECUTING | COMPLETED | success |
| COMPLETED | VERIFIED_OUTPUT | V2 passes |
| VERIFIED_OUTPUT | DONE | success |
| VERIFIED_OUTPUT | REPAIR_QUEUED | failure |
| REPAIR_QUEUED | REPAIRING | R picks |
| REPAIRING | REPAIRED | done |
| REPAIRED | VERIFIED_REPAIR | V3 checks |
| VERIFIED_REPAIR | DONE | pass |
| ANY | ESCALATED | critical failure |

---

## Guards

- max retries not exceeded
- context budget respected
- dependencies resolved

