# Global Audit README Drift

<!-- Save as: .handoffs/archive/cross-project/global-audit-readme-drift.md -->
<!-- Create verify script: .handoffs/archive/cross-project/verify-global-audit-readme-drift.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

The global audit README at `.handoffs/archive/campaigns/global-audit/README.md`
contains setup commands that don't match canopy's actual CLI. Agents or users
following the README hit errors that are invisible (due to cortina hook output
suppression) or confusing.

Specific drift:
1. `--host-id` used where CLI expects separate `--agent-id` and `--host-id`
2. Missing required flags: `--host-instance`, `--model`, `--project-root`, `--worktree-id`
3. `--priority` flag referenced but doesn't exist on `task create`
4. `canopy task status <id> --status completed` syntax may not match actual CLI
5. Task counts and timing estimates don't reflect volva addition (22 tasks, not 19)

## What exists (state)

- **README.md**: Written before canopy v0.3.1 CLI was finalized
- **Canopy CLI**: `src/cli.rs` defines the actual flag names and required args
- **Installed binary**: v0.3.1 now installed at `~/.local/bin/canopy`

## What needs doing (intent)

Update the README setup commands to match the actual canopy CLI, test each
command works, and add a note about binary version requirements.

---

### Step 1: Fix agent registration commands

**Project:** `.handoffs/archive/campaigns/global-audit/`
**Effort:** 15 minutes
**Depends on:** Nothing

Update all `canopy agent register` commands to include all required flags:
`--agent-id`, `--host-id`, `--host-type`, `--host-instance`, `--model`,
`--project-root`, `--worktree-id`

Optional flags: `--role`, `--capabilities`

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
canopy agent register --help 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->
Usage: canopy agent register [OPTIONS] --agent-id <AGENT_ID> --host-id <HOST_ID> --host-type <HOST_TYPE> --host-instance <HOST_INSTANCE> --model <MODEL> --project-root <PROJECT_ROOT> --worktree-id <WORKTREE_ID>

Options:
      --agent-id <AGENT_ID>
      --db <DB>                        Path to the Canopy database file
      --host-id <HOST_ID>
      --host-type <HOST_TYPE>
      --host-instance <HOST_INSTANCE>
      --model <MODEL>
      --project-root <PROJECT_ROOT>
      --worktree-id <WORKTREE_ID>
      --role <ROLE>                    [possible values: orchestrator, implementer, validator]
      --capabilities <CAPABILITIES>
  -h, --help                           Print help
<!-- PASTE END -->

**Checklist:**
- [x] All register commands include required flags
- [x] Commands tested against actual CLI
- [x] Role and capabilities flags included where appropriate

---

### Step 2: Fix task creation commands

**Project:** `.handoffs/archive/campaigns/global-audit/`
**Effort:** 15 minutes
**Depends on:** Nothing

Update all `canopy task create` commands. Required flags: `--title`,
`--requested-by`. Optional: `--parent`, `--description`, `--required-role`,
`--required-capabilities`, `--scope`.

Remove `--priority` if it doesn't exist on the CLI.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
canopy task create --help 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->
Usage: canopy task create [OPTIONS] --title <TITLE> --requested-by <REQUESTED_BY>

Options:
      --db <DB>
          Path to the Canopy database file
      --title <TITLE>

      --description <DESCRIPTION>

      --requested-by <REQUESTED_BY>

      --project-root <PROJECT_ROOT>
          [default: .]
      --parent <PARENT>

      --required-role <REQUIRED_ROLE>
          [possible values: orchestrator, implementer, validator]
      --required-capabilities <REQUIRED_CAPABILITIES>

      --auto-review
<!-- PASTE END -->

**Checklist:**
- [x] All task create commands include `--requested-by`
- [x] `--priority` removed if not supported
- [x] `--parent` used correctly for subtasks
- [x] Commands tested against actual CLI

---

### Step 3: Fix task status commands

**Project:** `.handoffs/archive/campaigns/global-audit/`
**Effort:** 10 minutes
**Depends on:** Nothing

Verify `canopy task status` syntax matches actual CLI. Update completion
and monitoring commands.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
canopy task --help 2>&1 | head -30
```

**Output:**
<!-- PASTE START -->
Usage: canopy task [OPTIONS] <COMMAND>

Commands:
  create
  assign
  claim
  complete
  status
  triage
  action
  verify
  list
  list-view
  show
  help       Print this message or the help of the given subcommand(s)

Options:
      --db <DB>  Path to the Canopy database file
  -h, --help     Print help
<!-- PASTE END -->

**Checklist:**
- [x] Task status update syntax matches CLI
- [x] Monitoring commands (snapshot, api) syntax correct
- [x] Task counts updated for 9 projects (was 8)

---

### Step 4: Add version requirement note

**Project:** `.handoffs/archive/campaigns/global-audit/`
**Effort:** 5 minutes
**Depends on:** Nothing

Add a prerequisite note at the top of the README:

```markdown
**Prerequisite:** canopy >= 0.3.1 (`canopy -V` to check).
If outdated: `cd canopy && cargo install --path . && cp ~/.cargo/bin/canopy ~/.local/bin/canopy`
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
grep -q '0.3.1\|version\|prerequisite' .handoffs/archive/campaigns/global-audit/README.md
```

**Output:**
<!-- PASTE START -->
grep matched
<!-- PASTE END -->

**Checklist:**
- [x] Version requirement documented
- [x] Install instructions included
- [x] Binary path issue noted (`~/.local/bin` vs `~/.cargo/bin`)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/cross-project/verify-global-audit-readme-drift.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/archive/cross-project/verify-global-audit-readme-drift.sh
```

**Output:**
<!-- PASTE START -->
=== Global Audit README Drift Verification ===

--- Step 1: Agent Registration ---
  PASS: register commands have --agent-id
  PASS: register commands have --host-instance
  PASS: register commands have --model
  PASS: register commands have --project-root

--- Step 2: Task Creation ---
  PASS: task create has --requested-by

--- Step 3: Task Status ---
  PASS: task counts reflect 9 projects

--- Step 4: Version Requirement ---
  PASS: version requirement documented

================================
Results: 7 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Discovered when trying to run the global audit for the first time (2026-04-03).
The README commands failed because the CLI flags didn't match the actual canopy
binary. The errors were invisible due to cortina hook output suppression
(see cortina/hook-output-suppression.md).
