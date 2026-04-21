# Hyphae Backup and Restore

## Problem

Hyphae's memory store is a SQLite database, so a failed migration, corrupted DB, or accidental purge can delete data permanently unless there is a reliable backup path.

## What was implemented

- `hyphae backup` now creates a timestamped copy in the Hyphae backup directory by default.
- `hyphae backup --list` now lists existing backups with size and modified time.
- `hyphae restore <file>` now validates the backup as SQLite and asks for confirmation before replacing the live DB.
- `hyphae consolidate` and `hyphae purge` now create an automatic pre-write backup unless `--no-backup` is passed.
- The CLI docs now describe the real backup, restore, and auto-backup behavior.

---

### Step 1: Add backup and restore CLI commands

**Project:** `hyphae/`
**Effort:** 1-2 hours
**Depends on:** nothing

Add to `hyphae-cli`:
- `hyphae backup [--output <path>] [--list]` - copies the live DB to the Hyphae backup directory by default and prints the backup path
- `hyphae restore <file>` - replaces the live DB with the given backup file after confirmation prompt
- `hyphae backup --list` - shows existing backups with size and date

#### Verification

```bash
cargo build -p hyphae-cli --no-default-features
cargo test -p hyphae-cli --no-default-features
```

**Output:**
<!-- PASTE START -->
`cargo build -p hyphae-cli --no-default-features`
`Finished \`dev\` profile [optimized + debuginfo] target(s) in 5.42s`

`cargo test -p hyphae-cli --no-default-features`
`test result: ok. 149 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.50s`
<!-- PASTE END -->

**Checklist:**

- [x] hyphae backup creates timestamped copy
- [x] hyphae backup --list lists backups
- [x] hyphae restore <file> validates SQLite before replacing
- [x] Restore requires confirmation
- [x] Build passes

---

### Step 2: Auto-backup before destructive operations

**Project:** `hyphae/`
**Effort:** 30 min
**Depends on:** Step 1

Before `hyphae consolidate` and `hyphae purge`, automatically run a backup unless `--no-backup` is passed. Print the backup path to stderr so the user knows where to restore from if needed.

**Checklist:**

- [x] hyphae consolidate auto-backs up first
- [x] hyphae purge auto-backs up first
- [x] --no-backup skips it
- [x] Backup path printed to stderr

#### Verification

```bash
HOME=/tmp/hyphae-backup-restore-home-4601 ./target/debug/hyphae --db /tmp/hyphae-backup-restore.db store --topic backup-test --content hello
HOME=/tmp/hyphae-backup-restore-home-4601 ./target/debug/hyphae --db /tmp/hyphae-backup-restore.db backup
HOME=/tmp/hyphae-backup-restore-home-4601 ./target/debug/hyphae backup --list
printf 'y\n' | HOME=/tmp/hyphae-backup-restore-home-4601 ./target/debug/hyphae --db /tmp/hyphae-backup-restore-restored.db restore /tmp/hyphae-backup-restore-home-4601/Library/Application Support/hyphae/backups/hyphae-backup-20260410-003553-395.db
```

**Output:**
<!-- PASTE START -->
`Memory stored`
`Backup created: /tmp/hyphae-backup-restore-home-4601/Library/Application Support/hyphae/backups/hyphae-backup-20260410-003553-395.db`
`Backups in /tmp/hyphae-backup-restore-home-4601/Library/Application Support/hyphae/backups:`
`This will replace the current database at /tmp/hyphae-backup-restore-restored.db with /tmp/hyphae-backup-restore-home-4601/Library/Application Support/hyphae/backups/hyphae-backup-20260410-003553-395.db.`
`Database restored from /tmp/hyphae-backup-restore-home-4601/Library/Application Support/hyphae/backups/hyphae-backup-20260410-003553-395.db`
`Location: /tmp/hyphae-backup-restore-restored.db`
<!-- PASTE END -->

## Completion Protocol

- [x] All step verification output pasted
- [x] `cargo build --no-default-features` passes
- [x] `hyphae backup && hyphae backup --list` works end-to-end
- [x] the verification output is pasted into this handoff

## Context

From `.plans/remaining-gaps.md` P1.2. The DB is the only copy of all memories, so one failed migration or purge should not mean data loss.
