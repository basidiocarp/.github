# Septa: Context Envelope V1 Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** `septa/` (new schema file + fixture), `septa/validate-all.sh` (update)
- **Cross-repo edits:** none (this handoff creates the contract; adopter handoffs follow separately)
- **Non-goals:** does not implement the context assembly logic in hyphae or cap; does not define retrieval strategies; does not replace the existing `code-graph-v1` schema
- **Verification contract:** `bash septa/validate-all.sh` and the paired verify script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by serena's context assembly pattern (audit: `.audit/external/audits/serena-ecosystem-borrow-audit.md`):

> "Schema-versioned context envelopes and token-budgeted context assembly. Best fit: hyphae, then cap."
> — serena `src/serena/resources/config/contexts/`, `prompt_factory.py`

And corroborated by multiple Wave 2 audits pointing to the same missing septa contract.

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:**
  - `context-envelope-v1.schema.json` (new) — the JSON Schema definition
  - `context-envelope-v1.fixture.json` (new) — a concrete example used for validation
  - `validate-all.sh` — add the new schema to the validation run
- **Reference seams:**
  - `septa/code-graph-v1.schema.json` — existing schema file to follow for conventions
  - `septa/code-graph-v1.fixture.json` — existing fixture file for format
- **Spawn gate:** seam confirmed; schema can be written directly

## Problem

When a tool (hyphae, rhizome, canopy) assembles context for the model, it produces a bag of facts: memory snippets, code symbols, session state, diagnostics. Today there is no shared envelope for this payload. Each tool formats context differently, the structure is not versioned, and consumers cannot tell which components are present without parsing the raw content.

This matters because:
1. Cap cannot render context components without knowing their types
2. Hyphae and rhizome cannot coordinate on token budgets without a shared shape
3. The assembly cannot be validated against a contract

Serena's insight: a schema-versioned context envelope that declares components explicitly (memory, symbols, session, diagnostics) with per-component token counts and source metadata.

## What the schema should define

A `context-envelope-v1` payload:

```json
{
  "schema_version": "context-envelope-v1",
  "assembled_at": "<ISO 8601 timestamp>",
  "token_budget": {
    "total": 8000,
    "used": 3420,
    "remaining": 4580
  },
  "components": [
    {
      "type": "memory",
      "source": "hyphae",
      "topic": "errors/resolved",
      "token_count": 420,
      "content": "..."
    },
    {
      "type": "symbols",
      "source": "rhizome",
      "path": "canopy/src/tools/mod.rs",
      "token_count": 840,
      "content": "..."
    },
    {
      "type": "session",
      "source": "cortina",
      "session_id": "sess-abc123",
      "token_count": 200,
      "content": "..."
    },
    {
      "type": "diagnostics",
      "source": "rhizome",
      "path": "canopy/src/store/traits.rs",
      "token_count": 160,
      "content": "..."
    }
  ]
}
```

Component `type` is an open enum: `memory`, `symbols`, `session`, `diagnostics`, `handoff`, `task`. New types should be addable without breaking consumers.

## What needs doing (intent)

Write the JSON Schema and a concrete fixture. The schema should:
1. Require `schema_version`, `assembled_at`, `components`
2. Make `token_budget` optional but typed if present
3. Define `components` as an array of objects with required `type`, `source`, `token_count`, `content`
4. Use `additionalProperties: false` on the envelope but allow open `type` values (string enum with known values listed but not exhaustive)

---

### Step 1: Write the JSON Schema

**Project:** `septa/`
**Effort:** small
**Depends on:** nothing (read `septa/code-graph-v1.schema.json` first for conventions)

