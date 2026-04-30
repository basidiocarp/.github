# Stipe: Move package_repair Backups Out of Harness-Loaded Paths

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/package_repair.rs` and any related test fixtures or helpers; possibly a new module like `stipe/src/commands/backup_root.rs` if the implementation calls for it
- **Cross-repo edits:** none — this is internal to stipe
- **Non-goals:** does not change the package_repair operation itself (what files are backed up, when, and why); does not change the rollback contract; does not move existing live backups already on operator machines
- **Verification contract:** `bash .handoffs/stipe/verify-backup-path-out-of-harness-load-tree.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem

`stipe/src/commands/package_repair.rs:364-371` `sibling_backup_path` puts every backup directly next to the original path:

```rust
fn sibling_backup_path(path: &Path, timestamp: u64, index: usize) -> PathBuf {
    let suffix = format!(".stipe-backup-{timestamp}-{index}");
    let file_name = path.file_name().and_then(|v| v.to_str()).unwrap_or("state");
    path.with_file_name(format!("{file_name}{suffix}"))
}
```

When stipe backs up content inside a directory another tool walks recursively as input — anywhere under `~/.claude/`, in particular — the sibling backup lands inside that walked tree. **Claude Code's harness loads `~/.claude/{rules,skills,hooks,commands,plugins,agents}/**` as user-private global instructions**. Every package_repair run that touches one of these paths writes a sibling backup that the harness then loads as duplicate content. The blast radius is most of the harness-loaded surface, not just rules: skills, hooks, plugins, commands, and agents are all affected.

User confirmation: "the bug creates duplicate backups across most of `.claude` settings."

This is a stipe-side bug. The harness is doing the right thing. Stipe should not be parking backups inside paths other tools treat as input.

### Existing convention

Stipe already has the right pattern in another code path. `stipe/src/backup.rs` (lines 61-121, lines 220-247) creates per-event backup directories under a dedicated root with a `manifest.json`:

```text
~/.claude/backups/<timestamp>-pre-<reason>/<original-relative-path>/
```

`~/.claude/backups/` is outside the harness load tree (the harness loads `~/.claude/{rules,skills,hooks,...}/` but not `~/.claude/backups/`). The fix is to converge package_repair on **this same convention** — or a sibling helper inside `backup.rs` if the exact shape needs to differ — rather than inventing a new backup location. That keeps stipe's two backup mechanisms aligned.

## Scope

- **Primary seam:** the backup path computation in `package_repair.rs`
- **Allowed files:** `package_repair.rs` (and any extracted helper); related tests/fixtures
- **Explicit non-goals:**
  - Moving live backups already on operator disks (out of scope; one-time cleanup script can be a separate handoff)
  - Changing rollback semantics (rollback must still restore from wherever the backup now lives)
  - Adding a CLI command to clean up old backups (separate handoff if wanted)

## Step 1 — Reuse the existing `stipe::backup` convention

Don't invent a new backup root. Read `stipe/src/backup.rs` lines 61-121 and 220-247 to understand the existing pattern: backups go under `~/.claude/backups/<timestamp>-<descriptor>/<original-relative-path>/` and carry a `manifest.json` describing what was backed up.

Two reasonable shapes for the package_repair fix:

- **Shape A — Reuse `backup.rs` directly.** If `backup.rs` exposes (or can be lightly extended to expose) a public API like `prepare_backup_root(reason: &str) -> Result<PathBuf>`, package_repair calls into it once at the start of each repair operation and gets a per-run root. This keeps the manifest convention consistent.
- **Shape B — Local helper in package_repair.** If reusing `backup.rs` is awkward (different lifecycle, different rollback semantics), introduce a small `package_repair_backup_root(timestamp) -> PathBuf` helper that produces `~/.claude/backups/<timestamp>-pre-package-repair/` (without a manifest if the existing `PackageBackup { original, backup }` struct is sufficient).

Default to **Shape A** if `backup.rs` already supports it; otherwise **Shape B**. Either way, the backup root MUST live under `~/.claude/backups/` (or a sibling outside the harness load tree such as `~/.local/share/stipe/backups/`), never inside `~/.claude/{rules,skills,hooks,commands,plugins,agents}/`.

