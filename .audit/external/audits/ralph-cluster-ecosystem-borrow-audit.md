# Ralph Cluster Ecosystem Borrow Audit

## One-Paragraph Read

The Ralph cluster is a family of six complementary orchestration frameworks (choo-choo-ralph, ralph-claude-code, multi-agent-ralph-loop, ralph-orchestrator, ralph-starter, smart-ralph) unified by the Ralph Wiggum technique — autonomous AI coding loops that iterate until task completion. Each repo addresses a different execution context: Choo Choo Ralph emphasizes git-native task tracking with Beads; Ralph Claude Code focuses on bash scripting with intelligent exit detection; Multi-Agent Ralph adds MemPalace memory and mandatory parallelization; Ralph Orchestrator is a Rust coordination platform with hats and event-sourcing; Ralph Starter is a production CLI for spec-driven loops across coding agents; Smart Ralph specializes in spec-to-execution with POC-first workflows. The cluster reveals three strong patterns: (1) **structured specs before code** — all use research/requirements/design as gates before implementation; (2) **fresh context per task** — each iteration or task runs with trimmed history, not accumulated conversation; (3) **backpressure gates** — validation (tests, lint, types) blocks completion, forcing quality. No shared contracts yet, but the cluster's convergence on loop structure, exit detection, and memory systems suggests ecosystem-level seams.

## What the Ralph Cluster Is Doing That Is Solid

### 1. Structured Specification as a Guard (All Six Repos)

Every repo enforces a phase-gated workflow: **research → requirements → design → implementation**. This is not just documentation; it gates execution.

- **Choo Choo Ralph** (`plugins/choo-choo-ralph/commands/spec.md`): XML-based spec format with `Spec` → `Molecule` → `Formula` workflow. Specs are poured into Beads with dependencies as multi-step workflows.
- **Ralph Claude Code** (`.ralph/PROMPT.md`, `fix_plan.md`): Plain markdown but enforced via PROMPT structure; tasks flow from `fix_plan.md` checklist.
- **Multi-Agent Ralph** (`docs/reference/aristotle-first-principles.md`): Mandatory Aristotle First Principles analysis (5 phases) before complexity >= 4 tasks run. Specs + learned rules + agent diaries in Obsidian vault.
- **Ralph Orchestrator** (`crates/ralph-core/src/event_loop/`): Specs in `.ralph/specs/` are **not optional** — the code references them; no implementation without approved spec first.
- **Ralph Starter** (`src/integrations/base.ts`, `src/sources/`): Multi-source integration (GitHub, Linear, Notion, Figma) fetches specs; `IMPLEMENTATION_PLAN.md` tracks tasks. Progressive context trimming keeps context < 176K tokens.
- **Smart Ralph** (`plugins/ralph-specum/templates/`): Six-agent workflow (research-analyst, product-manager, architect-reviewer, task-planner, spec-executor, triage-analyst) each producing markdown artifacts. Triage can decompose large features into epics.

**Evidence**: All six use markdown specs as state machines, not just guidance. The loop refuses to proceed without them.

### 2. Exit Detection via Dual Conditions (Ralph Claude Code, Multi-Agent Ralph, Ralph Starter, Smart Ralph)

A critical problem: "done" signals in agent output cause false positives (agent says "setup is done" while writing docs). Four repos solve this with dual-condition gates.

- **Ralph Claude Code** (`lib/response_analyzer.sh`): `EXIT_SIGNAL: true` in RALPH_STATUS block PLUS `completion_indicators >= 2` heuristic. JSON mode suppresses heuristics entirely; text mode requires `confidence_score >= 70 AND has_completion_signal=true`.
- **Multi-Agent Ralph** (`docs/batch-execution/BATCH_SKILLS_v2.88.0.md`): Tasks require `VERIFIED_DONE` validation guarantee; no task completes without passing 4-stage quality gates (correctness, quality, security, consistency).
- **Ralph Starter** (`src/loop/executor.ts`): Checks `completion_promise` (custom string) OR explicit `EXIT_SIGNAL: true`. Progressive iteration trimming prevents context creep.
- **Smart Ralph** (`agents/spec-executor.md`): Tasks output `TASK_COMPLETE` only after POC validation, refactoring, testing, and quality gates all pass. Coordinator outputs `ALL_TASKS_COMPLETE` when no open tasks remain.

