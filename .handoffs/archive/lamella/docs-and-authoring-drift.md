# Lamella: Docs And Authoring Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/README.md`, `lamella/CLAUDE.md`, `lamella/docs/`, `lamella/manifests/codex/README.md`, `lamella/Makefile`
- **Cross-repo edits:** none
- **Non-goals:** no plugin builder rewrite, no manifest format change, and no generated `dist/` edits
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-docs-and-authoring-drift.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** operator commands, architecture docs, hook authoring docs, inventory counts, Codex manifest README
- **Reference seams:** `Makefile`, `scripts/plugins/build-plugin.sh`, `scripts/plugins/build-marketplace.sh`, `resources/hooks/hooks.json`, `lamella` wrapper script
- **Spawn gate:** do not launch an implementer until the parent agent decides whether `make build PLUGIN=...` should be implemented or removed from docs

## Problem

Lamella docs contain false or stale operator guidance. `CLAUDE.md` documents `make build PLUGIN=core`, but the Makefile `build` target ignores `PLUGIN` and iterates every Claude manifest.

Architecture docs say `builders/build-claude-plugin.sh` updates the marketplace catalog, but marketplace generation is handled by `scripts/plugins/build-marketplace.sh`. The same section implies hook bundle docs and helper assets are copied wholesale, while the builder packages `hooks/hooks.json`, `scripts/hooks/*`, and selected skill-path rewrites.

Hook authoring docs tell authors to put matchers in `.claude/settings.json` while the example depends on `${CLAUDE_PLUGIN_ROOT}`, which is a plugin-only path convention. Inventory docs disagree with each other and the current count command, with docs claiming 286 or 292 skills while `make count` reports 301 skills and 52 plugins. `manifests/codex/README.md` also presents an in-place manual builder flow even though `./lamella build-codex` regenerates manifests under `dist/generated/codex-manifests`.

## What needs doing

1. Either implement `PLUGIN` filtering for `make build` or remove the false example.
2. Correct architecture docs so plugin build and marketplace generation are separate.
3. Clarify which hook resources are authored, which are packaged, and where plugin-only environment variables are valid.
4. Update skill and plugin inventory counts from `make count`.
5. Reframe `manifests/codex/README.md` as source/manual reference or point contributors to `./lamella build-codex`.
6. Keep generated `dist/` output out of the source-doc fix unless the task explicitly refreshes generated artifacts.

## Verification

```bash
cd lamella && make validate
cd lamella && ./lamella build-marketplace
cd lamella && ./lamella build-codex
cd lamella && make count
bash .handoffs/lamella/verify-docs-and-authoring-drift.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `make build PLUGIN=...` docs either work or are removed
- [ ] marketplace docs point at the marketplace builder
- [ ] hook authoring examples use paths valid for their target host/config
- [ ] inventory counts match `make count`
- [ ] Codex manifest docs distinguish source/manual flow from generated wrapper output
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 7 docs-to-code drift audit. Severity: high/medium.
