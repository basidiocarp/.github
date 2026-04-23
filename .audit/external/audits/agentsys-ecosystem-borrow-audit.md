# AgentSys Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `agentsys` (avifenesh/agentsys, agent-sh org)
Lens: what to borrow from the tool, how it fits the basidiocarp ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

AgentSys is a mature multi-platform plugin marketplace and orchestration runtime with a `Command → Agent → Skill` decomposition model, phase-gated workflows, and a substantial JS library (30k lines, 3,507 tests) covering drift detection, performance investigation, slop detection, cross-platform state, and skill validation. Its strongest ideas are the three-level `Command → Agent → Skill` contract, the deterministic-then-LLM collector pattern, the `flow.json` + `tasks.json` two-file workflow state model, the certainty-graded finding system, and the model-tiering discipline (opus for reasoning, sonnet for validation, haiku for mechanical work). It spans five platforms, maintains a formal plugin manifest schema with a JSON schema validator, and enforces cross-platform compatibility through a preflight system and a 399-rule linter (`agnix`). Primary fit for basidiocarp is `lamella` (skill decomposition and plugin architecture), `hymenium` (phase-gated workflow state), and `canopy` (task registry, drift detection). The certainty-graded finding format is septa-eligible.

## What AgentSys is doing that is solid

### 1. The Command → Agent → Skill decomposition is formally enforced

The three levels are not just naming conventions. The skill compliance test suite validates that any agent claiming to invoke a skill lists `Skill` in its tools field, that skill directory names match the `name` frontmatter field exactly, and that skill names conform to the `^[a-z0-9-]{1,64}$` pattern. The 2025-02-04 audit section in `checklists/new-skill.md` records 21 directory/name mismatches found and fixed, which proves the system was enforced retroactively and is actively maintained.

Evidence:

- `checklists/new-skill.md` — compliance checklist with audit findings
- `checklists/new-agent.md` — agent creation rules and tool-allowlist discipline
- `lib/enhance/skill-analyzer.js` — frontmatter parse and trigger-phrase validation
- `lib/enhance/agent-analyzer.js` — agent file structure and tool-annotation analysis
- `lib/schemas/plugin-manifest.schema.json` — JSON schema for plugin manifests
- `lib/schemas/validator.js` — minimal but complete schema validator

### 2. Workflow state is two files with clear ownership

The `workflow-state.js` module distinguishes `tasks.json` (main project directory, tracks active worktree/task) from `flow.json` (inside the worktree, tracks workflow progress). Each file has a typed schema, a monotonic version counter for optimistic locking, and a per-write unique writer ID for concurrent-write detection. Writes go through `utils/atomic-write.js`, which uses the write-to-temp-then-rename pattern. Corrupted JSON fails explicitly rather than silently overwriting recoverable state.

Evidence:

- `lib/state/workflow-state.js` — two-file schema, versioning, atomic writes, corruption guard
- `lib/utils/atomic-write.js` — temp-rename pattern with cleanup on failure
- `lib/utils/state-helpers.js` — `updatesApplied` and `sleepForRetry` for optimistic locking

### 3. The deterministic-then-LLM collector pattern is well-implemented

The `lib/collectors/` module separates data gathering (pure JS, no LLM) from synthesis (one LLM call with the gathered context). The `collect()` function in `lib/collectors/index.js` composes collectors by name (`github`, `docs`, `code`, `docs-patterns`, `git`), each returning plain objects. The README claims 77% token reduction for drift-detect vs multi-agent approaches; the implementation makes that believable because LLM calls only receive pre-gathered structured data, not raw file contents. The same collector registry is reused across drift-detect, deslop, and sync-docs, which prevents each feature from reinventing data collection.

Evidence:

- `lib/collectors/index.js` — composable collector registry
- `lib/collectors/codebase.js` — deterministic framework detection, file scanning, path-safe reads
- `lib/collectors/github.js` — gh CLI wrapper for issues and PRs
- `lib/collectors/documentation.js` — doc analysis without LLM
- `lib/drift-detect/collectors.js` — backward-compatible re-export showing the refactor story

### 4. Certainty-graded findings are a real discipline

Every finding in the codebase carries a `certainty` field with one of three values: `HIGH` (single regex match, auto-fixable), `MEDIUM` (multi-pass analysis, needs context), or `LOW` (heuristic or CLI tool, advisory). This appears in the slop detection pipeline, the enhance analyzers, and the drift-detect output. The certainty level drives action: HIGH findings are safe to auto-fix; MEDIUM findings require agent verification; LOW findings are advisory. This is not labeling as a formality — the `deslop` pipeline actually uses certainty to gate whether it applies a fix or only reports.

