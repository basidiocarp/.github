# Handoff: Canopy Verification Enforcement for Agent Handoffs

## Problem

Agents (Codex, Claude Code subagents) claim handoff tasks are complete without
verifying all steps. HANDOFF-TOOL-NUDGING was delegated to Codex and came back
75% done — Steps 2-3 were implemented but Step 1 (rule file) and Step 4
(find→fd rewrite) were skipped entirely. The agent reported success.

Current handoffs have verification checklists, but nothing forces the agent to
run them. Checklists are aspirational, not enforced.

## Design

Use Canopy's existing task/verification/evidence system to enforce completion.
When a handoff is delegated to an agent, it becomes a Canopy task tree with
machine-checkable verification gates.

### Flow

```
Handoff created (.handoffs/HANDOFF-*.md)
    │
    ▼
canopy import-handoff HANDOFF-TOOL-NUDGING.md
    │
    ├── Creates parent task: "Tool Nudging"
    ├── Creates subtask per step: "Step 1: Rule file", "Step 2: Read advisory", ...
    ├── Each subtask has: required_role=implementer, verification_required=true
    └── Links verify script as evidence requirement
    │
    ▼
Agent assigned (Codex, subagent, etc.)
    │
    ├── Agent works on Step 1
    ├── Agent runs: canopy task verify <step1-id> --script .handoffs/verify-tool-nudging.sh
    │     └── Script runs, PASS/FAIL recorded as evidence
    ├── If PASS: subtask marked complete
    ├── If FAIL: subtask stays in-progress, attention score rises
    └── Repeat for each step
    │
    ▼
Parent task auto-completes only when ALL subtasks verified
```

### Key Invariant

**A task cannot be marked complete unless its verification evidence shows PASS.**

This is the enforcement mechanism. The agent can claim done, but Canopy won't
accept it without evidence.

## What exists (state)

- **Canopy tasks:** Full CRUD with status, priority, verification fields
- **Canopy evidence:** `EvidenceSourceKind` with `ManualNote` (verified),
  `HyphaeSession` (verified), others (stubs)
- **Canopy verification:** `verification_required` bool on tasks, but no
  automated script execution
- **Canopy attention:** Scores tasks by SLA breach, staleness, verification state
- **Verify scripts:** Now exist per handoff (`.handoffs/verify-*.sh`)
- **Handoff template:** `TEMPLATE.md` with paste-output sections

### What's missing

1. `canopy import-handoff` command to parse handoff → task tree
2. `canopy task verify --script` to run a verify script and record result
3. Evidence kind for script verification results
4. Completion gate: block task completion when verification fails

## Implementation

### Step 1: Add `ScriptVerification` evidence kind

**File:** `canopy/src/models.rs`

Add to `EvidenceSourceKind`:

```rust
pub enum EvidenceSourceKind {
    // ... existing variants ...
    ScriptVerification,  // Output from a verify script
}
```

**File:** `canopy/src/main.rs` (or evidence verification)

```rust
EvidenceSourceKind::ScriptVerification => {
    // Parse script output for "Results: N passed, M failed"
    // Verified if M == 0
    let output = &evidence.content;
    if output.contains("0 failed") {
        EvidenceVerification::Verified
    } else {
        EvidenceVerification::Failed
    }
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd canopy && rg -n 'ScriptVerification' src/models.rs src/main.rs
```

