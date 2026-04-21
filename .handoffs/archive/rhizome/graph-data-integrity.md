# Rhizome: Fix code graph data integrity (node collision, edge corruption, pub label)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** rhizome/...
- **Cross-repo edits:** none
- **Non-goals:** rhizome quality fixes (separate handoff), septa schema changes
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

All three issues corrupt the code graph that Hyphae stores. They are false-data bugs,
not just quality issues.

### 1 — Node name collision silently loses symbol metadata (CRITICAL)
`crates/rhizome-core/src/graph.rs:139`

`process_symbols` uses `symbol.name` as the node identity. Two functions with the same
name in different files (e.g. `new`, `from`, `default`, `process`) produce nodes with
the same `name`. In `merge_graphs` (line 214), deduplication is also name-based: the
first node wins and the second is silently dropped. Hyphae may store wrong `file_path`
or `line_start` for any symbol that shares a name with another.

Fix: use `symbol.qualified_name()` (which includes the scope path) or `stable_id()`
as the node name so the uniqueness invariant is satisfied.

### 2 — `merge_graphs` deduplication creates dangling edges (CRITICAL)
`crates/rhizome-core/src/graph.rs:214`

Because node names are not unique (issue #1), the `seen_names` set retains the first
occurrence. Edges may be retained whose source/target names refer to a dropped node,
creating dangling edges that Hyphae consumes with wrong semantics. Fix this by
resolving node uniqueness (issue #1) first; the edge logic becomes correct once nodes
are uniquely identified.

### 3 — `sig.starts_with("pub")` incorrectly labels symbols (CRITICAL)
`crates/rhizome-core/src/graph.rs:121-127`

`sig.starts_with("pub")` matches `pub_key`, `publish`, `public_api`, etc. Any symbol
whose signature text starts with the substring "pub" but is not actually a Rust `pub`
visibility specifier will be incorrectly labelled as public in the exported graph.

The correct guard is already used in `export_tools.rs:383`:
```rust
sig.starts_with("pub ") || sig.starts_with("pub(")
```
Apply the same two-pattern check here.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/rhizome
cargo test --all 2>&1 | tail -5
cargo clippy --all 2>&1 | tail -10
```

Expected: all tests pass. The fix for node collision requires a test that exports a
project with same-named symbols in different files and verifies both nodes appear in
the graph.

## Checklist

- [ ] `process_symbols` uses qualified name or stable ID as node identity
- [ ] `merge_graphs` correctly deduplicates and validates edges with the new identity
- [ ] `sig.starts_with("pub")` replaced with `starts_with("pub ") || starts_with("pub(")`
- [ ] Test coverage for same-named symbols across files
- [ ] All tests pass, clippy clean
