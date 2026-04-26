# Cortina: GateGuard Fact-Force Hook

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/hooks/gate_guard.rs` (new gate state machine), `cortina/src/hooks/pre_tool_use.rs` (extend with GateGuard dispatch)
- **Cross-repo edits:** `lamella/resources/skills/gateguard.md` (new skill document)
- **Non-goals:** does not replace the existing advisory system; does not add network-based fact verification; gate state is in-process only (no SQLite persistence in this handoff); does not add JavaScript port of the hook
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the everything-claude-code re-audit (`.audit/external/audits/everything-claude-code-ecosystem-borrow-audit.md`, 2026-04-23):

> "GateGuard is a PreToolUse hook that enforces a three-stage investigation gate before any Edit, Write, MultiEdit, or destructive Bash operation. Two independent tests showed +2.25 points average quality improvement (9.0 vs 6.75/10)."

> "The core insight (validated with A/B evidence): LLM self-evaluation produces useless answers. Forcing investigation causes the model to actually run Grep and Read, and the act of investigation itself creates the context that self-evaluation never generates."

Evidence in source:
- `scripts/hooks/gateguard-fact-force.js` (415 lines)
- `skills/gateguard/SKILL.md`

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files:**
  - `cortina/src/hooks/gate_guard.rs` (new) — `GateState` enum, gate type dispatch, per-file state map, 30-minute TTL
  - `cortina/src/hooks/pre_tool_use.rs` (extend) — route Edit/Write/destructive-Bash through GateGuard before existing advisory checks
- **Cross-repo:**
  - `lamella/resources/skills/gateguard.md` (new) — SKILL.md for the GateGuard deliberation pattern
- **Reference seams:**
  - `cortina/src/hooks/pre_tool_use.rs` — existing advisory infrastructure (`read_advisory_for_path`, `write_advisory`, `ADVISORY_STATE_NAME`, temp state path helpers)
  - `cortina/src/utils.rs` — `temp_state_path`, `update_json_file`
- **Spawn gate:** read `pre_tool_use.rs` and `utils.rs` before writing gate_guard.rs

## Problem

Cortina's current advisory system nudges toward reading before editing, but it does not enforce investigation. A model that ignores the advisory and edits directly is not blocked. The GateGuard pattern goes further: the first Edit/Write/Bash attempt is denied outright; the model is forced to name specific facts (which files import this one? which public APIs change?); only after those facts are presented does cortina allow the operation.

This is not a policy preference — it is validated empirically. The ECC audit documented A/B tests showing +2.25 point average quality improvement when the investigation gate was enforced versus relying on self-evaluation alone.

Cortina already has the primitives:
- `ADVISORY_STATE_NAME` and `temp_state_path` for per-session state
- `update_json_file` for persisting advisory records
- `pre_tool_use.rs:handle` dispatches on tool type

GateGuard extends this with a state machine that makes the gate blocking rather than advisory.

## What needs doing (intent)

1. Define `GateState` enum: `Blocked`, `Investigating { facts_template: String }`, `Allowed`
2. Implement per-tool-type gate logic:
   - **Edit / MultiEdit gate**: demand importers (grep), affected public APIs, data schema details, verbatim instruction
   - **Write gate**: require uniqueness check (glob), caller identification, schema confirmation
   - **Destructive Bash gate**: triggered by `rm -rf`, `git reset --hard`, `DROP TABLE`, `git clean -f`, `truncate`; requires targets list + rollback procedure; fires every time (no session bypass)
   - **Routine Bash gate**: once-per-session verification of command purpose; bypassed for read-only git operations (`git log`, `git diff`, `git status`, `git show`)
3. Gate state is keyed by `(tool_name, target_path_or_command_hash)` with a 30-minute TTL
4. On first call → return `GateState::Blocked` with the fact template for that gate type
5. On retry with investigation content present in the hook context → advance to `GateState::Allowed`
6. Wire into `pre_tool_use.rs:handle` before the existing advisory checks

## Gate state model

```rust
use std::collections::HashMap;
use std::time::{Duration, Instant};

