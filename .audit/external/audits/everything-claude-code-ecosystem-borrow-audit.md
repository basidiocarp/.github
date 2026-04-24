# Everything Claude Code Ecosystem Borrow Audit

Re-audit Date: 2026-04-23, Original audit: 2026-04-14 (v1.10.0)
Repo reviewed: `everything-claude-code` (ecc-universal, HEAD main branch ~250 commits past v1.10.0, by Affaan Mustafa / ecc.tools)
Lens: what has changed since v1.10.0, updated borrow/adapt/skip verdicts, and new items that landed after the original audit

## One-paragraph read

The latest public release remains v1.10.0 (2026-04-05), but main is 250 commits ahead. Post-release activity has been almost entirely ecc2 maturation and harness expansion. The Rust TUI has grown from a 74-line stub to over 40,000 lines of production-grade Rust: multi-agent session management with worktree isolation, a full merge/rebase/staging UI, shared context graph, memory connectors (JSONL/Markdown/dotenv), persistent task scheduling, budget enforcement, OTel export, and desktop notifications. The risk scoring model from the original audit is now tested, configurable, and wired into session storage. Agent and skill counts grew from 47/181 to 48/183. The genuinely new items worth attention for basidiocarp are: (1) GateGuard — a fact-forcing PreToolUse hook with A/B evidence showing +2.25 point quality improvement; (2) two new agent targets (Kiro, Trae), bringing the total to 9; (3) the Council skill for structured multi-agent deliberation; (4) the code-tour skill for guided codebase walkthroughs; (5) the continuous-learning-v2 shift from probabilistic skill activation to 100%-deterministic hook-based observation; and (6) the Hermes operator shell as a documented pattern for treating a personal automation workspace as workflow input to a canonical public system. The TkInter dashboard has received a proper GUI rewrite with dark mode. ecc2 is now a serious multi-agent control-plane candidate, not just a risk-scoring module.

## What has changed since v1.10.0

### Version

The latest tagged release is still **v1.10.0** (2026-04-05). Main is 250 commits ahead with no new tag as of 2026-04-23. The VERSION file reads `1.10.0`. All changes described below are on the unreleased HEAD.

---

### 1. Selective-install with schema-validated manifests and dependency expansion — unchanged from prior audit

The install pipeline architecture is unchanged. `install-apply.js`, `install-manifests.js`, `install-executor.js`, and `install-state.js` remain the core. The manifests themselves have grown (new agents and skills) but the structural design is the same. The only notable change is a bug fix removing an unsupported `agents` field from the plugin manifest schema (`fix: remove unsupported agents manifest field in plugin JSON`) — the schema contract tightened slightly. The `docs/capability-surface-selection.md` document was added to guide users through module selection, which is useful reading for stipe's profile-selection UX.

---

### 2. Cross-agent install targets — expanded from 7 to 9 targets

The original audit identified 7 targets (Claude, Codex, Cursor, Gemini, OpenCode, CodeBuddy, Antigravity). Two new targets were added post-v1.10.0:

- **Kiro**: New `.kiro/` directory. Targets both the Kiro IDE graphical interface (Markdown agent files + JSON hooks) and the Kiro CLI (JSON agent configs). Uses a non-destructive install that leaves existing files untouched. Kiro's agent surface uses 16 specialized assistants with defined tool configurations. This is structurally equivalent to the existing Cursor/OpenCode adapters — file placement and format adaptation, not semantic translation.

- **Trae**: New `.trae/` directory. Targets the Trae IDE with a similar adapter pattern.

Additionally, the `HarnessKind` enum in ecc2 now enumerates 10 harness types: Claude, Codex, OpenCode, Gemini, Cursor, Kiro, Trae, Zed, FactoryDroid, Windsurf. This is the definitive list of supported targets and shows active expansion beyond the OSS adapter directories.

The `PLATFORM_SOURCE_PATH_OWNERS` cross-contamination guard pattern is unchanged.

