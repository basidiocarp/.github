# Canopy Capability Routing + Multi-Model Orchestration

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

Canopy has no concept of model capability. Orchestrators assigning tasks to agents
have no way to express that a task requires Opus (complex reasoning) vs. Sonnet
(general work) vs. Haiku (simple/fast). Without capability routing, multi-model
flows can't self-organize around task complexity — every agent sees every task.

## What exists (state)

- **Task ledger**: full lifecycle, triage metadata, priority, assignments, scope
- **Agent registry**: heartbeat + heartbeat history; agents register a name and
  last-heartbeat but no capability declaration
- **`canopy task claim <id>`**: first-come claiming; no capability matching
- **Sub-task hierarchy (gap #12)**: needed before multi-model orchestration is
  safe; this handoff depends on #12 being complete first

## What needs doing (intent)

Add a capability field to agent registration and task creation. When an agent
claims a task, check that the agent's declared capability matches the task's
required capability tier. Add an orchestrator shortcut: `canopy task assign
--capability opus` routes a task to the next available Opus-tier agent.

---

### Step 1: Add capability tiers to agent registry

**Project:** `canopy/`
**Effort:** 1 day
**Depends on:** Sub-task hierarchy (gap #12) complete

Add a `capability` field to agent records:

```sql
ALTER TABLE agents ADD COLUMN capability TEXT NOT NULL DEFAULT 'general';
```

Valid capability tiers: `opus`, `sonnet`, `haiku`, `general` (unspecified).

Update `canopy agent register` to accept `--capability <tier>`:

```bash
canopy agent register my-agent --capability sonnet
```

Agents without `--capability` default to `general`.

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
canopy agent register test-agent --capability sonnet 2>&1
canopy agent list 2>&1 | grep test-agent
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `capability` column added to agents table
- [ ] `canopy agent register --capability <tier>` works
- [ ] `canopy agent list` shows capability column
- [ ] Existing agents default to `general`
- [ ] Build and tests pass

---

### Step 2: Add required capability to tasks

**Project:** `canopy/`
**Effort:** 4–8 hours
**Depends on:** Step 1

Add `required_capability` field to tasks:

```sql
ALTER TABLE tasks ADD COLUMN required_capability TEXT;
```

Update `canopy task create` to accept `--required-capability <tier>`:

```bash
canopy task create "Refactor auth module" --required-capability opus
```

Tasks without `--required-capability` accept any agent (capability matching disabled).

Update `canopy task claim <id>` to check capability match:
- If `required_capability` is set and agent's `capability` doesn't match, reject:
  ```
  Error: task requires 'opus' capability; this agent is registered as 'sonnet'
  Use --override to claim anyway (logged to task history)
  ```
- `--override` allows mismatched claiming with an audit log entry

#### Verification

```bash
cd canopy && cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `required_capability` field on tasks
- [ ] `canopy task create --required-capability <tier>` works
- [ ] Mismatched claim rejected with clear error
- [ ] `--override` allowed with audit log entry
- [ ] Tasks without `required_capability` accept any agent

---

### Step 3: Add capability-aware task routing

**Project:** `canopy/`
**Effort:** 4–8 hours
**Depends on:** Step 2

Add `canopy task assign --capability <tier>` that finds the task and routes it
to the next available registered agent with the matching capability:

```bash
canopy task assign 42 --capability opus
# → finds registered opus agent with most recent heartbeat
# → assigns task to that agent
```

Also add automatic review sub-tasks: when a task is assigned to a haiku agent,
optionally auto-create a review sub-task assigned to a sonnet or opus agent:

```bash
canopy task create "Quick fix" --required-capability haiku --auto-review
# creates main task + review sub-task with required_capability=sonnet
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
- [ ] `canopy task assign --capability <tier>` routes to available agent
- [ ] `--auto-review` creates review sub-task with higher capability tier
- [ ] Assignment fails gracefully when no capable agent is available
- [ ] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `canopy/`
3. Capability mismatch on `canopy task claim` produces the expected error
4. `canopy task assign --capability opus` routes to the correct agent
5. All checklist items are checked

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
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #17 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Marked "planned later" — designed
but not started. Capability routing is the prerequisite for safe multi-model
orchestration where complex tasks go to Opus, routine tasks to Sonnet, and fast/
cheap tasks to Haiku. Depends on gap #12 (sub-task hierarchy) being complete so
that automatic review sub-tasks can be parented correctly.
