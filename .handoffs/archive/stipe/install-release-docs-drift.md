# Stipe: Install And Release Docs Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/README.md`, `docs/operate/release-and-install-matrix.md`, `docs/getting-started/install-scope.md`, `profile/README.md`, `stipe/src/commands/tool_registry/specs.rs`
- **Cross-repo edits:** workspace install/release docs only
- **Non-goals:** no release artifact provenance implementation and no installer UX redesign
- **Verification contract:** run the commands below and `bash .handoffs/stipe/verify-install-release-docs-drift.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `stipe` plus root install docs
- **Likely files/modules:** Stipe profile table, install scope docs, release/install matrix
- **Reference seams:** `stipe/src/commands/tool_registry/specs.rs`, Stipe dry-run install output
- **Spawn gate:** do not launch an implementer until the parent agent decides whether docs should be generated from the Stipe tool registry or kept manually maintained

## Problem

Install and release docs no longer match Stipe's actual tool registry. `docs/operate/release-and-install-matrix.md` omits `annulus`, `hymenium`, and `volva`; `docs/getting-started/install-scope.md` omits `volva`; and Stipe's own profile table says `full` includes only `cap`, `canopy`, and `volva` while the real full-stack registry also includes `annulus` and `hymenium`.

Because `profile/README.md` sends users to the stale matrix, this is user-facing install guidance drift rather than only internal maintenance debt.

## What needs doing

1. Update the release/install matrix to include every Stipe-managed tool.
2. Update install-scope docs to include `volva` and any other current registry entries.
3. Update Stipe's README profile table to match `tool_registry/specs.rs`.
4. Consider deriving the docs table from the registry or adding a registry-vs-docs check.
5. Keep artifact checksum/signature work in `release-artifact-provenance.md`.

## Verification

```bash
cd stipe && cargo run -- install --profile full-stack --dry-run
cd stipe && cargo run -- install annulus --dry-run
cd stipe && cargo run -- install hymenium --dry-run
cd stipe && cargo run -- install volva --dry-run
python3 scripts/validate-docs.py
bash .handoffs/stipe/verify-install-release-docs-drift.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] release/install matrix lists every Stipe-managed tool
- [ ] install-scope docs match current profile/tool behavior
- [ ] Stipe README profile table matches the registry
- [ ] profile docs no longer route users to stale install inventory
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 7 docs-to-code drift audit. Severity: high.
