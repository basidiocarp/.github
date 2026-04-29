# Sequential Audit Hardening Campaign

**Started:** 2026-04-26
**Status:** Complete

## Purpose

Run seven focused audits back-to-back, using parallel agents inside each audit
theme and consolidating findings before moving to the next theme.

## Audit Order

1. Contract Round-Trip Audit
2. Runtime Safety Audit
3. Verification Quality Audit
4. Data Integrity Audit
5. Security and Secrets Audit
6. Dependency and Supply Chain Audit
7. Docs-to-Code Drift Audit

## Operating Rules

- Run one audit theme at a time.
- Use parallel agents only inside the active theme.
- After each theme, consolidate findings and either fold them into active
  handoffs or create new handoffs.
- Do not duplicate existing active handoffs.
- Prefer repo-owned handoffs with narrow write scopes and paired verification
  scripts.

## Status

| # | Audit | Status | Findings |
|---|-------|--------|----------|
| 1 | Contract Round-Trip Audit | Complete | `phase1-contract-roundtrip/` |
| 2 | Runtime Safety Audit | Complete | `phase2-runtime-safety/` |
| 3 | Verification Quality Audit | Complete | `phase3-verification-quality/` |
| 4 | Data Integrity Audit | Complete | `phase4-data-integrity/` |
| 5 | Security and Secrets Audit | Complete | `phase5-security-secrets/` |
| 6 | Dependency and Supply Chain Audit | Complete | `phase6-supply-chain/` |
| 7 | Docs-to-Code Drift Audit | Complete | `phase7-docs-drift/` |

## Phase 1 Scope: Contract Round-Trip Audit

Check whether real producer output and real consumer input handling match Septa
contracts. The audit is split into five parallel lanes:

1. Canopy, Cap, and Annulus contracts
2. Hyphae, Rhizome, and Mycelium contracts
3. Volva and Cortina hook/session/runtime contracts
4. Hymenium and Canopy workflow contracts
5. Septa validation tooling itself

Each lane must report:

- schema or fixture involved
- producer and consumer files
- real payload shape evidence
- whether the issue is already covered by an active handoff
- recommended verification command
