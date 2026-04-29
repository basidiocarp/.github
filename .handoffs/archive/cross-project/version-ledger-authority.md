# Cross-Project: Version Ledger Authority

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `ecosystem-versions.toml`, `stipe/src/commands/doctor/plugin_inventory_checks.rs`, `annulus/Cargo.toml`, `cap/package.json`, `lamella/VERSION`, `lamella/package.json`, repo README/AGENTS validation notes, `.handoffs/`
- **Cross-repo edits:** version metadata and validation docs only
- **Non-goals:** no dependency upgrades and no release tagging
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-version-ledger-authority.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** workspace root plus Stipe doctor metadata
- **Likely files/modules:** ecosystem version ledger, Stipe pinned version table, repo manifests, validation script
- **Reference seams:** `ecosystem-versions.toml`, Stipe doctor version drift output, existing release docs
- **Spawn gate:** do not launch an implementer until the parent agent chooses the single source of truth for tool versions

## Problem

Ecosystem tool versions are split across multiple authorities. `ecosystem-versions.toml`, Stipe's embedded doctor pin table, and repo package manifests disagree for several tools. This can make `stipe doctor` report false drift or miss real drift, and it weakens release/install metadata.

The supply-chain audit confirmed concrete drift: Stipe doctor pins lag the ledger for Hyphae, Canopy, Stipe, and Spore; the ledger lags live manifests for Annulus, Cap, and Lamella; and Hyphae's release identity is ambiguous because the CLI crate is `0.11.0` while internal crates remain `0.10.17`.

The docs drift audit found a related Hyphae release-script defect: `hyphae/scripts/release.sh` says it bumps all crate `Cargo.toml` files, but its hard-coded crate list omits `crates/hyphae-ingest/Cargo.toml`.

## What needs doing

1. Decide whether `ecosystem-versions.toml` is authoritative for tool versions.
2. Generate or validate Stipe's pinned doctor versions from the authoritative ledger.
3. Align repo manifests or document intentional pending release differences.
4. Add a validation command that detects future ledger drift.
5. Define “tool version” for multi-crate workspaces such as Hyphae as the installed CLI/package version unless explicitly documented otherwise.
6. Make the verifier parse and compare values, not just search for visible strings.
7. Keep shared dependency upgrades separate; this handoff is version authority, not dependency update work.
8. Make Hyphae release version updates derive the crate list from the workspace or include `hyphae-ingest` explicitly.

## Verification

```bash
rg -n 'pins.insert|^version =|"version"|lamella =' ecosystem-versions.toml stipe/src/commands/doctor/plugin_inventory_checks.rs annulus/Cargo.toml cap/package.json lamella/VERSION
cd stipe && cargo test doctor
bash .handoffs/cross-project/verify-version-ledger-authority.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] one authoritative tool-version source is documented
- [ ] Stipe doctor pins match or are generated from the authority
- [ ] repo manifests either match or are explicitly marked pending/rationale
- [ ] Hyphae CLI/package version is clearly distinguished from internal crate versions
- [ ] Hyphae release script updates every crate it claims to update, including `hyphae-ingest`
- [ ] validation catches future tool-version drift
- [ ] verifier fails on mismatched ledger, Stipe pins, manifests, or package locks
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit and expanded by Phase 6 supply-chain and Phase 7 docs drift audits. Severity: high.