**Output:**
<!-- PASTE START -->
src/models.rs:332:    ScriptVerification,
src/main.rs:462:        EvidenceSourceKind::ScriptVerification => match evidence.summary.as_deref() {
<!-- PASTE END -->

**Checklist:**
- [x] `ScriptVerification` variant added to `EvidenceSourceKind`
- [x] Verification logic parses "N passed, M failed" format
- [x] `cargo test` passes
- [x] `cargo clippy --all-targets --quiet` exits 0

---

### Step 2: Add `canopy task verify --script` command

**File:** `canopy/src/cli.rs`

Add to Task subcommands:

```rust
/// Run a verification script and record result as evidence
Verify {
    /// Task ID to verify
    task_id: String,

    /// Path to verification script
    #[arg(long)]
    script: PathBuf,

    /// Only check specific steps (grep filter on script output)
    #[arg(long)]
    step: Option<String>,
},
```

**File:** `canopy/src/main.rs`

Handler:

```rust
TaskCommand::Verify { task_id, script, step } => {
    // 1. Run script, capture stdout+stderr
    let output = Command::new("bash")
        .arg(&script)
        .output()?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let combined = format!("{}\n{}", stdout, String::from_utf8_lossy(&output.stderr));

    // 2. Filter to specific step if requested
    let filtered = match &step {
        Some(s) => combined.lines()
            .filter(|l| l.contains(s) || l.starts_with("===") || l.starts_with("---") || l.starts_with("Results"))
            .collect::<Vec<_>>()
            .join("\n"),
        None => combined.to_string(),
    };

    // 3. Determine pass/fail
    let passed = output.status.success() && filtered.contains("0 failed");

    // 4. Record as evidence
    store.add_evidence(Evidence {
        task_id: task_id.clone(),
        source_kind: EvidenceSourceKind::ScriptVerification,
        source_ref: script.display().to_string(),
        content: filtered.clone(),
        verified: if passed {
            EvidenceVerification::Verified
        } else {
            EvidenceVerification::Failed
        },
    })?;

    // 5. Print result
    println!("{}", filtered);
    if passed {
        println!("\nVerification PASSED — task {} evidence recorded", task_id);
    } else {
        println!("\nVerification FAILED — task {} blocked from completion", task_id);
        std::process::exit(1);
    }
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd canopy && cargo test --quiet 2>&1 && echo "cargo test: OK" || echo "cargo test: FAILED"
```

**Output:**
<!-- PASTE START -->
cargo test: OK
<!-- PASTE END -->

**Checklist:**
- [x] `canopy task verify --script` runs a bash script
- [x] Script output captured and stored as evidence
- [x] PASS recorded when script or filtered step output passes
- [x] FAIL recorded otherwise
- [x] Exit code 1 on failure (blocks CI pipelines)

---

### Step 3: Add completion gate

**File:** `canopy/src/store.rs`

When updating task status to `Completed`, check verification:

```rust
pub fn update_task_status(&self, task_id: &str, new_status: TaskStatus) -> Result<()> {
    if new_status == TaskStatus::Completed {
        let task = self.get_task(task_id)?;
        if task.verification_required {
            let evidence = self.get_evidence_for_task(task_id)?;
            let has_passing_verification = evidence.iter().any(|e|
                e.source_kind == EvidenceSourceKind::ScriptVerification
                && e.verified == EvidenceVerification::Verified
            );
            if !has_passing_verification {
                anyhow::bail!(
                    "Task {} requires verification. Run: canopy task verify {} --script <path>",
                    task_id, task_id
                );
            }
        }
    }
    // ... existing status update logic ...
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd canopy && cargo test --quiet 2>&1 && echo "cargo test: OK" || echo "cargo test: FAILED"
```

**Output:**
<!-- PASTE START -->
cargo test: OK
<!-- PASTE END -->

**Checklist:**
- [x] Tasks with `verification_required=true` cannot complete without passing script evidence
- [x] Tasks without `verification_required` keep existing completion behavior
- [x] Error message tells the agent which `canopy task verify` command shape to run
- [x] `cargo test` passes

---

### Step 4: Add `canopy import-handoff` command

**File:** `canopy/src/cli.rs`

```rust
/// Import a handoff document as a task tree
ImportHandoff {
    /// Path to handoff markdown file
    path: PathBuf,

    /// Assign to agent
    #[arg(long)]
    assign: Option<String>,
},
```

**File:** `canopy/src/main.rs`

Parser logic:

```rust
TaskCommand::ImportHandoff { path, assign } => {
    let content = std::fs::read_to_string(&path)?;
    let handoff_name = extract_title(&content);  // # Handoff: <title>

    // Create parent task
    let parent_id = store.create_task(Task {
        title: handoff_name.clone(),
        status: TaskStatus::Open,
        verification_required: true,
        ..Default::default()
    })?;

    // Parse ### Step N: <title> sections
    let steps = extract_steps(&content);
    for (i, step) in steps.iter().enumerate() {
        let subtask_id = store.create_task(Task {
            title: format!("Step {}: {}", i + 1, step.title),
            parent_task_id: Some(parent_id.clone()),
            status: TaskStatus::Open,
            verification_required: true,
            assigned_agent: assign.clone(),
            ..Default::default()
        })?;

        // Link verify script if it exists
        let verify_script = path
            .with_file_name(format!("verify-{}.sh",
                path.file_stem().unwrap().to_str().unwrap()
                    .strip_prefix("HANDOFF-").unwrap_or("")
                    .to_lowercase()
            ));
        if verify_script.exists() {
            store.add_evidence(Evidence {
                task_id: subtask_id,
                source_kind: EvidenceSourceKind::ManualNote,
                content: format!("Verify with: canopy task verify <id> --script {} --step \"Step {}\"",
                    verify_script.display(), i + 1),
                ..Default::default()
            })?;
        }
    }

    println!("Imported '{}' as task {} with {} subtasks",
        handoff_name, parent_id, steps.len());
}
```

Helper functions:

```rust
fn extract_title(content: &str) -> String {
    content.lines()
        .find(|l| l.starts_with("# Handoff:") || l.starts_with("# "))
        .map(|l| l.trim_start_matches('#').trim().trim_start_matches("Handoff:").trim())
        .unwrap_or("Untitled Handoff")
        .to_string()
}

fn extract_steps(content: &str) -> Vec<Step> {
    let mut steps = Vec::new();
    for line in content.lines() {
        if line.starts_with("### Step ") {
            let title = line.trim_start_matches('#').trim()
                .trim_start_matches("Step ")
                .trim_start_matches(|c: char| c.is_ascii_digit())
                .trim_start_matches(':')
                .trim();
            steps.push(Step { title: title.to_string() });
        }
    }
    steps
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd canopy && cargo test --quiet 2>&1 && echo "cargo test: OK" || echo "cargo test: FAILED"
```

**Output:**
<!-- PASTE START -->
cargo test: OK
<!-- PASTE END -->

**Checklist:**
- [x] `canopy import-handoff HANDOFF-TOOL-NUDGING.md` creates a task tree
- [x] Parent task created with `verification_required=true`
- [x] Subtasks created per step
- [x] Verify script linked as evidence notes on parent and subtasks
- [x] `--assign` assigns the imported parent task

---

### Step 5: Add parent auto-completion

**File:** `canopy/src/store.rs`

After a verification-required imported subtask is marked complete, check if its
verified parent can now auto-complete:

```rust
fn check_parent_completion(&self, task_id: &str) -> Result<()> {
    let task = self.get_task(task_id)?;
    if let Some(parent_id) = &task.parent_task_id {
        let children = self.get_subtasks(parent_id)?;
        let all_complete = children.iter().all(|c| c.status == TaskStatus::Completed);
        if all_complete && parent.verification_required && parent.verification_state == Passed {
            self.update_task_status(parent_id, TaskStatus::Completed)?;
        }
    }
    Ok(())
}
```

#### Verification

<!-- AGENT: Run and paste output -->
```bash
cd canopy && cargo test --quiet 2>&1 && echo "cargo test: OK" || echo "cargo test: FAILED"
```

**Output:**
<!-- PASTE START -->
cargo test: OK
<!-- PASTE END -->

**Checklist:**
- [x] Verification-required parent auto-completes when all children complete
- [x] Parent does NOT auto-complete if any child is incomplete
- [x] Parent verification gate still applies and requires its own script pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/verify-canopy-verification-enforcement.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/canopy/verify-verification-enforcement.sh
```

**Output:**
<!-- PASTE START -->
=== HANDOFF-CANOPY-VERIFICATION-ENFORCEMENT Verification ===

--- Step 1: ScriptVerification Evidence Kind ---
  PASS: ScriptVerification variant exists in models.rs
  PASS: evidence verification reports script failures

--- Step 2: canopy task verify --script ---
  PASS: task verify completes a passing leaf task
  PASS: step filtering allows one passing section from a failing overall script
  PASS: task verify exits non-zero for a failing step

--- Step 3: Completion Gate ---
  PASS: verification-required task can enter in-progress normally
  PASS: verification-required task cannot complete without script evidence

--- Step 4: import-handoff Command ---
  PASS: import-handoff creates a verification-required parent task
  PASS: import-handoff creates subtasks for each step
  PASS: import-handoff attaches verification command notes

--- Step 5: Parent Auto-Completion ---
  PASS: verified parent stays open until all children are complete
  PASS: final child completion auto-completes a verified parent

--- Build Verification ---
  PASS: cargo test passes
  PASS: cargo clippy exits 0

================================
Results: 14 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Usage After Implementation

### Delegating a handoff to an agent

```bash
# Import handoff as task tree
canopy import-handoff .handoffs/HANDOFF-TOOL-NUDGING.md --assign codex-1

# Agent works on tasks...

# Agent verifies each step
canopy task verify <step1-id> --script .handoffs/verify-tool-nudging.sh --step "Step 1"
canopy task verify <step2-id> --script .handoffs/verify-tool-nudging.sh --step "Step 2"

# Check what's left
canopy api snapshot --preset attention
```

### Checking completion status

```bash
# See which tasks are verified vs blocked
canopy task list-view --preset review-queue

# See evidence for a specific task
canopy evidence list --task <task-id>
```

### CI integration

```bash
# In CI or post-agent hook: verify all open handoffs
for script in .handoffs/verify-*.sh; do
  handoff=$(basename "$script" .sh | sed 's/verify-/HANDOFF-/' | tr '[:lower:]' '[:upper:]')
  echo "=== Checking $handoff ==="
  bash "$script" || echo "BLOCKED: $handoff has failing checks"
done
```

## Context

This closes the loop on agent delegation quality. The progression:

1. **Handoff template** (`TEMPLATE.md`) — structured format with paste-output sections
2. **Verify scripts** (`verify-*.sh`) — machine-checkable assertions per handoff
3. **Canopy enforcement** (this handoff) — task system that blocks completion without evidence

Without #3, agents can still ignore the template and scripts. With #3, the
task system itself refuses to mark work complete until verification passes.
