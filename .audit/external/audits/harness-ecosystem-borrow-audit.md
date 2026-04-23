# Harness Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `harness`
Lens: what to borrow from harness, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Harness is a Claude Code plugin that auto-generates agent teams and skills from natural language domain descriptions. It implements 6 team architecture patterns (pipeline, fan-out/fan-in, expert pool, producer-reviewer, supervisor, hierarchical delegation), includes an evolution mechanism that feeds back deltas from shipped harnesses to improve future generations, and ships with 100 production harnesses across 10 domains. Its strongest portable ideas are: progressive disclosure in skills (3-tier loading: metadata / SKILL.md / references/), phase-skipping matrix for incremental updates, the 6 team architecture patterns as reusable decision vocabulary, and the evolution feedback loop for closing the learning cycle. Basidiocarp benefits most in `mycelium` (progressive disclosure), `canopy` (team patterns, phase-skipping), and `hyphae` (evolution feedback).

## What harness is doing that is solid

### 1. Progressive disclosure in skill loading

Skills use a 3-tier loading model: metadata+description always in context (cheap), SKILL.md loaded on trigger (medium), references/ directory loaded on demand (expensive, 300+ lines with nested ToC). This prevents context bloat while enabling deep detail.

Evidence:
- Skill metadata: name, description, triggers in frontmatter (always loaded)
- `SKILL.md`: full skill instructions (loaded when skill is triggered)
- `references/` directory with sub-documents: skill-writing-guide.md, architecture patterns, examples (loaded only when explicitly requested)

Why that matters here:
- `mycelium` output filtering should apply the same 3-tier loading to skill context, agent instructions, and tool outputs.
- `lamella` skill packaging should enforce this tier structure as a convention.

### 2. Team architecture pattern decision tree

Six reusable patterns with a clear decision tree for when each fits:
- **Pipeline**: sequential stages, each stage depends on prior
- **Fan-out/fan-in**: parallel exploration, aggregation at end
- **Expert pool**: specialized agents, coordinator routes tasks
- **Producer-reviewer**: generation + quality gate
- **Supervisor**: one coordinator + N specialized workers
- **Hierarchical delegation**: tree of coordinators + workers

Evidence:
- `patterns/team-architecture-patterns.md` with decision tree and when-to-use per pattern
- 100 production harnesses as examples
- Pattern templates: orchestrator instructions, agent role definitions, inter-agent communication protocols

Why that matters here:
- `canopy` multi-agent coordination runtime should standardize on this pattern vocabulary.
- `lamella` should include the decision tree as authoring guidance for skill authors building team-based skills.

### 3. Phase-skipping matrix for incremental updates

The generation workflow has 6 phases (domain analysis → architecture design → agent definitions → skill generation → orchestration → validation). The phase-skipping matrix allows updating only affected phases when a harness is evolved, avoiding regeneration of unchanged components.

Evidence:
- `SKILL.md` phase descriptions with skip conditions
- Matrix: which phases to re-run given a change type (new domain context, new agent role, new skill, orchestration change, validation fix)

Why that matters here:
- `canopy` task decomposition should support incremental updates — re-run only the affected sub-tasks when upstream changes.
- `hymenium` workflow engine should expose phase-level skip logic as a first-class feature.

### 4. Evolution feedback loop

`/harness:evolve` captures deltas between initial and shipped harness (what was added, removed, changed). Deltas feed back into the factory as training signal for better next-gen harness drafts.

Evidence:
- `/harness:evolve` skill captures diff between generated and shipped
- Delta format: added_agents, removed_agents, modified_skills, changed_orchestration
- Factory incorporates deltas as few-shot examples in next generation

Why that matters here:
- `hyphae` should formalize this pattern: capture what was generated vs. what shipped, store as a lesson, use in future generation.
- This is the closed-loop learning pattern the ecosystem needs across all skill/agent generation.

## What to borrow directly

### Borrow now

- Progressive disclosure pattern (3-tier loading).
  Best fit: `mycelium` (output filtering) and `lamella` (skill packaging conventions).

- Team architecture pattern decision tree.
  Best fit: `canopy` (standardize the pattern vocabulary for multi-agent coordination).

- Phase-skipping matrix.
  Best fit: `canopy` and `hymenium` (incremental task/workflow updates).

- Evolution feedback loop.
  Best fit: `hyphae` (persistent memory should capture generated vs. shipped deltas as lessons).

## What to adapt, not copy

### Adapt

- Team orchestrator templates.
  Adapt for other coordination patterns (event-driven, request-reply, pub-sub) in `canopy`; harness is Claude Code-specific but patterns generalize.

- Skill writing guide (`references/skill-writing-guide.md`).
  Adapt into basidiocarp-wide skill authoring standard; harness guide is polished and domain-aware.

- QA agent integration guide.
  Adapt for `lamella` skill validation; harness QA pattern is stronger than current skill testing practices.

## What not to borrow

### Skip

- Claude Code-specific agent team syntax (TeamCreate, SendMessage, TaskCreate).
  Too runtime-specific; `canopy` defines its own coordination primitives.

- Domain-specific harness examples (webtoon production, YouTube planning).
  Useful as reference material only; don't copy domain assumptions.

- Auto-generation of SKILL.md from natural language.
  This is a product feature that requires LLM calls at generation time; not infrastructure.

## How harness fits the ecosystem

### Best fit by repo

- `canopy`: Multi-agent orchestration patterns, task decomposition, inter-agent messaging.
- `lamella`: Skill generation templates, skill authoring standards, progressive disclosure conventions.
- `hyphae`: Evolution feedback and pattern learning from shipped harnesses.
- `hymenium`: Phase-skipping and incremental workflow execution.
- `rhizome`: Team architecture analysis and code intelligence for generated agents.

## What harness suggests improving in your ecosystem

### 1. No skill contract enforcement

Harness generates SKILL.md files but doesn't enforce that generated skills match their declared interface. `septa` should define skill contracts.

### 2. Evolution mechanism should be automatic

`/harness:evolve` is a manual skill invocation. Should be automatic (e.g., on session end or team completion via `cortina` hooks).

### 3. No pattern scoring

Harness includes 6 patterns but doesn't track which patterns work best for which domains. `hyphae` could learn pattern efficacy from shipped teams.

## Final read

**Borrow:** progressive disclosure pattern, team architecture patterns, phase-skipping matrix, evolution feedback loop.

**Adapt:** orchestrator templates and skill authoring guide into basidiocarp-wide standards.

**Skip:** Claude Code-specific syntax; domain-specific harness examples.
