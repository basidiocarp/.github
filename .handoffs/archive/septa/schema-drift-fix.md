# Septa: Fix schema drift (stipe-doctor, stipe-init-plan, canopy-notification)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa` (schemas and fixtures); read stipe and canopy source to confirm fields
- **Allowed write scope:** septa/...
- **Cross-repo edits:** none (schema fixes only; if Rust types need changing coordinate with the owning repo)
- **Non-goals:** other septa schemas
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

All three schema issues are false-greens in `validate-all.sh` because the fixtures don't exercise the missing fields/variants. Real binary output would fail schema validation.

### 1 — stipe-doctor-v1.schema.json missing three fields
`septa/stipe-doctor-v1.schema.json`

The `DoctorReport` Rust struct (`stipe/src/commands/doctor/model.rs:136-143`) emits `mcp_server_health`, `api_key_health`, and `plugin_inventory` unconditionally. The septa schema has `additionalProperties: false` and does not declare these fields. Any tool that validates real `stipe doctor --json` output against this schema will fail.

Fix: add `mcp_server_health`, `api_key_health`, and `plugin_inventory` to the schema properties. Update the fixture to include at least one of these fields so the gap is exercised.

### 2 — stipe-init-plan-v1.schema.json step status enum mismatch
`septa/stipe-init-plan-v1.schema.json`

Schema permits `["planned", "skipped", "done", "failed"]`. The Rust `InitStepStatus` type (`stipe/src/commands/init/model.rs:74-76`) serialises to `already-ok` (not in schema) and does not produce `done` or `failed`. Fix: align the enum to match what Rust actually serialises. Update the fixture to include an `already-ok` entry.

### 3 — canopy-notification-v1.schema.json missing two event_type variants
`septa/canopy-notification-v1.schema.json`

`NotificationEventType` in canopy (`canopy/src/models.rs:1494-1496`) produces `task_cancelled` and `evidence_received`. Cap's TypeScript type expects both. The septa schema enum omits both. Fix: add `task_cancelled` and `evidence_received` to the schema enum. Update the fixture.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp
bash septa/validate-all.sh 2>&1 | tail -5
```

Expected: all 47+ schemas pass (count increases by 0 — same files, updated content).

## Checklist

- [ ] `stipe-doctor-v1` schema includes `mcp_server_health`, `api_key_health`, `plugin_inventory`
- [ ] `stipe-init-plan-v1` step status enum matches Rust serialisation (`already-ok` present, `done`/`failed` corrected)
- [ ] `canopy-notification-v1` event_type enum includes `task_cancelled` and `evidence_received`
- [ ] All three fixtures updated to exercise the new/corrected fields
- [ ] `validate-all.sh` passes
