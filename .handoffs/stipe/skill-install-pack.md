# Stipe: Skill Install Pack

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/install/` (extend or new `skill_install.rs`), `stipe/src/commands/doctor/` (add skills check), `stipe/src/backup.rs` (extend for skill snapshots)
- **Cross-repo edits:** none
- **Non-goals:** no remote skill registry or CDN; no dependency resolution between skills; no auto-update; no lamella build pipeline changes
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from skill-management-and-council-adoption-plan Track A Phase 2:

> "Stipe owns install, backup, and rollback for binary tools. Skills are a new install target: markdown files that go to the host's Claude config directory. Stipe needs a skill-specific install path that reuses existing backup and rollback infrastructure."

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:**
  - `stipe/src/commands/install/runner.rs` — existing tool install with release verification; read before adding
  - `stipe/src/backup.rs` — existing pre-install backup and manifest; extend for skill snapshots
  - `stipe/src/commands/rollback.rs` — existing rollback via snapshot; reuse without modification
  - `stipe/src/commands/install/skill_install.rs` (new) — skill install logic
  - `stipe/src/commands/doctor/` — add skills check to existing doctor flow
- **Reference seams:**
  - `stipe/src/commands/install/runner.rs` — understand the install lifecycle (backup → install → verify → rollback on failure) to mirror it for skills
  - `stipe/src/backup.rs` — understand snapshot manifest format before extending
  - `stipe/src/commands/doctor/` — understand how doctor checks are registered
- **Spawn gate:** read all three existing files before spawning; the skill install must mirror the tool install lifecycle exactly

## Problem

Stipe installs binary tools and manages their backup and rollback. Skills are a distinct install target: they are markdown files, not binaries, and they go to the host's Claude skill directory rather than a bin path. Today there is no `stipe install-skills` command, so operators who want to install a lamella skill pack must copy files manually, with no backup, no checksum verification, and no rollback path. This handoff adds the missing skill install surface while reusing existing backup and rollback infrastructure.

## What needs doing (intent)

1. Add `stipe install-skills <pack-path>` subcommand to stipe's command surface
2. Define the skill pack format: a directory or `.tar.gz` with a `skills.json` manifest listing skill files and their target paths
3. Pre-install: create a skill snapshot via extended `backup.rs`
4. Install: copy skill files to host target paths (default: `~/.config/basidiocarp/skills/`)
5. Post-install: verify each installed file exists and matches the manifest SHA-256 checksum
6. Repair: if verification fails, roll back via existing `rollback.rs`
7. Add `stipe doctor skills` check: verify installed skills match the last-installed pack manifest

## Data model

```rust
/// Manifest file (`skills.json`) inside a skill pack.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SkillPackManifest {
    pub pack_name: String,
    pub version: String,
    pub skills: Vec<SkillEntry>,
}

/// A single skill file in the pack.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SkillEntry {
    /// Filename or relative path inside the pack archive.
    pub name: String,
    /// Relative path inside the pack to the source file.
    pub source_path: String,
    /// Absolute or `~`-prefixed path on the host where the file will be installed.
    pub target_path: String,
    /// Lowercase hex SHA-256 of the source file content.
    pub sha256: String,
}

