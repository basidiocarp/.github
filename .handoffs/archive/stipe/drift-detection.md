# Stipe Drift Detection and Repair

## Problem

Stipe can install and doctor tools, but it cannot detect when config drifts from
what was installed. Hook paths, MCP server registrations, and generated config files
can go stale silently. Operators only discover drift when something breaks. Stipe
roadmap names "drift detection and repair" as its next priority after legacy burn-down.

## What exists (state)

- **`stipe doctor`:** checks binary availability and version currency; does NOT check config consistency
- **`stipe init`:** writes MCP registrations and hook paths; does NOT track what it wrote
- **Hook path check:** stale-hook-path handoff (lamella) adds post-install hook validation — stipe side
- **No drift baseline:** stipe doesn't record what a correct config looks like at install time

## What needs doing (intent)

Add a drift detection pass to `stipe doctor` that compares current config state
against expected state and surfaces discrepancies with repair hints.

---

### Step 1: Track what stipe init writes

**Project:** `stipe/`
**Effort:** 2 hours

After `stipe init` completes, write a baseline manifest to
`~/.local/share/stipe/init-baseline.json` recording:
- Each MCP server registration (name, binary path, args)
- Each hook entry (event, path, type)
- Each config file written (path, checksum)
- Timestamp

This baseline becomes the reference for drift detection.

#### Verification

```bash
cd stipe && cargo test init 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe init` writes baseline manifest after completion
- [ ] Baseline includes MCP registrations, hook paths, config checksums
- [ ] Re-running `stipe init` updates the baseline

---

### Step 2: Add drift detection to stipe doctor

**Project:** `stipe/`
**Effort:** 2-3 hours
**Depends on:** Step 1

In `stipe doctor`, load the baseline manifest (if present) and compare against
current state:
- MCP server entries: are they still registered? Do paths still exist?
- Hook entries: are they still in `~/.claude/settings.json`? Do paths exist?
- Config checksums: have config files been externally modified?

Surface discrepancies:

```
Config drift detected:
  ✗ Hook PostToolUse: registered path not found (/old/path/to/hook.js)
    → Run: stipe init --repair-hooks
  ✗ MCP rhizome: binary not found at registered path
    → Run: stipe install rhizome
  ~ Config ~/.claude/claude_desktop_config.json: modified since last init
    → Review or run: stipe init --force
```

#### Verification

```bash
cd stipe && cargo test doctor 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` reports stale hook paths
- [ ] `stipe doctor` reports missing MCP binary paths
- [ ] `stipe doctor` reports externally-modified config files
- [ ] No baseline → doctor skips drift check with a note (not an error)
- [ ] `stipe doctor --json` includes drift findings in JSON output

---

### Step 3: Add --repair flag to stipe init

**Project:** `stipe/`
**Effort:** 1 hour
**Depends on:** Step 2

`stipe init --repair` re-runs only the drifted items from the last drift check,
without touching already-correct config. Safe for repeated use.

**Checklist:**
- [ ] `--repair` only updates drifted items
- [ ] `--dry-run` shows what would change without applying
- [ ] Repair updates the baseline manifest on success

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd stipe && cargo test --all` passes

## Context

Stipe roadmap "Next" #2. `IMPROVEMENTS-OBSERVATION-V3.md` notes that lamella hook
staleness causes silent breakage on every version update — drift detection is the
systemic fix. Also addresses the stipe side of `lamella/stale-hook-path.md`.
