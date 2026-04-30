# Cross-Project: Spore Rev Pin Decision (F3.1)

⚠ **Decision Required before starting** — this handoff has an open operator decision and should not be dispatched to an implementer until that decision is recorded.

## Handoff Metadata

- **Dispatch:** `direct` (after decision)
- **Owning repo:** workspace root + 8–9 consumer repos for the sweep step
- **Allowed write scope:** `ecosystem-versions.toml`, all `Cargo.toml` files that pin `spore` by `git rev`
- **Cross-repo edits:** yes — every consumer repo's Cargo.toml
- **Non-goals:** does not change anything in the spore crate itself; does not refactor the dependency graph; does not bump versions of other shared crates (those are separate handoffs)
- **Verification contract:** `bash .handoffs/cross-project/verify-spore-rev-pin-decision.sh` (after decision lands)
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem (F3.1, blocker)

`ecosystem-versions.toml` documents `spore` at rev `a3c7f5bf…`. Lane 3 of the 2026-04-30 audit found that 8 of 9 consumer repos pin `0bc2e878…` (only hymenium matches the doc). Either:

- **Option A** — bump `ecosystem-versions.toml` to `0bc2e878…` and update hymenium to match (1 consumer change).
- **Option B** — bump 8 consumers (cortina, hyphae, mycelium, rhizome, stipe, volva, canopy, annulus) back to `a3c7f5bf…`, leaving hymenium and the doc as the source of truth.

Option A is mechanically smaller and matches what's actually been built/tested across most consumers. Option B is more conservative but requires more change (and likely retesting all 8 consumers).

## ⚠ Decision needed

Before dispatch, the operator must record:

1. Which rev becomes the workspace pin (likely `0bc2e878…` — Option A).
2. Whether any consumer needs to ship at the older rev for compatibility (if so, document an exception in `ecosystem-versions.toml`).
3. Whether this drift indicates the version-pin process needs better hygiene (CI gate? release-time check?).

Capture the decision inline in this file (replace this section with the chosen direction) before dispatching.

## Scope (after decision)

- **Allowed files:**
  - `ecosystem-versions.toml`
  - Every `Cargo.toml` in the consumer repos that needs the pin updated
- **Explicit non-goals:**
  - other shared dep drifts (covered by `tier-b-pin-alignment-sweep.md`)
  - spore source changes
  - schema changes

## Step 1 — Apply decision

Update each affected `Cargo.toml` to pin `spore` at the chosen rev. Update `ecosystem-versions.toml` to reflect the chosen rev.

## Step 2 — Per-consumer cargo build

```bash
for repo in cortina hyphae mycelium rhizome stipe volva canopy annulus hymenium; do
  echo "=== $repo ==="
  (cd /Users/williamnewton/projects/personal/basidiocarp/$repo && cargo build --release) || break
done
```

## Step 3 — Per-consumer cargo test

```bash
for repo in cortina hyphae mycelium rhizome stipe volva canopy annulus hymenium; do
  echo "=== $repo ==="
  (cd /Users/williamnewton/projects/personal/basidiocarp/$repo && cargo test) || break
done
```

If any consumer fails to build or test against the chosen rev, that's a finding — surface it before continuing.

## Verify Script

`bash .handoffs/cross-project/verify-spore-rev-pin-decision.sh` (to be added after decision) confirms:
- Every consumer's `Cargo.toml` pins spore at the same rev as `ecosystem-versions.toml`
- All consumers build cleanly

## Context

Closes lane 3 blocker F3.1 from the 2026-04-30 audit. Foundational — most other Tier B drifts are smaller and unblocked by this decision.