Evidence:
- `.kiro/` directory in repo root
- `ecc2/src/session/mod.rs` — `HarnessKind` enum

---

### 3. Hook profile gating — unchanged, plus new hooks

The `ECC_HOOK_PROFILE` / `ECC_DISABLED_HOOKS` gating from v1.10.0 is unchanged. The post-v1.10.0 commits added several new hooks registered in `hooks/hooks.json`:

- `pre:edit-write:gateguard-fact-force` (PreToolUse) — the new GateGuard hook; see section 9 below
- `post:session-activity-tracker` (PostToolUse) — tracks tool calls and file activity per session
- `stop:desktop-notify` (Stop) — sends desktop notifications at session end
- `session:end:marker` (SessionEnd) — lifecycle end marker

One hook was removed: the `insaits-security-monitor` Python hook and its JS wrapper were deleted. The block-no-verify hook was routed through the `pre:bash:dispatcher` rather than as a standalone hook.

There was also a significant Windows bug fix: Claude Code v2.1.116 introduced an argv-dup bug on Windows where `bash.exe` received itself as a script argument due to path-with-spaces argument splitting. ECC added a workaround and shipped `docs/fixes/HOOK-FIX-20260421.md` with apply scripts. This is platform-validator-level knowledge useful for lamella's Windows hook packaging.

---

### 4. Agent introspection debugging skill — unchanged from prior audit

The four-phase loop (Failure Capture → Root-Cause Diagnosis → Contained Recovery → Introspection Report) is present at both `.agents/skills/agent-introspection-debugging/SKILL.md` and `skills/agent-introspection-debugging/SKILL.md`. No substantive changes since the original audit.

---

### 5. Verification loop quality gate — unchanged from prior audit

The six-phase quality gate is present at `skills/verification-loop/SKILL.md`. No substantive changes.

---

### 6. Strategic compact timing skill — unchanged from prior audit

The compaction-timing decision table is present at `skills/strategic-compact/SKILL.md`. No substantive changes.

---

### 7. Claude plugin validator documentation — updated

`PLUGIN_SCHEMA_NOTES.md` received a significant edit (18 additions, 45 deletions — net shrink from condensation). The unsupported `agents` field was documented as a validator anti-pattern and removed from the plugin JSON. The notes were also updated to reflect the Claude Code plugin identifier rename from `ecc` to `everything-claude-code`. These are live validator constraint updates, not aspirational documentation.

---

### 8. Tool call risk scoring (ecc2) — significantly matured

The 4-axis risk model from the original audit is now a tested, configured, and wired component, not an isolated module.

Risk axes are unchanged: base tool risk, file sensitivity, blast radius, irreversibility. Score thresholds are now explicit constants in `Config::RISK_THRESHOLDS`: `review: 0.35`, `confirm: 0.60`, `block: 0.85`. The `SuggestedAction` enum now has four values: `Allow`, `Review`, `RequireConfirmation`, `Block`. The function is fully unit-tested with cases for sensitive file detection, blast radius, irreversible commands, and combined high-risk operation blocking.

The scoring is wired to `ToolCallEvent` storage in SQLite via `ToolLogger` with paginated query support. The model is configurable through TOML config (`RiskThresholds` struct, overridable per-project).

Evidence:
- `ecc2/src/observability/mod.rs` — `compute_risk`, `RiskAssessment`, `SuggestedAction`
- `ecc2/src/config/mod.rs` — `RiskThresholds`, default constants

---

### 9. GateGuard — NEW since v1.10.0

This is the most significant new skill and hook added since v1.10.0. GateGuard is a PreToolUse hook that enforces a three-stage investigation gate before any Edit, Write, MultiEdit, or destructive Bash operation.

The core insight (validated with A/B evidence): LLM self-evaluation ("did you violate any policies?") produces useless answers. Forcing investigation ("list every file that imports this module") causes the model to actually run Grep and Read, and the act of investigation itself creates the context that self-evaluation never generates. Two independent tests showed +2.25 points average quality improvement (9.0 vs 6.75/10).

