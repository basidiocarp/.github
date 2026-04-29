# Lane 2: Orphan Schema Triage Decisions (2026-04-29)

## Summary

Triage of 12 orphan schemas (no first-party workspace producer or consumer found by lane 2's code search):
- **Marked draft**: 9 schemas tied to F1 freeze deferred work (volva, lamella, endpoint migration, context assembly)
- **Deleted**: 2 schemas identified as dead (mycelium-summary-v1 stores in DB not JSON; task-output-v1 unused)
- **Kept**: 1 schema corrected after applying triage — `host-identifier-v1` is `$ref`'d from 3 active schemas (`cortina-lifecycle-event-v1`, `tool-usage-event-v1`, `usage-event-v1`). It is a shared type definition, not a standalone payload. The original "delete" disposition broke `validate-all.sh` and was corrected to "keep" (no separate producer/consumer needed).

All deletions remove both the schema and matching fixtures. All drafts move to `septa/draft/` with fixtures deleted (draft schemas deferred indefinitely; fixtures not required). Integration-patterns.md updated to add a "Drafts (deferred)" section documenting the deferred schemas.

**Lesson**: orphan classification by lane 2 was based on producer/consumer code search; it did not account for `$ref` usage between schemas. Future audits should grep schemas for `$ref` to other schemas as a separate signal.

---

## Per-Schema Decisions

### context-envelope-v1 — disposition: draft

- **Description:** Versioned envelope for assembled context payloads passed between ecosystem tools. Producers: hyphae, rhizome, cortina, canopy. Consumer: model context assembly, cap operator view.
- **Original intent:** Support centralized context assembly and envelope-level token budgeting for multi-component context.
- **Investigation:** No code references found across workspace. Schema describes an aspirational context assembly flow. Mentioned in integration-patterns.md only; no actual producer or consumer emits/parses this JSON shape.
- **Decision rationale:** Schema is intentional design tied to context assembly work deferred under F1 freeze (volva, context consolidation blocked pending core loop stability). Keeping as draft preserves the design for post-freeze implementation.
- **Action taken:** Moved to `septa/draft/context-envelope-v1.schema.json`; fixtures deleted. Removed integration-patterns.md entry (none existed).

### credential-v1 — disposition: draft

- **Description:** Versioned envelope for credential metadata and references. Tracks credential identity, type, provider, source location, and lifecycle state.
- **Original intent:** Provide portable credential schema for stipe, cortina, and operator-initiated credential flows.
- **Investigation:** No code references found. Schema defines credential lifecycle and storage metadata. Credential system is a volva-adjacent feature explicitly deferred in F1 freeze roadmap.
- **Decision rationale:** Schema is aspirational design for credential management (volva, auth, deployment tooling). Deferred pending F1 criteria met. Mark draft.
- **Action taken:** Moved to `septa/draft/credential-v1.schema.json`; fixtures deleted.

### degradation-tier-v1 — disposition: draft

- **Description:** Runtime degradation status for an ecosystem tool. Describes tool availability, tier classification, and affected capabilities.
- **Original intent:** Support ecosystem health reporting and tooling-dependency fallback semantics.
- **Investigation:** No code references found. Schema describes degradation reporting for cortina, volva, canopy, and operator dashboards.
- **Decision rationale:** Degradation tracking is operational observability work tied to volva and advanced dashboard features, frozen in F1. Keep as draft.
- **Action taken:** Moved to `septa/draft/degradation-tier-v1.schema.json`; fixtures deleted.

### dependency-types-v1 — disposition: draft

- **Description:** Typed dependency edge between entities across ecosystem tools. Tracks blocking, relating, discovery, superseding, and duplication relationships between tasks, memories, memoirs, workflow steps, and handoffs.
- **Original intent:** Model task and workflow dependency graphs in canopy, hymenium, and memory systems.
- **Investigation:** No code references found. Schema is aspirational for cross-tool dependency modeling in canopy/hymenium.
- **Decision rationale:** Schema represents canopy/hymenium workflow primitives deferred under F1 freeze ("No new orchestration primitives"). Mark draft.
- **Action taken:** Moved to `septa/draft/dependency-types-v1.schema.json`; fixtures deleted.

### handoff-context-v1 — disposition: draft

- **Description:** Handoff context structure for task handoff flows between canopy and hyphae.
- **Original intent:** Support portable context assembly when agents hand off between layers.
- **Investigation:** Referenced in integration-patterns.md under "canopy → hyphae (Task Handoffs)" but actual flow uses hyphae CLI queries (session context, memory recall) not this JSON shape. No producer found.
- **Decision rationale:** Schema is aspirational for handoff payloads. Actual handoffs use hyphae query CLI. Tied to canopy/cortina context assembly work deferred in F1. Mark draft.
- **Action taken:** Moved to `septa/draft/handoff-context-v1.schema.json`; fixtures deleted.

### hook-execution-v1 — disposition: draft

- **Description:** Execution semantics contract for all hook runners. Codifies fail-open invariant: hooks must never block host commands on timeout, non-zero exit, or crash.
- **Original intent:** Standardize hook timeout, error handling, and fail-open semantics across cortina, volva, stipe.
- **Investigation:** No code references found. Schema describes hook configuration contract. No JSON producer found; cortina hardcodes fail-open behavior. Lamella hook templates frozen in F1.
- **Decision rationale:** Schema represents hook execution design aspirational for lamella hook templates and advanced hook configuration. Deferred under F1 ("No new hook adapters"). Mark draft.
- **Action taken:** Moved to `septa/draft/hook-execution-v1.schema.json`; fixtures deleted.

### host-identifier-v1 — disposition: keep (corrected)

- **Description:** Canonical host identifier enum for AI coding agent hosts (claude_code, codex, cursor, volva, unknown).
- **Original intent:** Provide shared host name vocabulary for workflow, usage events, and lifecycle reporting.
- **Investigation:** Schema is a simple enum. Used as a `$ref` target by three active schemas: `cortina-lifecycle-event-v1`, `tool-usage-event-v1`, `usage-event-v1`. Lane 2's grep saw the schema name in those files and classified it "no separate producer/consumer JSON" but missed that the validator resolves `$ref` at fixture-validation time.
- **Decision rationale:** ORIGINAL: delete (no standalone payload). CORRECTED after applying: deleting it broke `validate-all.sh` because the `$ref` resolutions failed. The correct disposition is "keep" — host-identifier-v1 is a shared type definition that is actively used. No producer/consumer change needed; fixture is retained because the validator needs it for the standalone schema validation pass.
- **Action taken:** Deletion attempted, then immediately reverted (`git restore --staged` + `git restore`). Schema and fixture remain in place. `validate-all.sh` returns to green.

### local-service-endpoint-v1 — disposition: draft

- **Description:** Typed endpoint descriptor for local service communication (unix-socket, tcp, http). Advertises endpoints for system-to-system calls without circular dependencies.
- **Original intent:** Support C7/C8 migration from CLI coupling to typed local service endpoints.
- **Investigation:** No code references found. Schema is part of C7/C8 ("capability endpoint handoff") infrastructure for endpoint registry and late-binding discovery. C7/C8 defined typed endpoint contracts; implementation deferred under F1 freeze ("Volva auth, native API backend, and workspace-session route model").
- **Decision rationale:** Schema is intentional design for endpoint migration work. Deferred under F1. Mark draft.
- **Action taken:** Moved to `septa/draft/local-service-endpoint-v1.schema.json`; fixtures deleted.

### mycelium-summary-v1 — disposition: delete

- **Description:** Per-invocation command-output summary payload emitted by Mycelium after compressing a command's output.
- **Original intent:** Support mycelium summarizer → hyphae storage and cap summary surfaces flow.
- **Investigation:** Lane 2 notes mycelium tracks summaries in DB; does not emit this JSON shape. No producer found in mycelium. Schema describes a data flow that was designed but never implemented — summaries stored as DB rows, not JSON payloads.
- **Decision rationale:** Dead schema. Mycelium summary storage happens in DB, not as this JSON format. No producer or path to land one. Delete.
- **Action taken:** Deleted `septa/mycelium-summary-v1.schema.json`; deleted matching fixtures.

### resolved-status-customization-v1 — disposition: draft

- **Description:** Host-neutral status and customization bundle. Segments, theme, and per-host overrides. Stipe injects into Claude Code, Codex, Cursor; cap previews; lamella packages presets.
- **Original intent:** Portable status and customization for statusline configuration and preset management.
- **Investigation:** Referenced in integration-patterns.md as "stipe → lamella → cap" pattern. Lane 2 lists in integration-patterns but marks it as aspirational (no real producer/consumer found). Lamella skill pack and customization features frozen in F1 ("No new skill packs or plugin categories").
- **Decision rationale:** Schema represents stipe→lamella→cap customization workflow. Lamella frozen. Deferred work. Mark draft.
- **Action taken:** Moved to `septa/draft/resolved-status-customization-v1.schema.json`; fixtures deleted.

### tool-relevance-rules-v1 — disposition: draft

- **Description:** Configuration mapping host operations and file patterns to recommended ecosystem tools. Determines which tools are relevant-but-unused for a given session.
- **Original intent:** Support cortina session analysis and tool relevance inference.
- **Investigation:** No code references found. Schema describes lamella rule package format. Lamella skill packs and rule authoring frozen in F1 ("No new skill packs or plugin categories").
- **Decision rationale:** Schema is for lamella-produced rule packages. Lamella frozen. Aspirational for post-freeze tool relevance analysis. Mark draft.
- **Action taken:** Moved to `septa/draft/tool-relevance-rules-v1.schema.json`; fixtures deleted.

### task-output-v1 — disposition: delete

- **Description:** Structured output from a completed canopy task.
- **Original intent:** Provide a task output envelope for canopy task completion reporting.
- **Investigation:** No code references found. Schema appears to be an early sketch for canopy task completion. Canopy task output is already covered by `canopy-task-detail-v1` and `workflow-outcome-v1` schemas. This schema is unused and redundant.
- **Decision rationale:** Dead schema. Canopy task completion is already modeled by existing task-detail and workflow-outcome contracts. No producer or consumer. Delete.
- **Action taken:** Deleted `septa/task-output-v1.schema.json`; deleted matching fixtures.

---

## Integration Patterns Updates

Rows removed (deleted schemas):
- `host-identifier-v1` (was part of internal type references, not a top-level integration pattern)
- `mycelium-summary-v1` (was listed under mycelium → hyphae, but never implemented)
- `task-output-v1` (never listed; no integration pattern)

Rows archived under new "Drafts (deferred until F1 freeze lifts)" section:
- `context-envelope-v1` — context assembly across ecosystem tools (volva, hyphae, canopy)
- `credential-v1` — credential management (stipe, cortina, volva auth system deferred)
- `degradation-tier-v1` — tool health and fallback semantics (volva, operational dashboards frozen)
- `dependency-types-v1` — task and workflow dependencies (canopy/hymenium primitives deferred)
- `handoff-context-v1` — context assembly for agent handoffs (canopy/hyphae deferred)
- `hook-execution-v1` — hook semantics (lamella hook templates frozen)
- `local-service-endpoint-v1` — typed endpoint registry (C7/C8 endpoint migration deferred)
- `resolved-status-customization-v1` — statusline customization (lamella preset management frozen)
- `tool-relevance-rules-v1` — cortina tool relevance inference (lamella rule packs frozen)

---

## Verification

- `bash septa/validate-all.sh` → pass (48 passed, 0 failed; 9 schemas moved to draft, 2 deleted, 12 fixtures removed; 1 schema kept after $ref-correctness check)
- `bash .handoffs/septa/verify-orphan-schema-triage.sh` → pass (all 12 orphans have decisions, no duplicate active/draft states)
- Integration-patterns.md updated without crossing existing row boundaries

