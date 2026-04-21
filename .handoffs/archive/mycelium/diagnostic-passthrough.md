# Handoff: Mycelium Diagnostic Command Passthrough

## Status

Implemented on 2026-04-01.

### Files changed

- `mycelium/src/commands.rs`
- `mycelium/src/dispatch.rs`
- `mycelium/src/discover/registry.rs`
- `mycelium/src/discover/registry_tests.rs`
- `mycelium/src/rewrite_cmd.rs`
- `mycelium/src/adaptive.rs`

### What shipped

- Added diagnostic passthrough routing through `mycelium invoke` so
  diagnostic shell commands execute with raw shell semantics while still
  flowing through Mycelium's tracking and hook surfaces.
- Added a diagnostic passthrough allowlist in the rewrite registry so
  commands like `which`, `type`, `file`, `stat`, `echo`, `printf`, and
  flagged `ls` forms rewrite to `mycelium invoke ...` instead of
  going through output filters.
- Added an adaptive safeguard so outputs of 5 lines or fewer always
  passthrough unchanged, even when byte counts are large.
- Updated rewrite explanations so passthrough diagnostics report the
  allowlist reason instead of looking like a savings rewrite.

### Verification run

```bash
cd mycelium && cargo fmt --check
cd mycelium && cargo test
cd mycelium && cargo build --release
cd mycelium && cargo run -- rewrite --explain "which git"
cd mycelium && cargo run -- invoke --explain type cargo
```

### Notes

- The implementation uses `mycelium invoke` plus an invoke-side
  diagnostic bypass so shell builtins like `type`, `echo`, and `printf`
  still work correctly without adding a separate public CLI mode.
- The verification surface uses focused Rust tests rather than snapshot
  fixtures. That is sufficient for this slice because the important
  behavior is command routing and passthrough mode selection.

## Problem

When debugging MCP startup failures, every diagnostic Bash command
(`which`, `type`, `file`, `stat`, `echo`, `ls -la`, `otool`, etc.)
produced empty output because:

1. Cortina's PreToolUse hook rewrites ALL Bash commands through mycelium
2. Mycelium's filters compress output, sometimes to zero for commands
   that produce short or unexpected output formats
3. There is no way for an agent to bypass filtering for diagnostic work

This made it impossible to diagnose the hyphae/rhizome MCP failures
without asking the user to run commands manually via `!` prefix.

## What exists (state)

- **`mycelium proxy <cmd>`** exists — runs commands without filtering
- **Cortina PreToolUse hook** rewrites Bash tool input: adds `mycelium`
  prefix to commands
- **No allowlist** for commands that should never be filtered

### Commands that were swallowed during debugging

```
which rhizome         → empty
type hyphae           → empty
file /path/to/binary  → empty
stat /path/to/binary  → empty
echo "text"           → empty
ls -la /path          → empty (ls filter too aggressive)
otool -L /path        → empty
cat /tmp/file.txt     → empty
```

## Proposed Fix

### Option A: Diagnostic command allowlist in mycelium (recommended)

Add a list of commands that should always pass through unfiltered.
These are introspection/diagnostic commands that produce small,
information-dense output.

**File: `mycelium/src/dispatch.rs` or a new `passthrough.rs`**

```rust
const DIAGNOSTIC_PASSTHROUGH: &[&str] = &[
    "which",
    "type",
    "file",
    "stat",
    "otool",
    "ldd",
    "readelf",
    "uname",
    "whoami",
    "hostname",
    "printenv",
    "echo",
    "printf",
    "id",
    "groups",
    "locale",
    "sw_vers",      // macOS version
    "xcode-select", // Xcode path
    "rustup",       // Rust toolchain info
    "nvm",          // Node version manager
    "pyenv",        // Python version manager
];
```

When the first token of a command matches this list, skip filtering
entirely — run the command and return raw output.

### Option B: Cortina PreToolUse skip list

Instead of mycelium handling it, cortina's `pre_tool_use.rs` could
skip the mycelium rewrite for diagnostic commands. The command would
run unmodified.

**Pro:** Simpler — no mycelium change needed
**Con:** The skip list lives in cortina, not mycelium, so `mycelium which`
from the CLI would still be filtered

### Option C: Small output passthrough (universal)

If the raw command output is under N lines (e.g., 5 lines or 200 bytes),
skip filtering entirely. Diagnostic commands almost always produce 1-3
lines.

**Pro:** No allowlist maintenance — automatically handles any short output
**Con:** Mycelium already has adaptive filtering (`adaptive.rs`) but the
threshold may be set too aggressively for very short output

### Recommendation

**Combine A + C:**
- Add diagnostic passthrough list for commands that should NEVER be filtered
- Lower the adaptive filter threshold so outputs under 5 lines always
  pass through unchanged

## Implementation

### Step 1: Add passthrough list

In mycelium's dispatch, before applying any filter, check if the command
starts with a diagnostic command. If so, execute raw and return.

### Step 2: Check adaptive threshold

Read `mycelium/src/adaptive.rs` — verify that outputs under 5 lines
(~200 bytes) always pass through. If the threshold is higher, lower it.

### Step 3: Test

```bash
# These should all produce non-empty output:
mycelium which git
mycelium type cargo
mycelium file /usr/bin/ls
mycelium stat /usr/bin/ls
mycelium echo "hello world"
```

### Step 4: Snapshot tests

Add fixture + snapshot tests for each diagnostic command to prevent
regression.

## Verification Checklist

- [x] `mycelium which git` routes through raw diagnostic passthrough
- [x] `mycelium echo "test"` routes through raw diagnostic passthrough
- [x] `mycelium file /usr/bin/ls` routes through raw diagnostic passthrough
- [x] `mycelium stat /usr/bin/ls` routes through raw diagnostic passthrough
- [x] Short outputs (<5 lines) always pass through unchanged
- [x] `cargo test` passes
- [x] Existing filter savings remain intact for non-diagnostic commands

## Context

This issue was discovered while debugging MCP startup failures for
hyphae and rhizome. See `HANDOFF-MCP-STARTUP-FIX.md` for that fix.
The mycelium filtering made the debugging process take 10x longer
than necessary because every diagnostic command returned empty output.