The three-stage state machine:
1. DENY — block the first Edit/Write/Bash attempt
2. FORCE — specify exactly which facts to gather (importers, affected public APIs, data schemas, verbatim user instruction)
3. ALLOW — permit retry once facts are presented; session state persists for 30 minutes

Per-gate type implementations:
- Edit/MultiEdit gate: demands import map (grep), affected public APIs, data schema details, verbatim instruction
- Write gate: requires caller identification, uniqueness verification (glob), schema confirmation
- Destructive Bash gate: triggers on `rm -rf`, `git reset --hard`, `drop table`, etc. — requires targets list and rollback procedure; fires every time
- Routine Bash gate: once-per-session verification of command purpose; read-only git operations bypass

The hook implementation is `scripts/hooks/gateguard-fact-force.js` (415 lines). There is also a `skills/gateguard/SKILL.md` (full skill document). The skill is in `manifests/install-modules.json` as an installable module.

Fit for basidiocarp: strong fit for `cortina`. This is exactly the kind of PreToolUse signal-before-action pattern that cortina is positioned to implement. The specific gate type implementations (per-tool-per-file state, destructive vs routine bash distinction) are directly borrowable as design patterns. The evidence-based framing (A/B test numbers) is unusually credible.

Evidence:
- `skills/gateguard/SKILL.md`
- `scripts/hooks/gateguard-fact-force.js`

---

### 10. Council skill — NEW since v1.10.0

A structured multi-agent deliberation pattern for ambiguous decisions. Four voices: Architect (self), Skeptic, Pragmatist, Critic. The pattern specifically uses fresh subagent instances with only the question and context — not the full conversation — as an anti-anchoring mechanism.

The workflow: extract the decision into one explicit question → gather minimal context → state initial position → launch three independent subagents in parallel → synthesize positions → present compact verdict showing where voices align/conflict.

Fit for basidiocarp: moderate fit for `canopy`. Canopy now has a DAG task graph; Council is a deliberation pattern that could run as a task graph node for architecture decisions. The anti-anchoring mechanism (context isolation per subagent) is particularly relevant for canopy's agent spawn model.

Evidence:
- `skills/council/SKILL.md`

---

### 11. Code-tour skill — NEW since v1.10.0

Generates CodeTour `.tour` files — JSON artifacts that anchor to specific files and line numbers for guided codebase navigation. The workflow: discover repo structure → infer reader persona (new-joiner, architect, PR-reviewer) → verify all anchors exist → compose narrative-driven step sequence (5–18 steps by persona).

Each step follows the SMIG principle: situation, mechanism, implication, gotcha. The skill explicitly guards against guessing line numbers.

Fit for basidiocarp: moderate fit for `rhizome`. Rhizome is the code intelligence MCP server. Code-tour's persona-based navigation model (architect tour vs new-joiner tour) is a higher-level navigation concept than rhizome currently supports. The anchor-verification step (confirm every file path and line number before generating) aligns with rhizome's structural analysis approach.

Evidence:
- `skills/code-tour/SKILL.md`

---

### 12. Continuous-learning-v2 shift to deterministic hook-based observation — changed since v1.10.0

The continuous-learning-v2 skill was substantially revised (modified in post-v1.10.0 compare). The key architectural shift: v1 relied on skills firing ~50-80% probabilistically; v2.x uses PreToolUse/PostToolUse hooks that fire 100% of the time deterministically. Analysis moved from synchronous (main context) to asynchronous (background Haiku agent). The unit of learning changed from full skills to atomic instincts with confidence scoring (0.3–0.9 range). Related instincts cluster into skills, commands, or agents; high-confidence patterns can promote from project to global scope.