**Evidence**: Dual-condition exit gates are now standard. No single repo uses heuristics alone.

### 3. Fresh Context Per Task (Multi-Agent Ralph, Ralph Starter, Smart Ralph)

Rather than accumulating conversation history, these repos start each task with **trimmed context** built from current state (spec, plan, previous learnings).

- **Multi-Agent Ralph**: Agent diaries in Obsidian vault; L0-L1 layer stack (~1050 tokens) loaded at session start. Tasks spawn fresh with focused prompts via Agent Teams.
- **Ralph Starter** (`src/loop/context-builder.ts`): Iteration prompt built from `IMPLEMENTATION_PLAN.md`, previous results, and current task. Context trimmed to ~176K tokens (40-60% of usable window = "smart zone"). No accumulated history.
- **Smart Ralph** (`agents/spec-executor.md`): Each task runs via Task tool with `.progress.md` as context source, not conversation history. POC-first workflow ensures minimal wasted context on failed approaches.

**Evidence**: Memory systems (Obsidian vault, `.progress.md`, task state files) replace conversation history. Convergence suggests this is the reliable approach.

### 4. Backpressure Validation Gates (Ralph Claude Code, Multi-Agent Ralph, Ralph Starter, Smart Ralph)

Quality gates that **block completion** until tests pass, lint clears, or types check. Not suggestions — hard stops.

- **Ralph Claude Code** (`.ralphrc` ALLOWED_TOOLS): Circuit breaker stops after 3 loops with no progress or 5 loops with same error. Dual-condition exit prevents premature termination.
- **Multi-Agent Ralph** (`TaskCompleted` hook): 4-stage validation (correctness, quality, security, consistency) fires before task completion. 3-Fix rule: max 3 attempts before escalation.
- **Ralph Starter** (`src/loop/validation.ts`): Optional `--validate` flag runs `npm test`, `npm run lint`, `npm run build` after each iteration. Validation failures provide feedback to next iteration.
- **Smart Ralph** (`references/quality-checkpoints.md`): [VERIFY] checkpoints inserted every 2-3 tasks. Quality gates run lint, types, build. Quality commands available mid-task for manual gates.

**Evidence**: All implement validation as blocking conditions, not advisory. This is the shared pattern.

### 5. Parallel-First Execution (Multi-Agent Ralph, Ralph Orchestrator, Ralph Starter, Smart Ralph)

Multi-agent coordination is now mandatory for complexity >= 3.

- **Multi-Agent Ralph** (`.claude/rules/parallel-first.md`): Agent Teams with 6 teammates (ralph-coder, ralph-reviewer, ralph-tester, ralph-researcher, ralph-frontend, ralph-security) must run in parallel. Sequential requires documented dependency.
- **Ralph Orchestrator** (`crates/ralph-core/src/wave_detection.rs`): Waves enable single hat to process multiple items in parallel within one iteration. `concurrency > 1` spawns parallel backend instances.
- **Ralph Starter** (`src/loop/executor.ts`): Single-threaded loops for simplicity; designed for agent team delegation within the agent.
- **Smart Ralph** (`agents/task-planner.md`): Tasks marked `[P]` can run in parallel; coordinator detects and spawns them together.

**Evidence**: Multi-Agent Ralph is the most explicit; Ralph Orchestrator has waves. Single-threaded repos (Ralph Claude Code, Choo Choo Ralph) delegate parallelism to agents themselves.

## Common Patterns Across the Cluster

