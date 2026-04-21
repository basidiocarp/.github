# Handoff Checkbox and Paste Marker Enforcement

<!-- Save as: .handoffs/cross-project/handoff-checkbox-enforcement.md -->
<!-- Create verify script: .handoffs/cross-project/verify-handoff-checkbox-enforcement.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Agents skip handoff checklist items and leave paste markers empty before
claiming steps complete. There is no enforcement mechanism to prevent forward
progress with unchecked boxes or unfilled output blocks, so verification
claims lack evidence.

## What exists (state)

- **Handoff template:** `templates/handoffs/WORK-ITEM-TEMPLATE.md` defines `<!-- PASTE START -->`
  / `<!-- PASTE END -->` markers and checkbox conventions
- **Verify scripts:** Every handoff has a paired `verify-*.sh` that checks
  implementation artifacts, but none check the handoff markdown itself
- **Cortina hooks:** `cortina/src/hooks/` has `pre_tool_use.rs` and stop hook
  infrastructure but no handoff-file validation
- **Lamella skills:** No `/handoff-check` skill exists yet
- **Pre-commit hooks:** No hook validates handoff file integrity on commit

## What needs doing (intent)

Add enforcement at two layers: a cortina stop hook that warns on session end
when handoff files have empty paste markers or unchecked items, and a lamella
skill that agents can invoke to audit their handoff progress before claiming
completion.

---

### Step 1: Handoff Markdown Parser (shared utility)

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** nothing

Create a parser that extracts checklist status and paste marker contents from
handoff markdown files. This will be used by both the stop hook and the
lamella skill.

#### Files to modify

**`cortina/src/handoff_lint.rs`** — new module with parsing functions:

```rust
pub struct HandoffAudit {
    pub file: PathBuf,
    pub total_checkboxes: usize,
    pub checked_checkboxes: usize,
    pub empty_paste_markers: Vec<usize>,  // line numbers
}

pub fn audit_handoff(path: &Path) -> Result<HandoffAudit> {
    // Parse markdown for:
    // - [ ] vs [x] checkbox counts
    // - <!-- PASTE START --> immediately followed by <!-- PASTE END -->
}
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd cortina && cargo test handoff_lint --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable

running 3 tests
...
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 145 filtered out; finished in 0.01s

<!-- PASTE END -->

**Checklist:**
- [x] `HandoffAudit` struct captures checkbox counts and empty paste markers
- [x] Parser correctly counts `- [ ]` and `- [x]` checkboxes
- [x] Parser detects empty paste blocks (no content between markers)
- [x] At least 3 unit tests: all checked, some unchecked, empty paste markers

---

### Step 2: Cortina Stop Hook — Handoff Validation

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Add a stop hook handler that checks if any `.handoffs/**/*.md` files were
modified during the session. If so, audit them for unfilled paste markers
and unchecked items. Emit a warning with specifics.

#### Files to modify

**`cortina/src/hooks/stop.rs`** — add handoff validation to session-end hook:

```rust
fn check_handoff_completion(session_files: &[PathBuf]) -> Vec<String> {
    // Filter for .handoffs/**/*.md files
    // Run audit_handoff on each
    // Return warnings for empty paste markers and unchecked items
}
```

**`cortina/src/policy.rs`** — add `handoff_lint_enabled` policy flag
(default: true).

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd cortina && cargo test stop --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
running 19 tests
...................
test result: ok. 19 passed; 0 failed; 0 ignored; 0 measured; 129 filtered out; finished in 5.04s

<!-- PASTE END -->

**Checklist:**
- [x] Stop hook identifies modified `.handoffs/**/*.md` files
- [x] Warnings list specific unchecked items and empty paste markers with line numbers
- [x] Policy flag `handoff_lint_enabled` controls whether the check runs
- [x] Warning output includes actionable instructions (which file, which markers)

---

### Step 3: Lamella `/handoff-check` Skill

**Project:** `lamella/`
**Effort:** 1-2 hours
**Depends on:** nothing (uses shell parsing, not cortina's Rust parser)

Create a lamella skill that agents invoke to audit their active handoff before
claiming completion. The skill scans the handoff markdown, reports unchecked
items and empty paste markers, and refuses to confirm completion if any remain.

#### Files to modify

**`lamella/resources/skills/workflow/handoff-check/SKILL.md`** — new skill:

```markdown
# /handoff-check — Audit Active Handoff

Scan the active handoff document for:
1. Unchecked checklist items (`- [ ]`)
2. Empty paste markers (no content between PASTE START/END)
3. Missing verification script output

Report findings and block completion claims if issues exist.
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
test -f lamella/resources/skills/workflow/handoff-check/SKILL.md && echo "Skill file exists"
grep -c 'PASTE' lamella/resources/skills/workflow/handoff-check/SKILL.md
```

**Output:**
<!-- PASTE START -->
Skill file exists
3

<!-- PASTE END -->

**Checklist:**
- [x] Skill file exists at the expected path
- [x] Skill instructions cover checkbox audit, paste marker audit, and verification script
- [x] Skill explicitly blocks completion claims when issues are found

---

### Step 4: Pre-Commit Hook (optional hardening)

**Project:** `cortina/`
**Effort:** 1 hour
**Depends on:** Step 1

Add a pre-commit-time warning: if `.handoffs/**/*.md` files were modified in
the current Cortina session, validate that no empty paste markers remain and
that no unchecked checklist items remain before the commit proceeds.

#### Files to modify

**`cortina/src/hooks/pre_commit.rs`** — add handoff file validation:

```rust
fn validate_session_handoffs(handoff_files: &[PathBuf]) -> Result<Vec<String>> {
    // Audit handoff files touched in the current Cortina session
    // Warn on empty paste markers
    // Warn on unchecked checklist items
}
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd cortina && cargo test pre_commit --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable

running 4 tests
....
test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 144 filtered out; finished in 0.00s

<!-- PASTE END -->

**Checklist:**
- [x] Pre-commit-time warning detects handoff files touched in the current session
- [x] Empty paste markers in touched handoffs produce a warning
- [x] Unchecked checklist items in touched handoffs produce a warning

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cross-project/verify-handoff-checkbox-enforcement.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/cross-project/verify-handoff-checkbox-enforcement.sh
```

**Output:**
<!-- PASTE START -->
=== Handoff Checkbox Enforcement Verification ===

--- Step 1: Handoff Markdown Parser ---
  PASS: handoff_lint module exists
  PASS: HandoffAudit struct defined
  PASS: checkbox counting logic
  PASS: paste marker detection

--- Step 2: Cortina Stop Hook ---
  PASS: handoff validation in stop hook
  PASS: handoff_lint_enabled policy flag

--- Step 3: Lamella Skill ---
  PASS: handoff-check skill exists
  PASS: skill covers paste markers
  PASS: skill covers checkboxes

--- Step 4: Pre-Commit Hook (optional) ---
  PASS: pre-commit handoff validation exists

--- Build Verification ---
  PASS: cortina cargo test passes
  PASS: cortina cargo clippy clean

================================
Results: 12 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

Originated from OBS-002 (2026-04-03). Agents claimed verification passes
without pasting output and moved forward with unchecked boxes. The cortina
stop hook is the primary enforcement layer; the lamella skill is the
self-service layer; the pre-commit hook is optional hardening.
