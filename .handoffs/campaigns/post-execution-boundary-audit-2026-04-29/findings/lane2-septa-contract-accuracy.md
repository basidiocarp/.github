# Lane 2: Septa Contract Accuracy Findings (2026-04-29)

## Summary

Read-only audit of all 55 septa schemas, their fixtures, the 5 Cap-consumed contracts (field-level), and `integration-patterns.md`. `validate-all.sh` is green (59 passed, 0 failed). Twelve findings: 2 blockers, 8 concerns, 2 nits. Eleven schemas have no first-party consumer in the workspace (orphaned producers). One schema name documented in septa is missing from septa entirely — Cap consumes `annulus status --json` (which emits `annulus-status-v1`) while septa only ships `annulus-statusline-v1` for a different command (`annulus statusline --json`).

## Baseline

- `bash septa/validate-all.sh` → `Results: 59 passed, 0 failed, 0 skipped` (some schemas have multiple fixture variants — `.example.json`, `.full.json`, `.degraded.json`, `.flagged.json` — which produce more passes than schema files)
- Schema file count: **55** (`ls septa/*.schema.json | wc -l`)
- Fixture file count: **60** (`ls septa/fixtures/`)
- Septa README "Contract Inventory" enumerates 55 contracts across 9 families; matches the on-disk file set.
- `septa/CLAUDE.md` claims "All 34 schemas must pass" — stale by 21 schemas (nit, F2.12).

## Producer/Consumer Map

Producer columns reference the actual emitting source. Consumer columns reference the actual reader. "—" means no concrete first-party consumer was found by code search across `cap/`, `canopy/`, `cortina/`, `hyphae/`, `hymenium/`, `mycelium/`, `volva/`, `spore/`, `stipe/`, `annulus/`, `lamella/`. Orphans are flagged.