/// State for a single gate instance.
#[derive(Debug, Clone)]
pub enum GateState {
    /// First attempt blocked. Return the fact template to the model.
    Blocked { fact_template: String },
    /// Model is investigating. Gate will allow on next call that includes facts.
    Investigating { started_at: Instant },
    /// Investigation accepted. Operation is allowed for `ttl` from `allowed_at`.
    Allowed { allowed_at: Instant },
}

impl GateState {
    const TTL: Duration = Duration::from_secs(30 * 60); // 30 minutes

    pub fn is_expired(&self) -> bool {
        match self {
            GateState::Allowed { allowed_at } => allowed_at.elapsed() > Self::TTL,
            GateState::Investigating { started_at } => started_at.elapsed() > Self::TTL,
            GateState::Blocked { .. } => false,
        }
    }
}

/// Gate key: stable identifier for one (tool, target) pair.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct GateKey {
    pub tool: String,
    /// For file-targeted tools: canonical path. For Bash: hash of command prefix.
    pub target: String,
}

pub type GateMap = HashMap<GateKey, GateState>;
```

## Fact templates by gate type

```rust
pub const EDIT_GATE_TEMPLATE: &str = r#"
Before this edit can proceed, gather these facts:
1. Run Grep to find every file that imports or calls the target file or symbol.
2. List every public API that would change signature or behavior.
3. Confirm the data schema (field names, types, required/optional) before and after.
4. Quote the verbatim user instruction that authorized this edit.
Present these facts in your next message, then retry.
"#;

pub const WRITE_GATE_TEMPLATE: &str = r#"
Before creating this file, gather these facts:
1. Run Glob to confirm no file at this path already exists.
2. Identify the caller: what existing code will import or invoke this new file?
3. Confirm the schema or interface contract (if the file exports anything).
Present these facts in your next message, then retry.
"#;

pub const DESTRUCTIVE_BASH_TEMPLATE: &str = r#"
This command is destructive and cannot be undone without manual intervention.
Before proceeding, state:
1. The complete list of targets that will be affected (files, rows, branches, etc.).
2. The rollback procedure if this command produces the wrong outcome.
Present these facts in your next message, then retry.
"#;

pub const ROUTINE_BASH_TEMPLATE: &str = r#"
Confirm the purpose of this command in one sentence, then retry.
"#;
```

## Destructive bash patterns

```rust
/// Returns true if the bash command matches a destructive pattern that triggers the gate every time.
pub fn is_destructive_bash(command: &str) -> bool {
    let lower = command.to_ascii_lowercase();
    let patterns = [
        "rm -rf", "rm -fr",
        "git reset --hard", "git clean -f", "git clean -fd",
        "drop table", "drop database", "truncate table",
        "git push --force", "git push -f",
        "dd if=", "mkfs.",
    ];
    patterns.iter().any(|p| lower.contains(p))
}