Fit for basidiocarp: strong fit for `cortina` and `hyphae`. The hook-based observation pipeline (cortina) feeding a background analysis agent that writes structured memories (hyphae) is exactly the architecture basidiocarp already has. The instinct promotion model (project → global scope based on confidence) is a concrete design for how hyphae's memory scoping should work. The confidence-scored evidence tracking is a useful input for hyphae's decay model.

Evidence:
- `skills/continuous-learning-v2/SKILL.md`

---

### 13. ecc2 multi-agent control plane — significantly expanded

ecc2 was described in the original audit as "alpha with a 4-axis risk scoring model." It is now a substantial multi-agent control-plane implementation. Size alone: `ecc2/src/main.rs` is 444KB, `session/manager.rs` received 7,998 additions and 486 deletions, `tui/dashboard.rs` received 14,609 additions and 719 deletions.

New capabilities since v1.10.0 (from commit log and code inspection):
- **Multi-session TUI**: approval queue sidebar, delegate activity board, delegate progress signals, blocker hints, session timeline mode, global timeline scope, pane navigation
- **Budget management**: configurable alert thresholds, auto-pause when budget exceeded, cost tracker metrics
- **Worktree integration**: branch prefix enforcement, retention cleanup policy, merge queue reporting, diff view with hunk navigation, word diff highlighting, git staging UI, draft PR prompt
- **Memory connectors**: JSONL file, JSONL directory, Markdown file, Markdown directory, dotenv file — all with sync checkpoints and priority observation types
- **Shared context graph**: auto-populated, dashboard view, automatic relation detection, graph-aware routing, recall memory ranking
- **Harness runners**: codex, opencode, gemini, kiro, trae, windsurf, zed, factory-droid — configurable per harness with project-marker detection
- **Agent profiles**: inheritable TOML config with allowed/disallowed tools, model selection, budget limits
- **OTel export**: structured spans for ecc sessions
- **Legacy migration**: audit, plan, and scaffold commands for importing old workspace memory, skills, and remote configs
- **Persistent task scheduling** using the `cron` crate
- **Desktop notifications** via the `notifications.rs` module (635 lines)
- **Remote dispatch intake** and computer-use remote dispatch

The Cargo.toml dependencies are production-grade: ratatui 0.30, tokio 1 (full), rusqlite 0.32 (bundled), git2 0.20 (ssh), cron 0.12, sha2, ureq, uuid, thiserror, anyhow. The crate produces an `ecc-tui` binary with LTO and strip for release.

Revised verdict: ecc2 is no longer "interesting only for the risk scoring model." It is a functional multi-agent session manager with worktree isolation and a TUI control plane. The full system is still alpha-quality, but individual modules — especially the worktree module, memory connectors, and agent profile system — are production-viable reference implementations.

Fit for basidiocarp:
- Worktree module → `canopy` (agent session + worktree isolation pattern)
- Memory connector enum → `hyphae` (typed connector registry design)
- Agent profile inheritance → `canopy`/`stipe` (profile inheritance with tool access lists)
- Harness runner enum + project-marker detection → `lamella`/`stipe`

Evidence:
- `ecc2/src/worktree/mod.rs`
- `ecc2/src/session/mod.rs`
- `ecc2/src/config/mod.rs`
- `ecc2/README.md`

---

### 14. Hermes operator shell pattern — NEW since v1.10.0

`docs/HERMES-SETUP.md` and `docs/HERMES-OPENCLAW-MIGRATION.md` document a pattern: personal automation workspaces (Hermes, OpenClaw) are treated as workflow input to a canonical public system (ECC), not as architectures to preserve. The migration guide codifies five extraction layers: schedulers, dispatch gateways, memory systems, skills, and tools → ECC-native equivalents.

Fit for basidiocarp: weak direct fit, but relevant as a pattern for the basidiocarp workspace itself. The explicit boundary between "private operator workspace" and "public reusable substrate" mirrors how basidiocarp's root workspace doc repo relates to its subproject repos.

---

