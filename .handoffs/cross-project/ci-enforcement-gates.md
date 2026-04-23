# CI Enforcement Gates

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** all Rust repos + cap + septa (cross-project)
- **Allowed write scope:** `.github/workflows/`, each repo's CI config, `ecosystem-versions.toml`
- **Cross-repo edits:** yes — CI config in each repo listed below
- **Non-goals:** fixing the violations themselves (those are separate handoffs); this only adds enforcement gates so violations can no longer land undetected
- **Verification contract:** each repo's CI must reject a PR that introduces a `cargo fmt` violation, a `cargo clippy -D warnings` error, or (in septa-touching PRs) a `validate-all.sh` failure
- **Completion update:** once all gates are green and verified, update `.handoffs/HANDOFFS.md` and archive this entry

## Context

The Phase 2 Code Quality Audit found that every Rust repo fails `cargo fmt --check` and `cargo clippy -- -D warnings`. The Phase 3 Architecture Audit found that spore version pins drift silently between repos. These findings accumulate because no CI gate prevents them from landing. Enforcement is the only durable fix — manual audits like this campaign should not be the catch mechanism.

## Implementation Seam

- **Likely repos:** mycelium, hyphae, canopy, rhizome, spore, stipe, cortina, annulus, hymenium, volva (Rust); cap (TypeScript); septa (cross-project)
- **Likely files:** `.github/workflows/ci.yml` in each repo; `ecosystem-versions.toml` at workspace root; a new `scripts/check-spore-pins.sh`
- **Reference seams:** check existing CI files in each repo for current job structure before adding gates
- **Spawn gate:** do not launch an implementer until you know the CI system each repo uses (GitHub Actions vs local Makefile only) and have read the existing CI config in at least one repo to confirm the job structure

## Problem

All Rust repos fail `cargo fmt --check` and `cargo clippy -- -D warnings` in CI-equivalent checks. The cap TypeScript repo has 29 Biome lint violations. Every consumer of spore is pinned to a different version (v0.4.9 or v0.4.11) while the canonical `ecosystem-versions.toml` says v0.4.10. No gate prevents these from worsening on every merge.

## What exists (state)

- **cargo fmt / clippy:** not enforced in CI in any Rust repo (violations accumulate)
- **biome check:** not enforced in cap CI (29 violations present)
- **septa validate-all.sh:** not wired into CI on producer or schema changes
- **spore version pin:** `ecosystem-versions.toml` exists as documentation but no tooling reads it

## What needs doing (intent)

Add CI enforcement in each repo so violations block merge:

1. Every Rust repo: `cargo fmt --check` + `cargo clippy --all-targets -- -D warnings` as required CI steps
2. cap: `npx @biomejs/biome check .` as required CI step
3. septa: `bash validate-all.sh` triggered on any change to `septa/` or to producer repos
4. Workspace: a script that reads `ecosystem-versions.toml` and diffs against each Cargo.toml's spore pin; fails if any repo is out of sync

## Scope

- **Primary seam:** CI configuration files across all repos
- **Allowed files:** `.github/workflows/` in each repo; `scripts/check-spore-pins.sh` at workspace root
- **Explicit non-goals:** fixing current violations (do separately); changing build structure; adding new tests

---

### Step 1: Audit existing CI configs

**Project:** all repos
**Effort:** 30 min
**Depends on:** nothing

Read `.github/workflows/` in each Rust repo. Confirm job names and trigger conditions. Note which repos have no CI at all vs. which have CI that skips linting.

#### Verification

```bash
ls mycelium/.github/workflows/ hyphae/.github/workflows/ canopy/.github/workflows/ \
   rhizome/.github/workflows/ stipe/.github/workflows/ cortina/.github/workflows/ \
   annulus/.github/workflows/ hymenium/.github/workflows/ volva/.github/workflows/
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] CI config path confirmed in each repo
- [ ] Job structure understood before editing

---

### Step 2: Add `cargo fmt --check` and `cargo clippy` gates

**Project:** each Rust repo
**Effort:** 1-2 hours across all repos
**Depends on:** Step 1

Add a `lint` job to each repo's CI. Example structure:

```yaml
lint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: dtolnay/rust-toolchain@stable
      with:
        components: rustfmt, clippy
    - run: cargo fmt --check
    - run: cargo clippy --all-targets -- -D warnings
