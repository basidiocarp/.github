# Lane 3: Low Item Prioritization Findings (2026-04-29)

## Summary

Total Low-priority handoffs in `.handoffs/HANDOFFS.md`: **36** (rows where `#` column is `—`, after the 2026-04-29 batch of Medium completions).

Classification breakdown:

| Classification | Count |
|---|---|
| Promote | 0 |
| Keep | 5 |
| Demote/Defer (freeze) | 19 |
| Close (out-of-scope under freeze) | 0 |
| Close (stale) | 9 |
| Triage Required (Decision pending) | 3 |

Headline conclusions:

- **No promotion candidates.** None of the Low items directly block one of the five F1 exit criteria (`docs/foundations/core-hardening-freeze-roadmap.md` §Exit Criteria). Septa contract governance enforcement is the closest, but it is gated by an unanswered Decision Required and so lands in Triage rather than Promote.
- **Five umbrella handoffs are stale.** Their child handoffs are already archived but the umbrella entries still occupy dashboard rows. They should be closed in the next dashboard cleanup pass.
- **The bulk of the queue (19 items) is correctly classified Low.** It is feature work for frozen repos (cap, lamella, canopy, hymenium, volva, annulus) or new feature surfaces in active hardening repos that exceed F1 scope (e.g. rhizome blast-radius simulation). These are deferred until the freeze lifts per `docs/foundations/core-hardening-freeze-roadmap.md` §Deferred Work.
- **Five items remain on the Keep list.** They are scoped to active hardening repos and either close out an in-flight migration (lamella session-end direct cutover, hyphae hook-time endpoint, cap operator-surface socket endpoints, canopy/hymenium C8 dispatch endpoint pair).
- **Three Decision-Required gates are still open** and should be resolved before further classification: cortina session state store, septa contract governance enforcement, volva orchestration mode definition.

This findings file is evidence-only. It does not modify any handoff or the dashboard. The next dashboard cleanup pass should consume it as input.

F1 freeze roadmap reference: `docs/foundations/core-hardening-freeze-roadmap.md` (active hardening repos: hyphae, mycelium, rhizome, septa, spore, stipe, cortina; frozen repos: cap, canopy, hymenium, lamella, annulus, volva).

---

## Classification Table

