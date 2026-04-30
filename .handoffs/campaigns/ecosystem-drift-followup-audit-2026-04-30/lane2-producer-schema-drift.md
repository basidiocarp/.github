# Audit Lane 2: Producer-Side Schema Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only)
- **Allowed write scope:** `.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane2-producer-schema-drift.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not fix producer drift (becomes fix-phase handoffs); does not modify any schema or producer code; does not validate consumers (covered by the prior campaign's lane 2)
- **Verification contract:** `bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane2-producer-schema-drift.sh`
- **Completion update:** when findings file is written and verification is green, parent updates campaign README + dashboard.

## Problem

The prior campaign's lane 2 audited septa schemas against their **consumers** (does Cap parse what septa says?). It did not deeply audit **producers** (does the emitting code still match the schema today?). Producer drift is asymmetric — fixtures stay in sync with the schema by definition, but the emitting code can drift away from both. F1 exit criterion #2 demands the producer/consumer/schema triangle stay aligned.

## Scope

For each active septa schema with a known producer, confirm the producer code:
- Emits all fields the schema lists as required.
- Does not emit fields the schema doesn't declare.
- Uses the correct const values (`schema_version`, `schema`, `version`).
- Uses types that match the schema (string vs number, array vs object, enum membership).

Use the prior campaign's producer/consumer map (`.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-septa-contract-accuracy.md` § Producer/Consumer Map) as the starting point for the producer file list. Do not re-audit schemas in `septa/draft/` (orphaned by F2.10).

## Audit method

For each schema:

1. Open the schema, capture the required field set + types + enum members + const values.
2. Open the producer file (Rust or TS), find the serialization site.
3. Compare field-by-field. Flag:
   - Fields the schema requires but the producer omits → potential nil/null at consumer (blocker).
   - Fields the producer emits but the schema does not declare → schema is too strict OR producer has invented a field (concern).
   - `schema_version` / `schema` / `version` const mismatches (blocker).
   - Type mismatches (blocker if it would parse-fail; concern if it just stringifies oddly).
   - Enum value mismatches (blocker if a real value falls outside the enum).

## High-priority producers to audit

Start with the contracts cap consumes (because their drift directly affects the operator console):

| Schema | Producer file (per prior audit) |
|--------|---------------------------------|
| `mycelium-gain-v1` | `mycelium/src/gain/export.rs` |
| `canopy-snapshot-v1` | `canopy/src/api.rs` (snapshot endpoint) |
| `canopy-task-detail-v1` | `canopy/src/api.rs` (task detail endpoint) |
| `stipe-doctor-v1` | `stipe/src/commands/doctor.rs` |
| `stipe-init-plan-v1` | `stipe/src/commands/init/plan.rs` |
| `annulus-status-v1` | `annulus/src/status.rs` (`status_json`) |
| `evidence-ref-v1` | embedded under canopy snapshot/task-detail evidence arrays |

Then sweep the remainder (per the prior producer/consumer map):

- `cortina-lifecycle-event-v1` — `cortina/src/events/normalized_lifecycle.rs`
- `tool-usage-event-v1` — `cortina/src/hooks/stop/tool_usage_emit.rs`
- `usage-event-v1` — cortina normalization edges
- `session-event-v1` — `cortina/src/utils/session_scope.rs`
- `volva-hook-event-v1` — volva hook adapter
- `dispatch-request-v1` — `hymenium/src/dispatch/orchestrate.rs`
- `task-packet-v1` — `hymenium/src/dispatch/task_packet.rs`
- `workflow-outcome-v1` — `hymenium/src/outcome.rs`
- `command-output-v1` — `mycelium/src/hyphae.rs`
- `code-graph-v1` — rhizome export_to_hyphae
- `capability-registry-v1` / `capability-runtime-lease-v1` — stipe registry
- `canopy-notification-v1` — `canopy/src/store/notifications.rs` (now correct after F2.11)
- `hyphae-*-v1` schemas — hyphae cli commands

Producer-only schemas (no first-party consumer): note the producer-only status; flag if the producer is itself broken.

## Findings file format

Write `findings/lane2-producer-schema-drift.md`:

- **Summary** — counts by severity.
- **Per-Schema Results** — one section per schema with: required fields, producer file:line, observed emission shape, drift findings.
- **Findings** — `[F2.N]` per drift, with severity, location, evidence, F1 link, proposed handoff.
- **Clean Areas** — schemas where producer matches schema cleanly.

## Style Notes

- A producer that cannot be located is `concern` — note it. Don't chase it for hours; the prior consumer-side map should suffice.
- Don't downgrade const-mismatch findings — they're always blockers (consumers will reject the payload).
- Don't escalate "schema declares optional field producer never emits" — that's just optional behavior, not drift.

## Completion Protocol

1. Each high-priority schema audited.
2. Findings file written with the 4 sections above.
3. Verify script exits 0.

```bash
bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane2-producer-schema-drift.sh
```

**Required result:** `Results: N passed, 0 failed`.
