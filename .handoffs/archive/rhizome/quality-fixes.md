# Rhizome: Quality fixes (hover stub, ref injection, path traversal, DefaultHasher)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** rhizome/...
- **Cross-repo edits:** none
- **Non-goals:** graph data integrity (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — `get_hover_info` registered but always errors (HIGH)
`crates/rhizome-mcp/src/tools/file_tools.rs:193`

`get_hover_info` is exposed as a registered MCP tool but always returns a static
error string regardless of input. Callers get no useful feedback related to their
actual `file`, `line`, or `column` values. Either remove it from `tool_schemas()` at
line 54, or add a schema annotation marking it as unimplemented.

### 2 — Git ref arguments allow flag injection (HIGH)
`crates/rhizome-mcp/src/tools/symbol_tools/git.rs:26-44`

`get_diff_symbols` and `get_changed_files` pass user-supplied `ref1` and `ref2`
directly as positional arguments to `Command::new("git")` without validation.
A crafted value like `--exec=cmd` would be treated as a git flag. The `file_filter`
argument at line 41 is correctly separated with `--`, but `ref1`/`ref2` are not.

Fix: validate that `ref1`/`ref2` match a safe git ref pattern
(`^[a-zA-Z0-9/_\-\.~^@{} ]+$` or similar) before passing them.

### 3 — `DefaultHasher` unstable for cache keys (HIGH)
`crates/rhizome-core/src/export_cache.rs:147`

`DefaultHasher` is not guaranteed stable across Rust versions. Cache file names
derived from it become stale after a toolchain upgrade, forcing full re-export with
no warning. Replace with a stable hasher (e.g. FNV, or SHA-256 truncated).

### 4 — `get_diagnostics` skips path-traversal check (MEDIUM)
`crates/rhizome-mcp/src/tools/file_tools.rs:160-169`

`get_diagnostics` passes the raw `file` path to `Path::new(file)` without calling
`resolve_path`. Every other tool in `edit_tools.rs` and `symbol_tools/` calls
`resolve_path` or `resolve_project_path`. Add the same check here to enforce the
containment boundary.

### 5 — Low items
- `parser.rs:55` — `.unwrap()` after guaranteed insert; use `expect("just inserted")`
- `graph.rs:74-79` — `module_name_from_path` falls back to `"unknown"`, causing
  node collision for multiple unnamed-stem files; use a unique fallback (path hash)
- `inspection.rs:196-199` — byte-index slicing on uppercased vs original string
  for annotation extraction; may panic on multi-byte annotation tag characters
- `mod.rs:68` — `RhizomeConfig::load(...).unwrap_or_default()` silently discards
  config parse errors; log at `warn` before falling back

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/rhizome
cargo test --all 2>&1 | tail -5
cargo clippy --all 2>&1 | tail -10
```

## Checklist

- [ ] `get_hover_info` removed from schema registry or explicitly marked unimplemented
- [ ] `ref1`/`ref2` validated before passing to git command
- [ ] `DefaultHasher` in `export_cache.rs` replaced with stable hasher
- [ ] `get_diagnostics` calls `resolve_path` before opening file
- [ ] Low items addressed
- [ ] All tests pass, clippy clean