### 15. Silent-failure-hunter agent — NEW since v1.10.0

A focused code-review agent with zero tolerance for silent failures. Hunts five categories: empty catch blocks, inadequate logging, dangerous fallbacks (`.catch(() => [])`), error propagation issues (lost stack traces), and missing async error handling. Output format is structured per-finding with location, severity, issue, impact, and fix recommendation.

Fit for basidiocarp: worth borrowing as a lamella agent. The five hunt categories map directly to the error-handling concerns in the Rust rules (err-result-over-panic, anti-unwrap-abuse). A Rust-adapted version would hunt for `.unwrap()` chains, unchecked `expect` in non-invariant positions, and `?`-chains with no context.

Evidence:
- `agents/silent-failure-hunter.md`

---

### 16. Additional new agents — NEW since v1.10.0

10 new agents added (agents directory grew from ~38 to 48):
- `a11y-architect` — WCAG 2.2 Level AA compliance across web/iOS/Android
- `code-architect` — feature architecture design using existing codebase patterns
- `code-explorer` — codebase navigation and pattern explanation
- `code-simplifier` — code simplification focused on reducing complexity
- `comment-analyzer` — review comments for clarity and intent
- `conversation-analyzer` — analyze conversation for corrections and repeated mistakes
- `pr-test-analyzer` — PR test coverage analysis
- `seo-specialist` — SEO analysis
- `silent-failure-hunter` — described above
- `type-design-analyzer` — TypeScript type design review

The most relevant to basidiocarp: `code-architect` (fits rhizome's codebase intelligence mission), `silent-failure-hunter` (fits lamella's quality gate skills), `conversation-analyzer` (fits the continuous-learning-v2 instinct extraction pattern).

---

### 17. New skills count and notable additions

Skills grew from 181 to 183 in the compare diff, but the live repo shows 183 entries in the `skills/` directory. Notable new skills not covered elsewhere:

- `accessibility/SKILL.md` — WCAG 2.2, POUR principles, three-platform coverage; domain-specific, skip for basidiocarp
- `api-connector-builder/SKILL.md` — generic API integration pattern; weak fit
- `council/SKILL.md` — covered in section 10
- `code-tour/SKILL.md` — covered in section 11
- `dashboard-builder/SKILL.md` — Grafana/SigNoz operator dashboard skill; relevant to cap but the implementation is web-dashboard-specific, not terminal TUI
- `gateguard/SKILL.md` — covered in section 9
- `hipaa-compliance/SKILL.md` — domain-specific, skip
- `hookify-rules/SKILL.md` — skill for generating hook rule files; companion to the `/hookify` command
- `terminal-ops/SKILL.md` — terminal command patterns; weak fit given annulus coverage
- `unified-notifications-ops/SKILL.md` — notification routing; relevant to ecc2's notifications.rs pattern

Domain-specific skips (Solana ecosystem additions): `defi-amm-security`, `evm-token-decimals`, `llm-trading-agent-security`, `nodejs-keccak256`, `security-bounty-hunter`.

---

### 18. New commands — NEW since v1.10.0

- `/hookify`, `/hookify-configure`, `/hookify-list`, `/hookify-help` — a workflow for generating hook rule files from conversation analysis. The `/hookify` command without args runs the `conversation-analyzer` agent to find behaviors worth preventing, then generates `.claude/hookify.{name}.local.md` rule files. This is a self-improving hook authoring loop — the hook rules are generated from observed bad patterns, not hand-authored. Fit for cortina: the automated rule generation pattern is novel and directly applicable.

- `/feature-dev` — a structured feature development command. Scope unclear from name alone; likely wraps verification loop + TDD pattern.

- `/review-pr` — surfaces as a command wrapper for the PR review workflow.

- `/agent-sort` — command-level version of the evidence-based agent sort skill.

Evidence:
- `commands/hookify.md`
- `commands/feature-dev.md`
- `commands/review-pr.md`
- `commands/agent-sort.md`

