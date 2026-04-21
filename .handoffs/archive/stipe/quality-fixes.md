# Stipe: Quality fixes (TTY guard, tilde expansion, file_name, low items)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none
- **Non-goals:** backup correctness bugs (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — No TTY guard on --interactive
`src/commands/init/seed.rs:144-155`

`stipe init --interactive` issues prompts with no check that stdin is a terminal. On a pipe where stdin is open but nothing is written, the process hangs indefinitely. Add an `isatty` check (e.g., via the `atty` or `is-terminal` crate) before entering the interactive prompt loop and return a clear error if stdin is not a terminal.

### 2 — STIPE_BACKUP_DIR tilde not expanded
`src/backup.rs:36-43`

`PathBuf::from(env::var("STIPE_BACKUP_DIR")?)` uses the value verbatim. `~/backups` becomes a directory literally named `~/backups` relative to CWD. Either document that the value must be an absolute path (in the env var description and help text), or apply tilde expansion using `dirs::home_dir()`.

### 3 — file_name().unwrap_or_default() silent failure
`src/backup.rs:67` and `src/backup.rs:83`

`path.file_name().unwrap_or_default()` uses an empty `OsStr` when the path has no filename component. `bin_dir.join(OsStr::new(""))` resolves to `bin_dir` itself, so `fs::copy` would overwrite the directory or fail with a misleading error. Validate that `file_name()` is `Some` and log+skip the entry (or return an error) if it is `None`.

### 4 — FNV-1a comment is misleading
`src/backup.rs:162-168`

The `hash_checksum` function uses 64-bit FNV-1a constants (offset basis and prime) but accumulates into a `u128`. The comment says "FNV-1a hash" but the result is not a compliant FNV-1a 128-bit hash. Correct the comment to describe what it actually is (a non-standard 64-bit FNV-1a folded into u128) or switch to a proper implementation.

### 5 — Epoch timestamp sort is implicit
`src/backup.rs:173-176`

Backup directories are sorted lexicographically to find the newest. This works for 10-digit epoch strings but is fragile by design. Change to an ISO-8601 timestamp (`YYYY-MM-DDTHH-MM-SS`) which sorts correctly by design and is human-readable.

### 6 — Useless test
`src/commands/backup.rs:54-57`

`test_backup_hyphae_function_defined` contains only `assert!(true)`. Delete it or replace with a meaningful assertion.

## Implementation Seam

- `src/commands/init/seed.rs:144` — TTY check before interactive prompts
- `src/backup.rs:36` — tilde expansion or documentation
- `src/backup.rs:67,83` — file_name None guard
- `src/backup.rs:162` — comment fix
- `src/backup.rs:173` — timestamp format change (note: changes backup directory naming; check `list_backups` sort and any callers that parse the name)
- `src/commands/backup.rs:54` — delete useless test

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/stipe
cargo test 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [x] `--interactive` TTY guard added (seed.rs — prior session)
- [x] `STIPE_BACKUP_DIR` tilde expansion implemented (backup.rs)
- [x] `file_name()` failures handled with early continue (backup.rs:77, 96)
- [x] FNV-1a comment corrected to describe actual behavior
- [ ] Timestamp format (epoch → ISO-8601) — skipped; touches sort logic and callers, deferred
- [x] Useless test removed (commands/backup.rs)
- [x] All tests pass (226 pass)