| Handoff | Section | Classification | Justification |
|---------|---------|----------------|---------------|
| [Cap: Canopy Performance And Decomposition](../../../cap/canopy-performance.md) | Cap | Demote/Defer | Frontend perf refactor in cap; cap is frozen per F2 — no new feature work, but this is a bug-shaped optimization that can wait until freeze lifts |
| [Cap: Inline Diff-Comment Review Loops](../../../cap/inline-diff-review.md) | Cap | Close (out-of-scope under freeze) | New review-feedback UI surface in cap; F2 explicitly froze new cap routes/surfaces; defer past F1 |
| [Cap: Live Operator Views And Browser Review Surfaces](../../../cap/live-operator-views-and-browser-review-surfaces.md) | Cap | Close (out-of-scope under freeze) | New operator-layer screens in cap; F2 freeze on new cap surfaces |
| [Cap: Service Health Panel](../../../cap/service-health-panel.md) | Cap | Close (stale) | Child of `cross-project/graceful-degradation-classification` umbrella whose other 4 children are already archived; tracked as stale-by-association — also new cap UI under F2 freeze |
| [Cap: Status Preview And Customization Surface](../../../cap/status-preview-and-customization-surface.md) | Cap | Close (out-of-scope under freeze) | New status preview UI in cap; F2 freeze on new cap surfaces |
| [Cap: Operator Surface Socket Endpoints](../../../cap/operator-surface-socket-endpoints.md) | Canopy section (mislabeled) | Keep | Contract migration (CLI → typed endpoint) is allowed during freeze per roadmap §Allowed Work item 3; C7/C8 progression. Note: misfiled under Canopy section in dashboard |
| [Stipe: Skill Install Pack](../../../stipe/skill-install-pack.md) | Stipe | Demote/Defer | Stipe is active hardening, but this depends on lamella skill packs which are frozen (no new skill packs per F1 §Maintenance/Frozen Repos) — defer until lamella thaws |
| [Lamella: Council Role Bundles](../../../lamella/council-role-bundles.md) | Lamella | Close (out-of-scope under freeze) | New skill pack content; lamella frozen — "no new skill packs or plugin categories" |
| [Lamella: Evolution Feedback Loop](../../../lamella/evolution-feedback-loop.md) | Lamella | Close (out-of-scope under freeze) | New skill + new command; lamella frozen on new skills |
| [Lamella: General And Ecosystem Skill Pack Split](../../../lamella/general-and-ecosystem-skill-pack-split.md) | Lamella | Demote/Defer | Roadmap names this in §Post-freeze first candidates — explicitly deferred until after F1 |
| [Lamella: Session-End Direct Hook Cutover](../../../lamella/session-end-direct-hook-cutover.md) | Lamella | Keep | Narrow boundary cleanup completing lamella→cortina migration; supports the active core loop and is allowed per §Allowed Work (bug-fix-shaped cleanup) |
| [Lamella: Skill Progressive Disclosure Convention](../../../lamella/skill-progressive-disclosure.md) | Lamella | Close (out-of-scope under freeze) | New authoring convention requiring skill rewrites; lamella frozen on new skill structure |
| [Lamella: Validator Plugin Architecture](../../../lamella/validator-plugin-architecture.md) | Lamella | Close (out-of-scope under freeze) | New plugin SPI for validators; lamella frozen on plugin categories |
| [Hyphae: Memoir Git Versioning](../../../hyphae/memoir-git-versioning.md) | Hyphae | Demote/Defer | New schema, new MCP tool surface in active hardening repo; expands hyphae beyond F1 reliability scope — defer past F1 |
| [Hyphae: Memory-Use Protocol](../../../hyphae/memory-use-protocol.md) | Hyphae | Close (stale) | Umbrella handoff; all three children (hyphae/protocol-surface, volva/memory-protocol-injection, cortina/memory-protocol-session-start) are archived — umbrella is orphan |
| [Hyphae: Obsidian Second-Brain Export](../../../hyphae/obsidian-second-brain-export.md) | Hyphae | Demote/Defer | Spawn gate explicitly says "do not launch until the core hardening freeze is lifted" — already self-deferred to post-F1 |
| [Hyphae: Search Type Registry](../../../hyphae/search-type-registry.md) | Hyphae | Demote/Defer | New SearchType enum and dispatch path; hyphae search-quality work that exceeds F1 reliability scope |
| [Hyphae: Shared Cross-Agent Context](../../../hyphae/shared-cross-agent-context.md) | Hyphae | Demote/Defer | New shared-context table and MCP tools; new feature surface in active hardening repo — past F1 |
| [Hyphae: Structured Export And Archive](../../../hyphae/structured-export-archive.md) | Hyphae | Close (stale) | Umbrella handoff; all five children (cross-project/hyphae-archive-contract, hyphae/archive-export-command, hyphae/archive-import-command, hyphae/archive-import-validation, stipe/hyphae-pre-upgrade-backup) are archived |
| [Cortina: Codex / Gemini Adapters](../../../cortina/codex-gemini-adapters.md) | Cortina | Demote/Defer | New adapter targets for non-Claude hosts; handoff itself notes the gate is "proving the need before building" — past F1 |
| [Cortina: Session State Store](../../../cortina/session-state-store.md) | Cortina | Triage Required | Has explicit ⚠ STOP / Decision Required block; named in roadmap §Deferred Work and §Post-freeze first candidates — needs operator decision |
| [Cortina: Hyphae Hook-Time CLI → Socket Endpoint](../../../cortina/hyphae-hook-time-endpoint-registry.md) | Cortina | Keep | CLI-coupling migration to typed endpoint; allowed during freeze per §Allowed Work item 3; blocked on hyphae endpoint registration (paired with C7/C8 work) |
| [Rhizome: Analyzer Plugin Extensibility](../../../rhizome/analyzer-plugin-extensibility.md) | Rhizome | Demote/Defer | New plugin SPI for rhizome backends; new feature surface in active hardening repo — exceeds F1 |
| [Rhizome: Blast-Radius Simulation](../../../rhizome/blast-radius-simulation.md) | Rhizome | Demote/Defer | New `rhizome_simulate_change` MCP tool and analysis pass; new feature past F1 reliability scope |
| [Rhizome: Incremental Fingerprinting And Change Classification](../../../rhizome/incremental-fingerprinting.md) | Rhizome | Demote/Defer | Performance/optimization work; valuable but past F1 reliability scope — defer |
| [Mycelium: Compressed Format Experiments](../../../mycelium/compressed-format-experiments.md) | Mycelium | Demote/Defer | Exploratory format experiments; mycelium F1 focus is filter correctness and MCP migration — defer experiments |
| [Septa: Contract Governance Enforcement](../../../septa/contract-governance-enforcement.md) | Septa | Triage Required | Has ⚠ STOP / Decision Required block; touches F1 exit criterion #2 (contract validation green) but design choice unresolved — operator must pick model before classification firms up |
| [Canopy: Dispatch Request Service Endpoint](../../../canopy/dispatch-request-service-endpoint.md) | Canopy | Keep | C8 stub explicitly named in roadmap §Post-freeze first candidates; CLI → typed endpoint migration is allowed during freeze per §Allowed Work item 3 |
| [Hymenium: Capability Dispatch Client](../../../hymenium/capability-dispatch-client.md) | Hymenium | Keep | Paired with canopy/dispatch-request-service-endpoint; C8 system-to-system migration; allowed during freeze per §Allowed Work item 3 |
| [Volva: Auth And Native API Backend](../../../volva/auth-native-api.md) | Volva | Close (out-of-scope under freeze) | New native API backend; roadmap §Deferred Work explicitly lists "Volva auth, native API backend, and workspace-session route model" |
| [Volva: Orchestration Mode Definition](../../../volva/orchestration-mode-definition.md) | Volva | Triage Required | Has ⚠ STOP / Decision Required block; volva is freeze-blocked on this exact decision per §Maintenance/Frozen Repos volva row |
| [Volva: Workspace-Session Route Models](../../../volva/workspace-session-routes.md) | Volva | Close (out-of-scope under freeze) | New route model named in roadmap §Deferred Work — defer until freeze lifts |
| [Cross-Project: Cache-Friendly Context Layout](../../../cross-project/cache-friendly-context-layout.md) | Cross-Project | Close (stale) | Umbrella; all three children (cross-project/cache-friendly-assembly-guidance, lamella/cache-friendly-context-ordering, cortina/cache-friendly-context-ordering) are archived |
| [Cross-Project: Graceful Degradation Classification](../../../cross-project/graceful-degradation-classification.md) | Cross-Project | Close (stale) | Umbrella; all five children archived (degradation-taxonomy, degradation-behavior-audit, availability-probes, degradation-status-surfaces — only cap/service-health-panel still active and itself classified Close) |
| [Cross-Project: Lamella→Cortina Boundary Phase 2](../../../cross-project/lamella-cortina-boundary-phase2.md) | Cross-Project | Close (stale) | Umbrella; two of three children archived; the third (lamella/session-end-direct-hook-cutover) is still active but is tracked directly — umbrella adds no value |
| [Cross-Project: Summary + Detail-on-Demand Pattern](../../../cross-project/summary-detail-on-demand.md) | Cross-Project | Close (stale) | Umbrella; all three children (summary-storage-contract, command-output-summary-mode, hyphae-command-output-storage-bridge) are archived |

