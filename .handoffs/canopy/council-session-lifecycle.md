# Canopy Council Session Lifecycle

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

Canopy has council message threads (proposal, objection, evidence, decision) but no
explicit session concept for councils. Councils have no formal open/close state,
participant roster, or timeline. The council audit points to explicit session records
with roster, transcript state, and lifecycle management. Without these, council
deliberation is not retrievable as a first-class artifact and operator tooling
cannot show which councils are open, who is participating, or what was decided.

## What exists (state)

- **canopy**: council threads per task with typed message kinds (`proposal`,
  `objection`, `evidence`, `decision`, `handoff`, `status`)
- No `council_sessions` table or session concept — messages exist but are not
  grouped under a session with explicit state
- No participant roster tracked per council
- No council session lifecycle events flowing to cortina or hyphae
- **hyphae typed artifact storage (#97)**: council records will be storable as typed
  artifacts once #97 lands, but canopy must produce them first

## What needs doing (intent)

Add a `council_sessions` table to canopy's SQLite schema. Council messages link to
a session. Sessions transition through explicit states. When a session closes, emit
a structured record that cortina can capture and hyphae can store as a typed
artifact.

---

### Step 1: Add council session model

**Project:** `canopy/`
**Effort:** 1 day
**Depends on:** nothing

Add a `council_sessions` table and wire council messages to it:

```sql
CREATE TABLE council_sessions (
    session_id   TEXT PRIMARY KEY,
    task_id      TEXT NOT NULL REFERENCES tasks(task_id),
    status       TEXT NOT NULL DEFAULT 'open',
    -- status: 'open' | 'deliberating' | 'decided' | 'closed'
    opened_at    TEXT NOT NULL,
    closed_at    TEXT,
    participants TEXT NOT NULL DEFAULT '[]',  -- JSON array of agent_ids
    outcome      TEXT,                        -- decision text if decided
    schema_version TEXT NOT NULL DEFAULT '1.0'
);

-- Link existing council_messages to sessions
ALTER TABLE council_messages ADD COLUMN session_id TEXT REFERENCES council_sessions(session_id);
```

Add CLI surfaces:

- `canopy council open --task <id>` — opens a new council session for the task
- `canopy council close --session <id> [--outcome "<text>"]` — closes and records outcome
- `canopy council status --task <id>` — shows open sessions and participant list
- `canopy council join --session <id> --agent <id>` — adds a participant

Session state transitions:
- `open` → `deliberating` (when first message is posted to the session)
- `deliberating` → `decided` (when a `decision` message is posted)
- `decided` → `closed` (explicit close, outcome recorded)

#### Files to modify

**`canopy/src/db/migrations/`** — add migration for `council_sessions` table and
`council_messages.session_id` column

**`canopy/src/council/session.rs`** — new file:

```rust
pub struct CouncilSession {
    pub session_id: String,
    pub task_id: String,
    pub status: SessionStatus,
    pub opened_at: String,
    pub closed_at: Option<String>,
    pub participants: Vec<String>,
    pub outcome: Option<String>,
    pub schema_version: String,
}

pub enum SessionStatus {
    Open,
    Deliberating,
    Decided,
    Closed,
}

impl CouncilStore {
    pub fn open_session(&self, task_id: &str) -> Result<CouncilSession>;
    pub fn close_session(&self, session_id: &str, outcome: Option<&str>) -> Result<CouncilSession>;
    pub fn join_session(&self, session_id: &str, agent_id: &str) -> Result<()>;
    pub fn get_open_sessions(&self, task_id: &str) -> Result<Vec<CouncilSession>>;
}
```

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
cargo test --all 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `council_sessions` table exists with migration
- [ ] Sessions have explicit `open` → `deliberating` → `decided` → `closed` lifecycle
- [ ] Participant roster tracked per session
- [ ] Existing council messages linked to sessions (or migration bridge in place)
- [ ] `canopy council open/close/status/join` CLI surfaces work
- [ ] Build and tests pass

---

### Step 2: Emit council lifecycle events to cortina

**Project:** `cortina/`, `canopy/`
**Effort:** 4–8 hours
**Depends on:** Step 1

When a council session opens or closes, emit a structured cortina event. This gives
cortina visibility into council lifecycle without making canopy dependent on cortina
at runtime — canopy writes to a local event file or calls a cortina CLI surface;
cortina picks it up.

Cortina captures the event and stores it in hyphae. If hyphae typed artifact storage
(#97) is available, council-close events store as `council_record` typed artifacts
with the full session payload (roster, message count, outcome).

```rust
// In canopy council close handler:
let record = CouncilRecord {
    session_id: session.session_id.clone(),
    task_id: session.task_id.clone(),
    participants: session.participants.clone(),
    outcome: session.outcome.clone(),
    message_count: thread.len(),
    opened_at: session.opened_at.clone(),
    closed_at: session.closed_at.clone(),
    schema_version: "1.0".into(),
};
cortina_client.emit_council_event(CouncilLifecycleEvent::Closed(record))?;
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
- [ ] Council open events captured by cortina
- [ ] Council close events captured by cortina with outcome and roster
- [ ] Council records stored in hyphae (as `council_record` artifact if #97 is
  available, as generic memory otherwise)
- [ ] Council outcomes linked to task evidence in canopy (evidence ref written)

---

### Step 3: Surface open councils in canopy task snapshots

**Project:** `canopy/`
**Effort:** 2–4 hours
**Depends on:** Step 1

When `canopy snapshot` or `canopy task show` is called, include open council
sessions for the task in the output: session ID, status, participant count, and time
open. This gives the operator visibility into pending deliberations without a
separate command.

#### Verification

```bash
cd canopy && cargo test --all 2>&1 | tail -10
canopy task show --task <id> 2>&1 | grep -i council
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Open council sessions appear in `canopy task show` output
- [ ] Status, participant count, and time open all visible
- [ ] Closed sessions omitted from the snapshot (not cluttering active view)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build` and `cargo test --all` pass in `canopy/`
3. Council sessions have explicit lifecycle state and participant rosters
4. Open councils surface in task snapshots
5. Council close events flow to cortina and hyphae
6. All checklist items are checked

### Final Verification

```bash
cd canopy && cargo build 2>&1 | tail -5 && cargo test --all 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** build clean, all tests pass.

## Context

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `canopy` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DX-1 ("Add task-linked council sessions and queue semantics to
Canopy, surfaced in Cap"). The council audit points to explicit session records with
lifecycle state, participant rosters, and council timeline. The synthesis lists this
under "do next." Council artifacts pair with hyphae typed artifacts (#97) for
council record storage — Step 2 of this handoff produces the records that #97's
`council_record` artifact type stores. Cap's live operator views (#24) would surface
council session state once the transport boundary decision is resolved.
