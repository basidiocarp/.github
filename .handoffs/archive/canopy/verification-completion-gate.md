# Canopy Verification Completion Gate

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Canopy validates handoff payloads at handoff time (shipped v0.3.1) but does not
enforce a hard completion block on tasks where `verification_required=true`. Agents
can mark such tasks complete without providing passing `ScriptVerification` evidence.
The gate exists at handoff; it doesn't exist at task completion.

## What exists (state)

- **Handoff completeness checker (v0.3.1)**: validates structured handoff payloads
  meet requirements at handoff time
- **`verification_required` field**: exists on task records; set by task creator
- **`ScriptVerification` evidence type**: exists in the evidence ref schema
- **Task completion command**: `canopy task complete <id>` — currently does not
  check `verification_required` or `ScriptVerification` evidence presence

## What needs doing (intent)

Add a completion guard to `canopy task complete` that blocks completion when
`verification_required=true` and no passing `ScriptVerification` evidence ref
exists on the task. The guard runs at `canopy task complete` time, not at handoff
time.

---

### Step 1: Add verification guard to task completion

**Project:** `canopy/`
**Effort:** 1 day
**Depends on:** nothing

Modify the `canopy task complete <id>` handler to:

1. Load the task by ID
2. If `verification_required=true`, query the task's evidence refs for any
   `ScriptVerification` entry with `status: "passed"`
3. If no passing `ScriptVerification` evidence is found, reject the completion:

```
Error: task <id> requires script verification before completion.

Attach a passing verification result:
  canopy task evidence add <id> --type script_verification --status passed --ref <ref>

Or override (operators only):
  canopy task complete <id> --force
```

4. `--force` flag bypasses the guard for operator use; log the override as a
   council event on the task

#### Files to modify

**`canopy-core/src/task/complete.rs`** (or equivalent):

```rust
pub fn complete_task(
    conn: &Connection,
    task_id: &TaskId,
    force: bool,
) -> Result<(), CompletionError>;

#[derive(Debug, thiserror::Error)]
pub enum CompletionError {
    #[error("task requires script verification evidence before completion")]
    VerificationRequired,
    #[error("task not found: {0}")]
    NotFound(TaskId),
}
```

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `canopy task complete` blocked for `verification_required=true` tasks without
  passing `ScriptVerification` evidence
- [ ] Error message includes instructions for attaching evidence
- [ ] `--force` flag bypasses the guard and logs a council event
- [ ] Tasks with `verification_required=false` complete normally (no regression)
- [ ] Build and tests pass

---

### Step 2: Add verification status to task list output

**Project:** `canopy/`
**Effort:** 2–4 hours
**Depends on:** Step 1

Update `canopy task list` output to show a verification column:
- `✓ verified` — `verification_required=true` and passing evidence present
- `⚠ needs verification` — `verification_required=true` and no passing evidence
- `-` — `verification_required=false`

This makes it easy to spot tasks blocked on verification before attempting completion.

#### Verification

```bash
cd canopy && cargo test --workspace 2>&1 | tail -10
canopy task list 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `canopy task list` shows verification status column
- [ ] `needs verification` tasks are visually distinct
- [ ] Tasks without `verification_required` show `-` not an error

---

### Step 3: Wire into canopy snapshot for cap

**Project:** `canopy/`
**Effort:** 1–2 hours
**Depends on:** Step 1

Add a `needs_verification_count` field to `canopy snapshot` output so cap can
surface "X tasks blocked on verification" in the operator view. The snapshot
already includes task counts by status; this adds one more dimension.

#### Verification

```bash
cd canopy && canopy snapshot 2>&1 | grep -i verification
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `canopy snapshot` includes `needs_verification_count`
- [ ] Count is accurate vs `canopy task list` output
- [ ] `schema_version: "1.0"` still present in snapshot

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `canopy/`
3. Attempting `canopy task complete` on a `verification_required=true` task without
   evidence returns the error message
4. All checklist items are checked

### Final Verification

```bash
cd canopy && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #11 in `docs/workspace/ECOSYSTEM-REVIEW.md`. The handoff validator (v0.3.1)
checks completeness at handoff time but there is no equivalent guard at task
completion time. `verification_required` is a first-class field that currently has
no enforcement. The `--force` escape hatch is important for operators who need to
override the gate, but the override should be logged explicitly as a council event.
