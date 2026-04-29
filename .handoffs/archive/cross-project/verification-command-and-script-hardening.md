# Cross-Project: Verification Command And Script Hardening

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `.handoffs/`, `templates/handoffs/`, root `AGENTS.md`, root `CLAUDE.md`, subrepo README/AGENTS/CLAUDE command sections
- **Cross-repo edits:** documentation and handoff/verify-script updates only; no production source changes
- **Non-goals:** no implementation of product features and no broad README rewrite unrelated to validation commands
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-verification-command-and-script-hardening.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** workspace root
- **Likely files/modules:** `.handoffs/HANDOFFS.md`, active `verify-*.sh`, `templates/handoffs/WORK-ITEM-TEMPLATE.md`, root/subrepo validation docs
- **Reference seams:** existing verify script `check()` wrappers and dashboard active-work rules
- **Spawn gate:** do not launch an implementer until the parent agent lists the active handoffs whose scripts are allowed to be changed in this pass

## Problem

Several active verify scripts are syntax-valid but behaviorally weak: they grep for broad keywords, can pass while the handoff still says the feature is missing, or rely on filtered Rust test names that can pass with zero relevant tests. Many handoff command blocks are also not copy-paste safe from the documented working directory, and root/subrepo docs omit CI-equivalent lint/fmt gates.

The docs drift audit added two command-doc defects to keep in this verification-focused handoff: Cap release automation and workspace docs disagree about whether tests are part of the release gate, and `docs/operate/troubleshooting.md` renders shell `|| true` commands incorrectly when they appear inside Markdown table cells.

## What needs doing

1. Update the handoff template and dashboard guidance so commands are cwd-safe, preferably with subshells such as `(cd repo && cargo test ...)`.
2. Harden weak active verify scripts so they run the exact behavioral tests named by their handoffs.
3. Add guards against filtered Rust test commands passing with zero tests when a handoff requires named behavior.
4. Move orphan verify scripts or fix dashboard links for completed/missing active handoffs.
5. Align documented green paths with CI-equivalent non-mutating checks.
6. Escape shell pipes in table-based command docs or move those commands out of Markdown tables.

## Verification

```bash
bash -n .handoffs/*/verify-*.sh
rg -n "cargo fmt --check|cargo clippy.*-D warnings|npm run lint:check|npm test|npm run build" AGENTS.md CLAUDE.md */README.md
bash .handoffs/cross-project/verify-verification-command-and-script-hardening.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] active handoff command blocks are copy-paste safe from the documented cwd
- [ ] weak keyword-only scripts for A18/A19/A21/A23/A24 are replaced with behavioral commands
- [ ] filtered test commands fail or are replaced when they would run zero relevant tests
- [ ] completed dashboard links and orphan verify scripts are cleaned up
- [ ] root and subrepo docs name CI-equivalent validation commands
- [ ] command snippets containing `||` render as single commands, not split table cells
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 3 verification quality audit and expanded by Phase 7 docs drift audit. Severity: high/medium.
