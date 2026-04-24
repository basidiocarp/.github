# Near-Miss Findings — Secondary Synthesis

Date: 2026-04-23
Scope: Findings from Wave 1, Wave 2, Wave 3, and ECC re-audit that were 60–70% of the way to a handoff but did not clear the bar. Organized by owning repo. Each entry states why it stopped short and what it would take to promote it.

This document is a living reference — not a task list. Findings here are worth tracking because they may be promoted when a second signal arrives, when a prerequisite ships, or when the owning repo gains the seam the pattern requires.

---

## Promotion bar

A finding clears the handoff bar when it has:
- Two or more independent audit signals pointing to the same owning repo, OR
- One very strong signal with a fully concrete implementation seam and no prerequisite gap

A finding stays here when it has:
- Only one audit signal (even a strong one)
- A clear pattern but ownership is ambiguous between two repos
- A clear seam but a prerequisite that has not shipped yet
- A pattern that is interesting but not in the ecosystem's core mission

---

## Annulus

### Context window % display (claude-hud)

**Signal:** claude-hud Wave 3 audit
**Pattern:** Surface autocompaction-aware context usage as a percentage (not raw tokens). Auto-compact fires at ~95% — showing % with a warning threshold at 80% gives operators early signal without requiring them to understand token counts. ECC's continuous-learning-v2 also tracks context pressure as a pre-compact trigger.
**Why it stopped short:** Single audit signal. claude-hud is the only source.
**Seam:** `annulus/src/segments/` — new context-percent segment. Reads token counts from cortina events or hyphae session context.
**Promotes when:** A second audit finds a similar pattern, or the annulus segment registry work ships and the cost of adding a segment drops.

### Pace delta formula + XDG cache safety (claude-pace)

**Signal:** claude-pace Wave 3 audit
**Pattern:** Two distinct borrowable primitives from the same audit.
- Pace delta: `(limit - used) / time_elapsed` gives a rolling rate that tells the operator whether they're consuming budget faster or slower than the period average. Displayed as Δ/hr.
- XDG cache safety: write usage data to `$XDG_CACHE_HOME/claude-pace/` (fallback to `~/.cache/claude-pace/`) rather than a fixed `~/.claude-pace/`. Avoids cluttering $HOME, survives HOME changes, and is more testable.
**Why it stopped short:** Single audit signal. Both primitives are strong, but annulus is the only repo with a matching surface (statusline, segment registry).
**Seam:** `annulus/src/segments/budget.rs` (pace delta), `annulus/src/storage.rs` or equivalent (XDG path).
**Promotes when:** A second signal appears, or the annulus segment registry (from annulus v0.3.0 work) is confirmed to support per-segment storage paths.

**Note:** claude-hud and claude-pace together form a two-audit signal toward annulus. If both are considered simultaneously, the combination may already clear the bar for an annulus handoff covering context % and pace delta together.

---

## Rhizome

### Blast-radius simulation (depwire)

**Signal:** depwire Wave 3 audit
**Pattern:** `simulate_change(symbol)` returns the full impact graph for modifying a symbol: direct dependents, transitive dependents, affected test files, change risk score. Depwire's `ProjectGraph` and `SymbolNode` schema are the data model. The output is a ranked list of affected nodes by change propagation depth.
**Why it stopped short:** Single audit signal. Rhizome does structural analysis but hasn't been audited as owning blast-radius simulation.
**Seam:** `rhizome` — new `analyze_impact` tool (or enhancement of the existing MCP tool). `septa/blast-radius-v1.schema.json` for the output contract.
**Promotes when:** A second audit identifies a blast-radius or change-impact pattern, or a user request for "what breaks if I change X?" surfaces in practice.

---

## Volva

### Two-axis timeout model (e2b)

**Signal:** e2b Wave 3 audit
**Pattern:** Separate `execution_timeout` (wall-clock limit for the whole operation) from `idle_timeout` (how long to wait with no output before killing). Merging them into one timeout means either killing long-running operations early or waiting too long on stalled ones. The two-axis model handles both cases correctly.
**Why it stopped short:** Single audit signal. Volva's checkpoint durability work (W2i) is the prerequisite and hasn't shipped.
**Seam:** `volva/src/config.rs` — add `execution_timeout_secs` and `idle_timeout_secs` fields alongside `durability_mode`. `septa/execution-envelope-v1.schema.json` for the cross-tool contract.
**Promotes when:** W2i (checkpoint durability) ships and volva has a real execution configuration surface to extend.

### Streaming adapter trait (roundtable)