| Pattern | Repos | Evidence |
|---------|-------|----------|
| **Markdown-first specs** | All 6 | Research/requirements/design/tasks in `.md` files, not JSON |
| **Dual-condition exit gates** | 4/6 (RCCC, MAR, RS, SR) | EXIT_SIGNAL + completion indicators, not heuristics alone |
| **Fresh context per task** | 3/6 (MAR, RS, SR) | Obsidian vault, `.progress.md`, task state; no accumulated history |
| **Backpressure validation** | 4/6 (RCCC, MAR, RS, SR) | Tests/lint/types block completion; not advisory |
| **Parallel execution intent** | 4/6 (CCR, MAR, RO, SR) | Explicit parallel-first rule or wave system |
| **Git as state machine** | 3/6 (CCR, RCCC, RS) | Commits as progress markers; `.ralph/` directory tracks state |
| **Agent subagents** | 4/6 (MAR, RO, SR, CCR has plugins) | Specialist roles (researcher, architect, executor, etc.) |
| **Learned rules/memory** | 3/6 (CCR via PROMPT, MAR via vault, RO via JSON) | Persistent learning across sessions |

## Standout Individual Contributions

1. **Choo Choo Ralph — Git-Native Task Tracking (Beads)**
   - Uses Beads for task management instead of JSON/markdown files. Molecules define multi-step workflows with real dependencies.
   - Solves team coordination problem: Beads syncs via git, no API latency or network errors.
   - Evidence: `plugins/choo-choo-ralph/commands/pour.md` pours specs into Beads molecules with dependency graphs.
   - **Standout**: Only repo using git as distributed task queue (not just source control).

2. **Ralph Claude Code — Mature Exit Detection**
   - Most sophisticated dual-condition exit gate: JSON mode suppresses heuristics entirely; text mode requires `confidence_score >= 70 AND has_completion_signal=true`.
   - 566 tests (100% pass rate); comprehensive exit detection test suite.
   - Evidence: `lib/response_analyzer.sh` with two-stage error filtering; `ralph_loop.sh:312-327` shows EXIT_SIGNAL override logic.
   - **Standout**: Only repo with production-grade exit detection deployed at scale.

3. **Multi-Agent Ralph — Mandatory Parallelization + Memory Architecture**
   - Enforces parallel-first execution: complexity >= 3 MUST use Agent Teams; sequential execution requires documented dependency.
   - MemPalace memory (4-layer stack L0-L3) with Obsidian vault knowledge graph. 27/1003 procedural rules make it to L1_essential via filtering.
   - Anti-rationalization tables prevent agents from justifying bad decisions without first-principles analysis.
   - Evidence: `.claude/rules/parallel-first.md` (mandatory language); `docs/architecture/AAAK_LIMITATIONS_ADR_2026-04-07.md` (encoding vs selection).
   - **Standout**: Only repo making parallelism non-negotiable; only repo with documented memory limitations and filtering criteria.

4. **Ralph Orchestrator — Event-Sourced Coordination**
   - Rust-based, Hats system with event-sourcing for durable coordination. Waves enable intra-loop parallelism within a single hat.
   - Web dashboard for monitoring and managing loops. MCP server mode for integration with other tools.
   - Multi-backend support (Claude, Kiro, Gemini, Codex, Roo, etc.). RObot (Telegram) for human-in-the-loop.
   - Evidence: `crates/ralph-core/src/event_loop/` (event loop), `wave_detection.rs` (waves), `.ralph/merge-queue.jsonl` (event-sourced queue).
   - **Standout**: Only repo with production-grade web UI and multi-backend abstraction.

5. **Ralph Starter — Spec-Source Integration + Production CLI**
   - Multi-source integration (GitHub, Linear, Notion, Figma) fetches specs directly from team tools.
   - Cost tracking (token/cost per iteration) and rate limiting built in.
   - Production-ready: npm-distributed, CI/CD pipeline, MCP server mode.
   - Evidence: `src/integrations/base.ts` (8+ integrations), `src/loop/cost-tracker.ts` (token budgeting), `src/commands/run.ts` (CLI).
   - **Standout**: Only repo integrating with modern team workflow tools (Linear, Figma, Notion).

6. **Smart Ralph — Spec Scanner + Codebase Indexing**
   - Spec-scanner during research phase discovers related existing components (research-analyst finds indexed specs).
   - Codebase indexing command (`/ralph-specum:index`) auto-generates component specs for legacy code discovery.
   - Triage-analyst workflow for epic decomposition; POC-first task execution.
   - Evidence: `agents/research-analyst.md` (searches indexed specs), `commands/index.md` (component discovery), `references/triage-flow.md`.
   - **Standout**: Only repo making existing code discoverable during new feature research.