/// Returns true if the bash command is read-only git and bypasses the routine gate.
pub fn is_readonly_git(command: &str) -> bool {
    let lower = command.trim().to_ascii_lowercase();
    let bypassed = ["git log", "git diff", "git status", "git show", "git branch", "git remote -v"];
    bypassed.iter().any(|p| lower.starts_with(p))
}
```

## Scope

- **Allowed files:** `cortina/src/hooks/gate_guard.rs` (new), `cortina/src/hooks/pre_tool_use.rs` (extend handle function), `lamella/resources/skills/gateguard.md` (new)
- **Explicit non-goals:**
  - No change to the existing advisory system (read_advisory_for_path, grep_advisory_for_path)
  - No SQLite persistence of gate state (in-process HashMap only)
  - No JavaScript implementation
  - No integration with cortina's signal emission pipeline

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `cortina/src/hooks/pre_tool_use.rs` — understand the `handle` function dispatch, `ADVISORY_STATE_NAME`, `temp_state_path`, and `update_json_file` usage
2. `cortina/src/utils.rs` — what helpers are available for state persistence?
3. `cortina/src/hooks/mod.rs` — how are hook modules registered?

---

### Step 1: Implement gate_guard.rs

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 0

Create `src/hooks/gate_guard.rs` with:
- `GateState` enum
- `GateKey` struct
- `GateMap` type alias
- `is_destructive_bash` and `is_readonly_git` functions
- Fact templates as constants
- `evaluate_gate(key: &GateKey, map: &mut GateMap, has_investigation: bool) -> GateDecision` function

`GateDecision` enum:
```rust
pub enum GateDecision {
    /// Allow the operation to proceed.
    Allow,
    /// Block with a message explaining what facts are needed.
    Block { message: String },
}
```

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `GateState` compiles with all variants
- [ ] `is_destructive_bash` returns true for `rm -rf`, `git reset --hard`, `drop table`
- [ ] `is_readonly_git` returns true for `git log`, `git diff`, false for `git commit`
- [ ] `evaluate_gate` returns `Block` on first call, `Allow` on second call with facts

---

### Step 2: Wire into pre_tool_use.rs

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 1

Extend `cortina/src/hooks/pre_tool_use.rs:handle` to:
1. Before existing advisory checks, determine if the tool is a gate-covered type (Edit, MultiEdit, Write, Bash)
2. Construct the `GateKey` from tool name + target path or command hash
3. Call `evaluate_gate` with the session-local `GateMap`
4. If `GateDecision::Block`, return the block message as the hook response
5. If `GateDecision::Allow`, continue to existing advisory checks

The `GateMap` can be stored in a thread-local or passed through the existing session state.

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
cd cortina && cargo test gate 2>&1
```

**Checklist:**
- [ ] Edit tool triggers the gate on first call
- [ ] Routine Bash bypasses the gate for `git log`
- [ ] Destructive Bash (`rm -rf`) triggers the gate every time (no TTL bypass)
- [ ] Gate does not fire for read-only tools (Read, Glob, Grep)

---

### Step 3: Write lamella skill document

**Project:** `lamella/`
**Effort:** tiny
**Depends on:** Step 2

Create `lamella/resources/skills/gateguard.md`. Content should follow lamella's SKILL.md convention (frontmatter + when-to-activate + workflow phases). The skill document describes the GateGuard deliberation pattern so it can be installed as a lamella skill independently of the cortina hook implementation.

#### Verification

```bash
cd lamella && make validate 2>&1 | tail -5
```

**Checklist:**
- [ ] Skill document present at `lamella/resources/skills/gateguard.md`
- [ ] Lamella validate passes

---

### Step 4: Full suite

```bash
cd cortina && cargo build --release 2>&1 | tail -5
cd cortina && cargo test 2>&1 | tail -20
cd cortina && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd cortina && cargo fmt --check 2>&1
cd lamella && make validate 2>&1 | tail -5
```

**Checklist:**
- [ ] Release build succeeds
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean
- [ ] Lamella validate passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output
2. Full test suite passes in cortina
3. Lamella validate passes
4. All checklist items checked
5. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- SQLite persistence of gate state so gate decisions survive cortina restarts
- Per-project gate configuration: override which tool types trigger the gate
- Gate metrics: track how often the gate fires vs. is bypassed, surface in cap
- Cortina signal emission for gate events (gate_blocked, gate_allowed) for hyphae storage
- GateGuard integration with the hook governance framework (W2g)

## Context

Spawned from the everything-claude-code re-audit (2026-04-23). GateGuard's A/B evidence (+2.25 points quality improvement) is unusually concrete — most hook patterns are based on intuition, not measurement. The key insight is that forcing investigation is qualitatively different from advising it: cortina's current advisory system leaves the model a path to ignore the advice and edit anyway. GateGuard closes that path. The three-stage state machine (DENY → FORCE → ALLOW) is the right primitive; the per-tool-type fact templates are the specific content. Cortina already has the infrastructure (temp state, advisory JSON, pre_tool_use dispatch) — this handoff adds the blocking layer on top.