## What to borrow directly (updated)

### Borrow now

- Skill authoring convention: YAML frontmatter + phased workflow body + When to Activate section + handoff pointers to related skills.
  Unchanged from original audit. Best fit: `lamella`.

- Strategic compact timing table as a lamella skill.
  Unchanged from original audit. Best fit: `lamella`.

- Verification loop as a lamella skill template.
  Unchanged from original audit. Best fit: `lamella`.

- Agent introspection debugging as a lamella skill template.
  Unchanged from original audit. Best fit: `lamella`.

- Claude plugin validator documentation (updated content).
  Now includes argv-dup bug, agents field removal, and identifier rename. Best fit: `lamella` plugin packaging docs.

- **GateGuard skill and hook — new, borrow now**.
  The three-stage gate (DENY/FORCE/ALLOW) with per-tool-type implementations and A/B evidence is directly usable in lamella (skill) and cortina (PreToolUse hook). The evidence-based framing (not just a pattern claim, actual measured improvement) makes this the strongest new borrow candidate from this audit cycle.
  Best fit: `lamella` for the skill document, `cortina` for the hook implementation.

- **Silent-failure-hunter agent — new, borrow now**.
  Adapt the five hunt categories to Rust: `.unwrap()` chains, unchecked `expect`, `?`-chains without context, missing `async` error propagation.
  Best fit: `lamella`.

- **Council skill — new, borrow now**.
  The anti-anchoring mechanism (context-isolated subagents with only the question, not the full conversation) is a concrete pattern for high-stakes decisions. Directly usable in lamella.
  Best fit: `lamella`.

- **Code-tour skill — new, borrow now**.
  Persona-based codebase navigation, SMIG step format, anchor verification. Useful for lamella's codebase-onboarding skill surface and as a rhizome workflow.
  Best fit: `lamella`, secondary `rhizome`.

- **Hookify command pattern — new, borrow now**.
  The automated hook rule generation from conversation analysis (find bad patterns → generate local rule files) is a concrete self-improvement loop not present in cortina or lamella. Adapt the concept for cortina's hook authoring workflow.
  Best fit: `cortina`.

## What to adapt, not copy (updated)

### Adapt

- Selective-install with schema-validated manifests and dependency expansion.
  Unchanged from original audit. Best fit: `stipe`.

- Cross-agent install targets with structural adaptation.
  Updated: now 9 targets (added Kiro, Trae) with non-destructive install. The Kiro adapter's non-destructive file placement model is a useful refinement to borrow. Best fit: `lamella`.

- Hook profile gating with env-var disable.
  Unchanged from original audit. Best fit: `cortina`.

- Tool call risk scoring model (4-axis).
  Updated: the model is now configurable (TOML `RiskThresholds`), fully tested, and wired to SQLite storage. The default thresholds (review: 0.35, confirm: 0.60, block: 0.85) are now concrete starting values. Adapt as a Rust trait in cortina with cortina-specific defaults.
  Best fit: `cortina` for classification, `volva` for enforcement.

- Evidence-based install classification (agent-sort).
  Unchanged from original audit. Best fit: `stipe`.

- **ecc2 worktree module**.
  The `WorktreeInfo`, `MergeReadiness`, `WorktreeHealth`, `BranchConflictPreview`, `GitStatusEntry`, and `DraftPrOptions` types are a complete vocabulary for worktree-aware agent session management. Adapt these types as a reference for canopy's session-per-worktree model. Do not copy the JavaScript-free Rust implementation as-is (canopy already has its own git integration decisions).
  Best fit: `canopy`.

- **ecc2 memory connector enum**.
  The five-variant connector enum (jsonl_file, jsonl_directory, markdown_file, markdown_directory, dotenv_file) with sync checkpoints and priority observation types is a concrete reference for hyphae's connector registry. Adapt as a typed enum in hyphae's connector API.
  Best fit: `hyphae`.

