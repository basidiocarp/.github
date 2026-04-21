# Cross-Project Normalized Usage Event Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

No normalized contract exists for usage events. Cortina captures session data,
mycelium tracks savings, cap wants to display costs — but each would define its own
shape without a shared contract in septa. The synthesis (DN-9) names a normalized
usage-event contract as a "do now" recommendation. Two existing handoffs (#59 and
#62) list this as a dependency but the contract was never defined in septa.

## What exists (state)

- **septa/**: 33 contracts; no `usage-event-v1.schema.json`
- **cortina**: captures session data in internal formats; no stable emission shape
- **mycelium**: tracks savings in its own format; `septa/mycelium-gain-v1` exists
  but covers only gain data, not full session usage
- **cap**: would consume usage data for cost views (#29) but has no stable intake
  format
- **ecosystem-versions.toml**: no `usage-event` entry in `[contracts]` section

## What needs doing (intent)

Define `usage-event-v1` in septa with a JSON Schema and a reference fixture. Add it
to `ecosystem-versions.toml`. This contract is the upstream dependency that unblocks
cortina producer serialization (#62) and mycelium telemetry summaries (#59).

---

### Step 1: Define usage-event-v1 schema in septa

**Project:** `septa/`
**Effort:** 4–8 hours
**Depends on:** nothing

Create `septa/usage-event-v1.schema.json`. The schema should cover:

- `session_id` (string, required) — cortina/hyphae session ID
- `project` (string, required) — project name or working directory
- `host` (string, required) — one of `"claude-code"`, `"volva"`, `"codex"`
- `model` (string, nullable) — model name (e.g. `"claude-sonnet-4-6"`)
- `input_tokens` (integer, nullable)
- `output_tokens` (integer, nullable)
- `cache_tokens` (integer, nullable)
- `estimated_cost_usd` (number, nullable)
- `duration_seconds` (integer, nullable) — wall-clock session duration
- `tool_calls_count` (integer, required, minimum 0)
- `errors_count` (integer, required, minimum 0)
- `corrections_count` (integer, required, minimum 0)
- `mycelium_tokens_saved` (integer, nullable) — populated when mycelium is in loop
- `timestamp` (string, required) — ISO 8601
- `schema_version` (string, required, `"1.0"`)

Nullable fields must accept `null` and must not be omitted — producers set unknown
fields to `null` rather than excluding them so consumers can rely on a stable shape.

Create a matching fixture: `septa/usage-event-v1.fixture.json`. The fixture should
exercise nullable fields (some null, some populated) to serve as a useful test
payload.

Add comments in the schema identifying the producing repos (cortina, volva via
cortina) and consuming repos (mycelium, cap, hyphae optionally) so the ownership
chain is visible from the contract file itself.

#### Files to create

**`septa/usage-event-v1.schema.json`**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "usage-event-v1",
  "title": "UsageEvent",
  "description": "Normalized usage event emitted at session end. Producers: cortina (claude-code adapter, volva adapter). Consumers: mycelium (telemetry summaries), cap (cost views), hyphae (optional enrichment).",
  "type": "object",
  "required": [
    "session_id", "project", "host",
    "tool_calls_count", "errors_count", "corrections_count",
    "timestamp", "schema_version"
  ],
  "additionalProperties": false,
  "properties": {
    "session_id": { "type": "string" },
    "project": { "type": "string" },
    "host": { "type": "string", "enum": ["claude-code", "volva", "codex"] },
    "model": { "type": ["string", "null"] },
    "input_tokens": { "type": ["integer", "null"], "minimum": 0 },
    "output_tokens": { "type": ["integer", "null"], "minimum": 0 },
    "cache_tokens": { "type": ["integer", "null"], "minimum": 0 },
    "estimated_cost_usd": { "type": ["number", "null"], "minimum": 0 },
    "duration_seconds": { "type": ["integer", "null"], "minimum": 0 },
    "tool_calls_count": { "type": "integer", "minimum": 0 },
    "errors_count": { "type": "integer", "minimum": 0 },
    "corrections_count": { "type": "integer", "minimum": 0 },
    "mycelium_tokens_saved": { "type": ["integer", "null"], "minimum": 0 },
    "timestamp": { "type": "string", "format": "date-time" },
    "schema_version": { "type": "string", "const": "1.0" }
  }
}
```

#### Verification

```bash
ls septa/usage-event-v1.schema.json septa/usage-event-v1.fixture.json
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `septa/usage-event-v1.schema.json` exists
- [ ] `septa/usage-event-v1.fixture.json` exists and validates against the schema
- [ ] All nullable fields are `["type", "null"]` not missing from the schema
- [ ] `additionalProperties: false` prevents silent field drift
- [ ] Producer and consumer repos named in schema description comment

---

### Step 2: Add to ecosystem-versions.toml

**Project:** workspace root
**Effort:** 15 minutes
**Depends on:** Step 1

Add a `usage-event` entry under the `[contracts]` section of
`ecosystem-versions.toml`. Include the version, the schema file path, and the
producing/consuming repos so the pin file reflects the full ownership picture.

#### Files to modify

**`ecosystem-versions.toml`** — add under `[contracts]`:

```toml
[contracts.usage-event]
version = "1.0"
schema = "septa/usage-event-v1.schema.json"
producers = ["cortina"]
consumers = ["mycelium", "cap"]
```

#### Verification

```bash
grep -A 4 "usage-event" ecosystem-versions.toml
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `usage-event` entry present in `ecosystem-versions.toml`
- [ ] Version, schema path, producers, and consumers all listed

---

### Step 3: Validate septa fixture in CI or local check script

**Project:** `septa/`
**Effort:** 1–2 hours
**Depends on:** Step 1

Add a validation step (shell script or Makefile target) that validates all
`*.fixture.json` files against their matching `*.schema.json` in `septa/`. If a
schema validation script already exists, extend it to cover `usage-event-v1`.

This ensures the fixture stays valid as the schema evolves — a broken fixture is the
cheapest possible signal that a contract change broke a producer or consumer.

#### Verification

```bash
bash septa/scripts/validate-fixtures.sh 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Fixture validation runs without error
- [ ] Usage-event fixture is included in the validation pass
- [ ] Script exits non-zero on validation failure

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. Schema and fixture both exist in `septa/`
3. Fixture validates against the schema
4. `ecosystem-versions.toml` lists the contract
5. All checklist items are checked

### Final Verification

```bash
ls septa/usage-event-v1.* && grep "usage-event" ecosystem-versions.toml
```

**Output:**
<!-- PASTE START -->
septa/usage-event-v1.schema.json
usage-event = "1.0"
PASS  usage-event-v1.schema.json  (via septa/validate-all.sh — Results: 47 passed, 0 failed, 0 skipped)
<!-- PASTE END -->

**Required result:** both files listed, `ecosystem-versions.toml` entry present.

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DN-9 ("Define a normalized usage-event contract so local telemetry
tools do less retrospective parsing"). Listed as "do now" in the synthesis adoption
order alongside host event contracts for cortina and septa. CCUsage and RTK audits
independently converge on the same gap: sharper usage-event contracts before host
heuristics spread. This contract unblocks cortina producer serialization (#62) and
mycelium deterministic telemetry summaries (#59). Cap cost and usage tracking (#29)
is a downstream beneficiary.