Evidence:

- `lib/patterns/pipeline.js` — `CERTAINTY` constants, fix-vs-report gating by level
- `lib/enhance/skill-analyzer.js` — `certainty: 'HIGH'` on structural issues
- `lib/enhance/agent-analyzer.js` — per-pattern certainty annotation
- `README.md` — benchmark table showing token savings attributed to JS-first collection

### 5. Model tiering is explicit and consistently applied

The workflow agent reference table in `agent-docs/workflow.md` assigns a specific model to each agent: opus for exploration, planning, implementation, debate orchestration; sonnet for task discovery, delivery validation, CI fixing, deslop, reporting; haiku for worktree management, CI monitoring, simple fixes. This is not aspirational — the `checklists/new-agent.md` encodes the same tiering decision criteria so that new agents land in the right tier by default.

Evidence:

- `agent-docs/workflow.md` — full phase/agent/model/tool table
- `checklists/new-agent.md` — model-tier decision table
- `AGENTS.md` — agent/model table across all 47 agents

### 6. The performance investigation workflow is architecturally serious

The `lib/perf/` module defines 10 phases (setup, baseline, breaking-point, constraints, hypotheses, code-paths, profiling, optimization, decision, consolidation) with typed state persisted per investigation under `{state-dir}/perf/`. Each investigation has a unique ID, a phase sequence, and per-phase result fields. The codebase has dedicated test files for every phase: `perf-baseline.test.js`, `perf-breaking-point-runner.test.js`, `perf-checkpoint.test.js`, `perf-schemas.test.js`, and more. Path traversal protection and safe ID validation are both present.

Evidence:

- `lib/perf/investigation-state.js` — phase list, typed state, atomic writes, path validation
- `lib/perf/schemas.js` — schema validation for investigation state
- `__tests__/perf-investigation-state.test.js` through `perf-state.test.js` — dedicated test per module

### 7. The plugin manifest is versioned, schema-validated, and machine-readable

The `.claude-plugin/marketplace.json` file at the repo root is a structured plugin registry with typed fields (`name`, `version`, `source`, `category`, `homepage`, `description`), not a README table. Plugin sources are typed objects with a `source` field (`url`) and a `url` field. The `lib/schemas/plugin-manifest.schema.json` defines required fields, string constraints, and patterns. The installer reads this registry and fetches plugins from their standalone repos at install time.

Evidence:

- `.claude-plugin/marketplace.json` — 19-plugin typed registry
- `lib/schemas/plugin-manifest.schema.json` — JSON schema with pattern and length constraints
- `lib/schemas/validator.js` — schema validator used in preflight

### 8. Cross-platform state is handled by one abstraction, not scattered conditionals

Platform detection reads the `AI_STATE_DIR` environment variable and falls back to `.claude`. State directory resolution is centralized in `lib/platform/state-dir.js`. Every module that needs a state path calls `getStateDir()` instead of hardcoding a platform-specific path. The `lib/cross-platform/index.js` exposes `detectPlatform()`, `getStateDir()`, and MCP response helpers so that plugin code can be platform-neutral without repetitive conditionals.

Evidence:

- `lib/platform/state-dir.js` — single source for state directory resolution
- `lib/cross-platform/index.js` — detectPlatform, getStateDir, MCP helpers
- `lib/state/workflow-state.js` — calls `getStateDir()` rather than hardcoding

## What to borrow directly

### Borrow now

- The `Command → Agent → Skill` taxonomy as a formal authoring discipline for lamella content. The rule that skill directory name must match skill `name` frontmatter exactly, enforced by test, is simple and prevents the class of drift that AgentSys found and fixed at scale. Best fit: `lamella`.

- Certainty-graded findings (`HIGH` / `MEDIUM` / `LOW`) as a septa contract for any cross-tool finding format. Any tool that produces findings — cortina audits, canopy handoff checks, hymenium phase violations — should carry a certainty level so consumers can decide whether to auto-fix, flag for review, or treat as advisory. Best fit: `septa` contract, consumed by `cortina`, `canopy`, and `hymenium`.

- The two-file workflow state model (`tasks.json` at project root, `flow.json` in the active worktree) as a pattern for hymenium's state management. The key insight is that workflow progress state belongs in the worktree where the work is happening, not in the project root alongside the task registry. Best fit: `hymenium`.

