# Hymenium: Docs And CLI Surface Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/README.md`, `hymenium/AGENTS.md`, `hymenium/CLAUDE.md`, `hymenium/docs/`
- **Cross-repo edits:** none
- **Non-goals:** no new CLI commands, MCP server, workflow execution engine, or template system
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-docs-and-cli-surface-drift.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** public README, contributor guidance, command inventory, module-path references
- **Reference seams:** `hymenium/src/main.rs`, `hymenium/src/dispatch/mod.rs`, `hymenium/src/monitor/mod.rs`
- **Spawn gate:** do not launch an implementer until the parent agent confirms whether docs should describe current shipped behavior only or also mark planned commands as roadmap

## Spawn Gate Decision

- **Docs describe current shipped behavior only** — no roadmap section; remove `run`, `serve`, `retry` without replacement.
- **Actual CLI surface**: `dispatch`, `status`, `decompose`, `cancel`, `reconcile` (as of 2026-04-26). `complete`/`fail` are library commands, not CLI subcommands — do not expose them in user docs.
- **`decompose` stub status**: document it as "generates child task outlines; does not dispatch agents" so users understand it is not full workflow decomposition.
- **MCP claims**: remove or mark as "not yet shipped"; the current binary has no `serve` subcommand.

## Problem

Hymenium docs describe a CLI and MCP surface that does not match the shipped binary. `README.md` documents `hymenium run --handoff ...`, `hymenium serve`, and a `retry` command, while the real CLI currently exposes `dispatch`, `status`, `decompose`, and `cancel`. `decompose` is still a stub. `CLAUDE.md` also calls Hymenium a "CLI and MCP server" even though no MCP server command is exposed.

Contributor docs also reference stale module paths and project layout. `AGENTS.md` and `CLAUDE.md` point at `src/dispatch.rs` and `src/monitor.rs`, but the real modules are `src/dispatch/mod.rs` and `src/monitor/mod.rs`. `AGENTS.md` treats a root `templates/` directory as authoritative even though Hymenium does not have that repo-local layout.

## What needs doing

1. Replace public command examples with the actual `dispatch`, `status`, `decompose`, and `cancel` surface.
2. Mark unimplemented workflow execution, retry, serve, and MCP behavior as roadmap or remove it from shipped-usage docs.
3. Correct module references from flat files to the current `mod.rs` paths.
4. Clarify the status of `decompose` so users do not treat it as complete workflow decomposition.
5. Keep future architecture notes separate from operator quickstart docs.

## Verification

```bash
cd hymenium && cargo run -- --help
cd hymenium && cargo test
bash .handoffs/hymenium/verify-docs-and-cli-surface-drift.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] README command inventory matches `cargo run -- --help`
- [ ] docs no longer present `run`, `serve`, or `retry` as shipped commands
- [ ] MCP server claims are either removed or explicitly marked future
- [ ] module path references match `src/dispatch/mod.rs` and `src/monitor/mod.rs`
- [ ] `decompose` stub status is documented accurately
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 7 docs-to-code drift audit. Severity: high/medium.