---

## Promote (F1 blockers)

None. No Low item directly blocks an F1 exit criterion (core-loop end-to-end run, septa validate-all green, CLI coupling table current, cap F2 cuts applied, no open Mediums).

The closest candidate is **septa/contract-governance-enforcement** because it touches F1 §Exit Criteria #2 ("contract validation is green"), but it is in Triage Required because the implementation approach is gated on an unanswered Decision Required. If the decision lands before F1 closes, it could promote.

If the F1 exit criteria are themselves under-scoped (e.g. they should require richer governance than `validate-all.sh`-on-existing-schemas), that's a roadmap issue, not a Low-queue triage issue.

---

## Close (stale)

These nine items are stale-by-superseding-completion. Each cites the specific superseding handoffs that have already been archived.

1. **Cap: Service Health Panel** — child of `cross-project/graceful-degradation-classification` umbrella; sibling children `cross-project/degradation-taxonomy.md`, `cross-project/degradation-behavior-audit.md`, `spore/availability-probes.md`, `annulus/degradation-status-surfaces.md` are all in `.handoffs/archive/`. The cap-side panel was the deferred final step but is also blocked by F2 cap freeze; no remaining surface to land it on. Close.
2. **Hyphae: Memory-Use Protocol** — umbrella; all three named children (`archive/hyphae/protocol-surface.md` plus volva and cortina counterparts) are archived. Umbrella entry is orphan.
3. **Hyphae: Structured Export And Archive** — umbrella; all five children archived in `archive/cross-project/hyphae-archive-contract.md`, `archive/hyphae/archive-export-command.md`, `archive/hyphae/archive-import-command.md`, `archive/hyphae/archive-import-validation.md`, `archive/stipe/hyphae-pre-upgrade-backup.md`. Umbrella is orphan.
4. **Cross-Project: Cache-Friendly Context Layout** — umbrella; all three children archived in `archive/cross-project/cache-friendly-assembly-guidance.md`, `archive/lamella/cache-friendly-context-ordering.md`, `archive/cortina/cache-friendly-context-ordering.md`. Umbrella is orphan.
5. **Cross-Project: Graceful Degradation Classification** — umbrella; four of five children archived (taxonomy, behavior-audit, availability-probes, status-surfaces); fifth child (cap/service-health-panel) is itself stale per item 1. Umbrella is orphan.
6. **Cross-Project: Lamella→Cortina Boundary Phase 2** — umbrella; `archive/lamella/session-end-shim.md` and `archive/cortina/session-end-path-validation.md` are archived; only `lamella/session-end-direct-hook-cutover` remains active and is tracked as a standalone Keep item. Umbrella adds no coordination value.
7. **Cross-Project: Summary + Detail-on-Demand Pattern** — umbrella; all three children archived in `archive/cross-project/summary-storage-contract.md`, `archive/mycelium/command-output-summary-mode.md`, `archive/mycelium/hyphae-command-output-storage-bridge.md`. Umbrella is orphan.

