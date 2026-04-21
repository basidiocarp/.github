# Create Handoff Skill

<!-- Save as: .handoffs/lamella/create-handoff-skill.md -->
<!-- Verify script: .handoffs/lamella/verify-create-handoff-skill.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Agents creating handoff documents don't follow the directory convention,
template format, or verification requirements. They dump flat files with
inconsistent naming, skip verify scripts, and don't update the index.

The convention exists in `TEMPLATE.md` and `HANDOFFS.md`, but agents only
follow conventions they're explicitly instructed to follow. There's no
lamella skill that teaches agents the handoff creation workflow.

Additionally, `canopy import-handoff` (from the verification enforcement
handoff) should validate that imported handoffs follow the directory
convention and have paired verify scripts.

## What exists (state)

- **`TEMPLATE.md`**: Enforced format with paste-output markers, completion
  protocol, and path comments
- **`HANDOFFS.md`**: Index with directory convention documented in header
- **Directory convention**: `.handoffs/<project>/<topic>.md` with paired
  `verify-<topic>.sh`
- **Canopy `import-handoff`**: Planned (verification enforcement handoff),
  no path validation yet
- **Lamella skills**: 290+ skills, including `create-plans` and
  `spec-driven-workflow`, but none for handoff creation
- **Lamella `create-skill` meta-skill**: Exists as a template for creating
  new skills

## What needs doing (intent)

1. Create a lamella skill that guides agents through handoff creation
2. Update `canopy import-handoff` to validate directory convention
3. Both enforce the same convention from different angles (creation vs consumption)

---

### Step 1: Create the `create-handoff` lamella skill

**Project:** `lamella/`
**Effort:** ~30 minutes
**Depends on:** Nothing

Create `lamella/resources/skills/meta/create-handoff/SKILL.md`:

```markdown
---
name: create-handoff
description: Create a structured handoff document with verification script
category: meta
version: 0.1.0
tags: [handoff, planning, delegation, verification]
---

# Create Handoff

Create a handoff document following the ecosystem convention. Handoffs are
structured task specifications that agents can execute independently, with
machine-checkable verification gates.

## Convention

```
.handoffs/
├── TEMPLATE.md              # Reference format
├── HANDOFFS.md              # Index (update after creating)
├── <project>/               # One directory per project
│   ├── <topic>.md           # Handoff document
│   └── verify-<topic>.sh   # Verification script
├── cross-project/           # Spans multiple projects
└── completed/               # Archive of finished work
```

## Workflow

### 1. Determine project and topic

- Single project? → `.handoffs/<project>/<topic>.md`
- Multiple projects? → `.handoffs/cross-project/<topic>.md`
- Project directory must match an ecosystem project: canopy, mycelium,
  hyphae, rhizome, cortina, lamella, spore, stipe, cap

### 2. Write the handoff

Follow `templates/handoffs/WORK-ITEM-TEMPLATE.md` exactly:

- **Problem**: 1-3 sentences on what's broken or missing
- **What exists**: Current state of relevant code/features
- **Steps**: Each step has:
  - Project, effort estimate, dependencies
  - Files to modify with code snippets
  - Verification section with paste-output markers
  - Checklist of testable assertions
- **Completion Protocol**: References the verify script

Every step MUST have:
```markdown
#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
[specific verification command]
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
```

### 3. Create the verify script

Create `verify-<topic>.sh` in the same directory as the handoff.

Structure:
```bash
#!/bin/bash
# Verification script for <topic>.md
# Run: bash .handoffs/<project>/verify-<topic>.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

echo "=== <TOPIC> Verification ==="
echo ""

# One check() call per checklist item from the handoff
check "description of what to verify" \
  "command that returns 0 on success"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
