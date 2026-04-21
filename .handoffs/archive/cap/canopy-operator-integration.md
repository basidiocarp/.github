# Cap Canopy Operator Integration

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Cap has no canopy integration. The transport decision that blocked it (CLI vs HTTP)
is settled: cap already uses CLI-backed reads with schema_version contracts for
hyphae and mycelium — the same pattern applies to canopy. Canopy snapshots and
task-detail already use `schema_version: "1.0"`. Cap already validates this in other
contexts. There is nothing blocking implementation — the decision just hasn't been
committed to. Operators have no view into active agents, task board, blocked tasks,
pending handoffs, or council summaries in cap.

## What exists (state)

- **Canopy CLI:** `canopy snapshot`, `canopy task list`, `canopy task get <id>`, all output JSON
- **Schema contracts:** `evidence-ref-v1`, snapshot, task-detail at `schema_version: "1.0"`
- **Cap pattern:** reads hyphae and mycelium via CLI → JSON → validated by cap backend
- **Agent coordination:** already works via canopy MCP (30 tools) — the gap is the operator view only
- **Cap backend:** Hono server in `cap/server/` — add canopy routes here

## What needs doing (intent)

Add a canopy read layer to cap using CLI-backed reads, matching the established
hyphae/mycelium pattern. Ship the operator view: active agents, task board,
pending handoffs.

---

### Step 1: Add canopy CLI read surface to cap backend

**Project:** `cap/`
**Effort:** 2-3 hours

Create `cap/server/canopy.ts` (or equivalent) that shells out to `canopy snapshot`
and `canopy task list --format json`, parses the output, validates `schema_version`,
and exposes it as cap backend endpoints.

**Endpoints to add:**
- `GET /api/canopy/snapshot` — active agents, open tasks, pending handoffs counts
- `GET /api/canopy/tasks` — task list with status, owner, priority
- `GET /api/canopy/tasks/:id` — task detail with evidence refs

Follow the same pattern as `cap/server/hyphae.ts` (or equivalent hyphae read module).

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy backend routes exist and build
- [ ] `schema_version: "1.0"` validated on canopy responses
- [ ] Graceful degradation when canopy is not running (empty state, not error)

---

### Step 2: Add canopy panel to cap frontend

**Project:** `cap/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Add a canopy section to the cap dashboard showing:
- Active agents (name, last heartbeat, owned tasks)
- Task board: open / in-progress / blocked / pending handoff counts
- Recent tasks list with status badges

Match the visual style of existing cap panels.

#### Verification

```bash
cd cap && npm test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy panel renders without errors
- [ ] Shows empty/unavailable state cleanly when canopy is not running
- [ ] Task board counts are accurate vs `canopy snapshot` output

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. An operator can see active agents and task board in cap

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands`IMPROVEMENTS-OBSERVATION-V1.md` and `IMPROVEMENTS-OBSERVATION-V2.md` both confirm
the transport decision is effectively made: CLI-backed reads are the pattern.
`ECOSYSTEM-OVERVIEW.md` lists canopy integration as gap #2. AI agent coordination
through canopy MCP already works — this is only the human operator dashboard surface.