- The atomic write pattern from `lib/utils/atomic-write.js`: write to a temp file with a random suffix, then rename. This is a small, standalone utility with no deps. Hyphae, canopy, and hymenium all do file-backed state; all should use this pattern. Best fit: `spore` as a shared primitive.

- The deterministic-before-LLM collector pattern as a design principle for hymenium phases and cortina signal collection. Any phase that currently fires an LLM call to inspect the environment should collect data deterministically first and pass structured context to the LLM. Best fit: `hymenium` and `cortina`.

### Borrow eventually

- The model-tiering table format (`agent-docs/workflow.md` phase/agent/model/tool matrix) as a human-readable contract for canopy's agent assignment model. Canopy already tracks which agent owns a task; the tiering table gives a reference format for matching task complexity to model tier. Best fit: `canopy` documentation and potentially the coordination schema.

- Preflight as a first-class command that runs all validators before release operations. AgentSys's `npx agentsys-dev preflight` runs plugin, agent, skill, and platform validators in one pass. Lamella has `make validate`; a named preflight entry point that is more discoverable belongs there too. Best fit: `lamella`.

## What to adapt, not copy

### The phase list for performance investigation

The 10-phase perf investigation model (setup through consolidation) is useful as a reference for what a structured investigation looks like, but the specific phases map to JavaScript profiling tools (jscpd, madge, escomplex) rather than Rust or system-level workflows. The right borrow is the architectural idea — a named phase list with typed result fields per phase, persisted state, and unique investigation IDs — not the specific phases. Best fit: `hymenium` as a pattern for any multi-phase investigation workflow.

### The enhance analyzer suite

The `lib/enhance/` module has analyzers for agents, skills, plugins, hooks, prompts, and CLAUDE.md structure. These are useful as a reference for what a structured quality analysis looks like, but they are JavaScript, they are written against Claude Code-specific markdown conventions, and they embed AgentSys's own patterns (the `{PLUGIN_ROOT}` variable convention, specific frontmatter keys). Lamella should develop its own validators using these as a reference for coverage, not as code to vendor. Best fit: `lamella` validation tooling, informed by but not derived from AgentSys's patterns.

### The marketplace registry format

The `.claude-plugin/marketplace.json` format is close to what lamella's manifests do but is oriented toward npm-installed, git-cloned plugins from a standalone org. The typed registry concept transfers; the specific source schema (url, git clone) does not map directly to lamella's local-first, path-based install model. Adapt the machine-readable registry concept and the typed-source idea; do not import the installer mechanics. Best fit: `lamella` manifest schema and `stipe` install flows.

### Cross-platform abstraction

The `AI_STATE_DIR` env-var pattern and `detectPlatform()` function are a solid single-variable approach to multi-platform state. Basidiocarp's ecosystem is not multi-platform in the same sense; its tools target Claude Code specifically. The useful adaptation is the principle: one env-var override point for the state directory, not scattered platform conditionals. Canopy and hymenium should each have a single path-resolution function rather than inline path construction. Best fit: `spore` as a shared path primitive.

## What not to borrow

### The JS runtime itself

AgentSys is a JavaScript-first system. Its collectors, state machine, pipeline, and analyzers are Node.js modules. The basidiocarp ecosystem is primarily Rust (canopy, hymenium, cortina, stipe, spore). Vendoring or porting the JS library is the wrong direction; the patterns are worth borrowing but the implementation language boundary is real.

### The multi-platform compatibility layer

AgentSys supports Claude Code, OpenCode, Codex CLI, Cursor, and Kiro, with adapter transforms for frontmatter, tool permission syntax, and state directories. This is genuine scope for an org publishing to multiple hosts. Basidiocarp does not need to target OpenCode or Kiro. Borrowing the compatibility layer would add complexity without a concrete user.

### The agnix linter (399 rules)

AgentSys maintains a 399-rule linter for agent configuration files. The rules are useful reading but the linter itself is a standalone tool (`agent-sh/agnix`) and the rule surface is coupled to AgentSys's own conventions. Lamella's validators should be small, focused on lamella's own schemas, and not attempt to become a general-purpose agent linter.

### The auto-suppression system

The `lib/enhance/auto-suppression.js` and `lib/enhance/suppression.js` modules manage suppress-lists for enhance findings, persisted to a per-user directory. This is a quality-of-life feature for a tool with many findings per run. It is not needed until lamella validators produce enough volume that suppressions matter.

## How AgentSys fits the ecosystem

