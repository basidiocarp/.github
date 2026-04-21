# Cap Rhizome Project Boundary

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

<!-- Save as: .handoffs/cap/rhizome-project-boundary.md -->
<!-- Create verify script: .handoffs/cap/verify-rhizome-project-boundary.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

`POST /api/rhizome/project` currently accepts any existing directory path and switches
the active Rhizome project to it. That lets a caller pivot the analysis root to
arbitrary server-readable directories.

## What exists (state)

- **Route:** `cap/server/routes/rhizome/project.ts`
- **Current validation:** path exists, is accessible, and is a directory
- **Current warning:** non-project directories only generate a warning log

## What needs doing (intent)

Constrain project switching to approved roots instead of any readable directory.

---

### Step 1: Enforce Allowed Project Roots

**Project:** `cap/`
**Effort:** 60 min
**Depends on:** nothing

Introduce an allowlist check before `registry.switchProject(path)`:

- allow the current active project
- allow recent known project roots
- optionally allow extra roots from an explicit environment variable such as
  `CAP_ALLOWED_PROJECT_ROOTS`
- reject any path outside the allowlist with `400`

Treat “looks like a project” markers as advisory only; the real gate is the allowlist.

#### Files to modify

**`cap/server/routes/rhizome/project.ts`** — add the allowlist boundary check.

**`cap/server/__tests__/rhizome-project-boundary.test.ts`** — add tests for:

- allowed recent project path → success
- disallowed arbitrary directory → `400`
- non-directory path → existing rejection still works

#### Verification

```bash
cd cap && npm run test:server
```

**Output:**
<!-- PASTE START -->
PASS: Project route has explicit allowlist handling
PASS: Project route still validates directories
PASS: Boundary tests cover project boundary cases
Results: 3 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] Arbitrary readable directories are rejected
- [x] Known project roots still work
- [x] Server tests cover the new boundary

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-rhizome-project-boundary.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-rhizome-project-boundary.sh
```

**Output:**
<!-- PASTE START -->
PASS: Project route has explicit allowlist handling
PASS: Project route still validates directories
PASS: Boundary tests cover project boundary cases
Results: 3 passed, 0 failed

<!-- PASTE END -->

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsCreated from the completed Cap deep audit on 2026-04-05. This is separate from the
general boundary-documentation handoff because it is a concrete runtime boundary bug.
