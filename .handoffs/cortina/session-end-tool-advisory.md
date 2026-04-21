# Cortina: Session-End Tool Usage Advisory

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

Pre-write advisories (#115b) nudge agents in real-time, but there's no retrospective summary of tool adoption gaps at session end. Operators reviewing session outcomes need a concise report: "this agent edited 5 Rust files but never called rhizome." This summary feeds into canopy scoring (#114c) and cap surfaces (#114d).

## What exists (state)

- **Cortina SessionEnd handler**: Fires at session close — already emits session summary signals
- **Tool usage accumulator**: #114b tracks per-session tool calls
- **Tool relevance rules**: #115a defines which tools are relevant for which operations
- **Pre-write advisories**: #115b emits real-time nudges — this is the retrospective counterpart

## What needs doing (intent)

At session end, generate a tool usage summary that lists adoption gaps and stores them for canopy and cap to consume.

---

### Step 1: Generate tool adoption gap summary

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** #114b (Tool Usage Accumulator), #115a (Tool Relevance Rules)

At session end, cross-reference:
1. What operations the agent performed (from the signal buffer — which files were written/edited)
2. What tools were recommended for those operations (from the relevance rules)
3. What tools were actually called (from the accumulator)

Produce a structured summary:

```rust
pub struct ToolAdoptionGapSummary {
    pub session_id: String,
    pub total_write_ops: u32,          // how many Write/Edit calls
    pub files_touched: Vec<String>,     // paths written to
    pub gaps: Vec<ToolAdoptionGap>,
    pub advisory_count: u32,            // how many pre-write advisories were emitted
}

pub struct ToolAdoptionGap {
    pub tool_name: String,
    pub source: String,
    pub relevance_reason: String,
    pub severity: String,
    pub files_affected: Vec<String>,    // which files triggered this gap
}
```

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Gap summary generated from accumulator + rules + signal buffer
- [ ] Files touched extracted from session signals
- [ ] Gaps list only includes tools that were relevant but unused
- [ ] Build and tests pass

---

### Step 2: Emit gap summary in session-end output

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Wire the gap summary into cortina's SessionEnd output:
1. Include in the tool-usage-event-v1 (extends the `tools_relevant_unused` field with file-level detail)
2. Write a human-readable summary to stderr (visible to operators watching the session)
3. Store in hyphae as `context/{project}/tool-gaps` with importance `medium` (so future sessions can recall "you skipped rhizome last time")

Human-readable format:
```
Tool adoption: 3/5 relevant tools used
Gaps:
  - rhizome.find_references (recommended) — 3 Rust files edited without reference check
  - hyphae.memory_store (optional) — decisions made but not stored
```

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Gap summary included in tool-usage-event emission
- [ ] Human-readable summary written to stderr
- [ ] Summary stored in hyphae for cross-session recall
- [ ] No output when there are no gaps (clean sessions are quiet)
- [ ] Tests pass

---

### Step 3: Unit tests for gap detection

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 2

Test cases:
1. Session with Write to .rs files, no rhizome calls → gap detected
2. Session with Write to .rs files, rhizome called → no gap
3. Session with no Write/Edit calls → no gaps (nothing to check)
4. Session with only optional-severity gaps → gaps reported but with softer language
5. Rules file missing → no gap detection, no error

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Gap detection works for various scenarios
- [ ] Severity levels affect output language
- [ ] Clean sessions produce no output
- [ ] Missing rules handled gracefully
- [ ] All tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `cortina/`
3. All checklist items are checked

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFinal piece of the behavioral guardrails chain (#115a-c). Depends on #114b (accumulator), #115a (rules), and complements #115b (pre-write checks). The gap summary stored in hyphae creates a cross-session feedback loop — if the agent skips rhizome repeatedly, the memory recall will surface "you skipped rhizome in your last 3 sessions" which may improve adoption over time.
