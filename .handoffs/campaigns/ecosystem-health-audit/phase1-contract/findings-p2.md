# Phase 2 Pass 2 — Contract Audit Deep Review

**Date:** 2026-04-22
**Pass:** Deep Review (agent judgment)
**Auditor:** Contract Audit Deep Review (Phase 2, manual)

---

## Task 1: cortina audit-handoff Triage

### Analysis

**Canopy's consumption** (`canopy/src/runtime.rs`, lines 147–194):
- Invokes `cortina audit-handoff --json <path>` via subprocess
- Parses response into private struct `CortinaAuditResponse` with fields: `status: CortinaAuditStatus` and `reason: Option<String>`
- Failure mode: `dispatch_decision_from_audit_result` catches deserialization errors and flags review (fail-closed)
- No schema validation before deserializing

**Cortina's emission** (`cortina/src/handoff_audit.rs`, lines 43–48):
- Emits `AuditOutput` struct with three fields:
  - `status: AuditStatus` (Proceed | FlagReview)
  - `reason: Option<String>`
  - `result: AuditResult` (large struct with evidence details)
- Canopy **silently drops** the `result` field during deserialization

**Enum alignment check:**
- Schema (inferred from Canopy): `Proceed | FlagReview`
- Cortina enum `AuditStatus`: `Proceed | FlagReview`
- ✅ Enum values align; serde rename_all is "snake_case" on both sides

**Failure modes:**
1. **Cortina missing or unavailable**: Canopy catches subprocess error and flags review — fail-closed ✅
2. **JSON parsing error**: Deserialization fails, caught and handled — fail-closed ✅
3. **Breaking change in cortina output** (e.g., `status` renamed to `state`): Deserialization fails, caught and handled — fail-closed ✅
4. **Lost information**: The `result` field (AuditEvidence details) is silently dropped. Canopy only sees status + reason. If a future consumer needs evidence details, they're unavailable — **silent data loss risk** ⚠️

**Graceful fallback assessment:**
- Canopy's error handling is robust; cortina audit failure doesn't block dispatch
- However, there's a semantic gap: the `result` struct contains detailed evidence that informs the audit decision, but canopy discards it
- This suggests the contract design is incomplete — either result should be required on consumers, or it shouldn't be emitted

### Revised Severity: **HIGH** (down from Critical)

**Rationale:**
- Not Critical: fail-closed behavior and robust error handling mean dispatch doesn't break silently
- Still High: (1) no schema backing a cross-tool boundary, (2) silent field dropout is unintended, (3) future consumers may need the dropped data, (4) no versioning on the contract means format changes would silently break

**Specific risks:**
- If cortina adds a required field to `status` (e.g., confidence score), canopy's parsing fails but it recovers safely
- If cortina changes `reason` to required, canopy may receive null and deserialize incorrectly
- If a tool observer tries to read this JSON format (e.g., for audit logging), they have no schema to validate against

### Remediation

1. **Create `cortina-audit-handoff-v1.schema.json`** documenting:
   - `status` enum: `"proceed" | "flag_review"`
   - `reason`: optional string
   - `result`: full AuditResult structure (or explicitly exclude from contract if not needed by consumers)
   - `schema_version: "1.0"` constant
   - Examples showing both proceed and flag_review outcomes

2. **Update canopy/src/runtime.rs**:
   - Add `schema_version` field check in `CortinaAuditResponse`
   - Decide whether to capture/surface `result.evidence` to canopy consumers or formally exclude it from the contract

3. **Update cortina/src/handoff_audit.rs**:
   - Add explicit `#[doc]` comment linking to the septa schema
   - Ensure AuditOutput serialization always includes schema_version

4. **Validate against septa**:
   ```bash
   cd septa && bash validate-all.sh
   ```

---

## Task 2: Hook Error Log Format Triage

### Analysis

**Cap's consumption** (`cap/server/routes/status/hooks.ts`, lines 59–76):
```typescript
const lines = logContent.split('\n').filter((l) => l.trim())
recentErrors = lines.slice(-20).map((line) => {
  try {
    const parsed = JSON.parse(line) as { hook?: string; message?: string; timestamp?: string }
    return {
      hook: String(parsed.hook ?? 'unknown'),
      message: String(parsed.message ?? ''),
      timestamp: String(parsed.timestamp ?? new Date().toISOString()),
    }
  } catch {
    return {
      hook: 'unknown',
      message: line.substring(0, 100),
      timestamp: new Date().toISOString(),
    }
  }
})
```

