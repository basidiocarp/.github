# Workspace Foundations

This directory is the concrete source of truth for workspace-level Rust
architecture standards.

Use these docs when:

- creating or updating `foundation-alignment` handoffs
- auditing repo structure or dependency direction
- writing new repo architecture notes or maintainer guidance
- checking whether a Rust repo still fits the ecosystem boundary model

Core docs:

- [graceful-degradation.md](./graceful-degradation.md) — tool degradation tiers, behavior contracts, and ecosystem resilience
- [rust-workspace-architecture-standards.md](./rust-workspace-architecture-standards.md)
- [rust-workspace-standards-applied.md](./rust-workspace-standards-applied.md)
- [repo-documentation-standards.md](./repo-documentation-standards.md)
- [internal-repo-audit-blueprint.md](./internal-repo-audit-blueprint.md)
- [rust-repo-audit-checklist.md](./rust-repo-audit-checklist.md)
- [rust-repo-audit-report-template.md](./rust-repo-audit-report-template.md)

The audit set under `.audit/external/audits/` holds example audits and
synthesis only. It is not the source of truth for workspace standards.
