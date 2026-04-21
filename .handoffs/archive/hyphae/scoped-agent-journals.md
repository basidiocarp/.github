# Scoped Agent Journals

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

When multiple agents work on the same project (via canopy coordination), their memories are interleaved in hyphae with no agent-level scoping. Agent A's corrections and decisions are indistinguishable from Agent B's in recall. Mempalace solves this with per-agent "diary" wings. The basidiocarp equivalent is scoped journals — hyphae memories tagged by agent identity from canopy's agent registry.

## What exists (state)

- **hyphae**: memories have `topic` and `project` scoping but no `agent_id` field.
- **canopy**: agent registry with unique agent IDs, heartbeats, and task ownership.
- **cortina**: captures signals with session context but doesn't tag by agent identity.
- **No way to query** "what did Agent A learn during its session" vs "what did Agent B learn."

## What needs doing (intent)

Add an optional `agent_id` field to hyphae memory metadata, wire cortina to pass agent identity from canopy's registry, and enable agent-scoped recall queries.

---

### Step 1: Add agent_id field to hyphae memory metadata

**Project:** `hyphae/`
**Effort:** 1 day
**Depends on:** nothing

Add an optional `agent_id` field to hyphae's memory metadata:
- Migration adds nullable `agent_id` column to the memories table.
- `hyphae memory store --agent-id <id>` accepts the field.
- `hyphae search --agent <id>` filters by agent.
- `hyphae session start --agent-id <id>` associates the session with an agent.
- MCP tools accept `agent_id` parameter where relevant.
- When agent_id is not provided, behavior is unchanged (backwards compatible).

#### Verification

```bash
cd hyphae && cargo test --workspace
```

**Output:**
<!-- PASTE START -->
766 tests, 0 failed (all crates pass)
<!-- PASTE END -->

**Checklist:**
- [x] Migration adds `agent_id` column
- [x] CLI and MCP accept agent_id parameter
- [x] Search can filter by agent (get_by_agent_id in memory_store)
- [x] Existing memories without agent_id still work

---

### Step 2: Wire cortina to pass agent identity from canopy

**Project:** `cortina/`
**Effort:** 4-8 hours
**Depends on:** Step 1

When cortina captures signals and writes to hyphae, check if canopy is running and has an active agent for the current worktree. If so, include the `agent_id` in hyphae memory writes.
- Use spore discovery to check canopy availability.
- Query canopy for active agent in current worktree.
- Pass agent_id to hyphae session and memory store calls.
- Graceful degradation: if canopy isn't running, omit agent_id (current behavior).

#### Verification

```bash
cd cortina && cargo build --release && cargo test
```

**Output:**
<!-- PASTE START -->
220 passed; 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] Cortina queries canopy for active agent identity (active_agent_id / current_agent_id_for_cwd)
- [x] Agent ID is passed to hyphae writes when available (--agent-id flag)
- [x] Missing canopy is handled gracefully (no error, no agent_id)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/hyphae/verify-scoped-agent-journals.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/hyphae/verify-scoped-agent-journals.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom the mempalace borrow audit ("Adapt" category). Mempalace uses per-agent "diary wings" for agent-scoped memory. This adaptation maps the concept to hyphae's existing memory model with canopy's agent registry providing identity, avoiding mempalace's literal wing_<agent> convention.
