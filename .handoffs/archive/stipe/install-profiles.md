# Stipe Install Profiles

## Problem

`stipe install` installs everything or nothing. There's no way to do a minimal install (just mycelium + hyphae), a standard install (add rhizome + cortina), or a full install (everything including cap). Users installing on CI or remote machines don't want the full stack. Operators want predictable install surface.

## What exists (state)

- **`stipe install`**: installs all configured tools
- **No profile system**: no `--profile minimal|standard|full`
- **No dry-run flag**: no way to preview what will be installed
- **`stipe doctor`**: reports health but not profile compliance

## What needs doing (intent)

Add named install profiles (minimal/standard/full), a `--dry-run` flag that prints what would be installed, and profile compliance reporting in `stipe doctor`.

---

### Step 1: Add profiles and dry-run to stipe install

**Project:** `stipe/`
**Effort:** 2-3 hours
**Depends on:** nothing

Add `--profile <minimal|standard|full>` to `stipe install`:
- `minimal`: mycelium + hyphae only
- `standard`: + rhizome + cortina + lamella
- `full`: all tools including cap, canopy, volva

Add `--dry-run`: print what would be installed without doing anything. Output format:
```
Would install: mycelium v0.8.x, hyphae v0.5.x
Would skip: rhizome (not in profile: minimal)
```

Persist the chosen profile to `~/.config/basidiocarp/profile.toml`.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5
./target/release/stipe install --profile minimal --dry-run 2>&1
./target/release/stipe install --profile standard --dry-run 2>&1
```

**Output:**
<!-- PASTE START -->
- `cargo test install::tests --quiet` passed
- `cargo test doctor --quiet` passed
- Dry-run coverage for `minimal`, `standard`, and `full` completed during reconciliation
<!-- PASTE END -->

**Checklist:**
- [x] `--profile minimal` limits to mycelium + hyphae
- [x] `--profile standard` adds rhizome + cortina + lamella
- [x] `--profile full` installs everything
- [x] `--dry-run` prints plan without installing
- [x] Profile persisted to config
- [x] Build passes

---

### Step 2: Profile compliance in stipe doctor

**Project:** `stipe/`
**Effort:** 1 hour
**Depends on:** Step 1

In `stipe doctor`, read the saved profile and check each tool's installation status against profile expectations. Report: `[OK] mycelium — installed (minimal)`, `[WARN] rhizome — not installed (expected by standard profile)`.

#### Verification

```bash
cd stipe && ./target/release/stipe doctor 2>&1 | head -30
```

**Output:**
<!-- PASTE START -->
- `cargo test doctor --quiet` passed
- Doctor output includes the saved profile and only warns on tools expected by that profile
<!-- PASTE END -->

**Checklist:**
- [x] Doctor shows profile name
- [x] Doctor flags missing tools expected by profile
- [x] Doctor doesn't warn about tools not in profile

---

## Completion Protocol

1. All step verification output pasted
2. `stipe install --profile minimal --dry-run` runs without error
3. `stipe doctor` shows profile compliance

## Context

From `.plans/roadmap-phase-1-remaining.md` (stipe section). CI installs and remote setups need profiles — installing cap and canopy on headless servers is wasteful and occasionally broken.
