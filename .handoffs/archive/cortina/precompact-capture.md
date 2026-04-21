# PreCompact / UserPromptSubmit Capture in Cortina

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Cortina misses the pre-compaction window entirely. When Claude Code compacts the
context, the agent's working state — open files, active error, partial plan — is
lost without any snapshot. `c0ntextKeeper` identifies this as the core gap: no
snapshot of working state before compaction means every compaction is a cold restart
from hyphae's perspective.

## What exists (state)

- **Cortina Claude Code adapter**: handles `PreToolUse`, `PostToolUse`, `Stop`,
  `SessionEnd` — `PreCompact` and `UserPromptSubmit` are not handled
- **`hyphae session end`**: structured session summary on Stop/SessionEnd — but
  `PreCompact` fires before Stop, while context is still intact
- **Hyphae session bridge**: worktree-scoped session start/reuse/end already wired
- **Cortina event model**: adapter-first, adding new event types is an isolated change

## What needs doing (intent)

Add `PreCompact` and `UserPromptSubmit` handler stubs to the cortina Claude Code
adapter, then implement `PreCompact` to snapshot agent working state into hyphae
before context is compacted.

---

### Step 1: Add PreCompact handler to cortina Claude Code adapter

**Project:** `cortina/`
**Effort:** 1 day
**Depends on:** nothing

Add a `PreCompact` arm to the Claude Code adapter's event dispatch. The handler
should:

1. Query the current session state from the cortina signal buffer (last N signals)
2. Build a compact working-state snapshot: recent errors, open files touched, active
   task (if canopy is running), current tool sequence
3. Call `hyphae memory store` with topic `context/{project}/pre-compact` and
   importance `high`
4. Write a cortina event record for the PreCompact capture

The snapshot should be a structured TOML/JSON payload, not prose. Hyphae's recall
on the next session can then surface this as "your last session was interrupted
during...".

#### Files to modify

**`cortina/src/adapters/claude_code/`** — add `pre_compact.rs`:

```rust
pub struct PreCompactCapture {
    session_id: SessionId,
    working_state: WorkingStateSnapshot,
}

pub struct WorkingStateSnapshot {
    recent_errors: Vec<ErrorSignal>,       // last 3 errors
    touched_files: Vec<PathBuf>,           // files edited this session
    last_tool_sequence: Vec<String>,       // last 5 tool calls
    active_task_id: Option<TaskId>,        // from canopy if available
    signal_summary: String,               // 1-2 sentence prose summary
}

impl PreCompactCapture {
    pub fn build(signal_buffer: &SignalBuffer, canopy: Option<&CanopyClient>) -> Self;
    pub fn store(&self, hyphae: &HyphaeClient) -> Result<()>;
}
```

**`cortina/src/adapters/claude_code/dispatch.rs`** — add arm:

```rust
HookEvent::PreCompact => {
    let capture = PreCompactCapture::build(&self.signal_buffer, self.canopy.as_ref());
    capture.store(&self.hyphae)?;
}
```

#### Verification

```bash
cd cortina && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `PreCompact` arm added to Claude Code adapter dispatch
- [ ] `WorkingStateSnapshot` captures recent errors, touched files, tool sequence
- [ ] Snapshot stored in hyphae at `context/{project}/pre-compact` with `high` importance
- [ ] Cortina event record written for the capture
- [ ] Build and tests pass

---

### Step 2: Add UserPromptSubmit handler

**Project:** `cortina/`
**Effort:** 4–8 hours
**Depends on:** Step 1 (uses same adapter pattern)

`UserPromptSubmit` fires when the user sends a new message. Capture:

1. Detect if the prompt contains an error message or stack trace → auto-tag as
   potential error session opener, store in `errors/active` if not already captured
2. Detect if the prompt references a file (path pattern) → add to session touched-files
3. Write a lightweight cortina event record for the prompt (no hyphae write unless
   error pattern detected)

This is less critical than `PreCompact` but closes the visibility gap at session
start.

#### Files to modify

**`cortina/src/adapters/claude_code/`** — add `user_prompt_submit.rs`:

```rust
pub struct UserPromptHandler;

impl UserPromptHandler {
    pub fn handle(&self, prompt: &str, ctx: &AdapterContext) -> Result<()>;
    fn detect_error_pattern(prompt: &str) -> Option<ErrorSignal>;
    fn extract_file_refs(prompt: &str) -> Vec<PathBuf>;
}
```

#### Verification

```bash
cd cortina && cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `UserPromptSubmit` arm added to Claude Code adapter dispatch
- [ ] Error patterns in prompt auto-create an `errors/active` signal
- [ ] File references extracted and added to touched-files
- [ ] No hyphae write unless error detected (keep this lightweight)

---

### Step 3: Surface pre-compact captures in `hyphae session context`

**Project:** `hyphae/`
**Effort:** 2–4 hours
**Depends on:** Step 1

When `hyphae session context` runs at session start, include any `pre-compact`
memory for the same project as a "last session was interrupted" notice. This
requires hyphae to query for `context/{project}/pre-compact` topics and surface
them alongside the normal session context.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -5
hyphae session context 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `hyphae session context` shows pre-compact snapshot from prior session
- [ ] Pre-compact memories decay normally (not pinned forever)
- [ ] Build passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `cortina/`
3. A simulated `PreCompact` event stores a snapshot in hyphae
4. `hyphae session context` shows the pre-compact snapshot on the next session start
5. All checklist items are checked

### Final Verification

```bash
cd cortina && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

Gap #5 in `docs/workspace/ECOSYSTEM-REVIEW.md`. Identified as the core gap vs.
`c0ntextKeeper` in the external tools audit. Without PreCompact capture, every
context compaction is a cold restart — the agent loses its working state and hyphae
has no snapshot of where it was. `UserPromptSubmit` is secondary but closes the
session-start visibility gap. Both are adapter-level additions to cortina, isolated
from the shared signal pipeline.

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsThe mempalace ecosystem borrow audit confirms PreCompact capture as a critical gap
across the ecosystem: mempalace ships precompact hooks as a standard, first-class
product surface, wired directly into the host plugin alongside session-start and
stop hooks. See `mempalace-ecosystem-borrow-audit.md` — "Make compaction and stop
continuity easier to install." This handoff also enables handoff #84 (Memory-Use
Protocol) to include pre-compaction state in its recall guidance — the working-state
snapshot stored here is the raw material that #84's session-start recall can surface.