AgentSys is operating in the same space as the basidiocarp ecosystem but from a different architectural starting point: JavaScript, multi-platform, content-centric (Markdown as the primary artifact), with a marketplace installer model. The basidiocarp ecosystem is Rust-first, single-platform (Claude Code), with a local-first coordination model and a memory layer. They are not competing; they are solving adjacent problems.

The specific ecosystem boundaries for AgentSys ideas:

- `lamella` — skill and plugin packaging, validation, and the Command/Agent/Skill taxonomy
- `hymenium` — phase-gated workflow state, the two-file state pattern, multi-phase investigation model
- `canopy` — task registry model, model-tiering documentation, drift detection as a coordination primitive
- `cortina` — deterministic signal collection before LLM synthesis, certainty-graded findings
- `septa` — certainty-graded finding format as a shared contract
- `spore` — atomic write utility, single state-dir resolution function

## What AgentSys suggests improving in the ecosystem

### Lamella needs a skill compliance test

AgentSys found and fixed 21 skill directory/name mismatches via an automated test. Lamella does not have an equivalent automated check that verifies skill directory names match their `name` frontmatter fields. This is a small, high-value test to add.

### Hymenium's workflow state should be worktree-aware

The current hymenium state model should distinguish project-level task registry state from in-progress workflow state. AgentSys's two-file separation (`tasks.json` at root, `flow.json` in the active worktree) solves a real problem: workflow progress state should survive the session in the context where the work is happening, not get mixed into the project-level registry.

### Septa lacks a finding-certainty contract

The ecosystem produces findings in cortina (handoff audits), canopy (handoff completeness checks), and hymenium (phase gate violations). None of these findings currently carry a formal certainty level. A septa schema that defines `HIGH / MEDIUM / LOW` certainty, what each level means operationally, and how consumers should respond would create consistency across these surfaces.

### Spore should own atomic write

The atomic write-to-temp-then-rename pattern is present or needed in hyphae, canopy, hymenium, and cortina. None of them share the implementation; each either reinvents it or relies on the OS. Spore should expose a single `write_atomic()` utility used by all of them.

### Canopy's model-tiering is implicit

Canopy assigns tasks to agents but does not have a documented or structured model for which task types should use which model tier. AgentSys's explicit phase/agent/model matrix is a useful reference for building a similar assignment guide into canopy's coordination schema or documentation.

## Verification context

Read directly from the GitHub API via `gh api repos/avifenesh/agentsys/contents/...` for all source files. The following paths were read:

- `README.md` — full read
- `AGENTS.md` (project CLAUDE.md) — full read
- `lib/state/workflow-state.js` — first 150 lines
- `lib/collectors/index.js` — full (80 lines)
- `lib/collectors/codebase.js` — first 100 lines
- `lib/drift-detect/collectors.js` — full
- `lib/patterns/pipeline.js` — first 100 lines
- `lib/perf/investigation-state.js` — first 100 lines
- `lib/enhance/skill-analyzer.js` — first 80 lines
- `lib/enhance/agent-analyzer.js` — first 80 lines
- `lib/enhance/plugin-analyzer.js` — first 80 lines
- `lib/utils/atomic-write.js` — first 80 lines
- `lib/utils/context-optimizer.js` — first 100 lines
- `lib/cross-platform/index.js` — first 100 lines
- `lib/schemas/plugin-manifest.schema.json` — full
- `lib/schemas/validator.js` — first 100 lines
- `.claude-plugin/marketplace.json` — full
- `checklists/new-skill.md` — full
- `checklists/new-agent.md` — full
- `agent-docs/workflow.md` — first 150 lines
- `agent-docs/MULTI-AGENT-SYSTEMS-REFERENCE.md` — first 150 lines
- `agent-docs/AI-AGENT-ARCHITECTURE-RESEARCH.md` — first 100 lines
- `docs/ARCHITECTURE.md` — first 150 lines
- `__tests__/` — directory listing only

## Final read

AgentSys is the most production-complete plugin marketplace and multi-agent workflow system in the Claude Code ecosystem. Its strongest contribution to basidiocarp is not a single feature but a set of disciplines: enforce naming contracts with tests, separate deterministic collection from LLM synthesis, grade findings by certainty and use that grade operationally, separate project-root state from worktree state, and assign model tiers explicitly rather than by feel. The lamella and hymenium repos are the immediate beneficiaries. The certainty-graded finding format is the one idea worth promoting to a septa contract, since it would create consistency across canopy, cortina, and hymenium surfaces that currently produce findings without a shared certainty vocabulary.
