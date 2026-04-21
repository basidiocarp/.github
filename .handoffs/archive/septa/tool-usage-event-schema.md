# Septa: Tool Usage Event Schema

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** septa/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `septa` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The ecosystem has no structured record of which tools an agent used (or didn't use) during a session. Cortina captures lifecycle events and tool calls, but there's no schema that aggregates tool usage into a per-session summary. Without this contract, canopy can't score tool adoption and cap can't surface it.

## What exists (state)

- **Cortina lifecycle events**: `cortina-lifecycle-event-v1.schema.json` captures individual tool calls per hook event
- **Usage event schema**: `usage-event-v1.schema.json` tracks cost/token usage but not tool adoption
- **Septa validation**: `validate-all.sh` validates all schema+fixture pairs with local $ref resolution

## What needs doing (intent)

Define a `tool-usage-event-v1.schema.json` in septa that records per-session tool usage: which ecosystem tools were available, which were called, call counts, and which were relevant but unused.

---

### Step 1: Define the schema

**Project:** `septa/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create `septa/tool-usage-event-v1.schema.json` with these fields:

- `schema_version`: const "1.0"
- `session_id`: ULID string (^[0-9A-HJKMNP-TV-Z]{26}$)
- `host`: $ref to host-identifier-v1.schema.json
- `timestamp`: ISO 8601 string
- `tools_available`: array of objects with { tool_name: string, source: enum ["hyphae", "rhizome", "cortina", "mycelium", "canopy", "volva", "spore", "other"] }
- `tools_called`: array of objects with { tool_name: string, source: enum (same), call_count: integer (minimum 1), first_call_at: ISO 8601 string, last_call_at: ISO 8601 string }
- `tools_relevant_unused`: array of objects with { tool_name: string, source: enum (same), relevance_reason: string } — tools that were relevant to the task but never called
- `task_id`: optional ULID — canopy task if available

Use `additionalProperties: false` at all levels. Use `$ref` for host identifier.

#### Files to modify

**`septa/tool-usage-event-v1.schema.json`** — create new schema file

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && bash validate-all.sh
```

**Checklist:**
- [ ] Schema created with all required fields
- [ ] Uses $ref for host-identifier-v1.schema.json
- [ ] ULID pattern matches existing schemas
- [ ] additionalProperties: false at all levels
- [ ] validate-all.sh passes (may skip if no fixture yet)

---

### Step 2: Create the example fixture

**Project:** `septa/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Create `septa/fixtures/tool-usage-event-v1.example.json` with a realistic example showing a session where hyphae and rhizome were available, hyphae was called 3 times, rhizome was never called despite being relevant (agent edited code without checking references).

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && bash validate-all.sh
```

**Checklist:**
- [ ] Fixture validates against schema
- [ ] Example shows realistic tool usage data
- [ ] Includes at least one tools_relevant_unused entry
- [ ] validate-all.sh passes with 0 failures

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `bash validate-all.sh` passes in `septa/`
3. All checklist items are checked

## Context

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `septa` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsPart of the tool usage observability chain (#114a-d). This schema is consumed by cortina (#114b) to emit events, by canopy (#114c) to score adoption, and by cap/annulus (#114d) to surface in the dashboard. Related to #96 (Usage Event Contract) which covers cost — this covers tool adoption.
