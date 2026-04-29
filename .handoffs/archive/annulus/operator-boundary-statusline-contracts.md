# Annulus: Operator Boundary And Statusline Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** `annulus/src/config.rs`, `annulus/src/statusline.rs`, `annulus/src/notify.rs`, `annulus/src/main.rs`, `annulus/tests/`, `annulus/README.md`, `annulus/AGENTS.md`, `annulus/CLAUDE.md`, `annulus/docs/`, `ecosystem-versions.toml`, matching `septa/annulus-statusline-v1.schema.json` and fixture only if the contract changes
- **Cross-repo edits:** `septa/` for statusline contract changes and root `ecosystem-versions.toml` for version ledger only
- **Non-goals:** no Canopy notification schema redesign; move Canopy-owned write behavior to a separate Canopy handoff if needed
- **Verification contract:** run the repo-local commands below and `bash .handoffs/annulus/verify-operator-boundary-statusline-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `annulus`
- **Likely files/modules:** statusline segment registry/rendering, notification polling, docs, version ledger
- **Reference seams:** `septa/annulus-statusline-v1.schema.json`, `canopy` notification ownership, `annulus/src/config.rs`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether `notify --poll` remains an Annulus write surface or moves behind Canopy

## Problem

Annulus is documented as a read-only operator surface, but `notify --poll` mutates Canopy notification rows. Statusline JSON can emit segments not represented in Septa, and segment rendering is split across duplicated terminal/JSON registries. Docs and version ledger are stale.

The docs drift audit made the stale public surface concrete: README/AGENTS/CLAUDE still describe Annulus as a two-command read-only utility focused on `statusline` and `validate-hooks`, while the binary exposes `status` and `notify` and `notify --poll` can write notification state.

## What needs doing

1. Decide whether notification acknowledgement belongs in Annulus or behind a Canopy-owned command/API.
2. If Annulus stays mostly read-only, remove direct `UPDATE` against Canopy DB or replace it with Canopy-owned interaction.
3. Align default statusline JSON segments with `annulus-statusline-v1`.
4. Consolidate segment declaration so terminal rendering, JSON rendering, config defaults, and schema status do not drift independently.
5. Update README/AGENTS/CLAUDE/docs to include `status`, `notify`, real config path, and actual module tree.
6. Update `ecosystem-versions.toml` for Annulus `0.5.5` or document why the repo is intentionally ahead.

## Verification

```bash
cd annulus && cargo test
cd septa && check-jsonschema --schemafile annulus-statusline-v1.schema.json fixtures/annulus-statusline-v1.example.json
bash .handoffs/annulus/verify-operator-boundary-statusline-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Annulus boundary docs match actual `status` and `notify` behavior
- [ ] direct Canopy DB mutation is removed or explicitly owned and documented
- [ ] default JSON statusline output is schema-backed
- [ ] statusline segment registry no longer duplicates contract-critical segment lists
- [ ] Annulus version ledger matches the repo version or records rationale
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: high/medium/low plus docs drift.
