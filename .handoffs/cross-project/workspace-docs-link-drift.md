# Cross-Project: Workspace Docs Link Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `AGENTS.md`, `CLAUDE.md`, `docs/foundations/`, `docs/workspace/`, `docs/research/orchestration/`, `docs/operate/`, `.handoffs/`
- **Cross-repo edits:** documentation and handoff references only
- **Non-goals:** no repo restructuring, no production code changes, and no archived handoff resurrection
- **Verification contract:** run the commands below and `bash .handoffs/cross-project/verify-workspace-docs-link-drift.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** workspace root
- **Likely files/modules:** root agent guidance, foundation docs, workspace interaction docs, orchestration notes, troubleshooting docs
- **Reference seams:** `scripts/validate-docs.py`, `.handoffs/archive/`, active `.handoffs/HANDOFFS.md`
- **Spawn gate:** do not launch an implementer until the parent agent lists which stale archived handoff links should be replaced with archive links versus removed

## Problem

Workspace documentation contains broken or stale links and at least one rendered-command defect. The docs validator flags stale/non-portable links in `docs/foundations/instruction-loading.md` and `docs/foundations/cache-friendly-assembly.md`, including an absent `stipe/CLAUDE.md` target and absolute filesystem links rejected by the validator.

`docs/workspace/ECOSYSTEM-INTERACTIONS.md` and `docs/research/orchestration/RESET-AUTHORITY.md` link to handoffs that have moved under `.handoffs/archive/`, so current-state docs point at missing active work. `docs/operate/troubleshooting.md` also puts raw `||` inside Markdown table cells, which breaks the rendered commands for `rhizome doctor 2>/dev/null || true` and `mycelium gain --diagnostics 2>/dev/null || true`.

Root guidance should also be checked for local skill references that are not distributed in this workspace. In this session, `writing-voice`, `tool-preferences`, and `test-writing` were referenced by `AGENTS.md` but were not present in the available skill list.

## What needs doing

1. Fix or remove doc links reported by `scripts/validate-docs.py`.
2. Update archived handoff references to point under `.handoffs/archive/` or remove them from current-state docs.
3. Escape Markdown table pipes in troubleshooting commands or move the commands out of table cells.
4. Reconcile root skill guidance with skills actually shipped in `.codex/skills` or `.agents/skills`.
5. Avoid using `fd` output that respects ignore rules as evidence that repo directories are absent; use `ls`, `fd -u`, or explicit path checks when validating workspace shape.

## Verification

```bash
python3 scripts/validate-docs.py
rg -n '\.handoffs/(cross-project|canopy|cap|cortina|hymenium|hyphae|lamella|rhizome|septa|stipe|volva)/[^ )]+\.md' docs AGENTS.md CLAUDE.md
bash .handoffs/cross-project/verify-workspace-docs-link-drift.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] docs validator passes
- [ ] current-state docs do not link to missing active handoffs
- [ ] archived handoff links either use `.handoffs/archive/` or are removed
- [ ] troubleshooting table commands render without splitting on shell pipes
- [ ] root skill guidance names available skills or marks unavailable local conventions explicitly
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 7 docs-to-code drift audit. Severity: medium. The audit lane also reported top-level repos as absent based on `fd` output; local `ls` confirms the repos exist, so this handoff treats that as a command-choice issue rather than a workspace-shape defect.
