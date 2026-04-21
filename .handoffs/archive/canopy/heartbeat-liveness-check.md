# Canopy Heartbeat Liveness Check on Task Claim

## Problem

Canopy flags stale agents in the attention model (`AgentAttentionReason::StaleHeartbeat`)
but does not prevent them from claiming tasks. An agent that crashed without clean
shutdown appears active until its heartbeat ages past the stale threshold
(`HEARTBEAT_STALE_MINUTES = 60`). During that window, task assignment to a stale
agent is a coordination hazard — work is assigned to something that isn't running.

## What exists (state)

- **`list_stale_agents(stale_threshold_secs)`:** `store/agents.rs:167` — queries by heartbeat age
- **`HEARTBEAT_STALE_MINUTES = 60`:** `api.rs:25` — stale threshold for attention model
- **Attention model:** flags `StaleHeartbeat` as a reason but takes no blocking action
- **Task claim:** no heartbeat freshness check before accepting a claim

## What needs doing (intent)

Add a freshness check to the task claim path: reject claims from agents whose
last heartbeat is older than a configurable threshold.

---

### Step 1: Add freshness check to task claim

**Project:** `canopy/`
**Effort:** 1-2 hours

In the task claim handler (`tools/task.rs` or equivalent), before accepting the
claim, look up the claiming agent's last heartbeat. If it's older than
`CLAIM_STALE_THRESHOLD_SECS` (default: 300 — 5 minutes), reject with a clear error:

```
ClaimError::StaleAgent {
    agent_id,
    last_heartbeat_secs_ago,
    threshold_secs,
}
```

Error message: `"agent {id} last heartbeat was {N}s ago (threshold: {T}s) — send a heartbeat before claiming"`

Allow override via `--force-claim` for manual operator intervention.

#### Verification

```bash
cd canopy && cargo test claim 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Claim rejected when agent heartbeat older than threshold
- [ ] Error message includes age and threshold
- [ ] Claim succeeds when heartbeat is fresh
- [ ] `--force-claim` flag bypasses check for operator use
- [ ] Agent with no heartbeat record treated as stale

---

### Step 2: Surface stale agent warnings in snapshot

**Project:** `canopy/`
**Effort:** 30 min
**Depends on:** Step 1

Ensure `canopy snapshot` output includes stale agent count and that stale agents
are clearly identified in `canopy agent list`. The attention model already tracks
this; confirm it flows through to CLI output.

**Checklist:**
- [ ] `canopy snapshot` includes `stale_agents` count
- [ ] `canopy agent list` shows freshness status per agent
- [ ] Stale agents have a visual indicator in `canopy agent list` output

---

## Completion Protocol

1. Every step has verification output pasted
2. All checklist items checked
3. `cd canopy && cargo test --all` passes

## Context

`IMPROVEMENTS-OBSERVATION-V2.md` identifies this as a correctness gap for
multi-agent coordination. Canopy roadmap "Research: Heartbeat model". The
implementation choice here is Option A (minimal, check on claim) rather than
Option B (background status transitions) — correctness without background job
complexity.