- **ecc2 agent profile inheritance**.
  The `AgentProfileConfig` (TOML, inherits field, allowed/disallowed tools, model, budget, token_budget) and resolved profile pattern is directly applicable to stipe's install profiles and canopy's agent launch configuration.
  Best fit: `stipe`, `canopy`.

- **Continuous-learning-v2 instinct confidence model**.
  The 0.3–0.9 confidence scoring with project vs global scope promotion is a concrete design for hyphae's memory decay and consolidation model. Adapt the confidence bands, not the shell script implementation.
  Best fit: `hyphae`.

## What not to borrow (updated)

### Skip

- The TkInter dashboard (`ecc_dashboard.py`).
  Now has dark mode and a proper GUI rewrite (913 lines), but it is still a Python/Tkinter tool. Cap is the right dashboard surface for the ecosystem.

- The ecc2 TUI rendering layer (dashboard.rs, widgets.rs).
  At 14,609 additions to dashboard.rs since v1.10.0, this is a substantial ratatui implementation. However, annulus already owns the TUI/statusline surface. The ecc2 TUI is interesting as a reference for ratatui patterns but not a borrow target.

- Project-specific skills.
  Unchanged from original audit. Skip: Solana ecosystem (defi-amm-security, evm-token-decimals, llm-trading-agent-security, nodejs-keccak256), investor-outreach, video-editing, visa-doc-translate, manim-video.

- The Python LLM provider abstraction (`src/llm/`).
  Unchanged from original audit. The abstraction design is standard, the ecosystem uses Rust.

- The GITAGENT export manifest (`agent.yaml`).
  Now 80 lines (from ~20). Still aspirational format at spec_version 0.1.0. The spec has grown substantially but remains a watch item, not a borrow.

- Per-language cursor rules.
  Unchanged from original audit. Thin files pointing back to skills.

- The MCP server template configs.
  Unchanged from original audit.

- Domain-specific accessibility, healthcare, compliance skills.
  New additions (hipaa-compliance, healthcare-cdss-patterns, defi-amm-security) are domain-specific with no ecosystem relevance.

## How Everything Claude Code fits the ecosystem (updated)

### Best fit by repo

- `lamella`
  Still the strongest overall fit. All original borrow targets remain. New additions: GateGuard skill (direct borrow), Council skill (direct borrow), code-tour skill (direct borrow), silent-failure-hunter agent (adapt to Rust), hookify command pattern (adapt for cortina), updated plugin validator docs. ECC's skill authoring convention continues to be the closest external reference for what lamella is building.

- `stipe`
  Strong fit unchanged. Add: agent profile inheritance model from ecc2 as a reference for stipe's profile resolution.

- `cortina`
  Strong fit, upgraded. The GateGuard hook is the most concrete new input for cortina's PreToolUse signal model. The hookify automated rule generation pattern is novel and directly relevant. The updated hook registry (consolidated dispatcher pattern, pre/post dispatcher separation) is a refinement to note.

- `canopy`
  Upgraded from weak to moderate fit. The ecc2 worktree module (WorktreeInfo, MergeReadiness, BranchConflictPreview, merge queue) and agent profile inheritance are direct design inputs for canopy's DAG task graph with per-task worktree isolation. The Council deliberation skill maps to a canopy task node type.

- `hyphae`
  Upgraded from weak to moderate fit. The ecc2 memory connector enum and the continuous-learning-v2 instinct confidence/scope model are both direct design inputs for hyphae's connector registry and memory decay model.

- `volva`
  Unchanged. Moderate fit for tool call risk enforcement with the now-concrete threshold defaults.

- `cap`
  Weak fit unchanged. The dashboard-builder skill (Grafana/SigNoz) is web-dashboard-oriented, not terminal-TUI. The ecc2 ratatui surface is a reference but annulus owns that space.

- `hymenium`, `rhizome`, `mycelium`, `spore`, `annulus`
  rhizome: code-tour skill has a weak secondary fit. Others unchanged.

