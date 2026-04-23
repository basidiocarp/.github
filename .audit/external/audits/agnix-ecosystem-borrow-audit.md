# Agnix Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `agnix`
Lens: what to borrow from agnix, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Agnix is a configuration validator for AI agent tools (Claude Code, Cursor, Cline, Copilot, etc.) with 405 rules across 9 tools validating agent configs, skills, hooks, MCP, and memory files. Its strongest portable ideas are: extensible `Validator` trait with auto-discovered rule registry, evidence-driven rule design where each rule includes normative level and test coverage metadata, multi-backend architecture (LSP/MCP/CLI/WASM) for broad IDE integration, and an auto-fix engine with safety tiers (HIGH/MEDIUM/LOW). Basidiocarp benefits most in `lamella` (validate skill/hook manifests on registration), `septa` (evidence-based contract definitions), and `rhizome` (code structure validation rules). The tool-specific rule implementations (CC-*, COP-*, CUR-*) should not be copied.

## What agnix is doing that is solid

### 1. Rule registry with plugin architecture

Extensible `Validator` trait with metadata, auto-discovered from `knowledge-base/rules.json`. `ValidatorProvider` SPI enables multi-tool support without coupling. ~39 validators compiled into registry with file-type detection chain.

Evidence:
- `src/validators/` (validator implementations per tool)
- `knowledge-base/rules.json` as single source of truth for rule definitions
- Parity tests enforcing sync between `rules.json` and `VALIDATION-RULES.md`
- `ValidatorProvider` SPI for plugin registration

Why that matters here:
- `lamella` skills and hooks should validate against a schema on registration — this is the right pattern.
- `septa` contract definitions should include evidence, normative level, and test coverage metadata similar to agnix rules.

### 2. Evidence-driven rule design

Each rule includes: source verification, normative level (`MUST`/`SHOULD`/`BEST_PRACTICE`), test coverage metadata, and a reference to the canonical evidence (often a cited specification or behavior). Rules are not just syntax checks — they explain why a constraint exists.

Evidence:
- `knowledge-base/rules.json`: each rule has `id`, `name`, `description`, `severity`, `category`, `evidence`, `normative_level`, `tools` fields
- `VALIDATION-RULES.md` (human-readable equivalent, kept in sync by parity tests)
- Rule categories: correctness, best-practice, security, performance, compatibility

Why that matters here:
- `septa` cross-tool contracts should adopt the same evidence pattern — not just what is required, but why.
- This makes contracts auditable and easier to enforce in CI.

### 3. Multi-backend architecture (LSP/MCP/CLI/WASM)

Same validation engine exposed through multiple surfaces: LSP server for editor inline diagnostics, MCP server for agent-driven validation, CLI for CI pipelines, WASM for browser playground. Core validation logic is backend-agnostic; backends are thin adapters.

Evidence:
- `src/backends/lsp.ts` (LSP server adapter)
- `src/backends/mcp.ts` (MCP server adapter)
- `src/backends/cli.ts` (CLI adapter)
- `src/backends/wasm.ts` (WASM/browser adapter)

Why that matters here:
- `septa` validation tools should adopt the same multi-backend pattern: CLI for CI, MCP for agents, LSP for editors.
- `rhizome` could expose code-structure validators through the same multi-backend pattern.

### 4. Auto-fix safety tiers

Fixes are categorized as HIGH/MEDIUM/LOW safety confidence. `--fix-safe` applies only HIGH-confidence fixes automatically. Fix application is separate from validation (composable pipeline): validate → categorize → optionally fix.

Evidence:
- `src/autofix/` directory with fix applicator and safety classifier
- `--fix-safe`, `--fix-medium`, `--fix-all` CLI flags
- Fix functions return `ApplicableFix` with `safetyTier` and `description`

Why that matters here:
- `mycelium` output filtering transformations should use the same safety-tier model for distinguishing safe vs. unsafe transformations.
- `stipe` (installer) should apply the same pattern: separate diagnostic from repair, and gate auto-repair by safety tier.

## What to borrow directly

### Borrow now

- Plugin validator architecture.
  Best fit: `lamella` (skills/hooks packaging should validate against schema on registration).

- Evidence-based rule registry.
  Best fit: `septa` (cross-tool contracts should include evidence, normative level, and test coverage metadata).

- Auto-fix safety tiers.
  Best fit: `mycelium` (distinguish safe/unsafe output transformations); `stipe` (separate diagnostic from auto-repair).

- File type detection chain.
  Best fit: `spore` (discovery module should use similar pattern for detecting tool config files).

## What to adapt, not copy

### Adapt

- Rule JSON schema.
  Adapt for `septa` contract definitions; agnix rules are tool-specific validation, septa contracts are tool-agnostic schemas.

- Multi-backend (LSP/MCP/CLI/WASM) pattern.
  Adapt as blueprint for other validators in basidiocarp — the architecture is clean, the specific adapters are swappable.

## What not to borrow

### Skip

- Tool-specific rule implementations (CC-*, COP-*, CUR-*).
  These belong in per-tool validator crates, not in core infrastructure.

- WASM bindings.
  Only if basidiocarp plans a browser-based validator (not currently in scope).

## How agnix fits the ecosystem

### Best fit by repo

- `lamella`: Validate skill/hook/plugin manifests on registration — auto-discover rules for SKILL.md, hooks.json, etc.
- `septa`: Contract schema definitions with evidence and normative levels; validation pipeline definition.
- `rhizome`: Add code-structure validators (complexity, test coverage, architecture rules).
- `cortina`: Validate lifecycle hooks (event shape, handler signature, fail-open invariants).

## What agnix suggests improving in your ecosystem

### 1. No semantic validation

agnix validates schema/syntax only; doesn't check if a skill actually implements its declared description or if hook handlers match their trigger shape. `septa` contracts should include semantic validation specs.

### 2. No cross-file validation

Can't check "if agent A calls skill B, does B exist?" — dependency graphs belong in `septa`.

### 3. Rules are tool-centric, not domain-centric

No rules for "correct handoff protocol" or "valid task ownership transfer". `septa` should define domain-level validation specs that agnix-style tools can implement.

## Final read

**Borrow:** plugin validator architecture, evidence-driven rule registry, auto-fix safety tiers, file type detection chain.

**Adapt:** rule schema and multi-backend (LSP/MCP/CLI) pattern for other validators in basidiocarp.

**Skip:** tool-specific rule implementations (CC-*, COP-*, CUR-*); focus on infrastructure.
