# Rhizome: LSP And Export Verification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/crates/rhizome-lsp/tests/`, `rhizome/crates/rhizome-mcp/tests/`, `rhizome/crates/rhizome-core/`, `rhizome/AGENTS.md`, `rhizome/README.md`
- **Cross-repo edits:** none
- **Non-goals:** no analyzer redesign and no Hyphae storage changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/rhizome/verify-lsp-and-export-verification.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** live LSP tests, MCP export tests, fake LSP process/test-double Hyphae target
- **Reference seams:** ignored `live_lsp` tests, ignored Hyphae export E2E, existing LSP client timeout tests
- **Spawn gate:** do not launch an implementer until the parent agent decides which live tests remain optional and which deterministic tests must run by default

## Problem

Rhizome documents live LSP semantics and Hyphae export behavior, but the riskiest coverage is ignored. Normal validation can pass while live backend/export behavior is untested.

## What needs doing

1. Add non-ignored deterministic tests using a fake LSP process for cross-file semantic behavior.
2. Add non-ignored export tests using an in-process or test-double Hyphae target.
3. Keep true live external-server tests optional, but document and expose their ignored command.
4. Update handoff and repo validation docs so default tests cover deterministic behavior.

## Verification

```bash
cd rhizome && cargo test -p rhizome-lsp
cd rhizome && cargo test -p rhizome-mcp export
cd rhizome && cargo test -p rhizome-lsp --test live_lsp -- --ignored
bash .handoffs/rhizome/verify-lsp-and-export-verification.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] deterministic LSP behavior has non-ignored tests
- [ ] Hyphae export behavior has non-ignored tests or a local test double
- [ ] external live tests remain documented as optional
- [ ] default validation no longer skips all high-risk LSP/export behavior
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 3 verification quality audit. Severity: high.