**Signal:** roundtable Wave 3 audit
**Pattern:** A uniform `AsyncStream` adapter interface that all harness runners (Claude, Codex, Gemini, etc.) implement. All runners expose `stream_response(prompt, context) -> impl Stream<Item=Chunk>`. The adapter hides harness-specific chunking, reconnection, and backpressure. Roundtable uses this to swap harnesses without changing the orchestration layer.
**Why it stopped short:** Single audit signal. Volva has harness runner hooks but the adapter interface is not yet formalized.
**Seam:** `volva/src/adapters/` — new `HarnessAdapter` trait with streaming implementation per harness.
**Promotes when:** A second audit finds a harness-adapter pattern, or volva begins active harness expansion beyond Claude.

---

## Hyphae

### Multi-level memory hierarchy (letta)

**Signal:** letta Wave 2 audit
**Pattern:** Four explicit memory tiers: working memory (in-context, current session), episodic memory (recent sessions, FIFO eviction), semantic memory (long-term facts, embedding-indexed), procedural memory (skills and workflows, stable). Each tier has different retrieval speed, eviction policy, and indexing. Letta's `ArchivalMemory` and `RecallMemory` implement this as typed storage with explicit promotion paths.
**Why it stopped short:** Single audit signal, but more importantly: the tiered eviction handoff (W2d) already covers part of this. The multi-level hierarchy is a design input for W2d, not a separate handoff.
**Seam:** W2d (hyphae/tiered-memory-eviction.md) is the implementation vehicle. Promote letta's tier model if W2d lands without covering episodic/procedural separation.
**Note:** This is a near-miss that is already partially tracked via W2d.

### Vector + graph hybrid store (cognee)

**Signal:** cognee Wave 2 audit
**Pattern:** Cognee stores memories in both a vector index (embedding similarity) and a knowledge graph (entity + relationship). Retrieval first queries the graph for structural matches, then widens with vector similarity. The hybrid store gives better precision on structured queries (what caused this error?) and better recall on fuzzy queries (what was similar to this session?).
**Why it stopped short:** Single audit signal. Hyphae uses SQLite + embeddings today but does not have a graph layer. Adding one is a significant architectural change that needs more design work.
**Seam:** `hyphae/src/store/` — graph store backend alongside the existing SQLite store. `septa/memory-graph-v1.schema.json` for the entity/relationship contract.
**Promotes when:** A second audit identifies a graph-memory pattern, or hyphae reaches the point where SQL queries on memories are hitting structural limits.

### Instinct confidence model and scope promotion (ECC continuous-learning-v2)

**Signal:** ECC re-audit 2026-04-23
**Pattern:** Atomic instincts (smallest learnable unit of behavior) with confidence scores from 0.3 to 0.9. Related instincts cluster into skills or commands at 0.7+. High-confidence instincts promote from project scope to global scope automatically. The observation pipeline is hook-based (100% deterministic, not probabilistic), and analysis is async in a background Haiku agent.
**Why it stopped short:** Single audit signal. It is also a design input for hyphae's memory decay model rather than a standalone implementation — the W2d tiered eviction handoff is the more immediate vehicle.
**Seam:** `hyphae/src/memory/` — confidence field on memory records, background consolidation using the confidence band thresholds.
**Promotes when:** W2d ships and the question of how to score memories for eviction vs. promotion remains unsolved.

---

## Canopy

### Meta-judge quality gate (context-engineering-kit)

**Signal:** context-engineering-kit Wave 3 audit
**Pattern:** A `meta-judge` node that runs after a task produces output and evaluates it against defined quality criteria before allowing the task to be marked complete. The judge is a separate agent invocation with only the task specification and the output — no conversation history. It returns pass/fail with a structured rationale. The pattern prevents tasks from completing with output that technically exists but is the wrong quality.
**Why it stopped short:** Single audit signal. Canopy's DAG task graph (W2f) is the prerequisite.
**Seam:** `canopy/src/tasks/` — a new `Evaluator` task type that runs after a worker task and gates completion. `septa/task-eval-v1.schema.json` for the evaluator contract.
**Promotes when:** W2f (canopy/dag-task-graph) ships and task-level quality gating becomes a real operator concern.

### Council session record (council.ai, ECC Council skill)

**Signal:** council.ai original audit + ECC Council skill (re-audit)
**Pattern:** Two different implementations, same concept. Council.ai: full multi-agent session with persistent records. ECC Council skill: lightweight 4-voice deliberation (Architect, Skeptic, Pragmatist, Critic) as an anti-anchoring mechanism for ambiguous decisions. The canopy-level primitive needed in both cases is a `council_session` record attached to a task: summon participants, store deliberation timeline, attach verdict to task context.
**Why it stopped short:** Two signals, but the skill-management-and-council-adoption-plan (Track B) covers this as a phased build. No standalone handoff was created because the plan already defines the decomposition.
**Seam:** `canopy/src/council/` — council session record, participant roster, timeline, verdict storage. Cross-repo: `lamella/resources/skills/council.md` (ECC borrow, direct), `cap/` (operator UI, later phase).
**Note:** The ECC Council skill is a fast lamella borrow (copy the SKILL.md, adapt for basidiocarp). The canopy session record is heavier infrastructure. Do the lamella skill first.
**Promotes when:** The decision is made to start Track B Phase 1 from the adoption plan. Ready to be promoted now if desired.

