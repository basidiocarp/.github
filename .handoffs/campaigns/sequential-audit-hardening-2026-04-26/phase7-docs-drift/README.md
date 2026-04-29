# Phase 7: Docs-To-Code Drift Audit

**Status:** Complete

## Scope

Audit README/AGENTS/CLAUDE/docs/manifests against actual code behavior, command names, repo ownership, generated output, version claims, validation instructions, and handoff guidance. Avoid duplicating contract/runtime/security/supply-chain findings unless the documentation drift needs a distinct docs fix.

## Planned Lanes

| Lane | Scope | Status | Findings |
|------|-------|--------|----------|
| 1 | Rust repo README/AGENTS/CLAUDE drift | Complete | summary.md |
| 2 | Cap dashboard docs and server/API docs drift | Complete | summary.md |
| 3 | Lamella authoring, manifest, generated-output docs drift | Complete | summary.md |
| 4 | Workspace/root foundations, Septa, and handoff docs drift | Complete | summary.md |
| 5 | install/release/validation command docs drift | Complete | summary.md |

## Consolidation Rules

- Fold pure version drift into `.handoffs/cross-project/version-ledger-authority.md`.
- Fold command verification drift into `.handoffs/cross-project/verification-command-and-script-hardening.md`.
- Create repo-local docs handoffs when the fix is mostly documentation and examples.

## Consolidated Output

- Created new handoffs A49-A53 for Hymenium, Cap, Lamella, cross-project workspace docs, and Stipe install/release docs drift.
- Folded overlapping findings into A6, A7, A16, A21, A25, A39, and A46.
- Syntax-checked the new verify scripts with `bash -n`.