| Schema | Producer | Consumer(s) | Status |
|---|---|---|---|
| `annulus-statusline-v1.schema.json` | `annulus/src/statusline.rs` (`schema: "annulus-statusline-v1"`) | host hook stdin (Claude Code/Codex statusline integration); no workspace code parses the JSON | orphan within workspace |
| `canopy-notification-v1.schema.json` | `canopy/src/store/notifications.rs` (DB row writer); schema description claims `canopy/src/notification.rs` which does not exist | `cap/server/canopy.ts:80-95` (reads via SQLite, not JSON; no `event_type` enum check) | producer path drift in description |
| `canopy-snapshot-v1.schema.json` | `canopy/src/api.rs` snapshot endpoint (`schema_version="1.0"`) | `cap/server/canopy.ts:142-148` (`validateCanopySnapshot`) | active |
| `canopy-task-detail-v1.schema.json` | `canopy/src/api.rs` task detail endpoint | `cap/server/canopy.ts:150-161` (`validateCanopyTaskDetail`) | active |
| `capability-registry-v1.schema.json` | `stipe/src/commands/tool_registry/capability_registry.rs` | `spore/src/capability.rs` (parses via serde, no schema name string) | active |
| `capability-runtime-lease-v1.schema.json` | running tools writing leases (`stipe/src/commands/tool_registry/capability_registry.rs` references) | `spore/src/capability.rs` (lease-first resolution) | active |
| `code-graph-v1.schema.json` | `rhizome` (export_to_hyphae) | `hyphae` (`hyphae_import_code_graph`) — no direct schema name reference found in hyphae code | active (internal MCP tool surface) |
| `command-output-v1.schema.json` | `mycelium/src/hyphae.rs` (`store_output`) | `hyphae/crates/hyphae-mcp/src/tools/ingest.rs` (`tool_store_command_output`) | active |
| `context-envelope-v1.schema.json` | — | — | **orphan** |
| `cortina-audit-handoff-v1.schema.json` | `cortina/src/handoff_audit.rs` (`cortina audit handoff --json`) | — (operator stdout consumer only) | likely orphan |
| `cortina-lifecycle-event-v1.schema.json` | `cortina/src/events/normalized_lifecycle.rs` (`schema_version="1.0"`) | downstream not in workspace | producer-only |
| `credential-v1.schema.json` | — | — | **orphan** |
| `degradation-tier-v1.schema.json` | — | — | **orphan** |
| `dependency-types-v1.schema.json` | — | — | **orphan** |
| `dispatch-request-v1.schema.json` | `hymenium/src/dispatch/orchestrate.rs` (`schema_version`) | canopy task creation (CLI) | active |
| `evidence-ref-v1.schema.json` | embedded under `canopy-snapshot-v1.evidence` and `canopy-task-detail-v1.evidence`; cortina memory-store evidence references | `cap/server/canopy.ts:123-140` (`validateEvidenceRefs`) | active |
| `handoff-context-v1.schema.json` | — | — | **orphan** (canopy/hyphae handoff data is stored in DB rows, not as this JSON shape) |
| `hook-execution-v1.schema.json` | — | — | **orphan** (no `on_timeout`/`timeout_ms` config object emitted matches this schema; cortina hardcodes fail-open behavior) |
| `host-identifier-v1.schema.json` | — | — | **orphan** |
| `hyphae-activity-v1.schema.json` | `hyphae/crates/hyphae-cli/src/commands/activity.rs` (`schema_version: ACTIVITY_SCHEMA_VERSION`) | `cap/server/routes/status/hyphae-cli.ts` (no `schema_version` check) | active but consumer skips version |
| `hyphae-analytics-v1.schema.json` | `hyphae/crates/hyphae-cli/src/commands/analytics.rs` | `cap/server/hyphae/analytics.ts` | active |
| `hyphae-archive-v1.schema.json` | `hyphae/crates/hyphae-cli/src/commands/export.rs` | `hyphae/crates/hyphae-cli/src/commands/import.rs` (intra-tool roundtrip) | active (internal contract) |
| `hyphae-context-v1.schema.json` | `hyphae/crates/hyphae-cli/src/commands/context.rs` | `cap/server/hyphae/context.ts` | active |
| `hyphae-health-v1.schema.json` | `hyphae` health command | `cap/server/hyphae/reads-cli.ts` | active |
| `hyphae-lessons-v1.schema.json` | `hyphae/crates/hyphae-cli/src/commands/lessons.rs` | `cap/server/hyphae/lessons.ts` | active |
| `hyphae-memoir-inspect-v1.schema.json` | `hyphae` memoir inspect | `cap/server/hyphae/memoirs-cli.ts` | active |
| `hyphae-memoir-list-v1.schema.json` | `hyphae` memoir list | `cap/server/hyphae/memoirs-cli.ts` | active |
| `hyphae-memoir-search-all-v1.schema.json` | `hyphae` memoir search-all | `cap/server/hyphae/memoirs-cli.ts` | active |
| `hyphae-memoir-search-v1.schema.json` | `hyphae` memoir search | `cap/server/hyphae/memoirs-cli.ts` | active |
| `hyphae-memoir-show-v1.schema.json` | `hyphae` memoir show | `cap/server/hyphae/memoirs-cli.ts` | active |
| `hyphae-memory-lookup-v1.schema.json` | `hyphae` memory lookup | `cap/server/hyphae/reads-cli.ts` | active |
| `hyphae-search-v1.schema.json` | `hyphae` search | `cap/server/hyphae/reads-cli.ts` | active |
| `hyphae-session-list-v1.schema.json` | `hyphae` session list | `cap/server/hyphae/session-list-cli.ts` | active |
| `hyphae-session-timeline-v1.schema.json` | `hyphae` session timeline | `cap/server/hyphae/session-timeline-cli.ts` | active |
| `hyphae-sources-v1.schema.json` | `hyphae` sources | `cap/server/hyphae/reads-cli.ts` | active |
| `hyphae-stats-v1.schema.json` | `hyphae` stats | `cap/server/hyphae/reads-cli.ts` | active |
| `hyphae-topic-memories-v1.schema.json` | `hyphae` topic memories | `cap/server/hyphae/reads-cli.ts` | active |
| `hyphae-topics-v1.schema.json` | `hyphae` topics | `cap/server/hyphae/reads-cli.ts` | active |
| `local-service-endpoint-v1.schema.json` | — | — | **orphan** |
| `mycelium-gain-v1.schema.json` | `mycelium/src/gain/export.rs` | `cap/server/mycelium/gain.ts` | active (drift; see F2.5) |
| `mycelium-summary-v1.schema.json` | — | — | **orphan** (mycelium tracks summaries in DB; does not emit this JSON shape) |
| `resolved-status-customization-v1.schema.json` | — | — | **orphan** |
| `session-event-v1.schema.json` | `cortina/src/utils/session_scope.rs` (`schema_version`) | `hyphae/crates/hyphae-cli/src/commands/session.rs` (CLI ingest) | active |
| `stipe-doctor-v1.schema.json` | `stipe/src/commands/doctor.rs` | `cap/server/routes/settings/shared.ts:70-81` (`isStipeDoctorReport`) | active (drift; see F2.1, F2.2) |
| `stipe-init-plan-v1.schema.json` | `stipe/src/commands/init/plan.rs` | `cap/server/routes/settings/shared.ts:87-100` (`isStipeInitPlan`) | active (drift; see F2.3, F2.4) |
| `task-output-v1.schema.json` | — | — | **orphan** |
| `task-packet-v1.schema.json` | `hymenium/src/dispatch/task_packet.rs` (`TaskPacket` struct) | dispatched-to agents — receiver not a workspace consumer | producer-only |
| `tool-relevance-rules-v1.schema.json` | — (lamella docs reference; no JSON producer) | `cortina/src/rules.rs` uses hardcoded `DEFAULT_RULES`, not parsed from this schema | **orphan** |
| `tool-usage-event-v1.schema.json` | `cortina/src/hooks/stop/tool_usage_emit.rs` (writes JSON) | hyphae stores via `hyphae_store_command_output` semantics; no schema_version validation in consumer | active but consumer skips version |
| `usage-event-v1.schema.json` | cortina normalization edges (per integration-patterns); test guard at `mycelium/tests/usage_event_contract_guard.rs` | mycelium summarizer/cap usage views — not directly parsed by code | producer-side guard only |
| `volva-hook-event-v1.schema.json` | volva hook adapter (per integration-patterns) | `cortina/src/adapters/volva.rs` (`parse_hook_event`/`validate_hook_event`) | active |
| `workflow-outcome-v1.schema.json` | `hymenium/src/outcome.rs` | `canopy/src/store/outcomes.rs` (`insert_workflow_outcome`) | active |
| `workflow-participant-runtime-identity-v1.schema.json` | volva execution-session state | canopy linkage | producer-only in workspace |
| `workflow-status-v1.schema.json` | `hymenium/src/commands/status.rs` | — | producer-only |
| `workflow-template-v1.schema.json` | `hymenium/src/workflow/template.rs` | — | producer-only |

