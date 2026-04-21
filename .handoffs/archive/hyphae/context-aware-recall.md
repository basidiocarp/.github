# Hyphae Context-Aware Recall on Session Start

## Problem

Every current hyphae recall requires an explicit query from the agent. The agent
has to know to ask, and it has to know what to ask for. At session start — when
context is most needed — the agent has no history yet and doesn't know what's
relevant.

The fix: extend `hyphae_session_start` to accept an optional `context_signals`
bag (recent files, active errors, git branch). Hyphae assembles a weighted recall
query internally from those signals and includes the results in the session start
response alongside the existing session context. Cortina already calls
`hyphae session start` at session begin and already tracks the signals needed —
it just passes them in.

This makes hyphae useful before the agent knows what to search for, which is most
of the time early in a session.

## What exists (state)

- **`hyphae_session_start`** (`crates/hyphae-mcp/src/tools/session.rs:15`):
  accepts `project`, `task`, `project_root`, `worktree_id`, `scope`,
  `runtime_session_id` — returns `{ session_id, started_at }` only
- **`tool_session_context`** (`session.rs:81`): already called inline inside
  `session_start` at line 241 to attach recent session history — the pattern
  for injecting more context into the start response already exists
- **Cortina call site** (`cortina/src/utils/session_scope.rs:300`): shells out to
  `hyphae session start` with identity args — this is where signal args get added
- **Recall machinery**: `hyphae_memory_recall` exists; this feature calls it
  internally, not as a new tool call from the agent
- **`hyphae_session_context`**: returns prior session history (files, errors, summaries)
  — different from context-aware recall, which searches episodic + semantic memories

## What needs doing (intent)

Three changes:
1. `hyphae_session_start` MCP tool: accept optional `context_signals`, call recall
   internally when signals are present, include results in response
2. `hyphae session start` CLI: accept `--recent-files` / `--active-errors` /
   `--git-branch` flags and pass them through to the store
3. Cortina `session_scope.rs`: populate and pass signals when starting a session

---

### Step 1: Add context_signals to hyphae_session_start (MCP)

**Project:** `hyphae/`
**Effort:** 2-3 hours

#### Files to modify

**`crates/hyphae-mcp/src/tools/session.rs`** — extend `tool_session_start`:

Parse the new optional field from args:

```rust
let context_signals = args.get("context_signals"); // Option<&Value>
```

When signals are present, assemble a recall query from them and call the existing
recall machinery:

```rust
fn signals_to_query(signals: &Value) -> Option<String> {
    let mut parts: Vec<String> = Vec::new();

    if let Some(files) = signals.get("recent_files").and_then(Value::as_array) {
        let names: Vec<&str> = files.iter()
            .filter_map(Value::as_str)
            .filter_map(|p| std::path::Path::new(p).file_stem()?.to_str())
            .take(5)
            .collect();
        if !names.is_empty() {
            parts.push(names.join(" "));
        }
    }
    if let Some(errors) = signals.get("active_errors").and_then(Value::as_array) {
        let error_text: Vec<&str> = errors.iter()
            .filter_map(Value::as_str)
            .take(3)
            .collect();
        if !error_text.is_empty() {
            parts.push(error_text.join(" "));
        }
    }
    if let Some(branch) = signals.get("git_branch").and_then(Value::as_str) {
        // Include branch only if it looks like a feature/fix branch (not main/master)
        if !matches!(branch, "main" | "master" | "develop") {
            parts.push(branch.replace(['-', '/'], " "));
        }
    }

    if parts.is_empty() { None } else { Some(parts.join(" ")) }
}
```

Call recall with the assembled query and attach results to the response:

```rust
let recalled_memories = if let Some(signals) = context_signals {
    signals_to_query(signals)
        .and_then(|q| store.search_memories_hybrid(&q, project, 5, 0).ok())
        .unwrap_or_default()
} else {
    vec![]
};
```

Return recalled memories in the response:

