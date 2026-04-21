# Lamella Skill Package Validation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** lamella/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

Lamella has strong authoring docs, but it still relies too much on human discipline. The audit set repeatedly pointed to the same missing layer: machine validation for skills, capability metadata, and packaged plugin surfaces. Without that, drift between docs, manifests, and installed behavior is too easy.

## What exists (state)

- **Lamella docs:** strong authoring guidance and package specs
- **Lamella manifests/resources:** already the source of truth for packaged content
- **No first-class validator:** there is no single Lamella-side validation surface comparable to the stronger external examples
- **Examples:** `skill-manager`, `claurst`, and `rtk` all reinforced validation and capability discipline

## What needs doing (intent)

Add Lamella-owned validation and scaffolding so that skill or plugin metadata is checked before packaging and before handoff to install surfaces.

Keep the boundary hard:

- `lamella` validates, scaffolds, and packages
- `stipe` installs, repairs, and mutates host state

---

### Step 1: Add a Lamella skill validator

**Project:** `lamella/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create a validator surface that checks:

- frontmatter presence and shape
- required fields
- allowed-tools or hook metadata shape where relevant
- host-specific metadata consistency against current Lamella authoring expectations

#### Files to modify

**`lamella/`** — add a validation command or script in the existing packaging or authoring flow.

**`lamella/docs/authoring/`** — document the validator and what it enforces.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
WARN: tools/token-reduction-optimizer/SKILL.md - missing recommended '## Workflow' section
WARN: tools/websocket-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: tools/xlsx-spreadsheets/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/backend-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/javascript-testing-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/modern-javascript-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/nextjs-app-router-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/payload/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/react-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/tailwind-design-system/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/typescript/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/zustand-store-ts/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/context-handoff/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/deliver-edge-cases/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/develop-adr/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/develop-spike-summary/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/executing-plans/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/finishing-a-development-branch/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-analyze-issue/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-create-pr/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-worktrees/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/handoff-check/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/kaizen/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/mental-models/SKILL.md - missing recommended '## Workflow' section
WARN: writing/content-writer/SKILL.md - missing recommended '## Workflow' section
WARN: writing/docs-style/SKILL.md - missing recommended '## Workflow' section
WARN: writing/humanizer/SKILL.md - missing recommended '## Workflow' section
WARN: writing/latex-posters/SKILL.md - missing recommended '## Workflow' section
WARN: writing/release-notes/SKILL.md - missing recommended '## Workflow' section
WARN: writing/voice-toolkit/SKILL.md - missing recommended '## Workflow' section
WARN: writing/writing-voice/SKILL.md - missing recommended '## Workflow' section
Validated 297 Lamella skill packages and 52 manifest alignments (221 warnings)
Skill package validator and scaffold checks passed
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (560 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.

<!-- PASTE END -->

**Checklist:**
- [x] Lamella has a machine validation surface for skills
- [x] validation checks current authoring expectations rather than stale assumptions
- [x] existing validation still passes

---

### Step 2: Add scaffolding for new skills or packaged surfaces

**Project:** `lamella/`
**Effort:** 2 hours
**Depends on:** Step 1

Add a scaffold path for new skills or related packaged surfaces so new content starts from valid metadata and structure instead of copy-paste.

#### Files to modify

**`lamella/`** — add scaffold command, script, or template-driven flow.

**`lamella/resources/` or `lamella/docs/authoring/`** — add or connect templates as needed.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
bash .handoffs/archive/lamella/verify-skill-package-validation.sh
```