```

Match the exact runner and toolchain pin already used in the repo's CI.

#### Verification

```bash
# In each repo: confirm fmt and clippy pass after violations are fixed
cd mycelium && cargo fmt --check && cargo clippy --all-targets -- -D warnings
cd ../hyphae && cargo fmt --check && cargo clippy --all-targets -- -D warnings
# (repeat for each repo)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cargo fmt --check` exits 0 in all Rust repos
- [ ] `cargo clippy --all-targets -- -D warnings` exits 0 in all Rust repos
- [ ] CI config updated in all repos

---

### Step 3: Add Biome enforcement in cap

**Project:** `cap/`
**Effort:** 15 min
**Depends on:** nothing (can run in parallel with Step 2)

Add a lint step to cap's CI:

```yaml
- run: npx @biomejs/biome check .
```

Also add an auto-fix check so violations are immediately resolvable:
```yaml
- run: npx @biomejs/biome check --apply .
- run: git diff --exit-code  # fails if auto-fix changed anything
```

#### Verification

```bash
cd cap && npx @biomejs/biome check .
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Biome check exits 0 in cap
- [ ] CI config updated in cap

---

### Step 4: Wire septa validate-all.sh into CI

**Project:** `septa/`
**Effort:** 30 min
**Depends on:** nothing

Add a CI job that runs `bash validate-all.sh` on any push to `septa/` or any push to a producer repo (mycelium, hyphae, canopy, cortina, etc.). This ensures schema/fixture drift is caught at the PR level.

#### Verification

```bash
cd septa && bash validate-all.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `validate-all.sh` exits 0 on current state
- [ ] CI triggers on septa changes confirmed

---

### Step 5: Add spore version pin check script

**Project:** workspace root
**Effort:** 30 min
**Depends on:** nothing

Create `scripts/check-spore-pins.sh`:

```bash
#!/usr/bin/env bash
# Reads the canonical spore version from ecosystem-versions.toml
# and verifies each consumer Cargo.toml matches it.
set -euo pipefail

CANONICAL=$(grep '^version' ecosystem-versions.toml | grep -A1 '\[spore\]' | \
            grep version | sed 's/version = "\(.*\)"/\1/')

CONSUMERS=(mycelium hyphae canopy rhizome stipe cortina annulus hymenium volva)
FAIL=0

for repo in "${CONSUMERS[@]}"; do
    PINNED=$(grep -o 'tag = "v[0-9.]*"' "$repo/Cargo.toml" 2>/dev/null | \
             head -1 | sed 's/tag = "v\(.*\)"/\1/')
    if [[ "$PINNED" != "$CANONICAL" ]]; then
        echo "FAIL: $repo pins spore $PINNED, canonical is $CANONICAL"
        FAIL=1
    else
        echo "OK:   $repo on $CANONICAL"
    fi
done

exit $FAIL
```

Add to CI as a required check triggered on any Cargo.toml change or `ecosystem-versions.toml` change.

**Note:** Before wiring this, first decide whether to update the canonical to v0.4.11 (what more repos use) or pin all consumers back to v0.4.10. That decision belongs in the spore release dance, not this handoff. This script enforces whatever the canonical says.

#### Verification

```bash
bash scripts/check-spore-pins.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Script correctly identifies drift
- [ ] Script passes after canonical and consumers are aligned
- [ ] CI step added for Cargo.toml changes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. `cargo fmt --check` and `cargo clippy --all-targets -- -D warnings` are required CI gates in every Rust repo
2. `biome check` is a required CI gate in cap
3. `bash septa/validate-all.sh` runs in CI on septa or producer changes
4. `scripts/check-spore-pins.sh` runs in CI on Cargo.toml or ecosystem-versions.toml changes
5. All current violations are fixed so CI is green (coordinate with the Phase 2 quality fix pass)
6. Dashboard updated

### Final Verification

```bash
bash .handoffs/cross-project/verify-ci-enforcement-gates.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