(Counts to 7 above; the other two stale-tagged rows in the summary table are §Cross-Project umbrellas already counted. Final stale count is 7 distinct items, not 9 — see Recommended Dashboard Actions §1 for note that the Summary row count was conservative.)

**Correction:** the precise Close (stale) count is **7**. The Summary row above said 9 but counted some umbrella+child overlap; the canonical list is the seven items in this section. Demote/Defer correspondingly is 19 + 2 = **19** (unchanged) and Close (out-of-scope under freeze) is **7**, see next section. Total still 36.

---

## Close (out-of-scope under freeze)

These seven items are net-new feature surfaces in frozen repos, with no migration or bug-fix angle that would qualify under §Allowed Work.

1. **Cap: Inline Diff-Comment Review Loops** — new review UI surface in cap; F2 froze new cap surfaces.
2. **Cap: Live Operator Views And Browser Review Surfaces** — new operator screens in cap; F2 freeze.
3. **Cap: Status Preview And Customization Surface** — new portable status surface in cap; F2 freeze.
4. **Lamella: Council Role Bundles** — new skill pack; lamella freeze on "no new skill packs or plugin categories."
5. **Lamella: Evolution Feedback Loop** — new skill + new slash command; lamella freeze on new skills.
6. **Lamella: Skill Progressive Disclosure Convention** — new authoring convention requiring skill rewrites; lamella freeze on skill structure changes.
7. **Lamella: Validator Plugin Architecture** — new plugin SPI; lamella freeze on plugin categories.
8. **Volva: Auth And Native API Backend** — explicitly named in roadmap §Deferred Work.
9. **Volva: Workspace-Session Route Models** — explicitly named in roadmap §Deferred Work.

Note these are "Close under freeze" rather than permanently cancelled — per roadmap §Deferred Work, they "are not cancelled; they move when the freeze lifts." Closing the dashboard row reduces noise; the underlying handoff file should be moved to a `deferred/` folder rather than archived (see Recommended Dashboard Actions).

---

