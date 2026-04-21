# Integration Script $ref Resolution

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `basidiocarp` workspace root
- **Allowed write scope:** `scripts/...`
- **Cross-repo edits:** none
- **Non-goals:** fixing the actual $ref structure inside individual schemas (they are correct — `septa/validate-all.sh` passes them), renaming schemas, or changing contract semantics
- **Verification contract:** `bash .handoffs/cross-project/verify-integration-script-ref-resolution.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive

## Implementation Seam

- **Likely repo:** workspace root
- **Likely files:** `scripts/test-integration.sh` (lines ~100-130, the generic `check-jsonschema` validation loop)
- **Reference seams:** `septa/validate-all.sh` already solves this problem correctly using a Python `referencing` registry that resolves cross-file `$ref` pointers
- **Spawn gate:** parent must have re-run `bash scripts/test-integration.sh` and confirmed that the 6 remaining failures all stem from schemas with `$ref` to other septa schemas (not from genuine fixture errors)

## Problem

After the `orchestration-reset` campaign and the `terminal-transition-correctness` PR, `scripts/test-integration.sh` reports 61 pass / 6 fail. All 6 failures come from the generic `check-jsonschema` loop (approximately lines 100-130 of the script), which calls `check-jsonschema --schemafile "$schema" "$fixture"` without any cross-file `$ref` registry. Schemas that reference other septa schemas via `$ref` (e.g., `canopy-task-detail-v1` referencing other canopy contracts) fail validation inside the integration script but pass `septa/validate-all.sh`, because the authoritative validator builds a proper referencing registry first.

Failing schemas:
- `canopy-snapshot-v1`
- `canopy-task-detail-v1`
- `cortina-lifecycle-event-v1`
- `handoff-context-v1`
- `tool-usage-event-v1`
- `usage-event-v1`

All 6 pass `septa/validate-all.sh` — the schemas are correct; the harness is wrong.

## What exists (state)

- `scripts/test-integration.sh` line ~100-132: a generic loop that iterates every septa schema and tries `check-jsonschema --schemafile` standalone. Fails silently on cross-ref schemas.
- `septa/validate-all.sh`: a Python wrapper using `jsonschema` + `referencing` that builds a registry of all schemas so `$ref` pointers resolve locally. Passes all 36 schema-fixture pairs.

## What needs doing (intent)

Replace the broken generic loop with a delegation to `septa/validate-all.sh` (authoritative), and retain the earlier hand-written jq-based sanity checks that verify specific required fields on specific contracts (those checks catch a different class of bug — fixture drift — and remain valuable).

## Scope

- **Primary seam:** `scripts/test-integration.sh` lines ~100-132
- **Allowed files:** `scripts/test-integration.sh` only
- **Explicit non-goals:**
  - Do not modify `septa/validate-all.sh`
  - Do not modify any schema or fixture
  - Do not add new validation patterns — just fix the existing broken loop

---

### Step 1: Replace the generic `check-jsonschema` loop with a `validate-all.sh` delegation

**Project:** workspace root
**Effort:** 0.5 day
**Depends on:** nothing

In `scripts/test-integration.sh`, locate the `if has_cmd check-jsonschema; then ... fi` block (approximately lines 101-132). Replace the body with:

```bash
if [ -x septa/validate-all.sh ]; then
  if bash septa/validate-all.sh >/dev/null 2>&1; then
    pass "all septa schemas validate (via validate-all.sh)"
  else
    fail "septa/validate-all.sh failed — run it directly to see details"
  fi
else
  skip "septa/validate-all.sh not executable"
fi
```

Remove the existing `for schema in septa/*.schema.json` loop entirely. The per-schema granularity was never useful because all the failures were harness bugs; developers wanting per-schema detail should run `validate-all.sh` directly.

Keep the hand-written jq checks higher up in the script (the ones that verify `schema_version`, `type`, and required fields on individual fixtures). Those catch a different class of bug and are cheap to maintain.

### Step 2: Re-run and confirm

**Project:** workspace root
**Effort:** 0.1 day
**Depends on:** Step 1

```bash
bash scripts/test-integration.sh
```

Expected: `Passed: N, Failed: 0` — all 6 `$ref`-related failures resolved. The exact pass count will drop by some because the generic loop previously counted each per-schema success individually; now it collapses into one "all schemas validate" result. That's fine — the integration script's job is go/no-go, not reporting detail.

---

## Verification Contract

```bash
bash scripts/test-integration.sh
bash .handoffs/cross-project/verify-integration-script-ref-resolution.sh
```

Expected: zero failures in both.

## Completion criteria

- [ ] Generic `check-jsonschema` loop replaced with `validate-all.sh` delegation
- [ ] Integration script reports zero failures (or only unrelated pre-existing ones — document them if any remain)
- [ ] HANDOFFS.md updated, handoff archived
