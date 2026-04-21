# Hook Output Suppression

<!-- Save as: .handoffs/cortina/hook-output-suppression.md -->
<!-- Create verify script: .handoffs/cortina/verify-hook-output-suppression.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Cortina's PreToolUse hook intercepts ALL Bash tool calls in Claude Code
sessions and suppresses their output. This affects not just `cargo` commands
(the intended target for mycelium rewriting) but also `canopy` CLI, `sqlite3`,
`python3`, `node`, `git` (for non-mycelium repos), and any other command
that runs through a shell.

The result: agents cannot see command output, errors fail silently, and
debugging requires workarounds (reading files directly, having the user run
commands via `!` prefix, or dispatching subagents).

This was discovered during canopy orchestration setup when `canopy task create`
commands inside a for-loop failed silently — no error output was visible.

## What exists (state)

- **Cortina PreToolUse hook** (`src/hooks/pre_tool_use.rs`): Intercepts Bash
  commands to rewrite them through mycelium. The rewrite produces filtered
  output that gets returned to Claude Code.
- **Hook config** (`~/.claude/settings.json`): `PreToolUse` matcher is `Bash`
  — matches ALL Bash tool calls unconditionally.
- **Known workarounds**: `mycelium cargo` for cargo commands, `printf`/`echo`
  for direct output, `script -q /dev/stdout` for fast commands, `!` prefix
  for user-run commands.

## What needs doing (intent)

The hook should only intercept commands it knows how to rewrite (cargo, git,
etc.) and pass through everything else unchanged. Commands that fail should
still show their error output.

---

### Step 1: Audit which commands cortina actually rewrites

**Project:** `cortina/`
**Effort:** 30 minutes
**Depends on:** Nothing

Read `src/hooks/pre_tool_use.rs` and `src/adapters/` to catalog every command
that cortina actually rewrites. Commands NOT in this list should pass through
with unmodified output.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd cortina && grep -rn 'rewrite\|intercept\|mycelium' src/hooks/pre_tool_use.rs | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Complete list of rewritten commands documented
- [ ] Commands NOT rewritten identified

---

### Step 2: Add passthrough for non-rewritten commands

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Modify the PreToolUse hook to only intercept commands it knows how to rewrite.
All other commands should pass through with their original output intact.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd cortina && cargo test pre_tool_use --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Non-rewritten commands pass through with original output
- [ ] Failed commands show error output (not swallowed)
- [ ] `canopy task list` produces visible output in Claude Code session
- [ ] `sqlite3`, `python3`, `node` commands produce visible output
- [ ] `cargo test` passes
- [ ] `cargo clippy` clean

---

### Step 3: Add error output preservation

**Project:** `cortina/`
**Effort:** 30 minutes
**Depends on:** Step 2

Even for rewritten commands, if the command fails (non-zero exit), the error
output should be preserved and shown to the agent. Currently errors are
swallowed along with stdout.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd cortina && cargo test error_output --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Failed rewritten commands show error output
- [ ] Exit code is preserved
- [ ] `cargo test` passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cortina/verify-hook-output-suppression.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cortina/verify-hook-output-suppression.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Discovered during canopy orchestration setup (2026-04-03). A for-loop creating
22 canopy subtasks failed silently — no error output visible. The cortina
PreToolUse hook was intercepting the `canopy` CLI commands and suppressing
their output. Multiple other commands (sqlite3, python3, node, git for
non-mycelium repos) were also affected.

This is a high-severity issue because it makes debugging impossible within
Claude Code sessions and causes silent data loss when commands fail.