**Output:**
<!-- PASTE START -->
WARN: tools/token-reduction-optimizer/SKILL.md - missing recommended '## Workflow' section
WARN: tools/websocket-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: tools/xlsx-spreadsheets/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/backend-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/javascript-testing-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/modern-javascript-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/nextjs-app-router-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/payload/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/react-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/tailwind-design-system/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/typescript/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/zustand-store-ts/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/context-handoff/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/deliver-edge-cases/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/develop-adr/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/develop-spike-summary/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/executing-plans/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/finishing-a-development-branch/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-analyze-issue/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-create-pr/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-worktrees/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/handoff-check/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/kaizen/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/mental-models/SKILL.md - missing recommended '## Workflow' section
WARN: writing/content-writer/SKILL.md - missing recommended '## Workflow' section
WARN: writing/docs-style/SKILL.md - missing recommended '## Workflow' section
WARN: writing/humanizer/SKILL.md - missing recommended '## Workflow' section
WARN: writing/latex-posters/SKILL.md - missing recommended '## Workflow' section
WARN: writing/release-notes/SKILL.md - missing recommended '## Workflow' section
WARN: writing/voice-toolkit/SKILL.md - missing recommended '## Workflow' section
WARN: writing/writing-voice/SKILL.md - missing recommended '## Workflow' section
Validated 297 Lamella skill packages and 52 manifest alignments (221 warnings)
Skill package validator and scaffold checks passed
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (560 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.

PASS: Lamella has validation surface mentioning skills
PASS: Lamella has scaffold or template flow for skills
PASS: Lamella manifests mention capability or packaged metadata
Results: 3 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] scaffold path exists for new skills or packaged surfaces
- [x] scaffold output matches current Lamella validation expectations
- [x] verify script passes

---

### Step 3: Add capability metadata and contract alignment tests

**Project:** `lamella/`
**Effort:** 3 hours
**Depends on:** Steps 1-2

Add capability declarations or equivalent package metadata where useful, and add contract-alignment tests so packaged metadata cannot silently drift from the expected install/runtime model.

#### Files to modify

**`lamella/manifests/`** — extend metadata as needed.

**`lamella/` tests or validation scripts** — add alignment checks.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -40
bash .handoffs/archive/lamella/verify-skill-package-validation.sh
```

**Output:**
<!-- PASTE START -->
WARN: tools/token-reduction-optimizer/SKILL.md - missing recommended '## Workflow' section
WARN: tools/websocket-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: tools/xlsx-spreadsheets/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/backend-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/javascript-testing-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/modern-javascript-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/nextjs-app-router-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/payload/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/react-patterns/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/tailwind-design-system/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/typescript/SKILL.md - missing recommended '## Workflow' section
WARN: typescript/zustand-store-ts/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/context-handoff/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/deliver-edge-cases/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/develop-adr/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/develop-spike-summary/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/executing-plans/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/finishing-a-development-branch/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-analyze-issue/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-create-pr/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/git-worktrees/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/handoff-check/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/kaizen/SKILL.md - missing recommended '## Workflow' section
WARN: workflow/mental-models/SKILL.md - missing recommended '## Workflow' section
WARN: writing/content-writer/SKILL.md - missing recommended '## Workflow' section
WARN: writing/docs-style/SKILL.md - missing recommended '## Workflow' section
WARN: writing/humanizer/SKILL.md - missing recommended '## Workflow' section
WARN: writing/latex-posters/SKILL.md - missing recommended '## Workflow' section
WARN: writing/release-notes/SKILL.md - missing recommended '## Workflow' section
WARN: writing/voice-toolkit/SKILL.md - missing recommended '## Workflow' section
WARN: writing/writing-voice/SKILL.md - missing recommended '## Workflow' section
Validated 297 Lamella skill packages and 52 manifest alignments (221 warnings)
Skill package validator and scaffold checks passed
Validated 128 shared subagent files
Subagent parser and emitters passed
Validated 52 manifests (560 resources)
Validated marketplace catalog (52 plugins, version 0.5.10)
Scanned 367 files (15 references checked)
Validated 8 preset files
All validators passed.

PASS: Lamella has validation surface mentioning skills
PASS: Lamella has scaffold or template flow for skills
PASS: Lamella manifests mention capability or packaged metadata
Results: 3 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] capability or equivalent package metadata exists where needed
- [x] alignment tests catch mismatches between package metadata and validation expectations
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/lamella/verify-skill-package-validation.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/lamella/verify-skill-package-validation.sh
```

**Output:**
<!-- PASTE START -->
PASS: Lamella has validation surface mentioning skills
PASS: Lamella has scaffold or template flow for skills
PASS: Lamella manifests mention capability or packaged metadata
Results: 3 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/skill-manager/ecosystem-borrow-audit.md`
- `.audit/external/audits/claurst/ecosystem-borrow-audit.md`
- `.audit/external/audits/rtk/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