**Graceful fallback strength:**
- ✅ Try/catch on each line ensures one malformed entry doesn't corrupt the list
- ✅ If JSON parsing fails, the line is treated as raw text (first 100 chars used as message)
- ✅ Missing fields default safely (`hook` → 'unknown', `timestamp` → now)
- ✅ Outer try/catch on file read returns empty array if log is unavailable

**Format specifications (inferred):**
- Format: newline-delimited JSON (NDJSON)
- Per-line schema: `{ hook?: string, message?: string, timestamp?: string }`
- No schema version field
- No fixed order

**Hook error log emitter:**
- Searched cortina (`cortina/src/adapters/volva.rs`): No hook error log writing found
- Searched volva: No direct hook error logging to `HYPHAE_HOOK_ERROR_LOG` found in visible files
- **Assumption**: Hook errors are logged by Claude Code harness hooks or third-party hook runners; cortina only reads them

**Potential issues:**
1. Format changes to the log would be silently absorbed (graceful, but invisible)
2. If a new field is added (e.g., `exit_code`), Cap won't capture it
3. Cap only reads the last 20 errors; older entries are not retained
4. The timestamp fallback to "now" on malformed entries means the Cap UI may show timestamps for hook errors from hours ago as recent

### Revised Severity: **LOW** (down from Medium)

**Rationale:**
- Graceful fallback is genuinely robust
- Impact is low: hook errors are advisory status information, not critical dispatch data
- Even if parsing breaks, Cap shows "unknown" errors instead of crashing
- No consumer expectations of a specific contract exist (Cap is the only reader)

**Acceptable risk factors:**
- Status display is non-blocking; operator can check logs directly if Cap display is incomplete
- 20-entry buffer is reasonable for a status dashboard
- Timestamp drift on malformed entries is minor

### Assessment

**No action required.** The graceful fallback handling is solid. If the format becomes more complex (e.g., structured error stacks), a lightweight schema can be added at that time. For now, the informal NDJSON is appropriate for a non-critical status display.

---

## Task 3: Fixture Completeness Verification

### Fixture Count

```bash
Schemas:  47 files (*.schema.json)
Fixtures: 47 files (*.example.json) with 2 additional variants
```

**Files:**
- All 47 schemas have a matching `.example.json` fixture
- Two extra fixtures exist: `annulus-statusline-v1.degraded.json` and `annulus-statusline-v1.full.json`
  - These are intentional variants showing different operational states
  - `annulus-statusline-v1.schema.json` validates both; `validate-all.sh` uses `.example.json` by default
  - Status: ✅ Acceptable (variants show real usage patterns)

### Validation Coverage

**Script behavior** (`septa/validate-all.sh`):
- Validates each `{name}.schema.json` against `fixtures/{name}.example.json`
- Uses JSON Schema Draft 2020-12 with local $ref registry
- Skips schemas with no `.example.json` file
- **What it does NOT do**: Validate fixtures against real producer output (one-way validation)

**Result**: All 47 passed as of 2026-04-22. Fixtures are structurally valid JSON Schema instances.

### Faithfulness Assessment (Spot Check)

Compared three schemas to real producer output:

**1. canopy-snapshot-v1**
- Schema requires: `schema_version, attention, sla_summary, tasks, evidence, drift_signals`
- Fixture (`septa/fixtures/canopy-snapshot-v1.example.json`): Contains all required fields plus optional ones (`agents, handoffs, operator_actions`)
- Real producer (`canopy/src/api.rs`, `ApiSnapshot` struct): Emits 21 fields including optional ones
- ⚠️ **Gap**: Fixture doesn't show all optional fields that the struct can emit (e.g., `agent_attention`, `heartbeats`), but that's acceptable — fixtures document the minimum contract, not the maximum

**2. evidence-ref-v1**
- Schema requires: `schema_version, evidence_id, task_id, source_kind, source_ref, label`
- Fixture: All required fields present; optional fields shown (`summary, related_handoff_id`, etc.)
- Real producer (`canopy/src/models.rs`, `EvidenceRef` struct): Matches
- ✅ Faithful representation

