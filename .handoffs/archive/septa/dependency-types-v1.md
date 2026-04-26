# Septa: Dependency Types V1 Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** `septa/` (new schema file + fixture + validation update)
- **Cross-repo edits:** none (this handoff creates the contract; adopter handoffs follow separately)
- **Non-goals:** does not implement dependency storage in any tool; does not add temporal scheduling enforcement; does not define the full task graph model (that is canopy/dag-task-graph.md)
- **Verification contract:** `bash septa/validate-all.sh` and the paired verify script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the beads ecosystem borrow audit (`.audit/external/audits/beads-ecosystem-borrow-audit.md`):

> "Issue struct encodes `blocks`/`relates_to`/`parent_child`/`discovered_from` relationships as first-class data. Agents can query 'what's blocking me?' or 'what did I discover?' with directional semantics. Edge types are not all equivalent — the direction and meaning matter."

> "`dependencies` table with `dep_type` column (blocks, relates_to, discovered_from, supersedes, duplicates)"

Multiple basidiocarp tools model relationships today without a shared vocabulary:
- `canopy` uses dependency tracking for task handoffs (untyped edges)
- `hyphae` memoir links are untyped (`hyphae_memoir_link`)
- `hymenium` workflow steps have implicit sequential dependencies

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:**
  - `dependency-types-v1.schema.json` (new) — JSON Schema definition
  - `dependency-types-v1.fixture.json` (new) — concrete examples for all edge types
  - `validate-all.sh` — add the new schema to the validation run
- **Reference seams:**
  - `septa/credential-v1.schema.json` — most recently added schema; follow for style
  - `septa/context-envelope-v1.schema.json` — component array pattern
- **Spawn gate:** seam confirmed; schema can be written directly

## Problem

Every tool that models relationships invents its own edge vocabulary. `canopy` uses "blocks" for task dependencies, `hyphae` memoir links have no type at all, and `hymenium` workflow step ordering is implicit. There is no way to ask cross-tool questions like "what tasks did this memory entry discover?" or "which workflow steps supersede earlier ones?"