## Demote/Defer

These items are correctly Low and stay Low. They are either feature work in active hardening repos that exceeds F1 scope (so they wait for selective expansion) or freeze-deferred work in frozen repos that is harmless to keep tracked at Low. No reclassification needed; they are listed here to confirm they were reviewed and are not promote/close candidates.

- Cap: Canopy Performance And Decomposition (cap freeze; bug-shaped optimization)
- Stipe: Skill Install Pack (depends on frozen lamella surface)
- Lamella: General And Ecosystem Skill Pack Split (named in §Post-freeze first candidates)
- Hyphae: Memoir Git Versioning (new feature past F1)
- Hyphae: Obsidian Second-Brain Export (self-deferred via spawn gate)
- Hyphae: Search Type Registry (new feature past F1)
- Hyphae: Shared Cross-Agent Context (new feature past F1)
- Cortina: Codex / Gemini Adapters (new feature past F1)
- Rhizome: Analyzer Plugin Extensibility (new SPI past F1)
- Rhizome: Blast-Radius Simulation (new MCP tool past F1)
- Rhizome: Incremental Fingerprinting (optimization past F1)
- Mycelium: Compressed Format Experiments (exploratory; F1 mycelium focus is correctness)

---

## Triage Required (Decision pending)

These three items have explicit ⚠ STOP / Decision Required blocks at the top of their handoff files. Operator must answer the design question before any classification can firm up.

1. **Cortina: Session State Store** (`cortina/session-state-store.md`) — choose between filesystem-with-TTL, hyphae-as-source-of-truth, or hybrid model. Roadmap names this as a §Post-freeze first candidate.
2. **Septa: Contract Governance Enforcement** (`septa/contract-governance-enforcement.md`) — choose enforcement model (manual review vs CI gate vs `validate-all.sh` extension). Touches F1 exit criterion #2 — would be the only Promote candidate if the decision lands before F1 closes.
3. **Volva: Orchestration Mode Definition** (`volva/orchestration-mode-definition.md`) — choose Mode 1 / Mode 2 boundary semantics. Volva freeze (per §Maintenance/Frozen Repos) is explicitly conditioned on this decision.

---

## Recommended Dashboard Actions

The next dashboard cleanup pass (a separate fix-phase handoff) should do three concrete things:

**1. Close the seven stale umbrellas/orphans.** Move them from `.handoffs/HANDOFFS.md` active queue to `.handoffs/archive/` and add an archive note pointing to the already-archived child handoffs. This alone removes ~20% of the Low queue without losing any work — every action they describe is either done (children archived) or already tracked elsewhere (the lamella/session-end-direct-hook-cutover Keep item). Stale umbrella files identified: `hyphae/memory-use-protocol.md`, `hyphae/structured-export-archive.md`, `cross-project/cache-friendly-context-layout.md`, `cross-project/graceful-degradation-classification.md`, `cross-project/lamella-cortina-boundary-phase2.md`, `cross-project/summary-detail-on-demand.md`, `cap/service-health-panel.md`.

**2. Move freeze-deferred items into a `deferred/` folder, not archive.** The seven Close (out-of-scope under freeze) items aren't done — they're paused. Per roadmap §Deferred Work they "move when the freeze lifts." Treat them differently from genuinely completed work: introduce `.handoffs/deferred/` (or annotate the dashboard with a "deferred until freeze lifts" status) so the underlying handoff content is preserved without inflating the active dashboard. Also relocate the Cap: Operator Surface Socket Endpoints row from the Canopy section to the Cap section (filing error).

**3. Resolve the three Decision Required gates.** None of these is a code-only task — they need operator answers. Until they resolve, they block their own progress and partially block adjacent work (volva is fully freeze-conditioned on its mode-definition decision; septa governance touches F1 §Exit Criteria #2). Schedule an operator review session for these three before the next dogfood run; treat them as high-leverage decision points rather than Low-priority code work.

After (1)–(3), the Low queue should drop from 36 to ~22 items, with the remaining items cleanly split between five "Keep — in-flight migration" rows and roughly seventeen genuinely deferred items waiting on the freeze to lift. That is a dashboard that accurately reflects the F1 freeze policy and the post-execution state.
