# Cross-Project: Rust Supply Chain Policy

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `.github/dependabot.yml`, `.github/workflows/`, `deny.toml`, `scripts/check-spore-pins.sh`, `ecosystem-versions.toml`, Rust repo `Cargo.toml` files only for source/pin policy changes, `.handoffs/`
- **Cross-repo edits:** Rust repo dependency source/pin policy only; functional dependency upgrades need repo-specific follow-up
- **Non-goals:** no broad dependency version upgrades and no release tagging
- **Verification contract:** run the commands below and `bash .handoffs/cross-project/verify-rust-supply-chain-policy.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** workspace root plus Rust repo manifests
- **Likely files/modules:** Dependabot config, reusable Rust CI, cargo-deny config, Spore git dependency pins, shared dependency drift checks
- **Reference seams:** `ecosystem-versions.toml`, `scripts/check-spore-pins.sh`, per-repo `Cargo.lock`
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether Spore should be pinned by manifest `rev` or by lockfile commit validation against the expected tag SHA

## Problem

Rust dependency monitoring is incomplete. Root Dependabot tracks GitHub Actions but not Cargo ecosystems, Spore's standalone CI does not run the reusable cargo-audit path, and there is no committed `cargo deny` or `cargo vet` policy.

The shared `spore` crate is consumed by mutable git tags across repos. Locks currently resolve to a specific commit, but a moved tag or lock regeneration can change the effective source unless the commit is validated. The audit also found shared dependency drift: Volva uses older `rusqlite` and `thiserror`, and Cortina carries a duplicate TOML parser stack.

## What needs doing

1. Add Cargo dependency monitoring for each Rust repo, or document why a repo is excluded.
2. Make Spore CI run cargo-audit or the same reusable Rust CI controls as sibling repos.
3. Add a cargo-deny policy for advisories, duplicate-version bans/warnings, and allowed sources.
4. Pin Spore by immutable `rev` or validate every lockfile's Spore commit against the expected ledger SHA.
5. Add shared dependency drift checks for `rusqlite`, `thiserror`, `toml`, and other ledger-owned crates.
6. Record intentional exceptions such as temporary duplicate TOML stacks with expiration or follow-up.

## Verification

```bash
for repo in mycelium hyphae rhizome stipe cortina spore canopy volva annulus hymenium; do
  (cd "$repo" && cargo tree --duplicates --locked)
  (cd "$repo" && cargo audit)
done
cargo deny check advisories bans sources
bash scripts/check-spore-pins.sh
bash .handoffs/cross-project/verify-rust-supply-chain-policy.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Cargo dependency monitoring covers Rust repos
- [ ] Spore CI includes advisory scanning
- [ ] cargo-deny or equivalent source/duplicate policy exists
- [ ] Spore git dependency source cannot drift through a moved tag
- [ ] shared dependency drift is detected or explicitly waived
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 6 dependency and supply-chain audit. Severity: high/medium.
