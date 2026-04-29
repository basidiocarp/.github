# Cross-Project: Add `annulus-status-v1` Septa Schema (F2.8)

<!-- Save as: .handoffs/cross-project/annulus-status-v1-schema.md -->
<!-- Verify script: .handoffs/cross-project/verify-annulus-status-v1-schema.sh -->
<!-- Index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (touches `septa/`, `cap/`, and references `annulus/`)
- **Allowed write scope:**
  - `septa/annulus-status-v1.schema.json` (new file)
  - `septa/fixtures/annulus-status-v1.example.json` (new file, optional `.full.json` if useful)
  - `septa/integration-patterns.md` (add row for the new contract)
  - `septa/CLAUDE.md` (refresh schema count if it's mentioned there — coordinate with F2.12 lazily, no requirement)
  - `cap/server/annulus.ts` (tighten consumer to validate `schema_version`/`schema` constant)
  - `cap/server/__tests__/annulus.test.ts` (extend the existing annulus shape tests)
- **Cross-repo edits:** septa is the schema home; cap is the consumer; annulus is the producer reference (no edits needed in `annulus/` — its emitter already tags `"schema": "annulus-status-v1"`)
- **Non-goals:**
  - Does not rename `annulus-statusline-v1` (the unrelated statusline contract stays as-is)
  - Does not change the annulus producer (it already emits the correct shape)
  - Does not address F2.10 (orphan schemas) or other lane 2 concerns
  - Does not touch annulus internals
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-annulus-status-v1-schema.sh`
- **Completion update:** after Stage 2 review passes and verification is green, commit, update `.handoffs/HANDOFFS.md` to mark this handoff done

## Implementation Seam

- **Likely repo:** workspace root, with primary writes in `septa/` and `cap/`
- **Likely files/modules:**
  - **Producer reference:** `annulus/src/status.rs:status_json` already emits `"schema": "annulus-status-v1"` with `version: "1"` and a `reports[]` array — schema must conform exactly to that shape
  - **Consumer:** `cap/server/annulus.ts:43-66` (`parseAnnulusOutput`) — currently parses the shape but does NOT validate the `schema` constant
  - **Existing reference:** `septa/annulus-statusline-v1.schema.json` shows the schema-name-as-`const` pattern (different command, same author convention)
- **Shape (from `annulus/src/status.rs`):**
  ```json
  {
    "schema": "annulus-status-v1",
    "version": "1",
    "reports": [
      { "tool": "string", "available": true|false, "tier": "tier1"|"tier2"|"tier3", "degraded_capabilities": ["string"] }
    ]
  }
  ```
- **Empty-state shape:** producer emits `{"schema":"annulus-status-v1","version":"1","reports":[]}` when no tools are registered. Schema must accept the empty array.
- **Spawn gate:** producer code is precise; consumer location is precise; ready to dispatch

## Problem

Cap consumes `annulus status --json` output (handles ecosystem health for the dashboard's `/api/ecosystem/status` route). The producer (`annulus/src/status.rs`) tags the payload with `"schema": "annulus-status-v1"`, but septa does not ship a schema by that name. `septa/annulus-statusline-v1.schema.json` describes a different command (`annulus statusline --json`, which emits segments, not reports). The cap/annulus pair therefore operates entirely off-contract: there is no schema for `validate-all.sh` to enforce, no fixture to lock the wire format, and no `schema_version` check at the consumer boundary.

This is an F1 #2 blocker: a future change to `annulus/src/status.rs` (renaming a field, adjusting tier values, dropping `degraded_capabilities`) would not be detected by `septa/validate-all.sh` and would silently break Cap's ecosystem panel.

## What exists (state)

- **Producer:** `annulus/src/status.rs` (line 39-50) — emits the correctly-tagged payload.
- **Consumer:** `cap/server/annulus.ts:43-66` — parses the payload; tier values validated as `'tier1'|'tier2'|'tier3'`; `degraded_capabilities` filtered to strings.
- **Septa:** no `annulus-status-v1.schema.json`; only `annulus-statusline-v1.schema.json` (different surface).
- **Integration patterns:** `septa/integration-patterns.md` does not list this producer/consumer pair.
- **Cap CLAUDE.md "Inbound contracts" table:** does not list `annulus-status-v1`.
- **Tests:** `cap/server/__tests__/annulus.test.ts` covers shape parsing but does not assert the `schema` constant.

## What needs doing (intent)

1. Author `septa/annulus-status-v1.schema.json` matching the producer shape exactly. Use the `annulus-statusline-v1` schema as a structural template.
2. Add at least one fixture (`septa/fixtures/annulus-status-v1.example.json`). If the empty-state shape is meaningfully different, add `annulus-status-v1.empty.json` too.
3. Add a row to `septa/integration-patterns.md` documenting the producer (annulus) → consumer (cap) flow.
4. Tighten `cap/server/annulus.ts:parseAnnulusOutput` to validate `schema === 'annulus-status-v1'` and `version === '1'` at the boundary, returning the same `{ available: false, reports: [] }` degradation on validation failure that `getAnnulusStatus` already returns on CLI failure.
5. Extend `cap/server/__tests__/annulus.test.ts` to assert the schema-constant check (rejects payloads with a wrong/missing `schema` field).
6. Confirm `septa/validate-all.sh` exits 0 with the new schema and fixture(s).

## Scope

- **Primary seam:** the septa contract gap between `annulus status --json` producer and cap consumer
- **Allowed files:** as listed under "Allowed write scope" above
- **Explicit non-goals:**
  - Renaming or repurposing `annulus-statusline-v1`
  - Changing the annulus producer (already correct)
  - Cap CLAUDE.md "Inbound contracts" table — optional update if the pattern there is to enumerate every schema (it currently lists only the 5 pre-existing ones; adding it is fine and recommended, but if scope creep concerns arise, defer)
  - Triaging orphan schemas (F2.10)
  - Touching the stipe validators (separate handoff)

---

### Step 1: Author `septa/annulus-status-v1.schema.json`

**Project:** `septa/`
**Effort:** small
**Depends on:** nothing

Use `septa/annulus-statusline-v1.schema.json` as the structural template (same `$schema`, `$id` pattern, `schema` const + `version` const + items pattern). The producer shape is fully specified in `annulus/src/status.rs:39-50` — match exactly.

#### Files to modify

**`septa/annulus-status-v1.schema.json`** (new):

Required top-level: `schema, version, reports`. Schema is `const: "annulus-status-v1"`. Version is `const: "1"`. Reports is array of report objects. Each report requires `tool, available, tier, degraded_capabilities`. Tier is enum `["tier1", "tier2", "tier3"]`. Degraded_capabilities is array of strings (may be empty).

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && python3 -c "import json; json.load(open('annulus-status-v1.schema.json'))")
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && grep -c '"const":' annulus-status-v1.schema.json)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Schema file is valid JSON
- [ ] `schema` is `const: "annulus-status-v1"`
- [ ] `version` is `const: "1"`
- [ ] `tier` enum matches `["tier1", "tier2", "tier3"]`
- [ ] `additionalProperties: false` set on each object
- [ ] No fields invented beyond what the producer emits

---

### Step 2: Add fixtures

**Project:** `septa/`
**Effort:** small
**Depends on:** Step 1

Add at least one fixture demonstrating the populated shape, plus an empty-state fixture if it adds coverage value (the producer can return `reports: []`).

#### Files to modify

**`septa/fixtures/annulus-status-v1.example.json`** (new):

Pick representative reports — at least 2 entries, mixing `available: true/false` and at least one tier from each value, with `degraded_capabilities` populated on the unavailable rows.

**`septa/fixtures/annulus-status-v1.empty.json`** (new, optional but recommended):

`{"schema":"annulus-status-v1","version":"1","reports":[]}` — locks in the empty-state contract that today depends on producer behavior alone.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && bash validate-all.sh 2>&1 | grep -E "annulus-status-v1|Results:")
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `validate-all.sh` includes the new schema in its run
- [ ] All annulus-status-v1 fixtures pass validation
- [ ] Final result remains "0 failed"

---

### Step 3: Update `septa/integration-patterns.md`

**Project:** `septa/`
**Effort:** trivial
**Depends on:** Step 2

Add a row to the producer/consumer table for the new contract. Match the existing table format. Note the producer (`annulus/src/status.rs`) and consumer (`cap/server/annulus.ts`).

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && grep -n "annulus-status-v1" integration-patterns.md)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Row added that names producer + consumer + schema file
- [ ] No prior row for `annulus-status-v1` (avoid duplicates)

---

### Step 4: Tighten cap consumer to validate `schema` and `version`

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 1

Update `cap/server/annulus.ts:parseAnnulusOutput` to reject payloads whose `schema` constant is missing or wrong, or whose `version` is not `"1"`. Use the existing degradation path (caught in `getAnnulusStatus` and returned as `{ available: false, reports: [] }`).

#### Files to modify

**`cap/server/annulus.ts`** — adjust `parseAnnulusOutput`:

After parsing JSON, before reading `payload.reports`, verify:

```typescript
if (payload.schema !== 'annulus-status-v1') {
  throw new Error(`annulus status --json schema mismatch: expected annulus-status-v1, got ${payload.schema}`)
}
if (payload.version !== '1') {
  throw new Error(`annulus status --json version mismatch: expected "1", got ${payload.version}`)
}
```

The existing `try`/`catch` in `getAnnulusStatus` already handles parse failures gracefully. New errors flow into the same path.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && grep -n "annulus-status-v1" server/annulus.ts)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Schema constant check present
- [ ] Version constant check present
- [ ] Existing tier/report validation logic untouched

---

### Step 5: Extend cap test coverage

**Project:** `cap/`
**Effort:** small
**Depends on:** Step 4

Extend `cap/server/__tests__/annulus.test.ts` to assert:

1. A payload with the correct `schema` and `version` parses (regression).
2. A payload with `schema: "wrong-name"` triggers the degradation path (returns `{ available: false, reports: [] }`).
3. A payload missing `schema` triggers the degradation path.
4. A payload with `version: "2"` triggers the degradation path.
5. The empty-reports case (`reports: []`) still parses cleanly.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm run test:server -- annulus)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All five cases covered
- [ ] Existing annulus tests still pass

---

### Step 6: Full validation

**Project:** workspace root
**Effort:** trivial
**Depends on:** Steps 1-5

Run all relevant validators end-to-end.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && bash validate-all.sh)
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- biome check server/annulus.ts server/__tests__/annulus.test.ts)
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm exec --offline -- tsc --noEmit -p server/tsconfig.json)
(cd /Users/williamnewton/projects/personal/basidiocarp/cap && npm test)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `validate-all.sh` final line shows "0 failed"
- [ ] Biome clean on touched cap files
- [ ] tsc --noEmit (server) passes
- [ ] `npm test` exits 0

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cross-project/verify-annulus-status-v1-schema.sh`
3. All checklist items are checked
4. Stage 1 + Stage 2 review have run and passed (per `CLAUDE.md` delegation contract)
5. The change is committed and `.handoffs/HANDOFFS.md` reflects completion

### Final Verification

```bash
bash .handoffs/cross-project/verify-annulus-status-v1-schema.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

This handoff closes lane 2 blocker F2.8 from the [Post-Execution Boundary Compliance Audit (2026-04-29)](../campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-septa-contract-accuracy.md). It addresses the F1 exit criterion #2 ("septa validate-all.sh stays green and covers cross-tool wire formats"). Pairs cleanly with the cap stipe validator handoff (F2.1+F2.3) — different repos, different files, runs in parallel.

## Style Notes

- Match `septa/annulus-statusline-v1.schema.json` for `$id`, `additionalProperties: false` discipline, and `const` field style.
- Producer field names are non-negotiable — the schema follows the code, not the other way around. If the producer field set seems wrong, that's a separate handoff.
- Don't add operator-readable text fields the producer doesn't emit. Schemas describe wire shapes, not UI state.
- Cap consumer should fail soft (degradation path) rather than 500 the route — this matches existing behavior.