Make the root override-able via `STIPE_BACKUP_ROOT` env var for testability.

## Step 2 — Adjust path computation

Replace `sibling_backup_path` with a function that takes the original path and produces a path under the backup root, preserving enough of the original path structure to make rollback unambiguous.

Suggested shape:

```rust
fn backup_path(original: &Path, timestamp: u64, index: usize) -> PathBuf {
    let root = backup_root();  // dirs::data_dir().join("stipe/backups")
    let bucket = format!("{timestamp}-{index}");
    // Use a flattened name that captures the original location for rollback.
    // E.g. "/Users/me/.claude/rules/rules" → "users-me--claude-rules-rules"
    let flattened = flatten_path_for_storage(original);
    root.join(bucket).join(flattened)
}

fn backup_root() -> PathBuf {
    if let Ok(override_path) = std::env::var("STIPE_BACKUP_ROOT") {
        return PathBuf::from(override_path);
    }
    dirs::data_dir()
        .unwrap_or_else(|| dirs::home_dir().unwrap().join(".local/share"))
        .join("stipe/backups")
}
```

Critical: the rollback path needs to know the original location to restore correctly. Option A — store both `original` and `backup` paths in the existing `PackageBackup` struct (already done — the struct has both fields). So rollback continues to work as long as the move operation populates both fields correctly. No structural change to rollback logic.

## Step 3 — Ensure parent directory exists

The current `fs::rename` works because the destination's parent is the source's parent (already exists). Under Option A, the destination's parent is a fresh per-bucket directory. Add `fs::create_dir_all(backup.parent().unwrap())?` before the rename.

## Step 4 — Update tests

`package_repair.rs:739` has a test `backup.ends_with("example.stipe-backup-1234-2")` — that assertion is anchored to the old layout and must change. Update it to assert the new layout: backup path is under the bucket dir, with the original filename or flattened-original-path embedded.

Add a test that:
- Creates a temp original file in a fake "harness-loaded" dir.
- Runs the backup operation (use `STIPE_BACKUP_ROOT=<temp dir>` to keep the test hermetic).
- Asserts the backup is at the expected new location AND that the original parent directory contains no `*.stipe-backup-*` siblings.

## Step 5 — Doc-only sanity check

If stipe's user-facing doc anywhere claims "backups are placed alongside the original" — update it. Search:

```bash
grep -rn "stipe-backup\|sibling_backup" stipe/ --include='*.md' --include='*.rs'
```

## Step 6 — Lint + test

```bash
cd stipe && cargo test --release && cargo clippy
```

## Verify Script

`bash .handoffs/stipe/verify-backup-path-out-of-harness-load-tree.sh` confirms:
- `sibling_backup_path` no longer exists, OR is no longer used to compute the production backup destination
- A backup-root function references `dirs::data_dir()` or `STIPE_BACKUP_ROOT` env var
- `cargo test` passes
- Test fixtures don't assert the old `<file>.stipe-backup-*` pattern in production paths

## Context

User-reported issue: stipe backups under `~/.claude/rules/rules.stipe-backup-<ts>-<n>/` get loaded by the Claude Code harness as duplicate user-private global instructions, bloating every conversation's context. Confirmed by inspecting the active session's system prompt, which contained both `~/.claude/rules/rust/api-parse-dont-validate.md` and `~/.claude/rules/rules.stipe-backup-1776488551-1/rust/api-parse-dont-validate.md` (identical content).

This is a Tier D-equivalent operator-loop hygiene bug: stipe is a setup/repair tool, the broken behavior is contained to the package_repair flow, and the impact is "every model session pays the cost" rather than "system breaks". Worth a focused fix once the current audit campaign settles.

## Style Notes

- Keep the rollback contract intact: `PackageBackup { original, backup }` already records both paths, so rollback should keep working with the new layout.
- Don't migrate existing live backups on operator machines as part of this change — that's a one-time operator action or a separate cleanup-script handoff.
- If `dirs` crate isn't already in stipe's dependencies, prefer extracting a small helper with `home_dir() + ".local/share"` rather than adding the crate just for this.
- The `STIPE_BACKUP_ROOT` env var is mainly for tests; document it in a one-line comment but don't add a full operator-facing flag.