---

## Hymenium

### Composite operation patterns (ateam-mcp)

**Signal:** ateam-mcp Wave 3 audit
**Pattern:** Server-side composite operations that batch multiple tool calls into a single atomic unit with a defined execution graph. Instead of the model issuing N sequential tool calls, it issues one `composite_op` call. The server executes the subgraph, handles partial failures with rollback semantics, and returns a single structured result. Reduces round-trips and provides cleaner error attribution.
**Why it stopped short:** Single audit signal. Hymenium handles workflow dispatch but the composite-operation primitive requires a matching tool interface contract in septa.
**Seam:** `hymenium/src/ops/` — `CompositeOp` executor, `septa/composite-op-v1.schema.json` for the operation graph contract.
**Promotes when:** A second audit finds a composite-operation or atomic-batch pattern, or hymenium's phase-gate work reaches a point where batching tool calls would meaningfully improve performance.

---

## Lamella

### Certainty-graded findings (agentsys)

**Signal:** agentsys Wave 3 audit
**Pattern:** Skill output includes findings tagged with certainty: `HIGH` (confirmed, reproducible), `MEDIUM` (likely but depends on context), `LOW` (possible, needs investigation). The grading is a first-class output field, not a prose qualifier. Downstream consumers can filter or escalate by certainty band.
**Why it stopped short:** Single audit signal.
**Seam:** `lamella/resources/skills/` — add a `certainty` field to the skill output convention; update `septa/skill-output-v1.schema.json` if one exists.
**Promotes when:** A second audit identifies a certainty or confidence grading pattern, or the agentsys compliance test approach surfaces as a model for lamella skill testing.

### Rationalizations-to-reject pattern (Trail of Bits)

**Signal:** Trail of Bits skills Wave 3 audit
**Pattern:** A dedicated section in a skill document titled "Rationalizations to Reject" — an explicit list of plausible-sounding excuses for skipping the skill's rigor, each annotated with why it's wrong. Example: "This is a small change" → "Small changes have caused large incidents." Prevents the model from self-exempting from the skill's procedures.
**Why it stopped short:** Single audit signal. It is a lamella skill authoring technique rather than a standalone skill.
**Seam:** Add as a required section in lamella's skill authoring convention. No code change — authoring guidance update only.
**Promotes when:** lamella formalizes its skill authoring convention (Track A Phase 1 in the adoption plan). At that point, "Rationalizations to Reject" should be a standard optional section.

### Silent-failure-hunter (Rust adaptation from ECC)

**Signal:** ECC re-audit 2026-04-23
**Pattern:** A focused agent that hunts five categories of silent failure: empty catch blocks, inadequate logging, dangerous fallbacks (`.catch(() => [])`), lost stack traces, and missing async error handling. The Rust adaptation would hunt `.unwrap()` chains, unchecked `expect` in non-invariant positions, `?`-chains with no context annotation, and missing error propagation in async functions.
**Why it stopped short:** Single source (ECC re-audit), and it is a skill/agent document rather than code. Lamella is the right owner but adding it requires confirming the skill authoring convention first.
**Seam:** `lamella/resources/skills/silent-failure-hunter.md` — adapt ECC's `agents/silent-failure-hunter.md` to Rust patterns. Or `lamella/resources/agents/` if agents have a separate directory.
**Promotes when:** Lamella ships the skill authoring convention, or the Rust error-handling rules (anti-unwrap-abuse, err-result-over-panic) are surfaced as needing automated enforcement.

### Variant analysis skill (Trail of Bits)

**Signal:** Trail of Bits skills Wave 3 audit
**Pattern:** A structured investigation skill for exploring all variants of a code pattern (all call sites, all edge cases, all error paths) before concluding a review or fix. The skill prevents premature conclusions from single-case analysis. Trail of Bits uses it in security reviews; the pattern generalizes to any thorough code analysis.
**Why it stopped short:** Single audit signal.
**Seam:** `lamella/resources/skills/variant-analysis.md` — direct lamella skill document.
**Promotes when:** A second audit identifies a similar exhaustive-analysis pattern, or the Trail of Bits skill set more broadly becomes a borrow target.

---

## Cortina

### fp-check Stop/SubagentStop hook (Trail of Bits)

