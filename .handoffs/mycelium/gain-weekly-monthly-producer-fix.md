# Mycelium: Gain Weekly/Monthly Producer Fix (F2.13)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/tracking/mod.rs`, plus any test files in `mycelium/tests/` or `mycelium/src/tracking/` that depend on the changed structs
- **Cross-repo edits:** none — `septa/mycelium-gain-v1.schema.json` is the source of truth and stays unchanged
- **Non-goals:** does not modify the schema; does not change the cap consumer (already updated by F2.5/C2); does not touch daily/history/by_project/by_command emission paths
- **Verification contract:** `bash .handoffs/mycelium/verify-gain-weekly-monthly-producer-fix.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem

Lane 2 of the 2026-04-30 audit (F2.13) found that `mycelium gain --json` emits `weekly[]` and `monthly[]` items with the wrong fields:

- Producer at `mycelium/src/tracking/mod.rs:195,220` emits `week_start`, `week_end`, and `month` — but the schema (`septa/mycelium-gain-v1.schema.json`) requires `date`.
- Producer also emits extra fields the schema's `additionalProperties: false` forbids.

This was latent until 2026-04-29 because Cap's consumer ignored both arrays. After C2 (F2.5 fix, committed 2026-04-29) the consumer now validates them via reused `isGainDailyStats` — which requires `date`. **The next time mycelium emits a payload with weekly or monthly populated, Cap will throw `'Mycelium gain returned an invalid payload'` and the analytics route fails.**

This is a Tier A regression-risk fix.

## Scope

- **Allowed files:**
  - `mycelium/src/tracking/mod.rs` — `WeekStats` and `MonthStats` structs and their serialization
  - any tests that build instances of those structs
- **Explicit non-goals:**
  - schema changes (the schema is correct)
  - cap consumer changes
  - other gain fields

## Step 1 — Inspect the schema's expected shape

```bash
jq '.properties.weekly.items, .properties.monthly.items' septa/mycelium-gain-v1.schema.json
```

Both items are expected to match the same item shape as `daily[]`: required `date`, plus the metric fields. Confirm the exact required set before editing.

## Step 2 — Align the structs

In `mycelium/src/tracking/mod.rs`, modify `WeekStats` and `MonthStats` so they:

- Serialize to JSON with field name `date` (not `week_start`/`week_end`/`month`).
- Drop fields not in the schema item shape, or `#[serde(skip_serializing)]` them.
- Match the schema's required keys exactly: `date`, `commands`, `saved_tokens`, `input_tokens`, `output_tokens`, `avg_time_ms`, `total_time_ms`, `savings_pct` (verify against schema in step 1).

The simplest implementation: pick one canonical date (e.g. ISO-8601 week-start for `WeekStats`, ISO-8601 month-start for `MonthStats`), serialize as `date`, and drop `week_start`/`week_end`/`month`. If the producer needs to retain the range internally, keep those fields private and skip serialization.

## Step 3 — Tests

Add or update a test that:
- Builds a `WeekStats`/`MonthStats` instance, serializes via `serde_json::to_string`, and asserts the JSON has key `date` (not `week_start` etc.).
- Asserts no extra fields beyond the schema's permitted set.

Run any existing tests in `mycelium/tests/` (especially `usage_event_contract_guard.rs` and any gain-related tests) and confirm they still pass.

## Step 4 — Verify against the schema

```bash
# Serialize a real WeekStats / MonthStats and validate against the schema.
# If mycelium has a test fixture path, use it; otherwise inline JSON in a test.
cd /Users/williamnewton/projects/personal/basidiocarp/mycelium && cargo test --lib tracking
cd /Users/williamnewton/projects/personal/basidiocarp/septa && bash validate-all.sh
```

## Style Notes

- Single canonical `date` per item — do not retain both `week_start` and `date`.
- Keep the public Rust struct names; only change the serialized field names if the schema demands it.
- Don't introduce new schema fields; if the producer was tracking something the schema doesn't, that's a follow-up handoff to extend the schema.

## Verify Script

`bash .handoffs/mycelium/verify-gain-weekly-monthly-producer-fix.sh` confirms:
- `WeekStats`/`MonthStats` no longer reference `week_start`/`week_end`/`month` as serialized field names
- The structs reference `date` as a serialized field
- `cargo test` passes for the tracking module
- `septa/validate-all.sh` still green

## Context

Closes lane 2 blocker F2.13 from the 2026-04-30 ecosystem drift follow-up audit. Production-blocking — must land before mycelium's next weekly/monthly emission would otherwise crash cap analytics.

Pairs (loosely) with the original C2/F2.5 cap consumer fix (committed 2026-04-29 as `dd310c8`).
