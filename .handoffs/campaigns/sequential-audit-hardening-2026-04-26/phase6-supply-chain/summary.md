# Phase 6 Dependency And Supply Chain Audit Summary

**Status:** Complete

## Consolidated Findings

| Finding | Severity | Disposition |
|---------|----------|-------------|
| Rust dependency monitoring gaps, missing cargo-deny/vet policy, mutable Spore tag source, shared dependency drift | High | New `.handoffs/cross-project/rust-supply-chain-policy.md` |
| Hyphae default embedding/native ML dependency chain pulls ORT/precompiled binaries | High | New `.handoffs/hyphae/embedding-supply-chain-profile.md` |
| Cap `npx` scripts/release checks and install-script policy gaps | Medium | New `.handoffs/cap/node-supply-chain-script-policy.md` |
| Stipe release/self-update downloads lack checksum/signature/provenance verification and have unbounded/predictable extraction risks | High | New `.handoffs/stipe/release-artifact-provenance.md` |
| Lamella vendored content license/provenance, mutable marketplace refs, unpinned runtime package specs, mutable container tags, zip helper provenance | High | New `.handoffs/lamella/package-provenance-and-runtime-pins.md` |
| Stipe/version ledger drift and weak verifier | High | Folded into `.handoffs/cross-project/version-ledger-authority.md` |
| Rhizome implicit unpinned package-manager installs during backend probing | High | Folded into `.handoffs/rhizome/code-graph-contract-and-install-boundary.md` |
| Lamella manifest traversal and post-edit toolchain env trust | High | Already covered by `.handoffs/lamella/hook-trust-and-manifest-path-security.md` |

## Agent Lanes

| Lane | Scope | Status |
|------|-------|--------|
| 1 | Rust dependency and Cargo.lock health | Complete |
| 2 | Node/package-manager dependency and script risk | Complete |
| 3 | generated/vendored content and plugin/package provenance | Complete |
| 4 | install/update/release supply-chain controls | Complete |
| 5 | cross-repo version ledger and dependency drift | Complete |

## Notes

- Lamella validator commands passed in the provenance lane, with existing pyenv rehash noise.
- No code changes were made; only handoffs and campaign tracking were updated.
