# Rhizome: Code Graph Contract And Install Boundary

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/crates/rhizome-core/src/graph.rs`, `rhizome/crates/rhizome-core/src/hyphae.rs`, `rhizome/crates/rhizome-core/src/backend_selector.rs`, `rhizome/crates/rhizome-core/src/installer.rs`, `rhizome/crates/rhizome-cli/`, `rhizome/crates/rhizome-mcp/`, `rhizome/tests/`, matching `septa/code-graph-v1.schema.json` and fixture only if the contract is intentionally changed
- **Cross-repo edits:** `septa/` only when changing the code graph contract intentionally
- **Non-goals:** no Hyphae storage changes; use a separate handoff for importer identity/storage behavior
- **Verification contract:** run the repo-local commands below and `bash .handoffs/rhizome/verify-code-graph-contract-and-install-boundary.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** code graph serialization in `rhizome-core`, Hyphae export builder, backend selection and installer seams
- **Reference seams:** `septa/code-graph-v1.schema.json`, existing `rhizome-core` graph tests, CLI/MCP explicit install commands if present
- **Spawn gate:** do not launch an implementer until the parent agent has chosen whether file-level graph nodes can have source ranges or should omit line metadata

## Problem

Rhizome can emit code-graph payloads that do not match Septa: line metadata is string-valued and synthetic file nodes use line `0` while the schema requires integer lines with minimum `1`. The audit also found backend selection can trigger package-manager installation from `rhizome-core`, mixing probing, host mutation, and policy.

The supply-chain audit added that those implicit installs are unpinned registry/package-manager executions, including `gopls@latest` and language servers installed through npm, brew, pip, gem, or dotnet without an integrity manifest.

## What needs doing

1. Make code-graph metadata typed enough to satisfy `code-graph-v1`.
2. Emit numeric line fields where the schema requires numbers.
3. Remove invalid zero-line metadata or update Septa deliberately.
4. Add a producer test that validates a real Rhizome graph against the Septa schema or fixture expectations.
5. Split backend probing from package-manager installation; installs should be explicit through CLI/MCP with approval/policy semantics.
6. Add a versioned LSP/tool install manifest with pinned package versions or explicit operator-managed paths.
7. Prefer locked/offline install modes where possible and reject `@latest` in default install recipes.

## Verification

```bash
cd rhizome && cargo test -p rhizome-core graph
cd rhizome && cargo test -p rhizome-core hyphae
cd septa && check-jsonschema --schemafile code-graph-v1.schema.json fixtures/code-graph-v1.example.json
bash .handoffs/rhizome/verify-code-graph-contract-and-install-boundary.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Rhizome graph output cannot emit string line fields for `code-graph-v1`
- [ ] no code-graph node emits invalid line `0` unless Septa is changed intentionally
- [ ] graph export tests cover Septa-compatible serialization
- [ ] backend probing does not invoke package-manager install paths
- [ ] install behavior is explicit and policy-aware
- [ ] LSP install recipes are pinned or explicitly operator-managed
- [ ] default install recipes do not use mutable `@latest` package specs
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: high/medium. This covers Rhizome-owned contract and architecture issues.
