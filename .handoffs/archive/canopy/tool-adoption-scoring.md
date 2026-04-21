# Canopy: Tool Adoption Scoring

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** canopy/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Canopy tracks task outcomes (pass/fail, evidence, handoffs) but has no signal about whether agents leveraged the ecosystem's tools effectively. An agent that completes a code task without ever calling rhizome (code intelligence) may produce lower quality results than one that checks references first. Without scoring, there's no way to detect or improve tool adoption patterns.

## What exists (state)

- **Canopy task model**: Tasks have status, evidence, handoff context — no tool usage data
- **Tool usage events**: #114b adds per-session tool-usage-event-v1 emission from cortina
- **Evidence model**: Canopy's evidence-ref system can link arbitrary evidence to tasks

## What needs doing (intent)

Add a tool adoption score to canopy tasks, computed from cortina's tool-usage-events. The score reflects what percentage of relevant tools were actually used.

---

### Step 1: Define tool adoption score model

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** #114a (Tool Usage Event Schema)

Add a `ToolAdoptionScore` type to canopy's task model:

```rust
pub struct ToolAdoptionScore {
    pub score: f32,              // 0.0 to 1.0 — ratio of relevant tools used
    pub tools_used: u32,         // count of ecosystem tools called
    pub tools_relevant: u32,     // count of tools deemed relevant
    pub tools_available: u32,    // count of tools that were available
    pub details: Vec<ToolAdoptionDetail>,
}

pub struct ToolAdoptionDetail {
    pub tool_name: String,
    pub source: String,          // hyphae, rhizome, etc.
    pub status: ToolAdoptionStatus,
}

pub enum ToolAdoptionStatus {
    Used,             // Tool was called
    AvailableUnused,  // Available but not relevant — fine
    RelevantUnused,   // Relevant but not called — gap
}
```

Score = tools_used / tools_relevant (or 1.0 if no tools were relevant).

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] ToolAdoptionScore type defined with score, counts, and details
- [ ] Score computation handles edge case (no relevant tools = 1.0)
- [ ] Build and tests pass

---

### Step 2: Ingest tool usage events from cortina

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** Step 1, #114b (Cortina Tool Usage Emission)

Add a handler that:
1. Receives tool-usage-event-v1 from cortina (via the existing event ingestion path)
2. Matches the event to a canopy task via session_id or task_id
3. Computes the ToolAdoptionScore from the event data
4. Stores the score on the task record

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Tool usage events ingested from cortina output
- [ ] Events matched to tasks by session_id or task_id
- [ ] Score computed and stored on task record
- [ ] Tests pass

---

### Step 3: Add tool adoption to task detail API

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** Step 2

Expose the ToolAdoptionScore in canopy's task detail output (consumed by cap for display). The score should appear in the existing canopy-task-detail response alongside test_status and build_status.

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/canopy && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Tool adoption score included in task detail response
- [ ] Score serializes as JSON matching the ToolAdoptionScore structure
- [ ] Null/absent when no tool usage event received (backward compatible)
- [ ] Tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `canopy/`
3. All checklist items are checked

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsPart of the tool usage observability chain (#114a-d). Depends on #114a (schema) and #114b (cortina emission). Consumed by #114d (cap/annulus surfaces). Related to #63 (Recall Effectiveness Scoring) which scores hyphae recall quality — this scores tool adoption breadth.