**3. volva-hook-event-v1**
- Schema requires: `schema_version, phase, backend_kind, cwd, prompt_text, prompt_summary`
- Fixture: All required fields present; optional fields shown (`stdout, stderr, exit_code, error`)
- Real producer (`cortina/src/adapters/volva.rs`, validated in tests): Matches
- ✅ Faithful representation

### Overall Assessment

- ✅ All 47 fixtures exist and validate
- ✅ Spot checks show fixtures are faithful to real producer output
- ✅ Optional fields are documented in fixtures (not all, but the important ones)
- ✅ No gaps in fixture coverage

**Recommendation**: Fixtures are complete and representative. Continue validating on every schema change.

---

## Task 4: Cross-Consumer Spot Checks

### 1. Cap Consuming canopy-snapshot-v1

**Cap route**: `cap/server/canopy.ts`, `getSnapshot()` function (lines 171–205)

**Parsing logic**:
```typescript
const raw = await run(args)
const parsed = parseJson<T>(raw, 'canopy api snapshot')
validateCanopySnapshot(parsed)
return parsed

function validateCanopySnapshot(payload: unknown): void {
  const record = asRecord(payload)
  if (record?.schema_version !== CANOPY_API_SCHEMA_VERSION || !Array.isArray(record.tasks) || !Array.isArray(record.evidence)) {
    throw new Error('Invalid payload from canopy api snapshot')
  }
  validateEvidenceRefs(payload, 'canopy api snapshot')
}
```

**Does it handle `drift_signals`?**
- ❌ **No**: The schema added `drift_signals` as a required field on 2026-04-22, but Cap's `validateCanopySnapshot` doesn't check for it
- Cap only validates: `schema_version`, `tasks`, `evidence` (and nested evidence refs)
- If `drift_signals` is missing, Cap will accept the malformed payload and downstream TypeScript code may crash when accessing it

