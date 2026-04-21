# Cortina Lifecycle Capture Expansion

## Problem

Cortina only handles three Claude Code hook events: PreToolUse, PostToolUse, Stop.
This misses several lifecycle moments where hyphae capture would be valuable:
`UserPromptSubmit` (what the user asked, before any tool calls), `PreCompact`
(what state existed before context collapse), and `Notification` (async events
from the host). Without `PreCompact` in particular, hyphae has no snapshot of
working state before context is lost — the gap versus `c0ntextKeeper`.

Note: availability of these events depends on whether Claude Code exposes them.
Check host support before implementing.

## What exists (state)

- **Claude Code hook events:** PreToolUse, PostToolUse, Stop — all handled
- **Adapter:** `cortina/src/adapters/claude_code.rs` — parses hook envelopes
- **`main.rs`:** dispatches to PreToolUse, PostToolUse, Stop handlers only
- **Unknown:** whether Claude Code currently fires PreCompact, UserPromptSubmit,
  Notification as hookable events

## What needs doing (intent)

Add handlers for the lifecycle events Claude Code does expose, starting with
`UserPromptSubmit` (likely available), then `PreCompact` if/when available.

---

### Step 1: Audit available Claude Code hook events

**Project:** `cortina/`
**Effort:** 30 min

Check Claude Code's hook documentation or test by registering a hook for
`UserPromptSubmit` and `Notification` and seeing what arrives.

```bash
# Check what hook event types Claude Code sends
cat ~/.claude/settings.json | grep -A5 hooks
```

Document which events are actually fired by the current Claude Code version.

**Checklist:**
- [ ] `UserPromptSubmit` availability confirmed or denied
- [ ] `PreCompact` availability confirmed or denied
- [ ] `Notification` availability confirmed or denied

---

### Step 2: Add UserPromptSubmit handler (if available)

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 1

If `UserPromptSubmit` fires, add a handler that stores the prompt text as a
hyphae memory under `session/prompts` topic. This gives hyphae a record of
what the agent was asked to do, which improves context-aware recall.

Store as: `{ type: "prompt", content: <prompt_text>, session_id: ... }`

**Checklist:**
- [ ] `UserPromptSubmit` events parsed by Claude Code adapter
- [ ] Prompt stored to hyphae under `session/prompts`
- [ ] Deduplication applied (don't store identical prompts twice in same session)

---

### Step 3: Add PreCompact handler (if available)

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** Step 1

If `PreCompact` fires, capture working state before context collapse:
- Current active errors (from cortina's in-memory state)
- Files modified in this session
- Brief session summary request to hyphae

Store as a `session/compaction-snapshot` memory so the next session can
recall what was in progress before compaction.

**Note:** If `PreCompact` is NOT available from Claude Code, this step should
instead be implemented in volva (which owns the invocation boundary and can
fire its own pre-compaction hook before triggering the backend).

**Checklist:**
- [ ] `PreCompact` fires and cortina captures working state snapshot
- [ ] Snapshot stored to hyphae with session_id and worktree identity
- [ ] OR: documented that this must move to volva and why

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd cortina && cargo test --all` passes

## Context

`docs/ROADMAP-OTHER-TOOLS.md` P0 #1 (c0ntextKeeper comparison). `ECOSYSTEM-OVERVIEW.md`
gap #5. `IMPROVEMENTS-OBSERVATION-V1.md` notes PreCompact may be blocked upstream
in Claude Code — in that case volva is the right host, not cortina.
