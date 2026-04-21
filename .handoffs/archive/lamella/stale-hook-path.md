# Lamella Stale Hook Path Validation

## Problem

When lamella is updated, hook scripts in `~/.claude/settings.json` may reference
old paths that no longer exist. There is no post-install validation that checks
whether the registered hook paths are still valid. Silent breakage on every lamella
version update — hooks fail silently and cortina signals stop flowing without any
diagnostic output.

Mycelium made progress on its own hook staleness detection (v0.5.1) with `mycelium
doctor` surfacing stale embedded paths. Lamella has no equivalent.

## What exists (state)

- **`~/.claude/settings.json`:** hook entries with absolute paths to lamella scripts
- **No validation:** `lamella install` does not verify post-install that paths exist
- **`stipe doctor`:** general health check, but does not specifically check hook path validity for lamella hooks
- **`mycelium doctor`:** surface for stale mycelium paths — the model to follow

## What needs doing (intent)

Add post-install hook path validation to lamella, and surface stale paths in
`stipe doctor` output.

---

### Step 1: Add post-install validation to lamella install

**Project:** `lamella/`
**Effort:** 1 hour

After `lamella install` (or `./install.sh`) writes hook paths to
`~/.claude/settings.json`, verify that each registered hook path exists on disk.
If any path is missing, print a warning:

```
WARNING: Hook path not found after install: /path/to/script.js
  Run `lamella install` again or check your installation.
```

#### Files to modify

**`lamella/scripts/plugins/install-plugin.sh`** or **`lamella/install.sh`** — add post-install check.

#### Verification

```bash
cd lamella && bash install.sh core 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Post-install check runs after writing hook paths
- [ ] Warning printed for any path that doesn't exist on disk
- [ ] Clean install shows no warnings

---

### Step 2: Add hook path check to stipe doctor

**Project:** `stipe/`
**Effort:** 1 hour
**Depends on:** Step 1

Add a health check in `stipe doctor` that reads `~/.claude/settings.json`,
finds all hook entries, and verifies each path exists. Surface as:

```
Hooks:
  ✓ PreToolUse: /path/to/hook.js
  ✗ PostToolUse: /old/path/to/hook.js (not found)
```

#### Verification

```bash
cd stipe && cargo test doctor 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` shows hook path validity
- [ ] Stale paths flagged with ✗ and the path that's missing
- [ ] Valid paths show ✓

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `stipe doctor` surfaces stale hook paths

## Context

`ECOSYSTEM-OVERVIEW.md` gap #9 (lamella stale hook path bug #1). Also noted in
`IMPROVEMENTS-OBSERVATION-V3.md`. Mycelium's hook staleness detection (v0.5.1)
is the prior art to follow.
