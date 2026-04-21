# Stipe: Fix tar extraction path traversal risk

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none
- **Non-goals:** other install quality fixes (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

`src/commands/install/release.rs:173`

`entry.unpack_in(dest_dir)` is called after filtering on `file_name()` only. The `unpack_in` crate protects against absolute paths but not all path-traversal variants when the archive contains symlink entries whose target resolves outside `dest_dir`. A crafted release archive with a symlink or hardlink entry matching a binary name could write outside the temp directory before the binary-name whitelist check runs.

The whitelist check on `name_str` guards the final `binary_path` return value but does not prevent `unpack_in` from materialising a symlink first.

## Fix

Before calling `entry.unpack_in(dest_dir)`, check that the entry is a regular file:

```rust
use tar::EntryType;
let entry_type = entry.header().entry_type();
if !matches!(entry_type, EntryType::Regular | EntryType::Continuous) {
    continue; // skip symlinks, hardlinks, directories
}
```

After unpacking, additionally verify that the resolved path of the extracted file is still within `dest_dir` (check that `fs::canonicalize(extracted_path)?.starts_with(dest_dir)`).

## Implementation Seam

- `src/commands/install/release.rs` — the entry loop before `unpack_in`

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/stipe
cargo test 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [x] Non-regular tar entries (symlinks, hardlinks) are skipped before `unpack_in`
- [x] Extracted path is verified to remain within `dest_dir` after unpack
- [x] All tests pass, clippy clean

## Verification Output

```
cargo build --release: Finished `release` profile [optimized] target(s) in 32.15s
cargo test: test result: ok. 227 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.99s
cargo clippy: 39 pre-existing warnings (uninlined_format_args style), no new warnings
```
