# Rhizome Path Traversal Fix

## Problem

`resolve_path` in `edit_tools.rs` resolves relative paths against `project_root` without
validating the result stays within the project root. An MCP tool call with
`file: "../../etc/passwd"` can write to arbitrary files. All 10 write-capable tools
(replace_lines, insert_at_line, delete_lines, create_file, replace_symbol_body,
insert_after_symbol, insert_before_symbol, copy_symbol, move_symbol, rename_symbol)
are affected. This is a security vulnerability.

## What exists (state)

- **File:** `rhizome/crates/rhizome-mcp/src/tools/edit_tools.rs:214`
- **Function:** `resolve_path(file: &str, project_root: &str) -> PathBuf`
- **Behavior:** Joins `project_root` + `file`, returns absolute path, no validation
- **rename_symbol** in `file_tools.rs` also writes via LSP workspace edits

## What needs doing (intent)

Add path containment validation to `resolve_path` so that resolved paths must
be descendants of `project_root`. Apply the check consistently across all write tools.

---

### Step 1: Add path containment guard to resolve_path

**Project:** `rhizome/`
**Effort:** 30 min
**Depends on:** nothing

Add a validation function and apply it in `resolve_path`:

#### Files to modify

**`crates/rhizome-mcp/src/tools/edit_tools.rs`** — add containment check:

```rust
fn ensure_within_project_root(resolved: &Path, project_root: &Path) -> Result<(), RhizomeError> {
    let canonical_resolved = resolved.canonicalize()
        .or_else(|_| {
            // File may not exist yet (create_file). Canonicalize parent.
            resolved.parent()
                .ok_or_else(|| RhizomeError::Other("no parent directory".into()))
                .and_then(|p| p.canonicalize().map_err(|e| RhizomeError::Io(e)))
                .map(|p| p.join(resolved.file_name().unwrap_or_default()))
        })?;
    let canonical_root = project_root.canonicalize()
        .map_err(|e| RhizomeError::Io(e))?;

    if !canonical_resolved.starts_with(&canonical_root) {
        return Err(RhizomeError::Other(format!(
            "path '{}' escapes project root '{}'",
            resolved.display(), project_root.display()
        )));
    }
    Ok(())
}
```

Update `resolve_path` to call this guard and return `Result<PathBuf, RhizomeError>`.
Update all callers to propagate the error.

**`crates/rhizome-mcp/src/tools/file_tools.rs`** — add same guard to `rename_symbol`
where it constructs file paths for LSP workspace edits.

#### Verification

```bash
cd rhizome && cargo test --all 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `resolve_path` returns `Result<PathBuf, RhizomeError>`
- [ ] All 10 write tools propagate the error
- [ ] `rename_symbol` in file_tools.rs also validates paths
- [ ] Test: relative path `../../etc/passwd` returns error, not a valid path
- [ ] Test: valid relative path `src/main.rs` resolves successfully
- [ ] Test: absolute path outside project root returns error

---

### Step 2: Add targeted tests for path traversal

**Project:** `rhizome/`
**Effort:** 15 min
**Depends on:** Step 1

Add tests in `edit_tools.rs` or a new test module:

```rust
#[test]
fn rejects_path_traversal_above_project_root() {
    let project_root = std::env::temp_dir().join("rhizome-test-project");
    std::fs::create_dir_all(&project_root).unwrap();
    let result = resolve_path("../../etc/passwd", project_root.to_str().unwrap());
    assert!(result.is_err());
    let _ = std::fs::remove_dir_all(&project_root);
}

#[test]
fn accepts_valid_relative_path() {
    let project_root = std::env::temp_dir().join("rhizome-test-project2");
    std::fs::create_dir_all(project_root.join("src")).unwrap();
    std::fs::write(project_root.join("src/main.rs"), "fn main() {}").unwrap();
    let result = resolve_path("src/main.rs", project_root.to_str().unwrap());
    assert!(result.is_ok());
    let _ = std::fs::remove_dir_all(&project_root);
}
```

#### Verification

```bash
cd rhizome && cargo test path_traversal 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Path traversal test exists and passes
- [ ] Valid path test exists and passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. No write tool can access files outside project root

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of rhizome.
This is the highest-priority finding from the audit. See `ECOSYSTEM-AUDIT-2026-04-04.md` C1.
