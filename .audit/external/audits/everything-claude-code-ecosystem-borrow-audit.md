# Everything Claude Code Ecosystem Borrow Audit

Date: 2026-04-14
Repo reviewed: `everything-claude-code` (ecc-universal v1.10.0, by Affaan Mustafa / ecc.tools)
Lens: what to borrow from the tool, how it fits the `basidiocarp` ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

`everything-claude-code` is a massive multi-harness plugin packaging 47 agents, 181 skills, 79 commands, and a selective-install system that targets Claude Code, Codex, Cursor, Gemini, OpenCode, and CodeBuddy from a single canonical source tree. Its real value is in three areas: the selective-install architecture with schema-validated manifests, dependency expansion, and SQLite state tracking; the cross-agent translation pattern where one canonical skill set is structurally adapted per target at install time (rename transforms, tool name rewriting, prompt wrapper generation); and a handful of genuinely reusable skill designs, especially the agent-introspection-debugging loop, the verification-loop quality gate, and the strategic-compact compaction timing table. The TkInter dashboard is sketch-grade. An alpha Rust TUI (`ecc2`) has a 4-axis risk scoring model for tool calls that is worth reading. The strongest ecosystem matches are `lamella` (skill authoring patterns, cross-agent packaging, install manifests), `stipe` (install state, doctor/repair flow, selective profiles), and `cortina` (hook profile gating with env-var disable).

## What Everything Claude Code is doing that is solid

### 1. Selective-install with schema-validated manifests and dependency expansion

The install pipeline (`scripts/install-apply.js` → `install-manifests.js` → `install-executor.js` → `install-state.js`) uses typed module prefixes (`baseline:`, `lang:`, `framework:`, `capability:`, `agent:`, `skill:`) with JSON Schema validation via AJV. Profiles compose modules, modules declare dependencies, and the executor expands the dependency graph before materializing file copies. Install state is tracked in SQLite via `sql.js`, enabling doctor, repair, and uninstall to reason about what ECC owns versus what the user added. The `ecc` CLI surfaces: install, plan, catalog, list-installed, doctor, repair, status, sessions, session-inspect, uninstall.

Evidence:

- `scripts/install-apply.js`
- `scripts/lib/install-manifests.js`
- `scripts/lib/install-state.js`
- `manifests/install-modules.json`, `manifests/install-profiles.json`
- `schemas/`
- `docs/SELECTIVE-INSTALL-ARCHITECTURE.md`

### 2. Cross-agent install targets with structural adaptation

Seven agent targets (Claude, Codex, Cursor, Gemini, OpenCode, CodeBuddy, Antigravity) each have a per-target adapter in `scripts/lib/install-targets/`. Content is not semantically translated — the same Markdown prose ships everywhere — but structural adaptation happens at install time: Cursor gets `.md` → `.mdc` renames with namespace flattening; Gemini gets tool-name rewriting (`Read` → `read_file`, `Bash` → `run_shell_command`); Codex gets prompt wrapper generation with YAML frontmatter stripping. A `PLATFORM_SOURCE_PATH_OWNERS` map prevents cross-contamination (Cursor source cannot be installed into the Codex target).

Evidence:

- `scripts/lib/install-targets/helpers.js:5` — platform ownership map
- `scripts/lib/install-targets/cursor-project.js` — rename transform
- `scripts/gemini-adapt-agents.js` — tool name translation
- `scripts/sync-ecc-to-codex.sh` — Codex prompt generation and MCP merge

### 3. Hook profile gating with env-var disable

Hooks are JSON-registered via `hooks/hooks.json` with a `run-with-flags.js` wrapper. Runtime gating uses `ECC_HOOK_PROFILE` to select a hook set and `ECC_DISABLED_HOOKS` to disable individual hooks by name. Blocking hooks (PreToolUse, Stop) must be under 200ms with no network calls. Async hooks get a 30s timeout. All hooks must exit 0 on non-critical errors.

Evidence:

