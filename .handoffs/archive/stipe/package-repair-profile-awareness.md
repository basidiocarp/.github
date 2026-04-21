# Stipe Package Repair Profile Awareness

## Problem

`stipe package` now gives Stipe a safe mutation path for packaged skills and plugins, but it still treats `--profile` as audit context only. The command always delegates to `./lamella install` without profile-specific Lamella arguments, so package repair cannot yet line up with the selected install profile.

That means the operator-facing story is still incomplete:

- `stipe doctor` can report package drift against a saved or selected profile
- `stipe package --profile <profile>` cannot yet repair that exact profile surface

This follow-up should close that gap.

## What exists (state)

- **`stipe package`:** backs up package state, runs Lamella install, records an audit log, and rolls back backups on failure
- **`stipe doctor`:** reports package inventory and package drift based on the selected or saved install profile
- **`lamella`:** remains the source of truth for package composition and install semantics

## What needs doing (intent)

Make `stipe package --profile <profile>` profile-aware without moving package metadata or package selection logic into Stipe.

Keep the boundary hard:

- `stipe` decides when package repair should run and protects host state before mutation
- `lamella` decides what a package or profile actually installs

Explicitly out of scope for this handoff:

- deeper auth freshness or token-expiry detection
- new provider auth APIs
- changes to local auth heuristics in `stipe doctor`

---

### Step 1: Wire profile-aware Lamella invocation

**Project:** `stipe/`
**Effort:** 1-2 hours
**Depends on:** nothing

Update the package repair path so the selected Stipe profile can influence the Lamella install command.

The implementation should:

- map supported Stipe profile values onto Lamella install arguments only through an explicit boundary layer
- avoid hard-coding package contents into Stipe
- preserve the current no-profile behavior when no profile is supplied
- keep backup, rollback, and audit logging intact

If Lamella does not yet expose the argument shape Stipe needs, the handoff should stop at the narrowest compatible adapter or capability check and say so in code comments or tests.

#### Files to modify

**`stipe/src/commands/package_repair.rs`** — make Lamella invocation profile-aware.

**`stipe/src/commands/install/`** — reuse or expose profile-label helpers only if needed; do not duplicate profile naming logic.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd stipe && cargo test package_repair 2>&1 | tail -40
cd stipe && cargo run -- package --profile codex --dry-run 2>&1 | tail -40
cd stipe && cargo run -- package --profile claude-code --dry-run 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe package --profile <profile>` changes the Lamella invocation path or arguments
- [ ] no-profile behavior still works
- [ ] backup and rollback scaffolding remains intact

---

### Step 2: Add regression coverage for profile-aware repair

**Project:** `stipe/`
**Effort:** 1 hour
**Depends on:** Step 1

Add focused tests around:

- Lamella root discovery from the repo root and workspace sibling layout
- profile-to-Lamella argument mapping
- dry-run output for profile-aware package repair

Prefer small unit tests over broad integration scaffolding.

#### Files to modify

**`stipe/src/commands/package_repair.rs`** — add or extend tests here if the logic stays local.

**`stipe/src/main.rs`** — only if CLI parsing coverage needs adjustment.

#### Verification

```bash
cd stipe && cargo build 2>&1 | tail -20
cd stipe && cargo test 2>&1 | tail -40
bash .handoffs/stipe/verify-package-repair-profile-awareness.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] tests cover profile-aware Lamella invocation
- [ ] dry-run output remains clear about what will happen
- [ ] full repo tests pass
- [ ] verify script passes

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-package-repair-profile-awareness.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/stipe/verify-package-repair-profile-awareness.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Follow-on from:

- `.handoffs/stipe/provider-mcp-plugin-doctor-expansion.md`

Motivated by the remaining caveat from the completed implementation:

- `stipe package` delegates to `./lamella install` without profile-specific Lamella arguments yet
