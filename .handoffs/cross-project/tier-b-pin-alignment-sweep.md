# Cross-Project: Tier B Pin Alignment Sweep (F3.2 + F3.3 + F3.4 + F3.5 + F3.6 + F3.7)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root + volva + hymenium + cortina + mycelium
- **Allowed write scope:** `volva/Cargo.toml` (and `volva/crates/volva-runtime/Cargo.toml`, `volva/crates/volva-core/Cargo.toml`), `hymenium/Cargo.toml`, `cortina/Cargo.toml`, `ecosystem-versions.toml`
- **Cross-repo edits:** yes — five repos at root + workspace pin file
- **Non-goals:** does not address spore rev drift (separate handoff `spore-rev-pin-decision.md`); does not change source code; does not bump versions beyond what the audit names
- **Verification contract:** `bash .handoffs/cross-project/verify-tier-b-pin-alignment-sweep.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem

Lane 3 (2026-04-30 audit) found 6 non-spore drifts in shared dependency pins:

| ID | Severity | Repo | Dep | Declared | Workspace pin |
|----|----------|------|-----|----------|---------------|
| F3.2 | blocker | `volva-runtime` | `rusqlite` | `0.31` | `0.39` |
| F3.3 | blocker | `volva-core` + `volva-runtime` | `thiserror` | `1` | `2` |
| F3.4 | blocker | `hymenium` | `which` | `6` | `7` |
| F3.5 | concern | `cortina` | `toml` | `0.8` | `1` |
| F3.6 | concern | `mycelium` | `clap_complete` | `4` (not in pin file) | undocumented |
| F3.7 | nit | hyphae/mycelium/rhizome/stipe/spore | `toml` | `1.1` | `1` |

## Scope

Single coordinated sweep:
- F3.2 + F3.3: bump `volva-core` and `volva-runtime` Cargo.toml to match the workspace pins.
- F3.4: bump `hymenium/Cargo.toml` `which` pin.
- F3.5: bump `cortina/Cargo.toml` `toml` pin.
- F3.6: add `clap_complete` to `ecosystem-versions.toml` at the version mycelium uses (or remove it from mycelium if it's not needed).
- F3.7: align the `1.1` pins to `1` (or bump the workspace doc to `1.1`) — operator's call; default to matching the workspace pin to keep one source of truth.

Each bump must be followed by `cargo build` + `cargo test` in the affected repo to confirm no breakage.

## Step 1 — Capture current state

```bash
cat /Users/williamnewton/projects/personal/basidiocarp/ecosystem-versions.toml
grep -nE '^(rusqlite|thiserror|which|toml|clap_complete)\s*=' \
  /Users/williamnewton/projects/personal/basidiocarp/volva/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/volva/crates/*/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/hymenium/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/cortina/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/mycelium/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/hyphae/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/rhizome/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/stipe/Cargo.toml \
  /Users/williamnewton/projects/personal/basidiocarp/spore/Cargo.toml \
  2>/dev/null
```

## Step 2 — Apply F3.2 (volva rusqlite)

Bump `rusqlite` in `volva/crates/volva-runtime/Cargo.toml` from `0.31` to `0.39` (or whatever the workspace pin reads). Build + test volva.

If the bump introduces a real breaking change in the rusqlite API surface volva uses, **stop** and surface it as a finding — that becomes a follow-up code handoff, not just a pin bump.

## Step 3 — Apply F3.3 (volva thiserror)

Bump `thiserror` in `volva/crates/volva-core/Cargo.toml` and `volva/crates/volva-runtime/Cargo.toml` from `1` to `2`. Same caveat: if the upgrade requires Rust code changes (it might — thiserror 2 has some breaking changes), surface and stop.

## Step 4 — Apply F3.4 (hymenium which)

Bump `which` in `hymenium/Cargo.toml` from `6` to `7`. Build + test hymenium.

## Step 5 — Apply F3.5 (cortina toml)

Bump `toml` in `cortina/Cargo.toml` from `0.8` to `1`. Build + test cortina.

## Step 6 — Apply F3.6 (mycelium clap_complete)

Either:
- Add `clap_complete` to `ecosystem-versions.toml` at the version mycelium currently uses (it's not in the doc today), OR
- Confirm mycelium actually needs it — if not, remove it from `mycelium/Cargo.toml`.

Default: add to `ecosystem-versions.toml` (we want the pin file to reflect what's actually used).

## Step 7 — Apply F3.7 (toml 1.1 vs 1)

Pick a single version. Default: align all consumers to the workspace pin (`1`). Update any `1.1` pins to `1`.

## Step 8 — Per-repo confirm

```bash
for repo in volva hymenium cortina mycelium; do
  (cd /Users/williamnewton/projects/personal/basidiocarp/$repo && cargo build --release && cargo test) || echo "FAIL $repo"
done
```

## Style Notes

- One bump per step — don't conflate "pin bump" with "code refactor". If a bump requires code changes, stop and raise a code handoff.
- `ecosystem-versions.toml` is the source of truth — the pin file should reflect reality after this handoff.
- Don't touch spore rev (separate handoff).

## Verify Script

`bash .handoffs/cross-project/verify-tier-b-pin-alignment-sweep.sh` confirms:
- All flagged drifts are resolved (per-dep grep)
- All affected repos build cleanly
- `ecosystem-versions.toml` has been updated where needed

## Context

Closes lane 3 findings F3.2, F3.3, F3.4, F3.5, F3.6, F3.7 from the 2026-04-30 audit.