Create `septa/context-envelope-v1.schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "context-envelope-v1",
  "title": "Context Envelope V1",
  "description": "A versioned envelope for assembled context payloads passed between ecosystem tools.",
  "type": "object",
  "required": ["schema_version", "assembled_at", "components"],
  "additionalProperties": false,
  "properties": {
    "schema_version": {
      "type": "string",
      "const": "context-envelope-v1"
    },
    "assembled_at": {
      "type": "string",
      "format": "date-time"
    },
    "token_budget": {
      "type": "object",
      "required": ["total", "used", "remaining"],
      "additionalProperties": false,
      "properties": {
        "total":     { "type": "integer", "minimum": 0 },
        "used":      { "type": "integer", "minimum": 0 },
        "remaining": { "type": "integer", "minimum": 0 }
      }
    },
    "components": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type", "source", "token_count", "content"],
        "additionalProperties": true,
        "properties": {
          "type": {
            "type": "string",
            "description": "Component type. Known values: memory, symbols, session, diagnostics, handoff, task."
          },
          "source": {
            "type": "string",
            "description": "Ecosystem tool that produced this component."
          },
          "token_count": {
            "type": "integer",
            "minimum": 0
          },
          "content": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

#### Verification

```bash
cd septa && node -e "
const s = require('./context-envelope-v1.schema.json');
console.log('schema_version const:', s.properties.schema_version.const);
console.log('components type:', s.properties.components.type);
console.log('OK');
"
```

**Checklist:**
- [ ] Schema file parses as valid JSON
- [ ] Required fields correct: `schema_version`, `assembled_at`, `components`

---

### Step 2: Write the fixture

**Project:** `septa/`
**Effort:** tiny
**Depends on:** Step 1

Create `septa/context-envelope-v1.fixture.json` with a concrete multi-component example:

```json
{
  "schema_version": "context-envelope-v1",
  "assembled_at": "2026-04-23T12:00:00Z",
  "token_budget": {
    "total": 8000,
    "used": 1620,
    "remaining": 6380
  },
  "components": [
    {
      "type": "memory",
      "source": "hyphae",
      "topic": "errors/resolved",
      "token_count": 420,
      "content": "Previous session: fixed canopy dispatch_tool borrow issue by restructuring match before early-return."
    },
    {
      "type": "symbols",
      "source": "rhizome",
      "path": "canopy/src/tools/mod.rs",
      "token_count": 840,
      "content": "pub async fn dispatch_tool(store: &impl CanopyStore, agent_id: &str, name: &str, ...) -> ToolResult"
    },
    {
      "type": "session",
      "source": "cortina",
      "session_id": "sess-abc123",
      "token_count": 200,
      "content": "Session started 2026-04-23T11:45:00Z. Working in canopy. Last tool: mcp__canopy__canopy_task_list."
    },
    {
      "type": "diagnostics",
      "source": "rhizome",
      "path": "canopy/src/store/traits.rs",
      "token_count": 160,
      "content": "No diagnostics."
    }
  ]
}
```

#### Verification

```bash
cd septa && node -e "
const Ajv = require('ajv');
const ajv = new Ajv({ strict: false });
const schema = require('./context-envelope-v1.schema.json');
const fixture = require('./context-envelope-v1.fixture.json');
const valid = ajv.validate(schema, fixture);
if (!valid) { console.error(ajv.errors); process.exit(1); }
console.log('PASS: fixture validates against schema');
" 2>/dev/null || echo "Note: if ajv not installed, validate manually"
```

**Checklist:**
- [ ] Fixture validates against the schema
- [ ] Fixture has at least 3 components of different types

---

### Step 3: Add to validate-all.sh

**Project:** `septa/`
**Effort:** tiny
**Depends on:** Step 2

Add `context-envelope-v1` to `septa/validate-all.sh` following the existing pattern for other schemas.

#### Verification

```bash
cd septa && bash validate-all.sh 2>&1 | tail -10
```

**Checklist:**
- [ ] `validate-all.sh` includes context-envelope-v1
- [ ] `validate-all.sh` passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Schema and fixture written and validated
2. `validate-all.sh` updated and passing
3. `.handoffs/HANDOFFS.md` updated to reflect completion

## Follow-on work (not in scope here)

- `hyphae`: produce `context-envelope-v1` payloads from `hyphae_gather_context`
- `rhizome`: include code symbols in context envelopes with token counts
- `cap`: render context envelope components in the operator view
- Rate this contract in `septa/README.md` as a v1 contract with known consumers

## Context

Spawned from the serena Wave 1 re-audit (2026-04-23), corroborated by multiple Wave 2 audits pointing to the same missing septa contract. Several external projects bundle memory+symbols+diagnostics informally; the ecosystem needs a versioned envelope that all tools can produce and consume. This is the contract definition only — implementation handoffs follow.