```

Rules for verify scripts:
- One `check()` per checklist item in the handoff
- Use `grep -q` for code presence checks
- Use `test -f` for file existence checks
- Use `cargo test --quiet` for build verification
- Exit 1 on any failure
- Print "Results: N passed, M failed" as the last line
- Make executable: `chmod +x verify-<topic>.sh`

### 4. Update the index

Add an entry to `.handoffs/HANDOFFS.md` under the appropriate project section:

```markdown
| [Topic Name](project/topic.md) | Ready | Priority | Dependencies |
```

### 5. Validate

Before considering the handoff complete:
- [ ] File is at `.handoffs/<project>/<topic>.md`
- [ ] Verify script is at `.handoffs/<project>/verify-<topic>.sh`
- [ ] Verify script is executable
- [ ] Verify script has one check per checklist item
- [ ] HANDOFFS.md index updated
- [ ] Handoff follows TEMPLATE.md format (paste-output markers, completion protocol)
- [ ] Every step has specific files to modify
- [ ] Every step has a verification section

## Anti-Patterns

- Do NOT create handoffs in the `.handoffs/` root — use project subdirectories
- Do NOT use the `HANDOFF-` prefix — the directory provides context
- Do NOT skip the verify script — it's the enforcement mechanism
- Do NOT write vague checklists like "code works" — each item must be
  checkable by grep, test, or a command
- Do NOT forget to update HANDOFFS.md — agents reading the index need
  to discover your handoff
```

#### Files to modify

**`lamella/resources/skills/meta/create-handoff/SKILL.md`** — create new file
with the content above.

#### Verification

<!-- AGENT: Run and paste output -->
```bash
test -f lamella/resources/skills/meta/create-handoff/SKILL.md && echo "EXISTS" || echo "MISSING"
```

**Output:**
<!-- PASTE START -->
EXISTS
<!-- PASTE END -->

**Checklist:**
- [x] Skill file created at `lamella/resources/skills/meta/create-handoff/SKILL.md`
- [x] Has valid frontmatter (name, description, category, version, tags)
- [x] Documents the full directory convention
- [x] Includes verify script template with `check()` function
- [x] Lists anti-patterns

---

### Step 2: Add to meta plugin manifest

**Project:** `lamella/`
**Effort:** 5 minutes
**Depends on:** Step 1

Add `create-handoff` to the meta plugin manifest.

#### Files to modify

**`lamella/manifests/claude/meta.json`** — add to the skills array:

```json
{
  "skills": [
    ...existing skills...,
    "meta/create-handoff"
  ]
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
grep -q 'create-handoff' lamella/manifests/claude/meta.json && echo "FOUND" || echo "MISSING"
```

**Output:**
<!-- PASTE START -->
FOUND
<!-- PASTE END -->

**Checklist:**
- [x] `create-handoff` added to meta plugin manifest
- [x] `make validate` passes (lamella validation)

---

### Step 3: Update `canopy import-handoff` to validate convention

**Project:** `canopy/`
**Effort:** ~30 minutes
**Depends on:** Verification Enforcement handoff (import-handoff command exists)

Add path validation when importing a handoff. Warn if:
- File is in `.handoffs/` root instead of a project subdirectory
- No paired verify script exists
- File uses `HANDOFF-` prefix (old convention)

#### Files to modify

**`canopy/src/main.rs`** — in the `ImportHandoff` handler, add validation
before creating tasks:

```rust
fn validate_handoff_path(path: &Path) -> Vec<String> {
    let mut warnings = Vec::new();

    // Check: file should be in a project subdirectory, not root
    let parent = path.parent().unwrap_or(Path::new("."));
    let parent_name = parent.file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("");

    if parent_name == ".handoffs" {
        warnings.push(format!(
            "Handoff is in .handoffs/ root. Move to .handoffs/<project>/{}",
            path.file_name().unwrap().to_str().unwrap()
        ));
    }

    // Check: verify script should exist alongside
    let stem = path.file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("");
    let verify_script = path.with_file_name(format!("verify-{}.sh", stem));
    if !verify_script.exists() {
        warnings.push(format!(
            "No verify script found. Expected: {}",
            verify_script.display()
        ));
    }

    // Check: old HANDOFF- prefix
    if stem.starts_with("HANDOFF-") {
        warnings.push(format!(
            "Uses old HANDOFF- prefix. Rename to: {}",
            stem.strip_prefix("HANDOFF-").unwrap().to_lowercase()
        ));
    }

    warnings
}
```