- `WORKING-CONTEXT.md:125-144`
- `.agents/skills/strategic-compact/SKILL.md:42-52` (hook JSON example)

### 4. Agent introspection debugging skill

A four-phase self-debugging loop: Failure Capture → Root-Cause Diagnosis → Contained Recovery → Introspection Report. The failure-pattern table classifies: loop detection, context overflow, 429 rate limit, and stale diff. Each pattern has a named recovery action. This is the most architecturally novel skill in the repo — it addresses meta-level agent self-management, not object-level coding tasks.

Evidence:

- `.agents/skills/agent-introspection-debugging/SKILL.md`

### 5. Verification loop quality gate

A six-phase quality gate: build → types → lint → tests → security scan → diff review. Produces a structured VERIFICATION REPORT with per-phase pass/fail. The gate is designed as a composable skill that other skills invoke as a completion check.

Evidence:

- `.agents/skills/verification-loop/SKILL.md`

### 6. Strategic compact timing skill

A compaction-timing decision table that tells the agent when to compact context based on usage percentage, message count, and active file count. The table is directly usable as a lamella skill — it solves the "when should I compact?" problem that every long-running agent session faces.

Evidence:

- `.agents/skills/strategic-compact/SKILL.md`

### 7. Claude plugin validator documentation

`PLUGIN_SCHEMA_NOTES.md` documents undocumented Claude Code plugin validator constraints, anti-patterns, and a hooks registration flip-flop across 4 Claude Code releases. This is tribal knowledge not available elsewhere, and it documents real gotchas that any plugin author will hit.

Evidence:

- `.claude-plugin/PLUGIN_SCHEMA_NOTES.md`

### 8. Tool call risk scoring (ecc2 alpha)

The alpha Rust TUI (`ecc2`) includes a 4-axis risk scoring model for tool calls: base tool risk, file sensitivity, blast radius, and irreversibility. The composite score (0.0–1.0) produces Allow/Review/Block recommendations. The model is well-typed and testable, though the TUI around it is incomplete.

Evidence:

- `ecc2/src/observability/`
- `research/ecc2-codebase-analysis.md`

### 9. Skill authoring conventions

Every skill is a `SKILL.md` with YAML frontmatter (`name`, `description`, `origin`). Body follows a phase model: When to Activate → How It Works (numbered phases) → code examples → checklists → handoff pointers to related skills. The convention is consistent across 181 skills and produces self-contained workflow documents that work as system-prompt injections.

Evidence:

- `.agents/skills/tdd-workflow/SKILL.md`
- `.agents/skills/security-review/SKILL.md`
- `RULES.md` (authoring contract)

### 10. Agent sort and install classification

The `agent-sort` skill uses actual repo `grep` evidence to classify an ECC install as DAILY (actively used skills) versus LIBRARY (reference collection). The evidence-based classification is the interesting part — it makes install recommendations based on observed usage, not self-reported preferences.

Evidence:

- `.agents/skills/agent-sort/SKILL.md`

## What to borrow directly

### Borrow now

- Skill authoring convention: YAML frontmatter + phased workflow body + When to Activate section + handoff pointers to related skills.
  Best fit: `lamella`. The convention is more structured than lamella's current skill format and produces consistently usable system-prompt injections across 181 skills.

- Strategic compact timing table as a lamella skill or cortina hook input.
  Best fit: `lamella`. The decision table (when to compact based on usage %, message count, active files) is directly usable and solves a universal agent session problem.

- Verification loop as a lamella skill template.
  Best fit: `lamella`. The six-phase quality gate is composable and reusable across projects.

- Agent introspection debugging as a lamella skill template.
  Best fit: `lamella`. The failure-pattern table (loop, overflow, 429, stale diff) with named recovery actions is the most novel skill in the repo and has no lamella equivalent.

- Claude plugin validator documentation.
  Best fit: `lamella` (docs or reference). The gotchas about directory-vs-file paths, hooks flip-flop, and validator constraints are directly useful for lamella's plugin packaging.