```rust
json!({
    "session_id": session_id,
    "started_at": started_at,
    "recalled_context": recalled_memories.iter().map(|(m, score)| json!({
        "content": m.content,
        "topic": m.topic,
        "score": score,
    })).collect::<Vec<_>>(),
})
```

#### Verification

```bash
cd hyphae && cargo test session_start 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `context_signals` field parsed without breaking existing calls (field is optional)
- [ ] `signals_to_query` produces a non-empty query from files + errors
- [ ] Empty / missing signals return `recalled_context: []` without error
- [ ] `recalled_context` key present in response when signals provided
- [ ] Existing `test_session_start` tests still pass

---

### Step 2: Add --context-signals flags to the hyphae session start CLI

**Project:** `hyphae/`
**Effort:** 1 hour
**Depends on:** Step 1

**`crates/hyphae-cli/src/commands/session.rs`** (or equivalent `start` subcommand):

Add flags:
- `--recent-files <paths>` (repeatable or comma-separated)
- `--active-errors <messages>` (repeatable or comma-separated)
- `--git-branch <branch>`

Serialize into a `context_signals` JSON object and pass to the store / MCP call.

#### Verification

```bash
cd hyphae && cargo build --release 2>&1 | tail -3
hyphae session start --project test --git-branch feat/foo --help
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `--recent-files`, `--active-errors`, `--git-branch` flags exist on `session start`
- [ ] Flags are optional; omitting them produces current behavior
- [ ] Flags serialize into `context_signals` correctly

---

### Step 3: Populate signals in cortina session_scope.rs

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 2

**`cortina/src/utils/session_scope.rs`** — at the `hyphae session start` call site
(line ~300), populate the three signal types before calling:

```rust
// Collect recent files from cortina's tracked edit state
let recent_files: Vec<String> = /* files modified in current worktree session */;

// Collect active error messages from in-memory error state
let active_errors: Vec<String> = /* error messages from cortina's outcome tracker */;

// Git branch from the worktree identity or a git call
let git_branch: Option<String> = std::process::Command::new("git")
    .args(["rev-parse", "--abbrev-ref", "HEAD"])
    .current_dir(&identity.project_root)
    .output()
    .ok()
    .and_then(|o| String::from_utf8(o.stdout).ok())
    .map(|s| s.trim().to_string());
```

Then pass them via CLI flags:

```rust
if !recent_files.is_empty() {
    for f in &recent_files {
        cmd.args(["--recent-files", f]);
    }
}
if let Some(branch) = &git_branch {
    cmd.args(["--git-branch", branch]);
}
```

Note: at a fresh session start, `recent_files` and `active_errors` will usually
be empty (cortina hasn't seen anything yet). `git_branch` is the highest-value
signal here. Over time as cortina accumulates signals from prior hooks in a
longer session, re-starting a session will carry richer context.

#### Verification

```bash
cd cortina && cargo test session_scope 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `git_branch` populated and passed when `git rev-parse` succeeds
- [ ] Missing git or empty signals degrade gracefully (session start still works)
- [ ] `--recent-files` and `--active-errors` passed when cortina has tracked state
- [ ] No regression in `hyphae session start` call behavior

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. `cd hyphae && cargo test` passes
4. `cd cortina && cargo test` passes

## Context

`IMPROVEMENTS-OBSERVATION-V1.md` calls context-aware recall "the highest-leverage
hyphae improvement not being worked on." Design decision documented in session
2026-04-04: assembly logic lives in hyphae (`hyphae_session_start` extended with
`context_signals` bag), not in cortina. Cortina knows what happened; hyphae knows
what to recall. Cortina passes signals in; hyphae assembles the query and fires
recall internally. The agent gets relevant context without knowing what to search for.

Related: `hyphae/docs/FEEDBACK-LOOP-DESIGN.md` for the recall effectiveness scoring
that will eventually weight these auto-recalled memories based on outcome correlation.
