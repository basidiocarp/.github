# Hook Registration Fix

<!-- Save as: .handoffs/mycelium/hook-registration.md -->
<!-- Verify script: .handoffs/mycelium/verify-hook-registration.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

`mycelium doctor` reports two issues:

```
! Claude Code hook       not installed — run `stipe init` if you use Claude Code
! claude settings        exists but Mycelium hook is not registered
```

Mycelium's Claude Code hook is not registered in the user's settings despite
cortina being installed and configured. The cortina PreToolUse hook rewrites
Bash commands through mycelium, but mycelium's own doctor check looks for a
different hook registration format.

## What exists (state)

- **Cortina hook**: `cortina/src/hooks/pre_tool_use.rs` rewrites Bash commands
  through mycelium — this is working (proven by the passthrough fix)
- **Mycelium doctor**: Checks for mycelium-specific hook registration in
  `~/.claude/settings.json` or `~/.claude.json`
- **`stipe init`**: Registers cortina hooks, not mycelium-specific hooks
- **`mycelium init`**: May register its own hook format that differs from
  cortina's approach

## Investigation Needed

### Step 1: Understand what mycelium doctor checks

**Project:** `mycelium/`
**Effort:** 15 minutes

Read the doctor check implementation to understand what hook format it
expects.

#### Files to read

- `mycelium/src/doctor.rs` or equivalent — find the Claude Code hook check
- Understand what "registered" means: is it looking for a specific hook
  entry in settings.json? A specific command pattern?

#### Verification

<!-- AGENT: Run and paste output -->
```bash
grep -rn 'hook\|Claude Code\|settings' mycelium/src/doctor.rs 2>/dev/null || grep -rn 'hook.*install\|not installed' mycelium/src/ | head -20
```

**Output:**
<!-- PASTE START -->
/Users/williamnewton/projects/basidiocarp/mycelium/src/doctor_cmd.rs:67:            pass("Claude Code hook", "installed and verified");
/Users/williamnewton/projects/basidiocarp/mycelium/src/doctor_cmd.rs:73:                    "not installed — run `{}` if you use Claude Code",
/Users/williamnewton/projects/basidiocarp/mycelium/src/init/host_status.rs:130:                "settings present at {} but Mycelium hook is not installed",
/Users/williamnewton/projects/basidiocarp/mycelium/src/init/host_status.rs:135:            format!("hook installed but not registered in {}", path.display())

<!-- PASTE END -->

**Checklist:**
- [x] Identified what mycelium doctor checks for hook registration
- [x] Identified the expected hook format/location

---

### Step 2: Determine the right fix

Two options:

**Option A: Update mycelium doctor to recognize cortina's hook**

If cortina's PreToolUse hook already routes Bash through mycelium, mycelium
doctor should recognize this as "hook installed" instead of reporting it
missing. The check should look for either:
- mycelium's own hook entry, OR
- cortina's hook entry (which routes through mycelium)

**Option B: Register mycelium's hook alongside cortina's**

If mycelium has its own hook that provides different functionality than
cortina's rewrite (e.g., tracking, non-Bash tool interception), it may
need its own registration.

Determine which option is correct based on Step 1 findings.

#### Verification

<!-- AGENT: Run and paste output -->
```bash
mycelium doctor 2>&1
```

**Output:**
<!-- PASTE START -->
Mycelium Doctor — Health Check

  ✓ version                v0.8.3
  ! Claude Code hook       not installed — run `stipe init` if you use Claude Code
  ! claude settings        exists but Mycelium hook is not registered
  ✓ Codex CLI              configured in /Users/williamnewton/.codex/config.toml (hyphae, rhizome)
  ✓ config                 using defaults (/Users/williamnewton/Library/Application Support/mycelium/config.toml)
  ✓ tracking db            7645 records (/Users/williamnewton/Library/Application Support/mycelium/history.db, default)
  ✓ plugins                1 plugin(s) in /Users/williamnewton/Library/Application Support/mycelium/plugins
  ✗ binary collision       MISMATCH — running /Users/williamnewton/projects/basidiocarp/mycelium/target/debug/mycelium but PATH resolves mycelium to /Users/williamnewton/.local/bin/mycelium
  ! PATH                   /Users/williamnewton/projects/basidiocarp/mycelium/target/debug is NOT in PATH — add it to your shell profile

<!-- PASTE END -->

**Checklist:**
- [x] Root cause identified
- [x] Fix approach chosen (A or B)

---

### Step 3: Implement the fix

Based on Step 2 findings, either:
- Update doctor to check for cortina hook (Option A)
- Register mycelium hook via stipe init (Option B)

#### Verification

<!-- AGENT: Run and paste output -->
```bash
mycelium doctor 2>&1
```

**Output:**
<!-- PASTE START -->
Mycelium Doctor — Health Check

  ✓ version                v0.8.3
  ✓ Claude Code hook       managed by Cortina PreToolUse adapter
  ✓ claude settings        Cortina PreToolUse hook registered
  ✓ Codex CLI              configured in /Users/williamnewton/.codex/config.toml (hyphae, rhizome)
  ✓ config                 using defaults (/Users/williamnewton/Library/Application Support/mycelium/config.toml)
  ✓ tracking db            7668 records (/Users/williamnewton/Library/Application Support/mycelium/history.db, default)
  ✓ plugins                1 plugin(s) in /Users/williamnewton/Library/Application Support/mycelium/plugins
  ✗ binary collision       MISMATCH — running /Users/williamnewton/projects/basidiocarp/mycelium/target/debug/mycelium but PATH resolves mycelium to /Users/williamnewton/.local/bin/mycelium
  ! PATH                   /Users/williamnewton/projects/basidiocarp/mycelium/target/debug is NOT in PATH — add it to your shell profile

<!-- PASTE END -->

**Checklist:**
- [x] `mycelium doctor` shows no `!` warnings for hook/settings
- [x] `cargo test` passes
- [x] `cargo clippy` clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/mycelium/verify-hook-registration.sh`
3. All checklist items are checked

### Final Verification

Note: the verification script now stages the hook-registration files into a
clean temporary worktree before running `cargo test` and `cargo clippy`, so
unrelated local changes in `mycelium/src/discover/registry.rs` do not block
completion of this handoff.

```bash
bash .handoffs/mycelium/verify-hook-registration.sh
```

**Output:**
<!-- PASTE START -->
=== MYCELIUM HOOK-REGISTRATION Verification ===

Preparing worktree (detached HEAD 8970e96)
--- Doctor Checks ---
  PASS: mycelium doctor runs
  PASS: no hook warning in doctor output
  PASS: no settings warning in doctor output

--- Hook Functionality ---
  PASS: cortina hook routes bash through mycelium
  PASS: diagnostic passthrough works

--- Build ---
  PASS: cargo test passes
  PASS: cargo clippy clean

================================
Results: 7 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Discovered during `stipe install` ecosystem update. Mycelium v0.8.3 reports
hook not installed despite cortina successfully routing all Bash commands
through mycelium. The diagnostic passthrough fix (now implemented) confirmed
cortina's hook works — mycelium doctor just doesn't recognize it.