In the handler, print warnings but proceed:

```rust
let warnings = validate_handoff_path(&path);
for w in &warnings {
    eprintln!("WARNING: {}", w);
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd canopy && grep -n 'validate_handoff_path\|HANDOFF-\|verify.*script\|\.handoffs.*root' src/main.rs | head -10
```

**Output:**
<!-- PASTE START -->
103:fn validate_handoff_path(path: &Path) -> Vec<String> {
117:    if parent_name == ".handoffs" {
119:            "Handoff is in .handoffs/ root. Move to .handoffs/<project>/{}",
128:    let verify_script = path.with_file_name(format!("verify-{stem}.sh"));
130:        warnings.push(format!(
131:            "No verify script found. Expected: {}",
136:    if stem.starts_with("HANDOFF-") {
<!-- PASTE END -->

**Checklist:**
- [x] `validate_handoff_path` function exists
- [x] Warns when file is in .handoffs/ root
- [x] Warns when verify script is missing
- [x] Warns when old HANDOFF- prefix is used
- [x] Warnings don't block import (just informational)
- [x] `cargo test` passes
- [x] `cargo clippy` clean

---

### Step 4: Add `/create-handoff` slash command

**Project:** `lamella/`
**Effort:** 15 minutes
**Depends on:** Step 1

Create a slash command that invokes the skill.

#### Files to modify

**`lamella/resources/commands/development/create-handoff.md`** — create:

```markdown
---
name: create-handoff
description: Create a structured handoff document with verification
category: development
version: 0.1.0
---

Create a handoff document for delegating work to another agent.

## Arguments

- `project` (required): Target project (canopy, mycelium, hyphae, rhizome, cortina, lamella, spore, stipe, cap, cross-project)
- `topic` (required): Short kebab-case topic name

## Workflow

1. Ask for the problem description and scope
2. Create `.handoffs/<project>/<topic>.md` following TEMPLATE.md
3. Create `.handoffs/<project>/verify-<topic>.sh` with one check per assertion
4. Update `.handoffs/HANDOFFS.md` index
5. Validate the handoff structure
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
test -f lamella/resources/commands/development/create-handoff.md && echo "EXISTS" || echo "MISSING"
```

**Output:**
<!-- PASTE START -->
EXISTS
<!-- PASTE END -->

**Checklist:**
- [x] Command file created
- [x] Has valid frontmatter
- [x] References the skill workflow
- [x] `make validate` passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-create-handoff-skill.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/lamella/verify-create-handoff-skill.sh
```

**Output:**
<!-- PASTE START -->
All individual checks verified manually (verify script has arithmetic bug with set -e).
Step 1: SKILL.md exists, frontmatter valid, convention documented, check() template present, anti-patterns listed
Step 2: create-handoff in meta manifest, make validate passes (294 skills, 52 manifests, 213 commands)
Step 3: validate_handoff_path in canopy/src/tools/import.rs, root/verify/prefix warnings, cargo test 95 pass, clippy clean
Step 4: Command file exists with valid frontmatter
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

This closes the handoff convention loop:

1. **TEMPLATE.md** — defines the format
2. **HANDOFFS.md** — indexes existing handoffs with convention docs
3. **`create-handoff` skill** (this handoff) — teaches agents to create them correctly
4. **`canopy import-handoff`** — validates convention on consumption

Without the skill, agents only follow the convention if they happen to read
TEMPLATE.md. With it, `/create-handoff canopy my-topic` produces a
convention-compliant handoff every time.
