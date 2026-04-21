# Septa: Hymenium Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** septa/...
- **Cross-repo edits:** none
- **Non-goals:** hymenium implementation code
- **Verification contract:** bash validate-all.sh
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when complete

## Problem

Hymenium needs septa contracts before it can emit or consume structured data. Three schemas define its contract boundary: workflow templates (what patterns exist), dispatch requests (what to create in canopy), and workflow status (what's running for operator visibility).

## What exists (state)

- **Septa**: 34+ validated schemas with fixtures
- **validate-all.sh**: Python validator with local $ref resolution
- **host-identifier-v1**: Shared enum for host identifiers
- **canopy-task-detail-v1**: Canopy's task detail schema (hymenium reads this)
- **canopy-snapshot-v1**: Canopy's snapshot schema (hymenium reads this)

## What needs doing (intent)

Define three new septa contracts for hymenium's boundary.

---

### Step 1: workflow-template-v1 schema

**Project:** `septa/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create `septa/workflow-template-v1.schema.json`:

- `schema_version`: const "1.0"
- `template_id`: string (e.g., "impl-audit")
- `name`: string (e.g., "Implementer/Auditor")
- `description`: string
- `phases`: array of objects:
  - `phase_id`: string (e.g., "implement", "audit")
  - `role`: enum ["implementer", "auditor", "reviewer", "operator"]
  - `agent_tier`: enum ["opus", "sonnet", "haiku", "any"]
  - `entry_gate`: object with { requires: array of strings } — conditions that must be true to enter this phase
  - `exit_gate`: object with { requires: array of strings } — conditions that must be true to exit
- `transitions`: array of objects:
  - `from_phase`: string
  - `to_phase`: string  
  - `condition`: string (human-readable gate description)

Use additionalProperties: false at all levels.

Create `septa/fixtures/workflow-template-v1.example.json` with the implementer/auditor pattern:
- Phase 1: "implement" — role implementer, tier sonnet, entry gate none, exit gate ["code_diff_exists", "verification_passed"]
- Phase 2: "audit" — role auditor, tier sonnet, entry gate ["code_diff_exists", "verification_passed"], exit gate ["audit_clean", "findings_resolved"]

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && bash validate-all.sh
```

**Checklist:**
- [ ] Schema created with phases and transitions
- [ ] Fixture validates against schema
- [ ] validate-all.sh passes with 0 failures

---

### Step 2: dispatch-request-v1 schema

**Project:** `septa/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create `septa/dispatch-request-v1.schema.json`:

- `schema_version`: const "1.0"
- `handoff_path`: string — path to the handoff document
- `workflow_template`: string — template_id to use (e.g., "impl-audit")
- `project_root`: string — workspace root
- `target_repo`: string — owning repository
- `priority`: enum ["low", "medium", "high", "critical"]
- `agent_tier_override`: optional enum ["opus", "sonnet", "haiku"] — override template default
- `decompose`: boolean — whether to auto-decompose large handoffs
- `max_effort_per_piece`: optional string — e.g., "4h" — max effort for decomposed pieces
- `depends_on`: optional array of strings — workflow IDs that must complete first

Create `septa/fixtures/dispatch-request-v1.example.json` with a realistic example.

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && bash validate-all.sh
```

**Checklist:**
- [ ] Schema created
- [ ] Fixture validates
- [ ] validate-all.sh passes

---

### Step 3: workflow-status-v1 schema

**Project:** `septa/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create `septa/workflow-status-v1.schema.json`:

- `schema_version`: const "1.0"
- `workflow_id`: ULID string
- `handoff_path`: string
- `template_id`: string
- `status`: enum ["pending", "dispatched", "in_progress", "blocked", "completed", "failed", "cancelled"]
- `current_phase`: string — which phase is active
- `phases`: array of objects:
  - `phase_id`: string
  - `status`: enum ["pending", "active", "completed", "failed", "skipped"]
  - `agent_id`: optional string — assigned agent
  - `started_at`: optional ISO 8601 string
  - `completed_at`: optional ISO 8601 string
  - `canopy_task_id`: optional ULID — linked canopy task
- `created_at`: ISO 8601
- `updated_at`: ISO 8601

Create `septa/fixtures/workflow-status-v1.example.json` showing an in-progress impl/audit workflow where the implement phase is completed and audit is active.

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && bash validate-all.sh
```

**Checklist:**
- [ ] Schema created with workflow lifecycle status
- [ ] Fixture validates
- [ ] validate-all.sh passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. All three schemas + fixtures created
2. `bash validate-all.sh` passes with 0 failures
3. All checklist items checked

## Context

Part of hymenium chain (#118b). These contracts define hymenium's boundary with the rest of the ecosystem. Must be defined before hymenium can emit or consume structured data. Related to existing canopy contracts (canopy-snapshot-v1, canopy-task-detail-v1) which hymenium reads.
