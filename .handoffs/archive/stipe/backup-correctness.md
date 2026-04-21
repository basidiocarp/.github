# Stipe: Fix backup correctness bugs

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none
- **Non-goals:** interactive flag TTY guard, tilde expansion, other quality fixes (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — pre_upgrade_backup_hyphae swallows directory creation error
`src/backup.rs:190-199`

`create_dir_all(...).map_err(|e| { warn!(...); e }).ok()` discards the error and continues. When the backup directory cannot be created (permissions denied, parent missing), the function proceeds to copy files into a nonexistent directory, silently skips them, then returns `Ok(Some(backup_dir))` as if the backup succeeded. The caller prints a success message with a path that contains no backup.

Fix: propagate the error or return `Ok(None)` when directory creation fails — do not continue past it.

### 2 — home_dir() falls back to CWD silently
`src/backup.rs:211`

`dirs::home_dir().unwrap_or_else(|| PathBuf::from("."))` silently substitutes the current working directory when `$HOME` is unset (common in containers and some CI environments). The hyphae database path then resolves to `./.local/share/hyphae/hyphae.db`, which almost certainly does not exist, so the database backup is silently skipped with no warning. Add a warning log and return `Ok(None)` (or an appropriate error) when home directory resolution fails.

## Implementation Seam

- **Likely file:** `src/backup.rs`
  - Line ~190: `create_dir_all` error handling
  - Line ~211: `dirs::home_dir()` fallback

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/stipe
cargo test 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

Expected: 227+ tests pass, clippy clean.

## Checklist

- [x] `create_dir_all` failure stops `pre_upgrade_backup_hyphae` and propagates/returns cleanly
- [x] Caller no longer prints a success message when the backup directory was never created
- [x] `home_dir()` failure emits a warning and returns early rather than silently substituting CWD
- [x] All tests pass

## Verification Output (2026-04-21)

```
cargo build --release: Finished `release` profile [optimized] target(s) in 34.12s
cargo test: test result: ok. 227 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.98s
cargo clippy: 41 pre-existing uninlined_format_args warnings only (none introduced by this change)
```