## What Everything Claude Code suggests improving in your ecosystem (updated)

### 1. Lamella needs a structured skill authoring convention — unchanged from prior audit

Unchanged finding. ECC now has 183 skills at v1 format consistency. The authoring convention is a larger lead over lamella than before.

### 2. Lamella needs cross-agent install adapters — expanded finding

The target count grew from 7 to 9 (Kiro, Trae added). The non-destructive install model for Kiro (existing files untouched) is a concrete refinement lamella should adopt for its install adapters.

### 3. Stipe install manifests should be schema-validated — unchanged from prior audit

Unchanged finding.

### 4. Cortina should classify tool call risk — stronger case now

The risk model is now fully tested and configurable. The four default thresholds are proven starting values. The GateGuard hook adds a second concrete cortina input: not just risk classification but investigation enforcement before high-risk actions.

### 5. Lamella should ship agent introspection and strategic compact skills — unchanged from prior audit

Unchanged finding. Still no lamella equivalent.

### 6. Document Claude plugin validator constraints — partially addressed

The PLUGIN_SCHEMA_NOTES.md update covers new constraints discovered after v1.10.0 (argv-dup bug, agents field removal). These should be captured in lamella's plugin packaging docs.

### 7. Canopy should support worktree-per-agent session isolation — new finding

ecc2's worktree module shows a complete typed vocabulary for agent session + worktree lifecycle. Canopy's DAG task graph would benefit from a first-class worktree isolation model: one worktree per task node, with merge readiness tracked as task state, and conflict detection as a graph edge condition.

### 8. Hyphae should have a typed connector registry — new finding

ecc2's five-variant memory connector enum (with sync checkpoints and priority observation types) is a design that hyphae's source ingestion model should match. Currently hyphae's source types are more loosely specified. A typed connector registry would make hyphae's connector API more reliable and testable.

### 9. Cortina should support automated hook rule generation — new finding

The hookify pattern (analyze conversation for bad patterns → generate `.claude/hookify.{name}.local.md` rule files) is a concrete self-improvement loop that cortina lacks. Adding a similar pattern — cortina events that identify hook-worthy patterns and suggest new hook configs — would close the loop between observation and enforcement.

## Verification context

This re-audit was based on: (1) GitHub API queries for releases, commits since v1.10.0, and file diffs; (2) direct content fetches of key changed files via raw GitHub URLs; (3) the original v1.10.0 audit for baseline. The repo was not cloned locally. No `npm install`, `npm test`, or `ecc install` was run. The ecc2 Rust source, hooks, skills, and agent files were read directly. The ecc2 binary was not compiled.

## Final read

**What has genuinely changed since v1.10.0:**

Borrow now (new): GateGuard skill + hook (lamella/cortina), Council deliberation skill (lamella/canopy), code-tour skill (lamella/rhizome), silent-failure-hunter agent (lamella, Rust-adapted), hookify rule generation pattern (cortina).

Adapt (updated): ecc2 worktree module types (canopy), ecc2 memory connector enum (hyphae), ecc2 agent profile inheritance (stipe/canopy), continuous-learning-v2 instinct confidence model (hyphae), risk scoring thresholds now concrete (cortina/volva).

Skip (unchanged): TkInter dashboard, ecc2 TUI rendering layer, project-specific skills, Python LLM library, GITAGENT manifest, thin cursor rules, MCP template configs.

**What has not changed:** The original borrow targets (skill authoring convention, strategic compact, verification loop, agent introspection debugging, plugin validator docs) are all still valid and still unimplemented in lamella. The adapt targets (selective-install manifests, cross-agent adapters, hook profile gating) remain the right architecture with minor refinements noted above.

The most significant shift from the original audit is ecc2's upgrade from "alpha with one interesting module" to "functional multi-agent control plane with several production-viable subsystems." Canopy and hyphae are the ecosystem repos most affected by this upgrade.
