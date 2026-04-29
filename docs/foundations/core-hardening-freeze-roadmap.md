# Core Hardening Freeze Roadmap

> Produced 2026-04-29. Review quarterly or when a dogfood run changes the priority order.

---

## Freeze Decision

**Freeze in effect.** New feature work across the ecosystem is paused except for the categories listed below. The core tools and contracts need to be reliable and well-bounded before additional surfaces are built on top of them.

This decision followed:
- The CentralCommand dogfood run, which surfaced reliability and boundary issues rather than missing features.
- The sequential audit hardening campaign (53 issues fixed across the ecosystem).
- The capability control plane campaign (C0–C8), which defined typed endpoint contracts, CLI coupling policy, and the system-to-system communication boundary.
- F2 (Cap operator console scope reset), which narrowed Cap's role and froze its feature surface.

---

## Active Hardening Repos

These repos are in active hardening mode. Substantive improvements, bug fixes, contract migrations, and targeted feature work that supports the core agent loop are all allowed.

| Repo | Focus | Notes |
|------|-------|-------|
| **hyphae** | Memory reliability, search quality, MCP tool stability | Primary memory layer; quality here affects every agent session |
| **mycelium** | Filter correctness, token savings accuracy, MCP migration | Output quality directly affects context budget |
| **rhizome** | Code intelligence accuracy, MCP surface stability | Symbol and structure data feeds hyphae ingest and cap |
| **septa** | Contract completeness, schema validation coverage | All cross-tool boundary work lands here first |
| **spore** | Discovery, transport primitives, version pinning | Shared infrastructure; changes affect every consumer |
| **stipe** | Install health, doctor flow accuracy, backup reliability | A broken installer blocks every new setup |
| **cortina** | Lifecycle signal capture, hook reliability | Signal quality drives everything downstream |

---

## Maintenance/Frozen Repos

These repos are in maintenance mode. Critical bug fixes and security fixes are allowed. New features and new surfaces are frozen.

| Repo | Freeze scope | Exception path |
|------|-------------|----------------|
| **cap** | No new routes, no new API namespaces, no new direct DB reads into sibling databases (see F2 scope reset) | CLI-to-contract migrations are allowed as sibling endpoints land per C7/C8 |
| **canopy** | No new orchestration modes or workflow primitives | Dogfood-required task/handoff fixes are allowed via exception process |
| **hymenium** | No new workflow features | Narrow fixes required by the next dogfood run via exception process |
| **lamella** | No new skill packs or plugin categories | Skills that directly support the hardening loop (e.g. systematic-debugging, verify) via exception |
| **annulus** | No new statusline segments or UI surfaces | Security fixes and segment correctness fixes allowed |
| **volva** | No new orchestration mode definitions | Blocked on Orchestration Mode Definition decision handoff |

---

## Allowed Work During Freeze

The following categories of work are allowed in any repo without an exception request:

1. **Bug fixes**: any verified bug that breaks existing documented behavior.
2. **Security and safety fixes**: any repo, any severity.
3. **Contract migrations**: moving an existing CLI coupling to a typed endpoint per C7/C8 policy. No new data sources allowed.
4. **Docs that clarify current behavior**: corrections, accuracy fixes, stale reference removal. No new feature documentation that implies the feature exists.
5. **Septa schema additions**: adding a schema for a payload that already exists in production. No new payload designs without a corresponding implementation.
6. **Test coverage improvements**: adding tests for existing behavior, not for new behavior.
7. **Dependency updates**: patch-level version bumps with no API changes.

---

## Deferred Work

The following categories are explicitly deferred until the core loop is proven through at least one successful end-to-end dogfood run:

- New UI screens or dashboard surfaces in cap.
- New skill packs, hook adapters, or packaging features in lamella.
- New orchestration primitives in hymenium or canopy that are not required by an active task.
- New statusline segments in annulus.
- Volva auth, native API backend, and workspace-session route model.
- Cortina session state store (Decision Required gate is still open).
- Any new cross-tool payload that does not have an existing consumer already using it informally.

Deferred items are tracked as Low-priority handoffs in `.handoffs/HANDOFFS.md`. They are not cancelled; they move when the freeze lifts.

---

## Exception Process

To unfreeze a specific piece of work during the freeze period:

1. **Identify the dogfood blocker**: the work must be directly required for the next scheduled dogfood run, or a security/safety issue with no reasonable workaround.
2. **State the scope explicitly**: name the files, the change, and the timeline. No open-ended "we'll see where it leads" exceptions.
3. **Check for boundary impact**: if the change touches a septa contract or a cross-tool CLI coupling, it must go through the septa update workflow first.
4. **Get explicit approval**: the exception decision stays with the operator (this conversation / next session), not with an implementer agent.

Exceptions are one-time grants for the named work. They do not lift the freeze for adjacent work in the same repo.

---

## Exit Criteria

The freeze lifts when all of the following are true:

1. **Core loop works end-to-end**: at least one dogfood run completes a full session (init → agent work → session capture → memory recall → next session) without manual intervention.
2. **Contract validation is green**: `septa/validate-all.sh` passes with zero failures across all schemas.
3. **CLI coupling table is current**: the 10 remaining active CLI couplings in `septa/integration-patterns.md` have either been migrated or classified as permanent exceptions.
4. **Cap operator console is stable**: F2 cuts are applied (`/code`, `/symbols`, `/api/rhizome`, `/api/lsp` removed), and the remaining surfaces have fixture-backed contract tests.
5. **No open Medium-priority handoffs**: all Medium items in `.handoffs/HANDOFFS.md` are complete or explicitly reclassified as Low with written rationale.

When all five criteria are met, the ecosystem moves from freeze to **selective expansion**: one new surface or feature per repo at a time, with a completed dogfood run as the gate for each addition.

---

## Current Handoff Triage

As of 2026-04-29:

**Active hardening (in-flight or next up):**
- A12: Cap cross-tool consumer contracts — `script_verification` evidence kind gap, annulus contract fixture
- A37: Cap canopy stale cache — global cache key → per-request key
- A46: Cap node supply chain — `npx` replacement, release script alignment
- A50: Cap dashboard and API docs drift — route inventory, internals docs, getting-started accuracy

**Campaigns complete:**
- Ecosystem Health Audit: all 16 issues fixed
- Sequential Audit Hardening: all 53 issues fixed
- Capability Ecosystem Control Plane (C0–C8): all done

**Low-priority (deferred until freeze lifts):**
- All Low items in `.handoffs/HANDOFFS.md` across cap, lamella, hyphae, cortina, rhizome, mycelium, septa, canopy, hymenium, volva, cross-project

**Post-freeze first candidates** (most likely to unlock when exit criteria are met):
- Cortina session state store (after Decision Required gate resolves)
- Volva orchestration mode definition (after Decision Required gate resolves)
- Lamella general/ecosystem skill pack split (supports the core loop directly)
- Canopy dispatch request service endpoint (C8 stub — C8 is complete, implementation pending)