Beads shows that five edge types cover the full relationship surface of agent work:
- `blocks` — directional blocking dependency (can't proceed until source completes)
- `relates_to` — bidirectional soft association (informational, not blocking)
- `discovered_from` — provenance (this work was found while doing that work)
- `supersedes` — replacement (this supersedes that; that is now obsolete)
- `duplicates` — identity (this is the same as that; one is canonical)

Plus two temporal scheduling fields that extend any dependency edge:
- `defer_until` — hide this work until a future timestamp (not blocking, just scheduled)
- `due_at` — urgency timestamp for sorting unblocked work

## What the schema should define

A `dependency-types-v1` payload:

```json
{
  "schema_version": "dependency-types-v1",
  "edge_id": "edge-abc123",
  "edge_type": "blocks",
  "from_id": "task-xyz",
  "from_type": "task",
  "to_id": "task-abc",
  "to_type": "task",
  "defer_until": null,
  "due_at": null,
  "metadata": {}
}
```

Edge types: `blocks`, `relates_to`, `discovered_from`, `supersedes`, `duplicates`.
Entity types: `task`, `memory`, `memoir`, `workflow_step`, `handoff`.
Temporal fields: ISO 8601 datetime or null.

## Scope

- **Allowed files:** `septa/dependency-types-v1.schema.json`, `septa/dependency-types-v1.fixture.json`, `septa/validate-all.sh` (update)
- **Explicit non-goals:**
  - No implementation of dependency storage in any tool
  - No enforcement of temporal scheduling (defer_until is advisory)
  - No cycle detection — this schema describes edges, not graph invariants

---

### Step 1: Write the JSON Schema

**Project:** `septa/`
**Effort:** small
**Depends on:** nothing (read `septa/credential-v1.schema.json` first for style)

Create `septa/dependency-types-v1.schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "dependency-types-v1",
  "title": "Dependency Types V1",
  "description": "A versioned envelope describing a typed dependency edge between entities across ecosystem tools.",
  "type": "object",
  "required": ["schema_version", "edge_id", "edge_type", "from_id", "from_type", "to_id", "to_type"],
  "additionalProperties": false,
  "properties": {
    "schema_version": {
      "type": "string",
      "const": "dependency-types-v1"
    },
    "edge_id": {
      "type": "string",
      "description": "Unique identifier for this dependency edge."
    },
    "edge_type": {
      "type": "string",
      "enum": ["blocks", "relates_to", "discovered_from", "supersedes", "duplicates"],
      "description": "The semantic type of this dependency. 'blocks': to_id cannot proceed until from_id completes. 'relates_to': bidirectional soft association. 'discovered_from': to_id was found while doing from_id. 'supersedes': from_id replaces to_id. 'duplicates': from_id and to_id are the same thing."
    },
    "from_id": {
      "type": "string",
      "description": "ID of the source entity."
    },
    "from_type": {
      "type": "string",
      "enum": ["task", "memory", "memoir", "workflow_step", "handoff"],
      "description": "Entity type of the source."
    },
    "to_id": {
      "type": "string",
      "description": "ID of the target entity."
    },
    "to_type": {
      "type": "string",
      "enum": ["task", "memory", "memoir", "workflow_step", "handoff"],
      "description": "Entity type of the target."
    },
    "defer_until": {
      "type": ["string", "null"],
      "format": "date-time",
      "description": "Advisory: hide the to_id entity from 'ready' queries until this timestamp. Null means no deferral."
    },
    "due_at": {
      "type": ["string", "null"],
      "format": "date-time",
      "description": "Advisory urgency timestamp for sorting unblocked work. Null means no deadline."
    },
    "metadata": {
      "type": "object",
      "description": "Tool-specific additional fields.",
      "additionalProperties": true
    }
  }
}
```

#### Verification

```bash
cd septa && node -e "
const s = require('./dependency-types-v1.schema.json');
console.log('edge_type enum:', s.properties.edge_type.enum);
console.log('from_type enum:', s.properties.from_type.enum);
console.log('OK');
"
```

**Checklist:**
- [ ] Schema parses as valid JSON
- [ ] Required fields: schema_version, edge_id, edge_type, from_id, from_type, to_id, to_type
- [ ] edge_type enum has all 5 types
- [ ] from_type / to_type enum has all 5 entity types

---

### Step 2: Write the fixture

**Project:** `septa/`
**Effort:** tiny
**Depends on:** Step 1

Create `septa/dependency-types-v1.fixture.json` with examples for all edge types:

```json
[
  {
    "schema_version": "dependency-types-v1",
    "edge_id": "edge-001",
    "edge_type": "blocks",
    "from_id": "task-setup-db",
    "from_type": "task",
    "to_id": "task-run-migration",
    "to_type": "task",
    "defer_until": null,
    "due_at": null,
    "metadata": {}
  },
  {
    "schema_version": "dependency-types-v1",
    "edge_id": "edge-002",
    "edge_type": "relates_to",
    "from_id": "memoir-auth-architecture",
    "from_type": "memoir",
    "to_id": "task-implement-oauth",
    "to_type": "task",
    "defer_until": null,
    "due_at": null,
    "metadata": { "note": "memoir describes the architecture this task implements" }
  },
  {
    "schema_version": "dependency-types-v1",
    "edge_id": "edge-003",
    "edge_type": "discovered_from",
    "from_id": "task-fix-login-bug",
    "from_type": "task",
    "to_id": "task-audit-session-tokens",
    "to_type": "task",
    "defer_until": "2026-05-01T00:00:00Z",
    "due_at": "2026-05-15T00:00:00Z",
    "metadata": {}
  },
  {
    "schema_version": "dependency-types-v1",
    "edge_id": "edge-004",
    "edge_type": "supersedes",
    "from_id": "handoff-auth-v2",
    "from_type": "handoff",
    "to_id": "handoff-auth-v1",
    "to_type": "handoff",
    "defer_until": null,
    "due_at": null,
    "metadata": { "reason": "v1 approach was replaced after audit findings" }
  },
  {
    "schema_version": "dependency-types-v1",
    "edge_id": "edge-005",
    "edge_type": "duplicates",
    "from_id": "task-setup-ci-001",
    "from_type": "task",
    "to_id": "task-setup-ci-002",
    "to_type": "task",
    "defer_until": null,
    "due_at": null,
    "metadata": { "canonical": "task-setup-ci-001" }
  }
]
```

#### Verification

```bash
cd septa && node -e "
const Ajv = require('ajv');
const ajv = new Ajv({ strict: false });
const schema = require('./dependency-types-v1.schema.json');
const fixtures = require('./dependency-types-v1.fixture.json');
let allPass = true;
fixtures.forEach((f, i) => {
  const valid = ajv.validate(schema, f);
  if (!valid) { console.error('FAIL fixture', i, ajv.errors); allPass = false; }
});
if (allPass) console.log('PASS: all fixtures validate against schema');
" 2>/dev/null || echo "Note: if ajv not installed, validate manually"
```

**Checklist:**
- [ ] All 5 fixture examples validate against the schema
- [ ] Covers: blocks, relates_to, discovered_from (with defer_until + due_at), supersedes, duplicates

---

### Step 3: Add to validate-all.sh

**Project:** `septa/`
**Effort:** tiny
**Depends on:** Step 2

Add `dependency-types-v1` to `septa/validate-all.sh` following the existing pattern.

#### Verification

```bash
cd septa && bash validate-all.sh 2>&1 | tail -10
```

**Checklist:**
- [ ] `validate-all.sh` includes dependency-types-v1
- [ ] `validate-all.sh` passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Schema and fixture written and validated
2. `validate-all.sh` updated and passing
3. `.handoffs/HANDOFFS.md` updated to reflect completion

## Follow-on work (not in scope here)

- `canopy`: store typed dependency edges using this vocabulary (replace untyped `blocks` references)
- `hyphae`: add typed edges to `hyphae_memoir_link` using this schema
- `hymenium`: express workflow step dependencies as `blocks` edges with optional `defer_until`
- `septa/temporal-scheduling-v1.schema.json`: expand `defer_until`/`due_at` into full temporal contract if needed

## Context

Spawned from Wave 2 audit program (2026-04-23). Beads demonstrates that five edge types cover the full relationship surface of agent work. The key insight: edge types are not symmetric — direction and meaning both matter. `blocks` is unidirectional and blocks execution; `relates_to` is bidirectional and informational; `discovered_from` tracks provenance; `supersedes` marks obsolescence; `duplicates` resolves identity conflicts. Temporal scheduling (`defer_until`, `due_at`) extends any edge and enables hiding future work without blocking the backlog.