/// Result of post-install verification for a single skill.
#[derive(Debug, Clone)]
pub struct SkillVerifyResult {
    pub entry: SkillEntry,
    pub status: SkillVerifyStatus,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SkillVerifyStatus {
    /// File present and checksum matches.
    Ok,
    /// File missing from target path.
    Missing,
    /// File present but checksum does not match.
    ChecksumMismatch { actual: String },
}
```

## Install lifecycle

Mirror the existing tool install lifecycle:

1. **Validate pack**: parse `skills.json`; error early if malformed or if any `source_path` is missing from the pack
2. **Snapshot**: call extended `backup::create_skill_snapshot()` to record current state of all target paths named in the manifest
3. **Install**: for each `SkillEntry`, copy the source file to `target_path` (create intermediate directories as needed)
4. **Verify**: SHA-256 each installed file against the manifest; collect `Vec<SkillVerifyResult>`
5. **Repair**: if any result is not `Ok`, call `rollback::restore_skill_snapshot()` and return an error describing the failed entries
6. **Record**: write the installed manifest to `~/.config/basidiocarp/skills/.installed-manifest.json` for use by `doctor skills`

## Doctor skills check

Add a `skills` check to `stipe doctor` that:
- Reads `~/.config/basidiocarp/skills/.installed-manifest.json`
- Re-runs SHA-256 verification for every entry
- Reports `Ok`, `Missing`, or `ChecksumMismatch` per skill
- Exits non-zero if any skill is not `Ok`

## Scope

- **Allowed files:** `stipe/src/commands/install/skill_install.rs` (new), `stipe/src/commands/doctor/` (add skills check), `stipe/src/backup.rs` (extend for skill snapshots), `stipe/src/commands/` (register new subcommand)
- **Explicit non-goals:**
  - No remote skill registry, CDN, or network fetch
  - No dependency resolution between skills
  - No auto-update or watch mode
  - No changes to binary tool install or rollback paths
  - No lamella build pipeline changes

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `stipe/src/commands/install/runner.rs` — exact install lifecycle; what does the backup call look like? What is the verification pattern?
2. `stipe/src/backup.rs` — snapshot manifest format; is there already a generic snapshot type or is it binary-specific?
3. `stipe/src/commands/rollback.rs` — rollback API; can it accept a skill snapshot without changes?
4. `stipe/src/commands/doctor/` — how are doctor checks registered and run?

---

### Step 1: Define SkillPackManifest and SkillEntry

**Project:** `stipe/`
**Effort:** small
**Depends on:** Step 0

Create `src/commands/install/skill_install.rs` with `SkillPackManifest`, `SkillEntry`, `SkillVerifyResult`, and `SkillVerifyStatus`. Add a `load_manifest` function that reads and parses `skills.json` from a directory or `.tar.gz` pack.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5
```

**Checklist:**
- [ ] `SkillPackManifest` and `SkillEntry` compile with serde derives
- [ ] `SkillVerifyStatus` variants compile
- [ ] `load_manifest` parses a valid `skills.json` without error

---

### Step 2: Extend backup.rs for skill snapshots

**Project:** `stipe/`
**Effort:** small
**Depends on:** Step 1

Add `create_skill_snapshot(manifest: &SkillPackManifest) -> Result<SkillSnapshot>` and `restore_skill_snapshot(snapshot: &SkillSnapshot) -> Result<()>` to `backup.rs`. A skill snapshot records the pre-install content (or absence) of each target path named in the manifest.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5
```

**Checklist:**
- [ ] `create_skill_snapshot` captures current state of all target paths
- [ ] `restore_skill_snapshot` restores files from snapshot (removes newly installed files if they were absent before)
- [ ] Existing binary snapshot behavior is unchanged

---

### Step 3: Implement install-skills subcommand

**Project:** `stipe/`
**Effort:** small
**Depends on:** Step 2

Implement the full install lifecycle in `skill_install.rs`: validate pack → snapshot → install → verify → repair on failure → record installed manifest. Register `install-skills <pack-path>` as a subcommand in stipe's CLI.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5
cd stipe && cargo test skill_install 2>&1 | tail -20
```

**Checklist:**
- [ ] `stipe install-skills <path>` is reachable from the CLI
- [ ] Snapshot is created before any file is written
- [ ] Verification runs after install; checksum mismatches trigger rollback
- [ ] Installed manifest is written to `~/.config/basidiocarp/skills/.installed-manifest.json`

---

### Step 4: Add doctor skills check

**Project:** `stipe/`
**Effort:** small
**Depends on:** Step 3

Add a `skills` check to `stipe doctor`. Reads the installed manifest, re-verifies all files, reports per-skill status, exits non-zero on any failure.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5
cd stipe && cargo test doctor 2>&1 | tail -20
```

**Checklist:**
- [ ] `stipe doctor skills` runs without error when manifest is present
- [ ] Reports `Missing` when a skill file has been deleted after install
- [ ] Reports `ChecksumMismatch` when a skill file has been modified after install
- [ ] Exits non-zero when any skill is not `Ok`

---

### Step 5: Full suite

```bash
cd stipe && cargo test 2>&1 | tail -20
cd stipe && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd stipe && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] All tests pass in stipe
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output
2. Full test suite passes in stipe
3. All checklist items checked
4. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- `septa/skill-pack-manifest-v1.schema.json` — if skill pack manifests need to cross tool boundaries
- Remote pack fetch: `stipe install-skills <url>` with signature verification
- `stipe update-skills` subcommand for upgrading an installed pack
- `lamella`: build step that produces a `.tar.gz` skill pack with `skills.json` from `resources/skills/`
- `cap`: surface installed skill status in the operator dashboard

## Context

Spawned from skill-management-and-council-adoption-plan Track A Phase 2 (2026-04-23). Stipe already has install, backup, and rollback infrastructure for binary tools. Skills are a new install target with the same lifecycle requirements. Reusing the existing snapshot and rollback paths keeps the implementation narrow and the operational model consistent: operators who already understand `stipe doctor` and `stipe rollback` will find the skill variants familiar.
