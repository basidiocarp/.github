# Safe Install and Rollback

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`stipe install` and `stipe update` have no backup, lock, or rollback mechanism. If an update fails mid-way, the ecosystem can be left in an inconsistent state — some binaries at the new version, others at the old, and host config partially rewritten. There is no way to recover without manually reverting each affected file. Multiple audits (skill-manager, forgecode, claurst) point to safe install flows with explicit backup, lock, and rollback as a baseline expectation.

## What exists (state)

- **`stipe install`**: installs binaries and configures hosts. No backup of prior state.
- **`stipe update`**: updates binaries. No rollback on failure.
- **`stipe --dry-run`**: shows what would change but does not help with recovery after a failed install.
- **No lockfile**: concurrent install or update operations are not prevented.
- **No backup manifest**: there is no record of the pre-install state to restore from.

## What needs doing (intent)

Three independent pieces: pre-install backup that snapshots binary versions, config, and paths into a timestamped manifest; a rollback command that restores from a backup; and an install lockfile that prevents concurrent operations. Each piece ships independently and adds value incrementally.

---

### Step 1: Add pre-install backup

**Project:** `stipe/`
**Effort:** 1 day
**Depends on:** nothing

Before any `stipe install` or `stipe update` operation mutates the filesystem, snapshot the current state into a backup manifest.

Backup layout:
- Manifest at `~/.local/share/stipe/backups/<timestamp>/manifest.json`
- Binary copies at `~/.local/share/stipe/backups/<timestamp>/bin/`
- Host config snapshots at `~/.local/share/stipe/backups/<timestamp>/config/`

The manifest records: timestamp, stipe version, binary versions and paths, config file paths and checksums. The backup directory is configurable via `STIPE_BACKUP_DIR` env var.

Backup must complete before any mutation begins. If the backup itself fails, the install is aborted with a clear error.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Finished `release` profile [optimized] target(s) in 0.26s
test result: ok. 220 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 1.14s
<!-- PASTE END -->

**Checklist:**
- [x] Backup manifest written before install or update begins
- [x] Binary copies stored under timestamped backup directory
- [x] Host config state recorded (file paths and checksums)
- [x] Backup directory is configurable via `STIPE_BACKUP_DIR`
- [x] Failed backup aborts the install with a clear error message
- [x] Build and tests pass

---

### Step 2: Add rollback command

**Project:** `stipe/`
**Effort:** 1 day
**Depends on:** Step 1

`stipe rollback` restores from the most recent backup. `stipe rollback --to <timestamp>` restores from a specific backup. `stipe rollback --list` lists available backups with timestamps.

Rollback sequence:
1. Validate the backup manifest is intact
2. Restore binaries from backup copies
3. Restore host config files from backup copies
4. Run `stipe doctor` automatically to verify the restored state
5. Print a summary: what was restored and the doctor result

The backup is retained after rollback (not deleted). This allows re-rollback or inspection.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Finished `release` profile [optimized] target(s) in 0.26s
test result: ok. 220 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 1.14s
<!-- PASTE END -->

**Checklist:**
- [x] `stipe rollback` restores from the most recent backup
- [x] `stipe rollback --to <timestamp>` restores from a named backup
- [x] `stipe rollback --list` shows available backups with timestamps
- [x] Doctor runs automatically after rollback to verify state
- [x] Backup is retained (not deleted) after rollback
- [x] Build and tests pass

---

### Step 3: Add install lockfile

**Project:** `stipe/`
**Effort:** 4-8 hours
**Depends on:** nothing

Prevent concurrent install or update operations with a lockfile at `~/.local/share/stipe/install.lock`. The lock must be acquired before any mutation and released on completion, whether the operation succeeds or fails.

Stale lock detection: a lock older than 10 minutes is considered stale. Stipe reports the stale lock, asks the user to confirm before overriding, and skips the prompt when `--force` is passed.

The lockfile records the PID and timestamp of the locking process so users can inspect which process holds it.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Finished `release` profile [optimized] target(s) in 0.26s
test result: ok. 220 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 1.14s
<!-- PASTE END -->

**Checklist:**
- [x] Lockfile acquired before any install or update mutation
- [x] Second concurrent `stipe install` fails with a clear message naming the lock holder
- [x] Stale lock (>10 min) detected and reported with override prompt
- [x] `--force` skips the override prompt
- [x] Lock released on completion (success or failure)
- [x] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-safe-install-rollback.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/stipe/verify-safe-install-rollback.sh
```

**Output:**
<!-- PASTE START -->
PASS: backup module exists
PASS: lockfile module exists
PASS: rollback command exists
PASS: backup wired into install or update
PASS: lockfile wired into install or update
PASS: stipe tests pass
Results: 6 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DN-3 (stipe side). Skill-manager audit identifies safe update and rollback mechanics as a baseline expectation for any plugin manager. Forgecode audit points to install flows with explicit backup before mutation. Claurst audit reinforces safe update discipline at the provider and plugin layer. The lamella validation side of this gap is covered by lamella handoff #10 — this handoff covers the stipe install and recovery mechanics that complement that validation work.