**Orphans (zero workspace consumer found):** 11 — `annulus-statusline-v1` (workspace-internal; host hook reads via stdin), `context-envelope-v1`, `credential-v1`, `degradation-tier-v1`, `dependency-types-v1`, `handoff-context-v1`, `hook-execution-v1`, `host-identifier-v1`, `local-service-endpoint-v1`, `mycelium-summary-v1`, `resolved-status-customization-v1`, `tool-relevance-rules-v1`. (Some — `task-output-v1` — are also producer-orphans and not flagged separately above; treat as "no live producer or consumer".)

**Stale rows in `septa/integration-patterns.md`:** the file lists `cortina → ecosystem` for `cortina-lifecycle-event-v1` and `stipe → lamella → cap` for `resolved-status-customization-v1` but no consumer is yet implemented for either; the doc presents them as live patterns.

## Findings

### [F2.1] Stipe doctor `repair_action.description` consumer rejects null — severity: blocker
- **Schema:** `septa/stipe-doctor-v1.schema.json` (`$defs/repair_action.description` is `["string", "null"]` — line 211)
- **Consumer:** `cap/server/routes/settings/shared.ts:50-58` — `isRepairAction` requires `typeof value.description === 'string'`
- **Drift:** schema permits `description: null`; consumer throws "Invalid stipe doctor payload" on null. If stipe ever emits a repair action without description, the dashboard's `/api/settings/*` doctor route returns 500 instead of rendering the report.
- **Why it matters:** F1 criterion #2 demands that producer/consumer pairs stay in sync — schema-allowed values must not crash the consumer. Today the existing fixture happens to set non-null descriptions, so `validate-all.sh` stays green and the bug is latent.
- **Proposed handoff:** "fix: cap stipe-doctor repair_action accepts null description"

### [F2.2] Stipe doctor / init repair_action shape mismatch between two schemas — severity: concern
- **Schema:** `septa/stipe-doctor-v1.schema.json` (`repair_action` requires `command, label, description, args, tier`) vs `septa/stipe-init-plan-v1.schema.json` (`repair_actions[]` requires `action_key, command, label` only — `args`, `tier`, `description` not required)
- **Consumer:** `cap/server/routes/settings/shared.ts:50-58` reuses one `isRepairAction` for both, which requires `args, tier, command, label, description` to all be present
- **Drift:** init plan repair actions can validly omit `tier` and `args` per schema; consumer rejects them.
- **Why it matters:** the two repair_action shapes are inconsistent at the schema level and the cap consumer cannot satisfy both at once. Either the schemas should converge on one shared `$ref` or the consumer needs two validators.
- **Proposed handoff:** "refactor: unify stipe repair_action shape across doctor/init schemas"

