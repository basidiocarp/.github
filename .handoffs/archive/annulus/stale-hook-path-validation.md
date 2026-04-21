# Lamella Stale Hook Path Bug

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

Lamella installs hooks by writing absolute paths into `~/.claude/settings.json`.
When lamella is updated or reinstalled to a different path, those absolute paths
go stale and the hooks silently stop firing. There is no post-install validation
that checks whether the installed hook paths still point to existing, executable
files. Mycelium fixed its own variant of this bug in v0.5.1; lamella's issue is
still open.

## What exists (state)

- **Mycelium v0.5.1**: ships hook install diagnostics — surfaces stale embedded
  paths and missing runtime dependencies explicitly instead of silent failure. The
  same pattern needs to land in lamella
- **`~/.claude/settings.json`**: Claude Code's hook configuration; lamella writes
  absolute paths here during install
- **`stipe doctor`**: checks ecosystem health; does not currently check hook path
  staleness
- **`lamella/scripts/hooks/`**: the actual hook executables whose paths get embedded

## What needs doing (intent)

Add post-install validation that checks all hook paths written to
`~/.claude/settings.json` and reports stale paths explicitly. Wire the same check
into `stipe doctor` so hook staleness is surfaced in routine health checks.

---

### Step 1: Implement hook path staleness checker in lamella

**Project:** `lamella/`
**Effort:** 1 day
**Depends on:** nothing

Add a `lamella validate-hooks` command (or extend `make validate`) that:

1. Reads `~/.claude/settings.json` and extracts all hook `command` entries
2. For each command that starts with a path (not a bare executable name), checks:
   - The file exists
   - The file is executable
   - The path is inside the current lamella install directory
3. Reports stale paths clearly:
   ```
   [STALE] ~/.claude/settings.json: hook "Stop" → /old/path/session-end.js (not found)
   [STALE] ~/.claude/settings.json: hook "PostToolUse" → /old/path/post-tool.js (not executable)
   [OK]    ~/.claude/settings.json: hook "PreToolUse" → /current/path/pre-tool.js
   ```
4. Exits non-zero if any stale paths are found

#### Files to modify

**`lamella/scripts/validate-hooks.js`** (new) or equivalent Python:

```javascript
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const os = require('os');

const settingsPath = path.join(os.homedir(), '.claude', 'settings.json');

function validateHooks() {
  const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
  const hooks = settings.hooks ?? {};
  let staleCount = 0;
  for (const [event, entries] of Object.entries(hooks)) {
    for (const entry of (Array.isArray(entries) ? entries : [entries])) {
      const cmd = entry.command ?? entry;
      const hookPath = cmd.split(' ')[0];
      if (hookPath.startsWith('/')) {
        const exists = fs.existsSync(hookPath);
        const executable = exists && (fs.statSync(hookPath).mode & 0o111) !== 0;
        if (!exists || !executable) {
          console.error(`[STALE] ${event} → ${hookPath} (${!exists ? 'not found' : 'not executable'})`);
          staleCount++;
        } else {
          console.log(`[OK]    ${event} → ${hookPath}`);
        }
      }
    }
  }
  process.exit(staleCount > 0 ? 1 : 0);
}

validateHooks();
```

#### Verification

```bash
cd lamella && node scripts/validate-hooks.js 2>&1
make validate 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
[OK]    No absolute hook paths configured to validate
WARN: writing/writing-voice/SKILL.md - missing recommended '## Workflow' section
Validated 297 Lamella skill packages and 52 manifest alignments (221 warnings)
Skill package validator and scaffold checks passed
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (560 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.
<!-- PASTE END -->

**Checklist:**
- [x] `validate-hooks.js` reads hook paths from `~/.claude/settings.json`
- [x] Stale paths reported with clear `[STALE]` prefix
- [x] Valid paths reported with `[OK]` prefix
- [x] Exit code is non-zero when stale paths found
- [x] `make validate` runs the hook validation check

---

### Step 2: Run hook path check on lamella install/update

**Project:** `lamella/`
**Effort:** 1–2 hours
**Depends on:** Step 1

Call `validate-hooks.js` at the end of the lamella install flow. If stale paths
are found, print a warning with instructions:

```
Warning: stale hook paths found in ~/.claude/settings.json
Run: lamella install --repair  (or stipe update --repair) to fix
```

Do not fail the install — only warn. The repair flow is a separate step.

#### Verification

```bash
cd lamella && bash scripts/ci/check-hook-health.sh 2>&1
```

**Output:**
<!-- PASTE START -->
[OK]    No absolute hook paths configured to validate
<!-- PASTE END -->

**Checklist:**
- [x] Install flow runs hook validation
- [x] Stale path warning printed during install (not a hard failure)
- [x] Warning includes repair command

---

### Step 3: Wire into stipe doctor

**Project:** `stipe/`
**Effort:** 2–4 hours
**Depends on:** Step 1

Add a `lamella hook paths` check to `stipe doctor`. When lamella is installed,
`stipe doctor` should call the lamella hook validation and surface any stale paths
alongside other health checks.

Follow the same pattern as the mycelium hook staleness check that already exists
in stipe doctor.

#### Verification

```bash
cd stipe && cargo build --workspace 2>&1 | tail -5
cd stipe && cargo test 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->
warning: `stipe` (bin "stipe") generated 2 warnings
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 2.90s
test result: ok. 187 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.77s
<!-- PASTE END -->

**Checklist:**
- [x] `stipe doctor` checks lamella hook path staleness
- [x] Stale hook paths reported in doctor output
- [x] Check is skipped gracefully when lamella is not installed
- [x] Build passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `make validate` in lamella runs hook path validation
3. `stipe doctor` surfaces hook staleness
4. All checklist items are checked

### Final Verification

```bash
cd lamella && node scripts/validate-hooks.js 2>&1
cd lamella && bash scripts/ci/check-hook-health.sh 2>&1
cd lamella && make validate 2>&1 | tail -5
cd stipe && cargo build --workspace 2>&1 | tail -3
cd stipe && cargo test 2>&1 | tail -3
```

**Output:**
<!-- PASTE START -->
[OK]    No absolute hook paths configured to validate
[OK]    No absolute hook paths configured to validate
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.
warning: `stipe` (bin "stipe") generated 2 warnings
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 2.90s
test result: ok. 187 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.77s
<!-- PASTE END -->

**Required result:** validate passes; check-hook-health passes; stipe builds and tests pass. ✓ PASS

## Context

Gap #9 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Mycelium v0.5.1 fixed the
equivalent bug and the pattern is documented there. The core issue is that lamella
writes absolute paths into `~/.claude/settings.json` at install time and never
checks whether they're still valid. Silent hook breakage is the worst kind —
operators don't discover it until they notice that sessions are missing signals.