## What to Borrow / Adapt / Skip

### Borrow Directly (Proven, Portable, Low Risk)

1. **Dual-Condition Exit Detection** — Ralph Claude Code's pattern is battle-tested (566 tests, 100% pass rate).
   - Best fit: **stipe** (install/doctor/repair flows would benefit from reliable exit detection)
   - Needs septa contract: **yes** — exit gate is a cross-tool concern
   - Implementation: Adopt Ralph Claude Code's `lib/response_analyzer.sh` logic as a shared utility

2. **Backpressure Validation Gates** — All four repos prove tests/lint/build blocks work.
   - Best fit: **lamella** (skills can define validation checkpoints) or **stipe** (validation is repair logic)
   - Needs septa contract: **yes** — validation gate protocol (inputs, outputs, exit codes)
   - Implementation: Standardize on `{"continue": true/false}` response format across tools

3. **Fresh Context Per Task** — Multi-Agent Ralph and Ralph Starter prove state-file-based context beats accumulated history.
   - Best fit: **hyphae** (memory system can manage trimmed context per task)
   - Needs septa contract: **yes** — task state schema (what fields must be present)
   - Implementation: Task state files should include spec reference, progress tracker, learned lessons

### Adapt, Not Copy

1. **Memory Architecture** — Multi-Agent Ralph's 4-layer stack is sophisticated but coupled to Obsidian vault.
   - Best fit: **hyphae** (memory system owns layering and filtering)
   - Adaptation: Extract the 27/1003 high-value rule filtering as a generic algorithm; allow different storage backends (Obsidian, local files, git history)
   - Risk: Coupling to specific knowledge base tools (Obsidian) reduces portability

2. **Parallel-First Rule** — Multi-Agent Ralph's mandatory parallelization is strong but inflexible for all use cases.
   - Best fit: **canopy** (orchestration layer) with a **septa contract** defining when parallelism is required vs. optional
   - Adaptation: Make parallelism configurable per repo/team; document cost-benefit (wall-clock speedup vs. token overhead)
   - Risk: Mandates may conflict with sequential dependencies that agents miss at plan time

3. **Spec-Source Integration** — Ralph Starter's multi-source fetching is powerful but tightly coupled to CLI.
   - Best fit: **lamella** (skills can define source connectors) or **stipe** (setup wizard uses sources)
   - Adaptation: Extract integration layer as reusable functions; allow pluggable backends (GitHub, Linear, Notion, Figma, etc.)
   - Risk: Each integration requires auth; centralizing reduces security

4. **Codebase Indexing** — Smart Ralph's component discovery is innovative but specialized to spec-driven workflows.
   - Best fit: **rhizome** (code intelligence system) + **hyphae** (knowledge graph for discovered components)
   - Adaptation: Index components once at repo startup; cache in memory for research phases; make index optional
   - Risk: Indexing cost (analysis time) may not justify benefit for small codebases

5. **Hats System + Waves** (Ralph Orchestrator) — Event-sourced coordination with named specialist roles (triggers, publishes, concurrency) and intra-loop wave detection. Architecturally sound and written in Rust.
   - Best fit: **canopy** (Hats as a named specialist model for agent coordination), **hymenium** (Waves for intra-loop parallelism detection)
   - Adaptation: Extract the Hat abstraction (triggers → process → publishes) as a canopy dispatch concept; implement wave detection as hymenium's parallelism gate. Do not copy Ralph Orchestrator's full event loop wholesale — canopy owns that seam.
   - Evidence: `crates/ralph-core/src/event_loop/`, `wave_detection.rs`, `.ralph/merge-queue.jsonl`
   - Septa contract needed: **yes** — Hat protocol (trigger types, publish types, concurrency limit) as a cross-tool contract
   - Note: The prior audit incorrectly marked this as "skip" because it claimed basidiocarp was bash/Node.js. Basidiocarp is primarily Rust; Ralph Orchestrator's Rust implementation is a direct peer, not a stack mismatch.

### Skip

1. **Beads Integration** (Choo Choo Ralph) — Excellent for team workflows with distributed task tracking, but introduces hard dependency on external tool.
   - Why skip: basidiocarp manages tasks via canopy snapshots + septa contracts; Beads is a team-scale tool
   - If needed later: Beads can be adopted as an optional source in ralph-starter style integrations