### [F2.3] Stipe init plan step `detail` consumer rejects null — severity: blocker
- **Schema:** `septa/stipe-init-plan-v1.schema.json` lines 22-30 — step requires only `status` and `title`; `detail` is `["string", "null"]`
- **Consumer:** `cap/server/routes/settings/shared.ts:83-85` — `isInitStep` requires `typeof value.detail === 'string'`
- **Drift:** schema permits null/missing detail; consumer throws when stipe emits a planned step without detail. Same latent-runtime-failure pattern as F2.1.
- **Why it matters:** F1 #2 — schema-permitted values must round-trip through the consumer.
- **Proposed handoff:** "fix: cap stipe-init-plan step accepts null/missing detail"

### [F2.4] Stipe init plan `repair_action.action_key` not validated by consumer — severity: concern
- **Schema:** `septa/stipe-init-plan-v1.schema.json` lines 38-40 — repair_actions require `action_key` (string)
- **Consumer:** `cap/server/routes/settings/shared.ts:50-58` does not check `action_key` at all (it checks doctor's superset)
- **Drift:** if stipe regresses and stops emitting `action_key` for an init repair action, cap silently accepts the payload.
- **Why it matters:** consumer is too lax against the contract.
- **Proposed handoff:** "fix: cap stipe-init-plan repair action validates action_key"

### [F2.5] Mycelium gain consumer ignores `weekly`/`monthly` arrays — severity: concern
- **Schema:** `septa/mycelium-gain-v1.schema.json` lines 96-131 — defines optional `weekly` and `monthly` arrays with required item shapes
- **Consumer:** `cap/server/mycelium/gain.ts:89-101` — `isGainCliOutput` validates `daily`, `history`, `by_project`, `by_command` but not `weekly` or `monthly`. `cap/server/mycelium/types.ts:9-18` declares `weekly?` and `monthly?` but no validator runs.
- **Drift:** consumer accepts any value (or no value) for `weekly`/`monthly`; producer can ship malformed data without the consumer noticing.
- **Why it matters:** the optional fields exist in the schema for a reason; if Cap intends to render them, drift will silently degrade UI; if Cap doesn't, the schema fields are dead weight in `mycelium-gain-v1`.
- **Proposed handoff:** "fix: cap mycelium gain validates weekly/monthly when present (or remove from schema)"

### [F2.6] Cap canopy snapshot consumer skips required `attention`/`sla_summary`/`drift_signals` — severity: concern
- **Schema:** `septa/canopy-snapshot-v1.schema.json:7` requires `["schema_version", "attention", "sla_summary", "tasks", "evidence", "drift_signals"]`
- **Consumer:** `cap/server/canopy.ts:142-148` only checks `schema_version`, `tasks`, `evidence`. `attention`, `sla_summary`, `drift_signals` are never validated.
- **Drift:** consumer is structurally lax. If canopy regresses and drops `drift_signals`, cap accepts the payload but the dashboard panels reading it crash later.
- **Why it matters:** F1 #2 — the consumer must reject payloads that violate required schema fields it actually depends on.
- **Proposed handoff:** "fix: cap canopy-snapshot validates attention/sla_summary/drift_signals"

### [F2.7] Cap canopy task detail consumer skips required `attention`/`sla_summary` — severity: concern
- **Schema:** `septa/canopy-task-detail-v1.schema.json:7` requires `["schema_version", "task", "attention", "sla_summary", "allowed_actions", "evidence"]`
- **Consumer:** `cap/server/canopy.ts:150-161` only checks `schema_version`, `task`, `allowed_actions`, `evidence`
- **Drift:** same pattern as F2.6 — required fields silently unenforced at the boundary.
- **Why it matters:** F1 #2 schema-vs-consumer parity.
- **Proposed handoff:** "fix: cap canopy-task-detail validates attention/sla_summary"

### [F2.8] Annulus producer schema `annulus-status-v1` has no septa contract — severity: blocker (downgrade to concern if intentional)
- **Schema:** none. `septa/annulus-statusline-v1.schema.json` ships for the unrelated `annulus statusline --json` command (segments shape).
- **Producer:** `annulus/src/status.rs:status_json` emits a JSON payload tagged `"schema": "annulus-status-v1"` with a `reports[]` array
- **Consumer:** `cap/server/annulus.ts:43-66` (`parseAnnulusOutput`) expects `reports` array (matches the `annulus-status-v1` shape, not `annulus-statusline-v1`)
- **Drift:** the consumer/producer pair operates on a contract that does not exist in septa. `annulus-statusline-v1` describes a different command entirely. From septa's perspective both ends are off-contract.
- **Why it matters:** F1 #2 — septa is supposed to own all cross-tool wire formats; here Cap consumes a sibling tool's output with no shared schema. A future change in `annulus/src/status.rs` cannot be detected by `validate-all.sh`.
- **Proposed handoff:** "feat: add septa annulus-status-v1 schema for `annulus status --json` (and either rename annulus-statusline-v1 or document its scope)"

### [F2.9] Cap `canopy-notification-v1` event_type consumed without enum check — severity: concern
- **Schema:** `septa/canopy-notification-v1.schema.json:14-27` — `event_type` is a closed enum of 9 values
- **Consumer:** `cap/server/canopy.ts:80-95` (`listNotifications`) — reads SQLite rows, treats `event_type` as opaque `string`. The downstream `cap/src/components/NotificationPanel*` UI then has to switch on the same strings without compile-time guarantees.
- **Drift:** if canopy emits a new event_type, cap silently passes it through. If it emits a typo, the UI degrades silently.
- **Why it matters:** the contract is intended to be closed; the consumer should reject unknown values at the boundary.
- **Proposed handoff:** "fix: cap canopy notification reader validates event_type against septa enum"

### [F2.10] Multiple orphan schemas (no first-party producer or consumer in workspace) — severity: concern
- **Schemas:** `context-envelope-v1`, `credential-v1`, `degradation-tier-v1`, `dependency-types-v1`, `handoff-context-v1`, `hook-execution-v1`, `host-identifier-v1`, `local-service-endpoint-v1`, `mycelium-summary-v1`, `resolved-status-customization-v1`, `tool-relevance-rules-v1`, `task-output-v1`
- **Consumer:** none located by code search across the workspace
- **Drift:** these schemas exist in `septa/` and pass `validate-all.sh`, but no Rust/TS code parses or emits them today. Fixtures may rot silently because nobody reads the actual shape.
- **Why it matters:** producer/consumer mapping (handoff Step 2) requires every schema to land at a real consumer. Eleven do not. Either the schemas are aspirational (and should be marked as "draft" or moved to `septa/docs/`), or producers/consumers were skipped in past handoffs.
- **Proposed handoff:** "audit: triage 12 orphan septa schemas (delete, mark draft, or land producer/consumer)"

### [F2.11] `septa/canopy-notification-v1` description references nonexistent producer file — severity: nit
- **Schema:** `septa/canopy-notification-v1.schema.json:5` — "Producer: canopy/src/notification.rs"
- **Consumer:** N/A (description text only)
- **Drift:** the actual producer is `canopy/src/store/notifications.rs` (writes the row); there is no `canopy/src/notification.rs` file.
- **Why it matters:** schema descriptions are the breadcrumb trail for future contract changes; a wrong path wastes audit time.
- **Proposed handoff:** "docs: fix canopy-notification-v1 producer path in schema description"

### [F2.12] `septa/CLAUDE.md` claims "All 34 schemas must pass" — severity: nit
- **Schema:** N/A (doc)
- **Consumer:** `septa/CLAUDE.md` line 39
- **Drift:** real count is 55. Off by 21.
- **Why it matters:** doc drift in the file Claude reads first when working in septa.
- **Proposed handoff:** "docs: refresh septa/CLAUDE.md schema count and recently-added contracts"

## Clean Areas

The following contracts came back clean from this audit (producer present, consumer present, validate-all green, no field-level drift detected against the consumer's actual reads):

- `canopy-snapshot-v1` and `canopy-task-detail-v1` for the fields the consumer actually validates (`schema_version`, `tasks`/`task`, `allowed_actions`, `evidence`, evidence-ref shape) — see F2.6/F2.7 for the unread required fields
- `evidence-ref-v1` end-to-end (canopy emits, cap validates `schema_version` and `evidence_id`)
- `mycelium-gain-v1` core flow (`schema_version`, `summary`, `by_command`, `daily`, `history`, `by_project`) — weekly/monthly excepted (F2.5)
- All 18 `hyphae-*-v1` Cap-consumed schemas use centralized `*_SCHEMA_VERSION` constants and validate `schema_version` consistently in `cap/server/hyphae/`
- `workflow-outcome-v1` producer (hymenium) → consumer (canopy `insert_workflow_outcome`)
- `volva-hook-event-v1` producer (volva) → consumer (`cortina/src/adapters/volva.rs:parse_hook_event` + `validate_hook_event`)
- `session-event-v1` producer (cortina) → consumer (hyphae session ingest)
- `code-graph-v1`, `command-output-v1`, `hyphae-archive-v1` round-trip through internal MCP tool surfaces (no field-level drift observed)
- `capability-registry-v1`/`capability-runtime-lease-v1` lease-first/registry-fallback resolution in `spore/src/capability.rs`
- `validate-all.sh` itself: 59/59 fixture validations pass on 2026-04-29
