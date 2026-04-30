# Schema Accuracy Audit Template

Validates the producer/consumer/schema triangle for septa contracts. Run as **two passes**: consumer-side and producer-side. They share methodology and findings shape.

**Cadence:** quarterly, or after any septa schema change touching ≥3 schemas.
**Maps to:** F1 exit criterion #2 ("validate-all.sh stays green AND producers/consumers haven't drifted from it").
**Runtime:** ~2–4 hours per pass for the full schema set.

---

## Two Passes

| Pass | Direction | What it catches |
|------|-----------|------------------|
| Consumer-side | schema → consumer code | Consumers too strict (reject valid payloads), too lax (accept invalid), or missing the consumer entirely (orphan schemas). |
| Producer-side | producer code → schema | Producers that emit fields the schema doesn't declare, omit required fields, or use mismatched const/enum values. |

Run consumer-side first; producer-side mirrors its findings file structure with the producer/consumer columns swapped.

---

## Handoff Metadata (instance)

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only)
- **Allowed write scope:** `.handoffs/campaigns/<campaign-name>/findings/lane<N>-<consumer|producer>-schema-accuracy.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not fix drift, does not modify schemas, does not regenerate fixtures
- **Verification contract:** `bash .handoffs/campaigns/<campaign-name>/verify-lane<N>-<consumer|producer>-schema-accuracy.sh`

## Audit Method

For each active septa schema (skip those in `septa/draft/`):

1. Open the schema. Capture:
   - Required field set (from `"required": [...]`)
   - Type per property (string, number, integer, array, object, enum, const)
   - Cross-schema `$ref` chains
   - `additionalProperties` setting
2. Open the matching code:
   - Consumer pass: the file that parses the JSON wire payload (often a `validate*` or `is<Schema>Output` function in a TS or Rust consumer).
   - Producer pass: the file that serializes the JSON wire payload (often a `*_json` function or a `serde::Serialize` derive site).
3. Compare field-by-field. Flag drift per the severity scale below.

## High-priority schemas to audit first

The contracts cap consumes (failure here directly affects the operator console):

- `mycelium-gain-v1` — producer `mycelium/src/gain/export.rs`; consumer `cap/server/mycelium/gain.ts`
- `canopy-snapshot-v1` — producer `canopy/src/api.rs`; consumer `cap/server/canopy.ts`
- `canopy-task-detail-v1` — producer `canopy/src/api.rs`; consumer `cap/server/canopy.ts`
- `stipe-doctor-v1` — producer `stipe/src/commands/doctor.rs`; consumer `cap/server/routes/settings/shared.ts`
- `stipe-init-plan-v1` — producer `stipe/src/commands/init/plan.rs`; consumer `cap/server/routes/settings/shared.ts`
- `annulus-status-v1` — producer `annulus/src/status.rs`; consumer `cap/server/annulus.ts`
- `evidence-ref-v1` — embedded under canopy snapshot/task-detail evidence arrays

Then sweep the remainder. Use the prior audit's producer/consumer map (when one exists) as the starting point for code locations.

## Schema-to-schema `$ref` check (added 2026-04-29)

A schema with no first-party producer or consumer may still be in active use as a `$ref` target by other schemas. Before classifying any schema as orphan or marking it draft, run:

```bash
grep -rE 'host-identifier-v1\.schema\.json|<schema>-v1\.schema\.json' septa/*.schema.json
```

If the schema is `$ref`'d by an active schema, it is NOT orphan — it is a shared type definition. Document this as "kept (shared $ref target)" rather than draft or delete. (This rule was added after F2.10's near-miss on `host-identifier-v1`.)

## Findings File Format

Write `findings/lane<N>-<consumer|producer>-schema-accuracy.md`:

```markdown
# Lane N: <Consumer|Producer>-Side Schema Accuracy Findings (YYYY-MM-DD)

## Summary
[counts by severity, total schemas audited, orphans flagged]

## Baseline
[`bash septa/validate-all.sh` output — should be green at the time of audit]

## Producer/Consumer Map
[full table: schema → producer file:line → consumer file:line → status (active / orphan / shared $ref / producer-only)]

## Findings

### [F#.M] Title — severity: blocker|concern|nit
- **Schema:** path
- **Producer:** file:line  (or "Consumer:" depending on pass)
- **Consumer:** file:line
- **Drift:** [what's wrong]
- **Why it matters:** [F1 #2 link or specific runtime impact]
- **Proposed handoff:** "[handoff title]"

## Clean Areas
[contracts that came back clean]
```

## Severity Calibration

| Severity | When |
|----------|------|
| `blocker` | Required-field omission, const mismatch, or type mismatch that causes runtime parse failure or silent data loss. Also: cap consumer reading a removed field. |
| `concern` | Optional field never emitted; consumer too lax against required fields; orphan schema still has fixture; `$ref` target with no producer/consumer (verify it's a shared type before classifying further). |
| `nit` | Description drift; mismatched producer-path comment in schema; outdated count in `septa/CLAUDE.md`. |

## Verify Script

Pair with `verify-lane<N>-<consumer|producer>-schema-accuracy.sh`. The verify script confirms:
- Findings file exists with the 5 required sections (Summary, Baseline, Producer/Consumer Map, Findings, Clean Areas)
- `septa/validate-all.sh` remains green
- Findings reference at least one schema (sanity)
- The Producer/Consumer Map table has rows

## Style Notes

- A schema with no consumer is `concern`, not `blocker` — it just means the producer is wasting work.
- A consumer reading a removed field is `blocker` — runtime failure waiting to happen.
- Don't include schema-internal `$ref` chains in the Producer/Consumer Map. Those go in their own row labeled `shared $ref target`.
- One pass = one findings file. Do not interleave consumer and producer findings.
