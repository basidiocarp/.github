# Usage Event Producer Serialization in Cortina

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

Cortina captures lifecycle signals but serializes them in ad-hoc formats. There
is no normalized usage-event shape that downstream consumers — mycelium for
reporting, cap for display — can rely on. The synthesis (DN-9) calls for a
normalized usage-event contract so local telemetry tools do less retrospective
parsing. Without it, every consumer invents its own parsing heuristics against
cortina's internal formats.

## What exists (state)

- **cortina**: captures errors, corrections, builds, tests, and session events in
  various internal formats; `cortina statusline` emits estimated cost and token
  counts but not in a stable schema
- **septa**: 33 contracts; no `usage-event-v1` contract exists yet
- **mycelium gain**: human-readable token savings output, not contract-backed
- **cap**: would consume usage data for cost views but has no stable intake format

## What needs doing (intent)

Implement a `UsageEvent` struct in cortina that normalizes session usage data into
a stable serialized shape. Emit it at session end. Once the upstream cross-project
contract (#96) exists in septa, align cortina's output to that schema and add a
contract validation test.

---

### Step 1: Define UsageEvent struct and emit at session end

**Project:** `cortina/`
**Effort:** 1 day
**Depends on:** nothing

Add a `UsageEvent` type that collects all available session usage fields and
serializes them to JSON at session end:

- `session_id` — matches the cortina/hyphae session ID for the run
- `project` — working directory or project name
- `host` — `"claude-code"`, `"volva"`, or `"codex"`
- `model` — model name if available from session context
- `input_tokens`, `output_tokens`, `cache_tokens` — from session signal buffer
- `estimated_cost_usd` — from cortina's existing cost estimation
- `duration_seconds` — wall-clock session duration
- `tool_calls_count`, `errors_count`, `corrections_count` — from signal tallies
- `timestamp` — ISO 8601 session-end time
- `schema_version: "1.0"`

Fields unavailable for a given host should be `null`, not omitted. The output
should land in a well-known location so downstream consumers can find it.

#### Files to modify

**`cortina/src/usage_event.rs`** — new file:

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct UsageEvent {
    pub session_id: String,
    pub project: String,
    pub host: String,
    pub model: Option<String>,
    pub input_tokens: Option<u64>,
    pub output_tokens: Option<u64>,
    pub cache_tokens: Option<u64>,
    pub estimated_cost_usd: Option<f64>,
    pub duration_seconds: Option<u64>,
    pub tool_calls_count: u32,
    pub errors_count: u32,
    pub corrections_count: u32,
    pub timestamp: String,
    pub schema_version: String,
}

impl UsageEvent {
    pub fn from_session(session: &SessionSummary) -> Self;
    pub fn write_to_disk(&self, dest: &Path) -> Result<()>;
}
```

**`cortina/src/adapters/session_end.rs`** — emit at session end:

```rust
let event = UsageEvent::from_session(&summary);
event.write_to_disk(&usage_event_path()?)?;
```

#### Verification

```bash
cd cortina && cargo build --release 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `UsageEvent` struct defined with all listed fields
- [ ] Emitted at session end for both Claude Code and volva adapters
- [ ] Fields unavailable for a host are `null`, not omitted
- [ ] `schema_version: "1.0"` always present
- [ ] Build and tests pass

---

### Step 2: Align with septa usage-event contract

**Project:** `cortina/`, `septa/`
**Effort:** 4–8 hours
**Depends on:** Step 1, and Cross-Project Usage Event Contract (#96)

Once `septa/usage-event-v1.schema.json` exists (created by #96), update cortina's
serializer to conform exactly to that schema. Add a contract test that validates a
sample emitted event against the septa schema using `jsonschema` or equivalent.

The test should live in `cortina/tests/` and load the schema from septa by relative
path (or a pinned fixture copy) so that schema changes force an explicit cortina
update.

#### Files to modify

**`cortina/tests/usage_event_contract.rs`** — new integration test:

```rust
#[test]
fn emitted_event_validates_against_septa_schema() {
    let schema = load_schema("../septa/usage-event-v1.schema.json");
    let event = UsageEvent::fixture();
    assert!(schema.validate(&serde_json::to_value(event).unwrap()).is_ok());
}
```

#### Verification

```bash
cd cortina && cargo test usage_event_contract 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Cortina output validates against the septa `usage-event-v1` schema
- [ ] Contract test is in `cortina/tests/` and runs with `cargo test`
- [ ] Schema path is relative so a schema change fails the test explicitly

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --release` and `cargo test --workspace` pass in `cortina/`
3. `UsageEvent` is emitted at session end with all available fields
4. Contract test validates against the septa schema
5. All checklist items are checked

### Final Verification

```bash
cd cortina && cargo build --release 2>&1 | tail -5 && cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** build clean, all tests pass.

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DN-9 ("Define a normalized usage-event contract so local telemetry
tools do less retrospective parsing"). Listed as a "do now" recommendation in the
synthesis. Feeds downstream into mycelium telemetry summaries (#59) and cap
cost/usage views (#29). Step 2 depends on the upstream contract definition in #96.
The cortina-side struct in Step 1 can be written before #96 exists; Step 2 just
aligns it once the schema is locked.
