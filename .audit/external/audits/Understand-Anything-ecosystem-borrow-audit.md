# Understand-Anything Ecosystem Borrow Audit

Date: 2026-04-07
Re-assessed: 2026-04-23 (Wave 1 re-audit — verdict: Update; spawned rhizome/incremental-fingerprinting.md handoff)
Repo reviewed: `Understand-Anything`
Lens: what to borrow from the tool, how it fits the `basidiocarp` ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

`Understand-Anything` is strongest where it is a typed analysis system and weakest where it falls back to prompt-as-runtime. The best ideas are its plugin-based analyzer core, incremental fingerprinting and change classification, graph persistence hygiene, and operator-facing graph UX. The right ecosystem move is to lift the typed analysis pieces into `rhizome`, feed richer understanding artifacts into `hyphae`, and keep prompts as orchestration or fallback instead of core implementation.

## What Understand-Anything is doing that is solid

### 1. It has a real analyzer core

The analysis core is genuinely modular: language-aware plugin registration, parser registration for non-code assets, and config-driven tree-sitter loading with graceful degradation.

Evidence:

- [packages/core/src/plugins/registry.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/plugins/registry.ts#L20)
- [packages/core/src/plugins/parsers/index.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/plugins/parsers/index.ts#L31)
- [packages/core/src/plugins/tree-sitter-plugin.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/plugins/tree-sitter-plugin.ts#L217)

### 2. Its incremental story is better than average

Fingerprints intentionally track signatures rather than bodies, and change classification is explicit about `SKIP`, `PARTIAL_UPDATE`, `ARCHITECTURE_UPDATE`, and `FULL_UPDATE`.

Evidence:

- [packages/core/src/fingerprint.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/fingerprint.ts#L124)
- [packages/core/src/change-classifier.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/change-classifier.ts#L12)

### 3. Persistence hygiene is thoughtful

Absolute file paths are sanitized before graph write, which is the kind of detail these tools often miss.

Evidence:

- [packages/core/src/persistence/index.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/persistence/index.ts#L21)

### 4. The orchestration idea is useful even if the implementation should change

The `/understand` skill uses a strong sequence: deterministic scan first, reuse an import map, then batch analysis, then review and architecture phases.

Evidence:

- [skills/understand/SKILL.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/skills/understand/SKILL.md#L80)
- [skills/understand/SKILL.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/skills/understand/SKILL.md#L118)
- [skills/understand/SKILL.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/skills/understand/SKILL.md#L225)

### 5. The dashboard has strong operator affordances

Validation on load, diff overlay, domain-vs-structural view, persona modes, path finding, and keyboard shortcuts are all useful operator ideas.

Evidence:

- [packages/dashboard/src/App.tsx](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/dashboard/src/App.tsx#L235)
- [packages/dashboard/src/store.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/dashboard/src/store.ts#L61)

## What to borrow directly

### Borrow now

- Richer parser and analyzer plugin surfaces.
  Best fit: `rhizome`.

- Incremental analysis based on typed fingerprints and explicit update classes.
  Best fit: `rhizome`, with value reporting ideas for `mycelium`.

- Better project-understanding bundles as durable artifacts.
  Best fit: `hyphae` as the consumer and store.

- Operator-facing graph diff and layered-graph UI ideas.
  Best fit: `cap` and possibly `canopy`, if tied to task and evidence context.

## What to adapt, not copy

### Adapt

- The staged orchestration flow.
  Adaptation: keep the deterministic-first idea, but execute it in typed tools rather than prompt-authored scripts.

- Richer graph payloads.
  Adaptation: if these need to move across repos, add a new `septa` contract family rather than overloading `code-graph-v1`.
  Evidence:
  [septa/code-graph-v1.schema.json](/Users/williamnewton/projects/basidiocarp/septa/code-graph-v1.schema.json#L7)

- Multi-host packaging.
  Adaptation: `lamella` should own packaging and manifests, `stipe` should own install and doctor flows.

## What not to borrow

### Skip

- Prompt files as the primary implementation layer for incremental analysis.
  Typed tool code is already stronger here than the prompt-heavy hook path.
  Evidence:
  [packages/core/src/fingerprint.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/fingerprint.ts#L248)
  [packages/core/src/change-classifier.ts](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/core/src/change-classifier.ts#L21)
  [hooks/auto-update-prompt.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/hooks/auto-update-prompt.md#L42)

- Manual symlink-based install as a model.
  `lamella` and `stipe` already define a better ownership split.

- The dashboard auth gate pattern using query/session token handling.
  Evidence:
  [packages/dashboard/src/components/TokenGate.tsx](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/understand-anything-plugin/packages/dashboard/src/components/TokenGate.tsx#L20)

- Treating dashboard deploy validation as equivalent to main CI.
  Evidence:
  [.github/workflows/ci.yml](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/.github/workflows/ci.yml#L20)
  [.github/workflows/deploy-homepage.yml](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/Understand-Anything/.github/workflows/deploy-homepage.yml#L39)

## How Understand-Anything fits the ecosystem

### Best fit by repo

- `rhizome`
  Best overall fit. Parser plugins, richer graph extraction, and incremental re-analysis belong here.

- `hyphae`
  Best consumer fit. Project-understanding bundles should be stored and retrieved here rather than rebuilt ad hoc.

- `lamella`
  Good fit for multi-host packaging of graph-aware skills or dashboard surfaces.

- `stipe`
  Good fit for optional install, doctor, and repair of packaged understanding surfaces.

- `cortina`
  Narrow fit for lifecycle-triggered re-analysis signals, not for analysis itself.

- `canopy`
  Limited fit unless graph views become task-aware and evidence-aware.

- `mycelium`
  Limited direct feature fit. The main borrow is the cheap deterministic-first operating principle plus clearer value reporting.

## What Understand-Anything suggests improving in your ecosystem

### 1. Expand Rhizome’s extension surface

`rhizome` should likely gain first-class support for non-code structure, config and docs nodes, and broader edge vocabularies.

### 2. Add a richer understanding contract family to Septa

If project-understanding artifacts need to move between repos, `code-graph-v1` is too narrow.

### 3. Let Hyphae persist understanding bundles

Onboarding and architectural context should be retrievable, not rebuilt every time.

### 4. Let Cortina emit lightweight structure-drift signals

The trigger can live at the lifecycle edge, but the actual re-analysis should stay in typed tools.

### 5. Add metrics for skipped analysis work

This fits `mycelium`’s existing value-reporting direction.

## Verification context

Reported by the audit pass:

- `pnpm --filter @understand-anything/core test`
- `pnpm --filter @understand-anything/skill test`
- `pnpm --filter @understand-anything/dashboard build`

Core tests passed, skill tests passed, and the dashboard build passed.

## Final read

Borrow: typed analyzer plugins, incremental fingerprints, better graph artifacts, and strong graph UX ideas.

Adapt: staged orchestration and cross-repo graph contracts through `rhizome`, `hyphae`, `lamella`, and `stipe`.

Skip: prompt-as-runtime implementation, manual install patterns, and dashboard auth/query-token habits.
