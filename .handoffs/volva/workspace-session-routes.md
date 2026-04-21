# Volva: Workspace-Session Route Models

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

<!-- Save as: .handoffs/volva/workspace-session-routes.md -->

## Problem

Volva manages execution-host sessions but has no formal model for how sessions
bind to workspaces. When multiple projects are active simultaneously — especially
under canopy multi-agent coordination — there is no defined answer for whether a
workspace can have multiple concurrent sessions, how session state is scoped to a
workspace, or how a workspace switch is handled mid-session. Without a binding
model, the implicit behavior is undefined and difficult to reason about when
canopy begins dispatching agents across multiple workspaces.

## What exists (state)

- **`volva-runtime`**: manages session lifecycle (start, run, end); sessions are
  associated with a working directory but have no formal workspace concept
- **Context assembly**: pre-run envelope includes a project identifier derived
  from the working directory; no workspace-level routing abstraction exists
- **Canopy dispatch**: assigns tasks to agents by capability and registration;
  does not yet express workspace affinity when routing tasks
- **Septa**: no workspace-session binding contract or event schema exists today
- **Spore**: provides workspace and path primitives used by other tools; the
  workspace discovery primitives are likely the right foundation

## What needs doing (intent)

Define a workspace-session binding model for volva, add workspace context to the
session lifecycle, and wire that model into canopy's agent dispatch. The design
should answer three questions: how many sessions can a workspace have (1:1 vs
1:N), what session state is scoped to the workspace vs the session, and how does
volva handle workspace switches cleanly. Start with the model definition before
writing any code.

---

### Step 1: Define the workspace-session binding model

**Project:** `volva/` (design document), `septa/`
**Effort:** 1–2 days (design-first)
**Depends on:** nothing

Produce a short design document (ADR or septa/README section) that answers:

- **Cardinality**: does a workspace support one session at a time (1:1) or
  multiple concurrent sessions (1:N)? Define the default and whether override
  is possible.
- **Scoping rules**: which session state is workspace-local (env, working
  directory, active config) vs session-local (context envelope, history, cost
  counters)?
- **Workspace switch semantics**: when a session moves to a different workspace,
  what is flushed, what is retained, and whether the old workspace session is
  cleanly closed first.
- **Identity**: how is a workspace identified — by canonical path, by spore
  workspace record, or by a stable ID independent of path?

This design gates Steps 2–4. Do not implement before it is settled.

#### Verification

- [ ] Design document written and placed in `septa/docs/` or `volva/docs/`
- [ ] Cardinality, scoping, switch semantics, and identity all answered
- [ ] Design reviewed against canopy multi-workspace patterns (even if canopy
      multi-workspace is not yet implemented)

---

### Step 2: Add workspace context to volva session lifecycle

**Project:** `volva/`
**Effort:** 2–3 days
**Depends on:** Step 1 (binding model settled)

Extend volva's session record and lifecycle to carry a workspace identifier:

- Add a `workspace_id` field to the session record, resolved from spore workspace
  primitives at session start
- Emit workspace context into the host envelope (after the recall injection point
  from `#71`) so agents know which workspace they are in
- Add a workspace-scoped session guard: if 1:1 cardinality is chosen, reject or
  queue a new session start when the workspace already has an active session
- Extend `volva backend doctor` to show active session count per workspace

The exact shape depends on the binding model from Step 1.

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `workspace_id` field in session record, resolved via spore
- [ ] Workspace context in host envelope
- [ ] Cardinality guard enforced at session start
- [ ] `volva backend doctor` shows workspace session counts
- [ ] Build and tests pass

---

### Step 3: Wire workspace routing into canopy agent dispatch

**Project:** `canopy/`
**Effort:** 2–3 days
**Depends on:** Step 2

Extend canopy's task dispatch to express workspace affinity:

- Tasks can carry an optional `workspace` field indicating which workspace the
  assigned agent must be running in
- `canopy task assign` checks workspace affinity when selecting an agent
- Agents register their current workspace via `canopy agent register
  --workspace <id>` (or heartbeat update) so canopy knows where each agent is
- Dispatch without workspace affinity continues to work as today

This is a soft constraint initially: workspace mismatch is logged but not
necessarily rejected, to allow gradual adoption.

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Tasks accept optional `workspace` field
- [ ] Agents can declare current workspace in registry
- [ ] Dispatch prefers agents matching the workspace affinity
- [ ] Mismatch logged clearly; not a hard rejection unless configured
- [ ] Build and tests pass

---

### Step 4: Add septa contract for workspace-session binding events

**Project:** `septa/`
**Effort:** 1 day
**Depends on:** Steps 2–3

Add a septa schema and fixture for workspace-session lifecycle events:

- `workspace_session_started`: workspace ID, session ID, agent ID, timestamp
- `workspace_session_ended`: workspace ID, session ID, outcome, duration
- `workspace_session_conflict`: emitted when a second session start is blocked
  by the cardinality guard

These events let cap, hyphae, and future tools observe workspace-session patterns
without polling volva directly.

#### Verification

```bash
cd septa && ./validate.sh 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Schema added for workspace-session events
- [ ] Example fixtures cover started, ended, and conflict events
- [ ] Validation script passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. The binding model document from Step 1 is written and answers all four design
   questions
2. Every subsequent step has verification output pasted between the markers
3. `cargo build --workspace` and `cargo test --workspace` pass in both `volva/`
   and `canopy/`
4. Septa validation passes with the new workspace-session event schema
5. All checklist items are checked

### Final Verification

```bash
cd volva && cargo test --workspace 2>&1 | tail -5
cd canopy && cargo test --workspace 2>&1 | tail -5
cd septa && ./validate.sh 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

Source: Vibe Kanban audit. Priority: **Lower** — may be premature until canopy
multi-workspace patterns are more concrete. The binding model is the hard part;
the implementation follows naturally once scoping decisions are made.

This handoff depends implicitly on `#71` (Volva Hyphae Recall Injection) being
in place, since the workspace context sits in the same host envelope as the
recall block. It also depends on canopy multi-workspace usage patterns being
clearer — right now canopy assigns tasks to agents without workspace awareness,
which works fine for single-workspace deployments.

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsDo not start Step 2 without completing Step 1. The wrong cardinality or scoping
choice at design time will require unwinding session record changes later.