## What to adapt, not copy

### Adapt

- Selective-install with schema-validated manifests and dependency expansion.
  Adaptation: the module/profile/dependency model is right. `stipe` already has install profiles; adapt the schema-validated manifest approach and the dependency expansion logic. The SQLite install-state tracking is heavier than stipe needs — adapt the concept (track what the installer owns) without importing `sql.js`.
  Best fit: `stipe`.

- Cross-agent install targets with structural adaptation.
  Adaptation: the per-target adapter pattern (Cursor rename, Gemini tool rewrite, Codex prompt wrapper) is the right architecture for lamella's cross-agent packaging. Adapt the adapter registry design, not the JavaScript implementation. The `PLATFORM_SOURCE_PATH_OWNERS` cross-contamination guard is directly borrowable as a concept.
  Best fit: `lamella`.

- Hook profile gating with env-var disable.
  Adaptation: `ECC_HOOK_PROFILE` and `ECC_DISABLED_HOOKS` are the same pattern as caveman's hook disable. Adapt the profile concept (set of hooks activated together) into cortina's config, not as env vars but as config-driven profiles.
  Best fit: `cortina`. (Reinforces handoff #123.)

- Tool call risk scoring model (4-axis).
  Adaptation: the risk axes (base tool risk, file sensitivity, blast radius, irreversibility) are a good taxonomy for what cortina or volva should use to classify tool calls. Adapt the scoring model as a Rust trait, not as the incomplete ecc2 TUI.
  Best fit: `cortina` for classification, `volva` for enforcement.

- Evidence-based install classification (agent-sort).
  Adaptation: the idea of classifying an installation as DAILY vs LIBRARY based on `grep` evidence is interesting for stipe's doctor flow — it could report which installed tools are actually being used. Adapt the concept, not the grep-based implementation.
  Best fit: `stipe`.

## What not to borrow

### Skip

- The TkInter dashboard (`ecc_dashboard.py`).
  Sketch-grade with bare `except: pass` on every file read. Cap is the right dashboard surface for the ecosystem and does not benefit from a TkInter reference.

- The ecc2 Rust TUI beyond the risk scoring model.
  The session management, TUI rendering, and inter-agent comms are incomplete. The risk scoring model is the only extractable value.

- Project-specific skills (Solana, Exa, fal.ai, X API, investor-outreach, video-editing).
  Domain-specific to the repo author's stack with no ecosystem relevance.

- The Python LLM provider abstraction (`src/llm/`).
  A standalone Python multi-provider library (Claude, OpenAI, Ollama) disconnected from the install system. The ecosystem uses Rust; the abstraction design is standard and adds no novel value.

- The GITAGENT export manifest (`agent.yaml`).
  Aspirational format at `spec_version: "0.1.0"`. Worth watching but not borrowable today.

- Per-language cursor rules (45 thin `.mdc` files).
  Redundant with the fuller skill content. The rules are 10-30 lines each and mostly point back to skills rather than encoding guidance.

- The 22 MCP server template configs (`mcp-configs/mcp-servers.json`).
  Template configurations with placeholder credentials. No novel configuration patterns.

## How Everything Claude Code fits the ecosystem

### Best fit by repo

- `lamella`
  Strongest overall fit. The skill authoring convention (YAML frontmatter + phased workflows), the cross-agent adapter pattern (one canonical source with per-target structural adaptation), the verification loop and strategic compact skills, the agent introspection debugging skill, and the plugin validator documentation all land here. ECC is the closest external reference for what lamella is building.

- `stipe`
  Strong fit for the selective-install manifest architecture (typed modules, profiles, dependency expansion), install-state tracking, and the doctor/repair/uninstall flow built on top of state. Also fits for evidence-based install classification (which tools are actively used?).

- `cortina`
  Strong fit for hook profile gating and per-hook env-var disable. Reinforces caveman and oh-my-openagent findings already captured in handoff #123. The tool call risk scoring taxonomy (base risk, file sensitivity, blast radius, irreversibility) is a new contribution from ecc2.

- `volva`
  Moderate fit for tool call risk enforcement (the Allow/Review/Block recommendation from ecc2's 4-axis model). The session lifecycle state machine in ecc2 (`Pending → Running → Completed/Failed/Stopped`) is standard and already covered by volva's existing design.

- `canopy`
  Weak fit. ECC is a plugin distribution system, not a multi-agent coordination runtime. The inter-agent comms in ecc2 are architecturally present but not functional.

- `hyphae`
  Weak fit. ECC has no memory or retrieval layer. The `WORKING-CONTEXT.md` file is an interesting manual analog to hyphae's session memory, but the pattern is already understood.

- `cap`
  Weak fit. The TkInter dashboard is not a reference. The Rust TUI is incomplete.

- `hymenium`, `rhizome`, `mycelium`, `spore`, `annulus`
  No meaningful fit.

## What Everything Claude Code suggests improving in your ecosystem

### 1. Lamella needs a structured skill authoring convention

ECC's 181 skills follow a consistent format: YAML frontmatter, When to Activate section, phased workflow body, code examples, checklists, and handoff pointers to related skills. Lamella skills lack this level of structural consistency. Adopting a documented skill format — informed by ECC's convention and by autoresearch's program.md finding — would make lamella skills more composable and more reliably useful as system-prompt injections.

### 2. Lamella needs cross-agent install adapters

ECC demonstrates that the same skill content can be structurally adapted for 7 different agent targets at install time. Lamella currently packages for Claude Code primarily. Adding per-target adapters (with rename transforms for Cursor, tool name rewriting for Gemini, prompt wrapper generation for Codex) would make lamella skills portable across the agents the ecosystem supports.

### 3. Stipe install manifests should be schema-validated

ECC validates its install manifests against JSON Schema at CI time and at install time. Stipe's install profiles are code-defined but not schema-validated. Adding schema validation to stipe's tool registry and install profiles would catch drift earlier and make the install surface more reliable.

### 4. Cortina should classify tool call risk

ECC's ecc2 alpha has a 4-axis risk scoring model (base tool risk, file sensitivity, blast radius, irreversibility) that produces Allow/Review/Block recommendations. Cortina captures lifecycle signals but does not classify tool calls by risk level. Adding risk classification would let cortina emit richer signals and let volva enforce risk-based policies.

### 5. Lamella should ship agent introspection and strategic compact skills

Two ECC skills have no lamella equivalent and address universal agent problems: the agent-introspection-debugging loop (self-repair when the agent gets stuck in loops, hits context overflow, or encounters stale diffs) and the strategic-compact timing table (when to compact based on usage metrics). Both are directly shippable as lamella skills with ecosystem adaptation.

### 6. Document Claude plugin validator constraints

The `.claude-plugin/PLUGIN_SCHEMA_NOTES.md` documents undocumented validator gotchas that lamella's plugin packaging will encounter: directory-vs-file path requirements, hooks registration flip-flop across Claude Code releases, and minimal known-good examples. This tribal knowledge should be captured in lamella's documentation.

## Verification context

This audit was based on source inspection of the installed ECC v1.10.0 checkout. No `npm install`, `npm test`, or `ecc install` was run. The install pipeline, manifests, schemas, skills, hooks, and ecc2 Rust source were read directly. The Python dashboard was read but not executed.

## Final read

Borrow: skill authoring convention (YAML frontmatter + phased workflow), strategic compact timing table, verification loop quality gate, agent introspection debugging loop, and Claude plugin validator documentation. All land in `lamella`.

Adapt: selective-install manifests with schema validation into `stipe`; cross-agent install adapters with structural adaptation into `lamella`; hook profile gating into `cortina`; tool call risk scoring taxonomy into `cortina`/`volva`.

Skip: the TkInter dashboard, the incomplete ecc2 TUI (except risk scoring), project-specific skills, the Python LLM provider library, the GITAGENT manifest, thin Cursor rules, and MCP template configs.