2. **Obsidian Vault** (Multi-Agent Ralph) — Powerful knowledge graph, but vendor lock-in and manual setup friction.
   - Why skip: hyphae is purpose-built for basidiocarp memory; Obsidian adds distribution friction
   - Recommendation: Use hyphae as the memory layer; Obsidian is an optional downstream export

## How Each Repo Fits the Ecosystem

| Repo | Best Fit in Ecosystem | Ownership | Septa Contract? | Integration Point |
|------|----------------------|-----------|-----------------|-------------------|
| **Choo Choo Ralph** | lamella (skills/workflows) + stipe (setup) | Workflow bundles with Beads molecules | No (Beads-specific) | Optional: ralph-starter source integration |
| **Ralph Claude Code** | stipe (setup, doctor, exit detection) | Loop harness; exit detection library | **YES**: dual-condition gate protocol, response_analyzer contract | Core loop pattern; used in other repos |
| **Multi-Agent Ralph** | canopy (coordination) + hyphae (memory) | Mandatory parallelization rules; learned rules taxonomy | **YES**: parallel-first septa, memory layer filtering | Parallelization mandates; memory layer |
| **Ralph Orchestrator** | canopy (coordination) | Event-sourced coordination; Hats system; web dashboard | **YES**: Hat protocol (triggers, publishes, concurrency) | Multi-backend support; waves for future |
| **Ralph Starter** | lamella (sources, integrations, presets) + stipe (setup wizard) | Multi-source spec fetching; production CLI; cost tracking | **YES**: integration source protocol; cost tracker API | GitHub/Linear/Notion/Figma sources |
| **Smart Ralph** | lamella (skills/commands) + rhizome (code intelligence) | Spec-driven execution; codebase indexing; epic decomposition | No (spec-driven philosophy embedded in agents) | Codebase discovery; spec scanner integration |

## Final Read

The Ralph cluster is unified by a strong pattern: **specs → parallelism → validation gates → memory → repeat**. No repo stands alone; each fills a niche (git-native tasks, mature exit detection, mandatory parallelism, event-sourcing, team integration, codebase discovery).

**For basidiocarp:**

1. **Borrow Ralph Claude Code's exit detection** immediately — it's proven and portable. Adopt it as a septa contract so other tools can reuse it.

2. **Adapt Multi-Agent Ralph's parallel-first rule** as a septa contract, not a mandate. Document cost-benefit and allow opt-out for sequential workflows.

3. **Borrow Ralph Starter's integration layer** as a lamella skill. Multi-source spec fetching is powerful and decoupled from CLI.

4. **Extract Smart Ralph's codebase indexing** as a rhizome + hyphae feature. Component discovery during research is underutilized.

5. **Do not adopt** Beads (team-scale, external dependency), Obsidian (vendor lock-in), Rust orchestration (stack mismatch), or Waves (Agent Teams are sufficient).

The cluster reveals no missing ecosystem seams that justify new tools. All patterns map cleanly into existing repos (stipe, lamella, canopy, hyphae, rhizome, cortina). The next synthesis step is defining septa contracts for exit detection, parallelization, and memory layering — shared boundaries that let tools compose.

---

**Verification Context**

- **Ralph Claude Code**: v0.11.5, 566 tests, 100% pass rate; bash/shell-based loop with modern CLI
- **Multi-Agent Ralph**: v3.0.0, MemPalace v3.0, parallel-first mandatory, Obsidian vault integration
- **Ralph Orchestrator**: Rust-based, event-sourcing, Hats, Waves, web dashboard, multi-backend support
- **Ralph Starter**: npm-distributed, multi-source integrations (GitHub, Linear, Notion, Figma), cost tracking
- **Smart Ralph**: Claude Code plugin, spec-scanner, codebase indexing, epic decomposition, POC-first workflow
- **Choo Choo Ralph**: Claude Code plugin, Beads integration, git-native task tracking, compounding knowledge system

All six are active, maintained, and used in production. No evidence of abandoned patterns or deprecated approaches.
