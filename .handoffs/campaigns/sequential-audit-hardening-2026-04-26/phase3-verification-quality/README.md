# Phase 3: Verification Quality Audit

**Status:** Complete

## Scope

Audit whether existing tests, verify scripts, fixtures, CI commands, and handoff completion checks actually prove the claims they make. This phase should not re-audit runtime bugs from Phase 2 except where the verification surface is misleading.

## Planned Lanes

| Lane | Scope | Status | Findings |
|------|-------|--------|----------|
| 1 | handoff verify scripts and dashboard completion checks | Complete | summary.md |
| 2 | Rust repo tests versus critical behavior claims | Complete | summary.md |
| 3 | Septa fixture/contract validation coverage | Complete | summary.md |
| 4 | frontend/server test quality in Cap | Complete | summary.md |
| 5 | CI parity and documented green paths | Complete | summary.md |

## Consolidation Rules

- Prefer improving existing handoff verification clauses over creating new work.
- Create new handoffs only where the verification gap is broad or cross-cutting.
- Record skipped or impossible validation explicitly.

## Consolidated Result

New handoffs created:

- `cross-project/verification-command-and-script-hardening.md`
- `cross-project/producer-contract-validation-harness.md`
- `cap/server-and-ui-verification-hardening.md`
- `hymenium/workflow-gate-integration-verification.md`
- `rhizome/lsp-and-export-verification.md`
- `cortina/hook-executor-verification.md`
- `mycelium/git-branch-regression-verification.md`

Existing handoffs updated:

- `canopy/septa-read-model-contracts.md`
- `cap/api-auth-and-webhook-defaults.md`

Existing handoffs already cover the Septa registry/variant/raw-ref validation gap (`septa/validation-tooling-and-inventory.md`) and the Cap auth/webhook defaults (`cap/api-auth-and-webhook-defaults.md`), but the proof quality gaps were made explicit in the new or updated work items.