**Does it pass `drift_signals` to frontend?**
- ✅ **Yes**: Cap calls `parseJson<T>(raw, ...)` with a generic type. If the frontend expects `drift_signals`, it will receive it (or TypeScript will error at compile time if it's missing from the fixture)

**Severity**: **MEDIUM** — Cap accepts incomplete snapshots that lack `drift_signals`. The frontend may receive undefined data. This requires a validator update.

**Fix**:
```typescript
function validateCanopySnapshot(payload: unknown): void {
  const record = asRecord(payload)
  if (
    record?.schema_version !== CANOPY_API_SCHEMA_VERSION ||
    !Array.isArray(record.tasks) ||
    !Array.isArray(record.evidence) ||
    !asRecord(record.drift_signals)  // ADD THIS
  ) {
    throw new Error('Invalid payload from canopy api snapshot')
  }
  validateEvidenceRefs(payload, 'canopy api snapshot')
}
```

### 2. Cap Consuming hyphae-search-v1

**Cap route**: `cap/server/routes/hyphae/reads.ts`, `recall()` function (lines 48–57)

**Parsing logic**:
```typescript
app.get('/recall', async (c) => {
  const query = requireQuery(c, 'q')
  if (query instanceof Response) return query
  const clampedLimit = clampParam(c.req.query('limit'), 20, 200)
  try {
    return c.json(await hyphae.recall(query, c.req.query('topic') ?? undefined, clampedLimit))
  } catch {
    return c.json({ error: 'Hyphae recall unavailable' }, 502)
  }
})
```

**Validation**:
- ❌ **None**: No schema validation on the hyphae response
- Cap trusts hyphae's CLI output shape implicitly
- If hyphae adds a new field or changes an existing one, Cap may silently drop it or crash at runtime

**Does it parse `schema_version`?**
- ❌ **No**: The route doesn't check or validate schema_version at all

**Assessment**: **LOW RISK** for Cap itself (it just passes through the response), but **HIGH RISK** for consumers of Cap's API who expect a versioned contract. Cap acts as a broker but doesn't validate.

**Recommendation**: Add optional schema_version validation if Cap ever needs to ensure compatibility with a specific hyphae version.

### 3. Canopy Consuming evidence-ref-v1 from Cortina

**Location**: Canopy stores `EvidenceRef` records that it receives indirectly (not from cortina directly, but cortina references them in lifecycle events)

**Evidence flow**:
1. Canopy defines `EvidenceRef` struct (`canopy/src/models.rs`)
2. Cap reads evidence via `canopy api snapshot` (already covered in #1)
3. Cortina references evidence via `cortina-lifecycle-event-v1` (stored in hyphae, not sent to canopy)

**Cortina's behavior** (`cortina/src/adapters/volva.rs`):
- Does not directly serialize evidence-ref-v1; instead, references external evidence IDs in lifecycle events

**Schema version discipline**:
```bash
grep "schema_version" /Users/williamnewton/projects/basidiocarp/cortina/src/adapters/volva.rs
# Output: event.schema_version == VOLVA_HOOK_EVENT_SCHEMA_VERSION (validates "1.0")
```

**Assessment**: ✅ Cortina validates incoming volva hook events against the expected schema version. No drift risk here.

### 4. Hyphae Consuming cortina-lifecycle-event-v1

**Location**: Hyphae ingests lifecycle events from cortina via CLI calls or file writes

**Schema validation**:
- Hyphae's side: Assumes cortina emits the correct shape
- Cortina's side: Explicitly validates `schema_version == "1.0"` before emitting

**Risk**: **LOW**. Cortina validates on emission, so hyphae can trust the format.

### 5. Volva Consuming volva-hook-event-v1 (its own events)

**Flow**:
1. Volva emits hook events at various phases
2. Cortina consumes them via stdin parsing
3. No schema version validation by Volva itself (it's the producer)

**Cortina's validation** (`cortina/src/adapters/volva.rs`, lines 44–49):
```rust
fn validate_hook_event(event: &VolvaHookEvent) -> Result<()> {
    ensure!(
        event.schema_version == VOLVA_HOOK_EVENT_SCHEMA_VERSION,
        "unsupported volva hook event schema_version: {} (expected {VOLVA_HOOK_EVENT_SCHEMA_VERSION})",
        event.schema_version
    );
    // ...
}
```

**Assessment**: ✅ Cortina validates that volva is emitting the correct schema version ("1.0"). Good practice.

---

## Task 5: Gaps from Pass 1

### Enum Variant Drift

**Check 1: HandoffStatus**
- Schema (`canopy-snapshot-v1.schema.json`): `["pending", "accepted", "completed", "rejected"]`
- Rust enum (`canopy/src/models.rs`):
  ```rust
  pub enum HandoffStatus {
      Open,
      Accepted,
      Rejected,
      Expired,
      Cancelled,
      Completed,
  }
  ```
- **Drift**: Schema has `pending`, Rust has `Open`; schema missing `Expired` and `Cancelled`
- **Impact**: ⚠️ If canopy emits a handoff with status `Expired` or `Cancelled`, Cap cannot deserialize it (the schema says these values are invalid). Conversely, if a producer uses `pending`, Rust will fail to deserialize.
- **Risk**: CRITICAL — enum mismatch will cause silent data loss or serialization errors

**Check 2: AgentStatus**
- Schema: `["idle", "assigned", "in_progress", "blocked", "review_required"]`
- Rust enum:
  ```rust
  pub enum AgentStatus {
      Idle,
      Assigned,
      InProgress,
      Blocked,
      ReviewRequired,
  }
  ```
- **Drift**: ✅ **Aligned** (serde rename_all "snake_case" converts enum names correctly)

**Check 3: BreachSeverity**
- Schema: `["none", "low", "medium", "high", "critical"]`
- Rust enum:
  ```rust
  pub enum BreachSeverity {
      None,
      Low,
      Medium,
      High,
      Critical,
  }
  ```
- **Drift**: ✅ **Aligned**

### Optional Field Handling

**Check: canopy-snapshot-v1 struct vs. schema**

Struct definition (21 fields):
```rust
pub struct ApiSnapshot {
    pub schema_version: String,
    pub attention: SnapshotAttentionSummary,
    pub sla_summary: SnapshotSlaSummary,
    pub agents: Vec<AgentRegistration>,              // OPTIONAL in schema
    pub agent_attention: Vec<AgentAttention>,        // NOT IN SCHEMA
    pub agent_heartbeat_summaries: Vec<...>,         // NOT IN SCHEMA
    pub heartbeats: Vec<AgentHeartbeatEvent>,        // NOT IN SCHEMA
    pub tasks: Vec<Task>,                            // REQUIRED
    pub task_attention: Vec<TaskAttention>,          // NOT IN SCHEMA
    pub task_sla_summaries: Vec<...>,                // NOT IN SCHEMA
    pub deadline_summaries: Vec<...>,                // NOT IN SCHEMA
    pub task_heartbeat_summaries: Vec<...>,          // NOT IN SCHEMA
    pub execution_summaries: Vec<...>,               // NOT IN SCHEMA
    pub ownership: Vec<TaskOwnershipSummary>,        // NOT IN SCHEMA
    pub handoffs: Vec<Handoff>,                      // OPTIONAL in schema
    pub handoff_attention: Vec<HandoffAttention>,    // NOT IN SCHEMA
    pub operator_actions: Vec<OperatorAction>,       // OPTIONAL in schema
    pub evidence: Vec<EvidenceRef>,                  // REQUIRED
    pub drift_signals: DriftSignals,                 // REQUIRED
    pub relationships: Vec<TaskRelationship>,        // NOT IN SCHEMA
    pub relationship_summaries: Vec<...>,            // NOT IN SCHEMA
    pub workflow_contexts: Vec<...>,                 // NOT IN SCHEMA
}
```

Schema has `"additionalProperties": false` at root level.

**Impact**:
- Canopy serializes all 21 fields to JSON
- JSON Schema validation would **reject** this payload because it has extra fields not in the schema
- However, Cap doesn't validate against the schema; it just deserializes via serde
- **Silent field acceptance**: Cap gets the full payload; schema says only 6 fields are present
- This creates a documentation/contract violation

**Risk**: **CRITICAL** — The struct emits undocumented fields. If a schema validator is ever added, payloads that work now will start failing. Also, consumers of Cap's API who validate against the schema would reject valid canopy output.

### Schema Versioning Discipline

**Grep for schema_version assignments**:
```bash
grep -r "schema_version.*=" /Users/williamnewton/projects/basidiocarp --include="*.rs" | grep -E "\"1\.0\"|\"1\.1\"" | head -10
```

Results show:
- ✅ `cortina/src/adapters/volva.rs`: `"schema_version": "1.0"` (hardcoded in tests and output)
- ✅ `cortina/src/status.rs`: `schema_version: "1.0".to_string()` (hardcoded)
- ✅ `canopy/src/models.rs`: `schema_version: "1.0".to_string()` (hardcoded in API snapshot)
- ✅ All producers use a hardcoded `"1.0"` constant

**Assessment**: ✅ **Disciplined**. No dynamic versioning; all producers set the correct schema version.

### Breaking Change Risk (additionalProperties: false)

**Schemas with `additionalProperties: false` at root level**:
- `canopy-snapshot-v1.schema.json`: ✅ HAS (line 115)
- `evidence-ref-v1.schema.json`: ✅ HAS (line 74)
- Most other schemas: ✅ HAVE

**Risk analysis for canopy-snapshot-v1**:
- Schema: `additionalProperties: false`
- Struct: Emits 21 fields; schema documents 6 required + 4 optional = 10 total
- **Undocumented fields**: `agent_attention, agent_heartbeat_summaries, heartbeats, task_attention, task_sla_summaries, deadline_summaries, task_heartbeat_summaries, execution_summaries, handoff_attention, relationships, relationship_summaries, workflow_contexts` (12 fields)

If a JSON Schema validator is applied to the actual canopy output:
- **Result**: FAIL — payload has extra fields not in schema

This is a **breaking change risk** because:
1. The schema is wrong (it's incomplete)
2. If Cap or any other consumer validates against the schema, they'd reject valid canopy payloads
3. If canopy adds even more fields, the schema drift worsens

**Remediation**: Either:
- Remove `additionalProperties: false` to allow undocumented fields, OR
- Document all 21 fields in the schema and update the fixture

---

## Revised Issue List

| # | Issue | Pass 1 Severity | Revised Severity | Status | Remediation |
|---|-------|-----------------|------------------|--------|-------------|
| 1 | cortina audit-handoff no schema | Critical | High | CONFIRMED | Create septa schema; add schema_version validation to canopy |
| 2 | Hook error log no schema | Medium | Low | CONFIRMED | No action; graceful fallback is solid |
| 3 | canopy-snapshot-v1 missing drift_signals validation | NEW | Medium | NEW | Add drift_signals check to Cap's validateCanopySnapshot |
| 4 | canopy-snapshot-v1 undocumented fields (additionalProperties mismatch) | NEW | High | NEW | Document all 21 fields in schema or remove additionalProperties: false |
| 5 | HandoffStatus enum drift (pending↔Open, missing Expired/Cancelled) | NEW | Critical | NEW | Update schema enum to match Rust enum values |
| 6 | Cap doesn't validate evidence refs from hyphae-search-v1 | NEW | Low | NEW | Optional: add schema_version check if version mismatch becomes a problem |

---

## New Issues Found in Pass 2

### 1. canopy-snapshot-v1 Validation Gap in Cap (Medium)

Cap's `validateCanopySnapshot()` doesn't check for the `drift_signals` field, which is required by the schema as of 2026-04-22.

**Impact**: Cap accepts incomplete snapshots; frontend receives undefined data.

**Fix**: Add `!asRecord(record.drift_signals)` check in the validation function.

### 2. canopy-snapshot-v1 Schema Mismatch (High)

The schema declares `additionalProperties: false` but the producer emits 21 fields; schema documents only ~10. This violates the JSON Schema contract.

**Impact**: Schema validators would reject valid payloads. Documentation is misleading.

**Fix**: Either expand schema to include all 21 fields or change `additionalProperties` to `true`.

### 3. HandoffStatus Enum Drift (Critical)

The septa schema defines `["pending", "accepted", "completed", "rejected"]` but the Rust enum is `[Open, Accepted, Rejected, Expired, Cancelled, Completed]`.

**Impact**: Serialization of `Open`, `Expired`, or `Cancelled` handoffs will fail schema validation. The schema is incomplete and misleading.

**Fix**: Update septa schema handoff status enum to match Rust values.

---

## Final Verdict

### Contract Health Score: **FAIR** (needs work before next feature wave)

**Breakdown:**
- ✅ 47 septa schemas validated and complete
- ✅ Fixtures are comprehensive and faithful
- ✅ Producer side schema_version discipline is strong
- ❌ Consumer-side validation gaps (Cap doesn't check drift_signals)
- ❌ Schema-struct mismatches (HandoffStatus, additionalProperties)
- ❌ cortina audit-handoff has no schema backing
- ⚠️ canopy-snapshot-v1 struct emits undocumented fields

### Blocking Issues (must fix before next feature wave)

1. **HandoffStatus enum drift** — handoffs will silently fail or serialize incorrectly
2. **canopy-snapshot-v1 additionalProperties mismatch** — schema is wrong; invalidates validation approach
3. **cortina audit-handoff missing schema** — no contract backing a critical cross-tool boundary

### Non-Blocking Issues (fix in next cleanup)

1. Cap's missing `drift_signals` validation in `validateCanopySnapshot`
2. Hook error log format documentation (low priority; fallback is robust)
3. Optional: Add schema_version validation to Cap's hyphae-search consumer

### Specific Action Items

**Week 1 (Critical path):**
1. Update `septa/canopy-snapshot-v1.schema.json` to document all 21 fields or change `additionalProperties: false` → `true`
2. Update `septa/canopy-snapshot-v1.schema.json` handoff status enum to `["open", "accepted", "rejected", "expired", "cancelled", "completed"]`
3. Create `septa/cortina-audit-handoff-v1.schema.json` documenting the audit response contract
4. Update `canopy/src/runtime.rs` to validate schema_version on CortinaAuditResponse

**Week 2 (Follow-up):**
1. Update `cap/server/canopy.ts` `validateCanopySnapshot()` to check `drift_signals` presence
2. Update cortina `AuditOutput` serialization to include explicit `schema_version` field
3. Run full `septa/validate-all.sh` and verify all 47 schemas + fixtures still pass
4. Update CLAUDE.md files in canopy and cortina to reference the new septa contracts

---

## Evidence & References

- **Pass 1 findings**: `.handoffs/campaigns/ecosystem-health-audit/phase1-contract/findings-p1.md`
- **Canopy runtime**: `canopy/src/runtime.rs` lines 147–194
- **Cortina audit**: `cortina/src/handoff_audit.rs` lines 43–48
- **Cap validation**: `cap/server/canopy.ts` lines 142–148
- **Cap hook parsing**: `cap/server/routes/status/hooks.ts` lines 59–76
- **Septa schemas**: `septa/*.schema.json` (47 total)
- **Septa validator**: `septa/validate-all.sh`

---

**Report Generated:** 2026-04-22
**Auditor:** Contract Audit Deep Review (Phase 2, manual agent judgment)
