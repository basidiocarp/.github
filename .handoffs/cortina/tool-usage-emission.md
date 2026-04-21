# Cortina: Tool Usage Emission

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

Cortina captures individual tool calls via PostToolUse events, but it doesn't aggregate them into a per-session summary. There's no signal that tells canopy "this agent used hyphae 3 times, never called rhizome, and had mycelium available but unused." Without session-level aggregation, tool adoption is invisible.

## What exists (state)

- **Cortina PostToolUse handler**: Captures individual tool calls with tool name, duration, and outcome
- **Cortina SessionEnd handler**: Fires at session close — natural point to emit aggregated data
- **Signal buffer**: Cortina maintains a rolling buffer of recent signals per session
- **Tool usage event schema**: #114a defines `tool-usage-event-v1.schema.json` in septa

## What needs doing (intent)

Add a tool usage accumulator to cortina that tracks tool calls per session and emits a `tool-usage-event-v1` at session end.

---

### Step 1: Add tool usage accumulator to session state

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** #114a (Tool Usage Event Schema)

Add a `ToolUsageAccumulator` to cortina's per-session state that:

1. Maintains a set of available tools (populated from the MCP tool list at session start)
2. On each PostToolUse event, increments call count and updates first/last call timestamps for that tool
3. Categorizes tools by source (hyphae, rhizome, cortina, mycelium, canopy, volva, spore, other) based on tool name prefix or MCP server name

#### Files to modify

**`cortina/src/signals/tool_usage.rs`** — create new module:

```rust
pub struct ToolUsageAccumulator {
    available: HashMap<String, ToolSource>,
    called: HashMap<String, ToolCallRecord>,
}

pub struct ToolCallRecord {
    source: ToolSource,
    call_count: u32,
    first_call_at: DateTime<Utc>,
    last_call_at: DateTime<Utc>,
}

pub enum ToolSource {
    Hyphae, Rhizome, Cortina, Mycelium, Canopy, Volva, Spore, Other,
}

impl ToolUsageAccumulator {
    pub fn new(available_tools: Vec<(String, ToolSource)>) -> Self;
    pub fn record_call(&mut self, tool_name: &str, timestamp: DateTime<Utc>);
    pub fn to_event(&self, session_id: &str) -> ToolUsageEvent;
}
```

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] ToolUsageAccumulator tracks available and called tools
- [ ] Call counts and timestamps updated on each PostToolUse
- [ ] Tool source categorization works for all ecosystem tools
- [ ] Build and tests pass

---

### Step 2: Emit tool usage event at session end

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Wire the accumulator into the SessionEnd handler:

1. Call `accumulator.to_event(session_id)` to build the event
2. Serialize to JSON matching `tool-usage-event-v1.schema.json`
3. Write to cortina's event output (same path as other lifecycle events)

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] SessionEnd handler emits tool-usage-event
- [ ] Event JSON matches septa schema
- [ ] Event includes tools_available, tools_called, and tools_relevant_unused
- [ ] Tests pass

---

### Step 3: Add unit tests with fixture validation

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 2

Add tests that:
1. Create an accumulator, record several tool calls, and verify the output event structure
2. Verify the emitted JSON validates against the septa schema (use the fixture as a reference)
3. Test edge cases: no tools called, all tools called, unknown tool names

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Unit tests cover accumulator logic
- [ ] Output matches septa schema structure
- [ ] Edge cases tested (empty session, all tools used, unknown tools)
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
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsPart of the tool usage observability chain (#114a-d). Depends on #114a (schema). Consumed by #114c (canopy scoring) and #114d (cap/annulus surfaces). Related to #66 (PreCompact capture) which also extends cortina's session-end behavior.
