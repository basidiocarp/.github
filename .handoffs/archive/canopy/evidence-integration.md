# Canopy Evidence Integration

## Problem

Canopy has typed evidence ref slots (`hyphae_session`, `hyphae_recall`, `cortina_event`,
`rhizome_impact`, etc.) but agents have to manually find and attach evidence IDs.
The ecosystem generates evidence continuously - cortina captures session IDs, hyphae
stores recall event IDs, rhizome tracks exports - but canopy tasks don't automatically
accumulate it. The cortina->canopy bridge writes best-effort refs at session end, but
no tool helps agents attach mid-task evidence as work progresses.

## What exists (state)

- **Evidence ref types:** `hyphae_session`, `hyphae_recall`, `hyphae_outcome`, `cortina_event`,
  `mycelium_command`, `rhizome_impact`, `rhizome_export`, `manual_note`
- **Cortina bridge:** best-effort evidence write at Stop - covered by `evidence-bridge-retry.md`
- **`canopy task attach-evidence`:** CLI command for manual evidence attachment
- **Gap:** no automatic evidence accumulation during task execution; agents must track IDs manually

## What needs doing (intent)

Add an `evidence` MCP tool that makes it easy for agents to attach evidence in-context,
and add automatic evidence accumulation from the cortina bridge for mid-task events.

---

### Step 1: Add evidence attach MCP tool

**Project:** `canopy/`
**Effort:** 1-2 hours

Add or improve `canopy_attach_evidence` MCP tool so agents can attach evidence during
work without looking up CLI syntax:

```json
{
  "tool": "canopy_attach_evidence",
  "task_id": "...",
  "evidence_type": "hyphae_session",
  "ref_id": "...",
  "note": "optional human-readable context"
}
```

Validate that `ref_id` looks plausible for the given `evidence_type` (for example, a
prefix-aware session ID for hyphae refs or a `cortina://...` URI for cortina events).
Return the updated task evidence summary.

#### Verification

```bash
cd canopy && cargo test evidence 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Canopy evidence slice passed.
- `tools::evidence::tests::tool_attach_evidence_returns_updated_task_summary`
- `store_roundtrip::verification_required_tasks_need_script_evidence_before_completion`
<!-- PASTE END -->

**Checklist:**
- [x] `canopy_attach_evidence` MCP tool accepts evidence type + ref_id
- [x] Returns updated evidence summary for the task
- [x] Invalid evidence type returns clear error
- [x] Evidence appears in `canopy task get <id>` output

---

### Step 2: Auto-attach cortina event IDs to active task

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 1

When cortina emits a signal and has an active canopy task for the current worktree,
automatically attach the cortina event ID as a `cortina_event` evidence ref. This
happens today on session end (Stop hook) but not mid-task on errors, corrections,
or test results.

Extend `cortina/src/bridges/canopy.rs` to call `canopy_attach_evidence` (or
`canopy task attach-evidence` CLI) for each significant mid-task signal:
- error captured -> attach cortina event ID as `cortina_event`
- correction captured -> attach as `cortina_event`
- test failure captured -> attach as `cortina_event`

**Checklist:**
- [x] Error/correction/test signals attach evidence to active canopy task
- [x] Mid-task evidence visible in `canopy task get` before session ends
- [x] Failure to attach evidence is logged but does not block signal capture

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd canopy && cargo test --all` passes
4. `cd cortina && cargo test --all` passes

Verification summary:
- `cd canopy && cargo test --all` -> passed
- `cd cortina && cargo test --all` -> passed

## Context

Canopy roadmap "Next: Evidence integration." `ECOSYSTEM-OVERVIEW.md` gap #3 (evidence
bridge completeness). The `evidence-bridge-retry.md` handoff handles reliability of
session-end writes; this handoff handles mid-task accumulation and agent ergonomics.
