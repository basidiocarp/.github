# Volva — Hyphae Recall Injection

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** volva/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Volva's context assembly seam exists and prepends a static host envelope before
backend invocation. Live hyphae recall is not yet wired into the pre-run context.
Volva sessions get none of the memory hydration that Claude Code sessions get via
MCP injection, meaning volva-launched agents start cold every time even when
relevant memories exist.

## What exists (state)

- **Context assembly seam**: `volva-runtime` prepends a static host context
  envelope before backend invocation; the seam is the right place to inject recall
- **`volva-adapters`**: adapter routing into ecosystem tools; the hyphae adapter
  path exists but recall injection is not implemented
- **`hyphae session context`**: CLI command that returns the recall context for the
  current project/worktree as structured JSON
- **Cortina adapter**: already wired end-to-end for hook events; hyphae recall is
  the remaining gap in the pre-run path

## What needs doing (intent)

Wire `hyphae session context` output into the volva pre-run context assembly step.
The recall context should be injected as a structured block in the host envelope,
after the static content and before the backend invocation.

---

### Step 1: Add hyphae recall query to volva pre-run context assembly

**Project:** `volva/`
**Effort:** 1 day
**Depends on:** nothing

In `volva-runtime`, extend the pre-run context assembly step to:

1. Check if hyphae is available (via `spore` discovery — same pattern as the
   cortina adapter uses)
2. Call `hyphae session context --format json --project <cwd_project>` as a
   subprocess
3. Parse the JSON response; extract the `memories` array and `session_summary`
4. Inject the recall block into the host envelope in this format:

```
## Memory Context (from hyphae)

{session_summary if present}

### Recent Memories
{formatted memory list}
```

5. If hyphae is unavailable or errors, skip injection and log a debug warning —
   do not fail the session

#### Files to modify

**`volva-runtime/src/context/recall.rs`** — new file:

```rust
pub struct HyphaeRecallInjector {
    hyphae_path: Option<PathBuf>, // resolved via spore
}

impl HyphaeRecallInjector {
    pub fn new() -> Self;
    pub fn inject(&self, envelope: &mut ContextEnvelope, project: &str) -> Result<()>;
    fn query_hyphae(&self, project: &str) -> Result<RecallContext>;
    fn format_for_envelope(ctx: &RecallContext) -> String;
}

pub struct RecallContext {
    pub memories: Vec<Memory>,
    pub session_summary: Option<String>,
}
```

**`volva-runtime/src/context/assembly.rs`** — extend pre-run assembly:

```rust
// After static envelope prepend:
self.recall_injector.inject(&mut envelope, &self.project)?;
```

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `HyphaeRecallInjector` queries `hyphae session context`
- [ ] Recall context injected into host envelope before backend invocation
- [ ] Hyphae unavailable → silent skip, no session failure
- [ ] Injection uses spore-resolved hyphae path (not hardcoded)
- [ ] Build and tests pass

---

### Step 2: Add recall injection status to volva backend doctor

**Project:** `volva/`
**Effort:** 2–4 hours
**Depends on:** Step 1

Extend `volva backend doctor` to show:
- Hyphae available: yes/no (with path)
- Recall injection: enabled/disabled
- Last recall query result: N memories injected / "hyphae unavailable"

This makes the injection status visible to operators without requiring a full
session run.

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -3
volva backend doctor 2>&1 | grep -i hyphae
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `volva backend doctor` shows hyphae availability
- [ ] Doctor shows recall injection enabled/disabled
- [ ] Doctor shows whether last query returned memories

---

### Step 3: Wire recall session end back through cortina

**Project:** `volva/`
**Effort:** 2–4 hours
**Depends on:** Step 1

When a volva session ends, the post-run hook should call `hyphae session end` to
persist session outcome alongside the recall that was injected at the start. This
closes the loop: recall in → outcome signal out.

The cortina adapter already handles `Stop`/`SessionEnd` via `cortina adapter volva
hook-event`. Confirm this also triggers `hyphae session end` and that the session
ID matches the one used for recall injection.

#### Verification

```bash
cd volva && cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Post-run hook calls `hyphae session end` via cortina adapter
- [ ] Session ID in session-end matches the one used for pre-run recall injection
- [ ] Hyphae session record shows `recalled_context: true` or equivalent marker

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `volva/`
3. A `volva run` command with hyphae available injects memories into the host envelope
4. `volva backend doctor` shows recall injection status
5. All checklist items are checked

### Final Verification

```bash
cd volva && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #10 in `docs/workspace/ECOSYSTEM-REVIEW.md`. The context assembly seam is
already implemented; this is the next planned slice. Without this, volva sessions
are cold-start even when hyphae has relevant memories. Claude Code sessions get
recall via MCP injection at session start; this brings volva sessions to parity.
Related to gap #21 (volva auth and native API backend) which comes after this.
