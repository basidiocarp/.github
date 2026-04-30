# Audit Lane 3: Shared Version Pin Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only across all subprojects)
- **Allowed write scope:** `.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane3-version-pin-drift.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not bump any pin; does not modify `ecosystem-versions.toml` or any `Cargo.toml`/`package.json`; does not refactor dependency declarations
- **Verification contract:** `bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane3-version-pin-drift.sh`
- **Completion update:** when findings file is written and verification is green, parent updates campaign README + dashboard.

## Problem

`ecosystem-versions.toml` documents shared dependency pins across the ecosystem (most importantly `spore`, the shared transport/discovery/path library; also rust-toolchain, key external deps). Each repo's `Cargo.toml` is supposed to match. Drift is silent — local builds work, but shared types diverge across repos and runtime breaks at integration boundaries with confusing errors.

## Scope

For each version key in `ecosystem-versions.toml`:

1. Identify which repos consume that dependency.
2. Open each repo's `Cargo.toml` (or `package.json`) and read the actual pin.
3. Compare against `ecosystem-versions.toml`.
4. Flag any mismatch.

Out of scope: TypeScript dependency drift (npm), unless `ecosystem-versions.toml` declares an npm pin. Focus on Rust pins.

## Audit method

```bash
# Read the workspace-pinned versions
cat /Users/williamnewton/projects/personal/basidiocarp/ecosystem-versions.toml

# For each shared key (spore, etc.), grep across repos
grep -rE 'spore\s*=\s*' \
  cortina/Cargo.toml \
  hyphae/Cargo.toml \
  hymenium/Cargo.toml \
  mycelium/Cargo.toml \
  rhizome/Cargo.toml \
  stipe/Cargo.toml \
  volva/Cargo.toml \
  canopy/Cargo.toml \
  annulus/Cargo.toml \
  spore/Cargo.toml

# Repeat for any other shared key in ecosystem-versions.toml
```

For workspace crates that consume spore via path (within the same repo), the path dependency is correct — only check published-version pins in cross-repo Cargo.toml files.

## Findings file format

Write `findings/lane3-version-pin-drift.md`:

- **Summary** — counts by severity. Most findings should be `concern` (silent ABI drift) unless something is severely broken.
- **Workspace-Pinned Versions** — table from `ecosystem-versions.toml`.
- **Per-Repo Comparison** — table: repo, dependency, declared version, workspace pin, match/mismatch.
- **Findings** — `[F3.N]` per mismatch, with severity, location, evidence, proposed fix-phase title.
- **Clean Areas** — repos that match exactly.

## Style Notes

- A path-dep within the same repo (e.g. `spore = { path = "../spore" }`) is correct — the version pin only matters for cross-repo published-package references.
- A `>=` or `~` range that includes the pinned version is a `concern`, not a blocker — it works today but invites future drift.
- An exact mismatch with the workspace pin is a `blocker` for shared-types crates (spore in particular).

## Completion Protocol

1. All `ecosystem-versions.toml` keys checked across all consuming repos.
2. Findings file written.
3. Verify script exits 0.

```bash
bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane3-version-pin-drift.sh
```

**Required result:** `Results: N passed, 0 failed`.
