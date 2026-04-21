# CI Single-Source Skill Sync

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** skill content authoring, eval harness (separate handoff), or plugin manifest format standardization
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-single-source-skill-sync.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** `.github/workflows/` for CI, `Makefile` for local validation, and skill source directories
- **Reference seams:** caveman `.github/workflows/sync-skill.yml:32-89` for the full CI workflow; existing lamella `make validate` and `make build-marketplace` for integration points
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Lamella packages skills for multiple agent hosts (Claude Code, Codex, Gemini, and others) but does not enforce that one canonical source drives all agent-specific outputs. When a skill is updated, each agent-specific copy must be manually synchronized. This creates drift risk: an update to the canonical skill may not reach all targets, or targets may diverge from each other. Caveman demonstrates the full workflow: one canonical SKILL.md, CI copies it to every agent-specific location, rebuilds the distribution artifact, and prepends per-agent frontmatter automatically.

## What exists (state)

- **`lamella`:** packages skills with `make build-marketplace`; validates with `make validate`
- **No CI enforcement:** there is no workflow that verifies all agent-specific skill copies match their canonical source
- **caveman reference:** a working `.github/workflows/sync-skill.yml` that copies canonical → targets, rebuilds ZIP, prepends per-agent frontmatter, and uses `[skip ci]` on commit-back

## What needs doing (intent)

1. Designate canonical source locations for each skill in lamella.
2. Add a CI workflow (or extend existing validation) that verifies all agent-specific copies are derived from and consistent with the canonical source.
3. Add a sync script that copies canonical → agent-specific targets with optional per-agent frontmatter prepending.
4. Integrate sync verification into `make validate` so local development catches drift before CI does.

## Scope

- **Primary seam:** skill distribution and consistency enforcement
- **Allowed files:** `lamella/` CI workflows, Makefile, and skill sync scripts
- **Explicit non-goals:**
  - Do not change skill content or authoring format in this handoff
  - Do not build the eval harness (separate handoff #125)
  - Do not standardize plugin manifest formats across agents (separate concern)

---

### Step 1: Define canonical source locations and agent targets

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** nothing

Create a manifest (e.g., `skill-sync.toml` or a section in the Makefile) that maps each skill's canonical source path to its agent-specific target paths. Document which agent targets exist and how per-agent frontmatter differences are expressed.

#### Verification

```bash
cd lamella && cat skill-sync.toml 2>/dev/null || grep -r "sync\|canonical" Makefile
```

**Checklist:**
- [ ] Canonical-to-target mapping is documented
- [ ] Each skill has exactly one canonical source

---

### Step 2: Add sync script

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** Step 1

Write a script that reads the manifest, copies canonical content to each target, and prepends any per-agent frontmatter. The script should be idempotent and report which files changed.

#### Verification

```bash
cd lamella && bash scripts/sync-skills.sh --dry-run 2>&1
```

**Checklist:**
- [ ] Script reads the canonical-to-target manifest
- [ ] Dry-run mode reports what would change without modifying files
- [ ] Per-agent frontmatter is prepended correctly

---

### Step 3: Integrate into validation and CI

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** Step 2

Add a `make sync-check` target that runs the sync in dry-run mode and fails if any target is out of date. Wire this into `make validate` and into CI so drift is caught before merge.

#### Verification

```bash
cd lamella && make validate 2>&1
```

**Checklist:**
- [ ] `make sync-check` fails when targets are out of date
- [ ] `make validate` includes the sync check
- [ ] CI catches skill drift before merge

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-single-source-skill-sync.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-single-source-skill-sync.sh
```

## Context

Source: caveman ecosystem borrow audit (2026-04-14) section "CI single-source skill sync." See `.audit/external/audits/caveman-ecosystem-borrow-audit.md` for the reference CI workflow.

Related handoffs: #125 Three-Arm Eval Harness (also lamella). The sync infrastructure established here is a prerequisite for meaningful skill evaluation — you cannot measure skill quality if the skill content has drifted across targets.