**Signal:** Trail of Bits skills Wave 3 audit
**Pattern:** A Stop hook that reads the session transcript, identifies unresolved false positives (FP) flagged earlier in the session, and emits a structured report. Prevents findings from being dropped silently at session end. The `SubagentStop` variant triggers when a subagent session ends, so findings from delegated work are captured before the parent session closes.
**Why it stopped short:** Single audit signal.
**Seam:** `cortina/src/hooks/stop.rs` — extend Stop hook handler to detect FP markers in transcript and emit a summary. Works alongside the existing session-end signal emission.
**Promotes when:** A second audit identifies a similar "capture-unresolved-at-stop" pattern, or cortina gains better access to session transcript content for Stop hook processing.

### Trigger-word Stop hook (context-engineering-kit)

**Signal:** context-engineering-kit Wave 3 audit
**Pattern:** A Stop hook triggered by the presence of specific trigger words in the agent's last message (e.g., "MEMORIZE", "ACE:"). The hook reads the trigger word, extracts the payload, and routes it to hyphae for storage. The key insight: the model communicates intent to persist through in-band trigger words rather than requiring an explicit tool call. Avoids the overhead of a tool call at the end of every message.
**Why it stopped short:** Single audit signal. Also overlaps conceptually with cortina's existing signal emission pipeline.
**Seam:** `cortina/src/hooks/stop.rs` or `session_end.rs` — scan final message for trigger words and dispatch to hyphae store.
**Promotes when:** A second audit finds a trigger-word or in-band-intent pattern, or the overhead of end-of-session tool calls becomes a documented problem.

---

## Stipe

### Hermes operator shell → canonical public system migration pattern (ECC)

**Signal:** ECC re-audit 2026-04-23
**Pattern:** Personal automation workspaces (Hermes, OpenClaw) are treated as workflow input to a canonical public system (ECC), not as architectures to preserve. The migration guide codifies five extraction layers: schedulers, dispatch gateways, memory systems, skills, and tools → ECC-native equivalents. The pattern is: audit what the personal workspace is doing → map each capability to a canonical repo → migrate with a cutover date.
**Why it stopped short:** Weak direct fit. The pattern is relevant to how the basidiocarp workspace relates to its subproject repos, but it is not an implementation task for stipe or any specific repo.
**Note:** This pattern is a meta-level design principle more than a handoff candidate. It is captured here for reference.

---

## Septa

### Rate-limit schema (claude-pace)

**Signal:** claude-pace Wave 3 audit
**Pattern:** `rate-limits-v1.schema.json` — a contract for rate limit state that can be shared between annulus (display), cortina (signal), and cap (dashboard). Fields: `model`, `period` (minute/hour/day), `limit`, `used`, `remaining`, `reset_at`. Allows any tool to read the current rate limit state without owning the source of truth.
**Why it stopped short:** Single audit signal. Septa already has a governance model; adding a schema requires a real consumer.
**Seam:** `septa/rate-limits-v1.schema.json` — new schema. Consumers: annulus (pace delta segment), cortina (rate-limit-exceeded signal), cap (operator alert).
**Promotes when:** Annulus ships a pace/rate-limit segment, giving septa a concrete consumer.

---

## Summary table

| Finding | Repo | Wave | What it needs to promote |
|---------|------|------|--------------------------|
| Context window % display | annulus | W3 | Second signal (claude-pace may be enough) |
| Pace delta + XDG cache | annulus | W3 | Second signal (claude-hud may be enough) |
| Blast-radius simulation | rhizome | W3 | Second signal |
| Two-axis timeout | volva | W3 | W2i ships first |
| Streaming adapter trait | volva | W3 | Second signal or harness expansion |
| Multi-level memory hierarchy | hyphae | W2 | Already tracked via W2d |
| Vector + graph hybrid | hyphae | W2 | Second signal + design work |
| Instinct confidence model | hyphae | ECC re-audit | W2d ships first |
| Meta-judge quality gate | canopy | W3 | W2f ships first |
| Council session record | canopy | W1/ECC | Ready to promote (adoption plan Track B Phase 1) |
| Composite operations | hymenium | W3 | Second signal |
| Certainty-graded findings | lamella | W3 | Second signal |
| Rationalizations-to-reject | lamella | W3 | Skill authoring convention ships |
| Silent-failure-hunter (Rust) | lamella | ECC re-audit | Skill authoring convention ships |
| Variant analysis skill | lamella | W3 | Second signal |
| fp-check Stop hook | cortina | W3 | Second signal |
| Trigger-word Stop hook | cortina | W3 | Second signal |
| Hermes migration pattern | stipe | ECC re-audit | Meta-level; not a handoff candidate |
| Rate-limit schema | septa | W3 | Annulus pace segment ships |
