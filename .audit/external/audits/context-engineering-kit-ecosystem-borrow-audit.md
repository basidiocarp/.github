# Context Engineering Kit Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `NeoLabHQ/context-engineering-kit`
Stars: ~857
Primary language: TypeScript (hooks), Markdown (skills/commands/agents)
Lens: context assembly patterns, token footprint minimization, injection strategies, sub-agent quality gates

---

## One-paragraph read

Context Engineering Kit (CEK) is a Claude Code plugin marketplace built around a single thesis: agent quality degrades predictably with context size, and you can engineer around that by keeping context lean and delegating aggressively to fresh sub-agents. Its thirteen plugins package real-world prompt engineering patterns into installable units — each loading only what it needs — with a granular plugin manifest controlling exactly what enters context. The strongest portable ideas are: progressive disclosure as an architectural primitive (skill descriptions load into context, full skill bodies load on activation), the meta-judge / LLM-as-judge quality gate pipeline baked directly into orchestration commands, the Agentic Context Engineering (ACE) memorize pattern that mines reflection outputs and writes curated insights back to CLAUDE.md, the Stop hook that detects a trigger word in the user prompt and blocks the session end to force a reflect pass, and a detailed context degradation taxonomy (lost-in-middle, context poisoning, distraction, confusion, clash) that informs when to isolate sub-agents and how to place critical instructions. The ecosystem fit is concentrated in `hyphae` (context-quality-aware recall, memorize pattern, degradation-aware retrieval), `mycelium` (content-aware output filtering with progressive disclosure), `lamella` (skill authoring conventions — commands-over-skills bias, frontmatter discipline), and `cortina` (trigger-word Stop hook, session-boundary reflection injection). Nothing here needs a new septa contract or new repo.

---

## What context-engineering-kit is doing that is solid

### 1. Progressive disclosure as a first-class architectural primitive

CEK encodes progressive disclosure as a hard design rule: skill descriptions load into context by default when a plugin is installed; full skill body text loads only when the skill is activated. Commands are explicitly preferred over always-on skills for anything that would pollute context with content that is not needed yet.

Evidence:
- CLAUDE.md development rules: "Commands over skills — Commands load on-demand; skill descriptions load into context by default."
- Plugin manifest `source` field points to per-plugin directories, and only skills that are installed enter context.
- `sadd/skills/multi-agent-patterns/SKILL.md` opens with: "At startup, agents load only skill names and descriptions — sufficient to know when a skill might be relevant. Full content loads only when a skill is activated."
- `customaize-agent/skills/context-engineering/SKILL.md` formalizes this as "The Progressive Disclosure Principle."

Why this matters here:
- `hyphae` recall already returns relevance-ranked context chunks. The progressive disclosure model gives a concrete shape for how callers should handle those results: load identifiers and relevance first, pull full content only on demand. The current `hyphae-context-v1` schema has `content`, `relevance`, and `source` — it supports this pattern but does not enforce it on callers.
- `lamella` skill authoring should encode this as an explicit rule: skill description text (which loads into context) must be short and trigger-bearing; the body carries the detail.

### 2. Meta-judge / LLM-as-judge quality gate pipeline with context isolation

The sadd (Subagent-Driven Development) plugin implements a repeatable pipeline: dispatch a meta-judge sub-agent first to generate tailored evaluation rubrics for the specific artifact, then dispatch the implementation agent, then dispatch a judge sub-agent with the meta-judge's YAML specification. The judge uses fresh context with no accumulated session state and is deliberately never told the pass threshold to prevent bias. The do-in-steps variant runs meta-judge and implementation in parallel, then waits for both before judging. If the judge fails, it retries with judge feedback injected, up to a fixed cap.

Evidence:
- `sadd/skills/judge/SKILL.md`: meta-judge → judge pipeline; `CRITICAL: NEVER provide score threshold to judges in any format`.
- `sadd/skills/do-and-judge/SKILL.md`: "Dispatch meta-judge AND implementation agent in parallel (meta-judge FIRST in dispatch order)."
- `sadd/skills/do-in-steps/SKILL.md`: per-step judge with meta-judge spec reused across retries within a step; a new meta-judge for each new step.
- Scoring table: 1.00–4.50 with explicit verdicts; default score is 2; score 5 in <5% of evaluations.
- README reliability table: do-in-steps reaches 90% accuracy on 4–10-file changes vs 30–50% for one-shot.

Why this matters here:
- `canopy` (multi-agent coordination) has no defined quality gate pipeline. The meta-judge → judge model is a concrete, tested protocol for agent verification that `canopy` should formalize.
- `hyphae` lesson extraction (`hyphae_extract_lessons`) is the nearest equivalent to the judge feedback loop. The judge's structured failure report — with specific criterion scores, evidence citations, and weighted total — is exactly what should feed hyphae's lesson store.

### 3. Agentic Context Engineering (ACE) memorize pattern

The reflexion plugin's `/reflexion:memorize` command implements what CEK calls Agentic Context Engineering: mine recent reflection and critique outputs, extract high-value reusable insights, and write curated bullets into CLAUDE.md under structured headings. The curation rules are explicit — atomicity, non-redundancy, no speculation, prefer specifics, do not auto-delete older entries. The design goal is preventing "context collapse" (vague summaries that dilute rather than sharpen context).

Evidence:
- `reflexion/skills/memorize/SKILL.md`: "Transform reflections, critiques, verification outcomes, and execution feedback into durable, reusable guidance by updating CLAUDE.md."
- Explicit prohibition on overwriting: "Do not overwrite or compress existing context; only add high-signal bullets."
- Section taxonomy for CLAUDE.md: Project Context, Code Quality Standards, Architecture Decisions, Testing Strategies, Development Guidelines, Strategies and Hard Rules.
- Paper citation: `https://arxiv.org/pdf/2510.04618` (ACE paper).

Why this matters here:
- `hyphae` is the structured memory store; CLAUDE.md is the flat-file working context. CEK treats them as different layers: hyphae for cross-session recall, CLAUDE.md for in-context injection at session start. The memorize pattern is the write path from hyphae-grade reasoning back into the flat file. Basidiocarp has `hyphae_memory_store` but no corresponding curated-write-to-CLAUDE.md workflow.
- This is the most directly borrowable idea: a skill that takes hyphae lesson output and curates it into CLAUDE.md with the atomicity and non-redundancy rules CEK specifies.

### 4. Stop hook with trigger-word detection and cycle prevention

The reflexion plugin ships a TypeScript `Stop` hook that reads session data from a per-session JSON file written during `UserPromptSubmit`, checks whether the most recent user prompt contained the word "reflect" as a standalone word (not part of `/reflect` or `/reflexion:reflect`), and blocks the session end with an instruction to run `/reflexion:reflect`. Cycle prevention is explicit: it checks that the second-to-last hook invocation was a UserPromptSubmit, not another Stop, before blocking.

Evidence:
- `reflexion/hooks/hooks.json`: `Stop` and `UserPromptSubmit` hook registrations.
- `reflexion/hooks/src/onStopHandler.ts`: trigger-word regex `(?<![:/])\b${word}\b` with negative lookbehind to exclude slash commands; consecutive Stop detection; session data read from tmpdir JSON.
- `reflexion/hooks/src/session.ts`: per-session JSON accumulation of all hook payloads by `session_id`.

Why this matters here:
- `cortina` captures lifecycle events and writes normalized signals. The trigger-word Stop hook is the pattern cortina is missing: a lightweight hook that reads session history to make a context-aware decision at Stop time, rather than always firing unconditionally. The cycle prevention logic (no consecutive Stops) should be a standard safeguard in any cortina hook that blocks a Stop.

### 5. Context degradation taxonomy with placement and isolation rules

The `customaize-agent/skills/context-engineering` skill contains a detailed empirically-grounded taxonomy of five context degradation failure modes: lost-in-middle (U-shaped attention curve, 10–40% lower recall for middle content), context poisoning (errors compound through repeated reference), context distraction (single irrelevant document measurably degrades performance), context confusion (irrelevant information influences responses unexpectedly), and context clash (contradictory correct information). It provides concrete mitigations for each: placement at attention-favored positions, compaction triggers at 70–80% utilization, sub-agent isolation for task switching.

Evidence:
- `customaize-agent/skills/context-engineering/SKILL.md`: "Research demonstrates that relevant information placed in the middle of context experiences 10–40% lower recall accuracy compared to the same information at the beginning or end."
- "Even a single irrelevant document in context reduces performance on tasks involving relevant documents."
- Four-bucket approach: Write, Select, Compress, Isolate.
- Compaction trigger guideline: "Implement compaction triggers at 70–80% utilization."

Why this matters here:
- `hyphae`'s context assembly (via `hyphae_gather_context`) returns ranked chunks but has no model for where callers should place them in context or when they should stop adding. The degradation taxonomy makes the design problem concrete: high-relevance items belong at the edges of context, not buried in the middle; one irrelevant result is not free.
- `mycelium`'s compression is about reducing token count; CEK's distraction finding shows that relevance filtering matters at least as much as compression ratio. A 90-token result with low relevance may hurt more than a 300-token result with high relevance.

### 6. Commands-over-skills bias with token overhead rationale

CEK provides a concrete token overhead table for each approach: one-shot prompt (0 overhead), /reflect (1k–3k), /reflect+/memorize (2k–5k), /do-and-judge (1.5x–3x), /do-in-steps (3x–5x), /plan-task+/implement-task (5x–20x). This makes explicit the tradeoff between reliability and token cost, and the preference for commands over always-on skills reflects the same tradeoff: commands are user-initiated and bounded; skills describe themselves cheaply but body-load on demand.

Evidence:
- README reliability and token overhead table.
- CLAUDE.md: "Minimal tokens — Every token counts; keep prompts concise."
- Plugin granularity: each plugin "loads only its specific agents, commands, and skills" and is "without overlap or redundant skills."

Why this matters here:
- `lamella` skill authoring has no equivalent cost model. Adding a token overhead column to the skill authoring guide — even as a rough order of magnitude — would help authors choose between always-on skills, on-demand commands, and agent delegation.

---

## What to borrow directly

### Progressive disclosure enforcement in lamella skill authoring

The rule is: description text that loads into context must be short, trigger-bearing, and self-contained. The skill body carries the detail and loads only on activation. `lamella` should encode this as a first-class authoring constraint with a character or token budget for descriptions.

Best fit: `lamella` (skill authoring conventions). No septa contract needed — this is an authoring rule, not a runtime payload.

### Trigger-word Stop hook with cycle prevention

A lightweight `Stop` hook that reads session history from a per-session accumulator, checks for a trigger token in the last user prompt, and blocks stop with a specific instruction if found. Cycle prevention: skip block if the previous hook was also a Stop.

Best fit: `cortina`. The session accumulator pattern (per-session JSON in tmpdir, accumulated across UserPromptSubmit and Stop events) is directly adoptable. The TypeScript implementation in `onStopHandler.ts` and `session.ts` is ~100 lines and straightforward to port to cortina's hook runner.

No septa contract needed — this is a local hook behavior, not a cross-tool payload.

### Degradation-placement rules for hyphae context assembly

Place the highest-relevance context chunk first in the assembled context window, the second-highest last, and fill the middle only when budget allows. Document the rationale (lost-in-middle, single-distractor effect) in hyphae's context assembly module.

Best fit: `hyphae`. The existing `hyphae-context-v1` schema returns `relevance` scores per chunk. The assembly ordering logic — which callers currently control — should become a documented convention or a CLI flag.

No septa contract change needed; the existing schema already carries relevance.

### CLAUDE.md curation skill (ACE memorize pattern)

A skill that takes hyphae lesson output and reflection summaries as input, applies atomicity and non-redundancy rules, and writes curated bullets under structured headings in CLAUDE.md. CEK's curation rules (no speculation, evidence-backed, one idea per bullet, no auto-delete) are the right defaults.

Best fit: `lamella` (the skill itself), consuming `hyphae` lesson output. This is the write path from cross-session memory back into the flat working context at session start.

No septa contract needed — the skill reads hyphae output and writes to CLAUDE.md, both already defined.

---

## What to adapt, not copy

### Meta-judge / judge quality gate pipeline

The pipeline is valuable but CEK's implementation is TypeScript-native and tightly coupled to Claude Code's `Task` tool and plugin root resolution (`CLAUDE_PLUGIN_ROOT`). The pattern — generate evaluation rubric first, run implementation, judge against rubric with fresh context, retry with feedback — should be adapted into `canopy`'s handoff verification model rather than copied verbatim.

Specifically: the meta-judge step (rubric generation before implementation) and the threshold-hiding rule (judge never sees the pass score) are worth adopting. The specific YAML rubric format and scoring table should be adapted to fit canopy's evidence-ref schema.

Best fit: `canopy` (quality gate model), with a septa contract update to `evidence-ref-v1` or a new `handoff-evaluation-v1` schema if the rubric needs to be cross-tool readable. Check septa first before adding a schema.

### Context degradation taxonomy as hyphae recall telemetry

CEK describes degradation thresholds empirically (meaningful degradation begins around 8,000–16,000 tokens for many models). Hyphae should track `tokens_used` against a per-call budget and log a warning when the assembly crosses 70% of a configurable ceiling. The `hyphae-context-v1` schema already has `tokens_budget` and `tokens_used` — the adaptation is to add a degradation-tier signal (normal / approaching / degraded) that callers can act on.

Best fit: `hyphae`. The `degradation-tier-v1` schema already exists in septa — check whether it models context assembly tier or only command output tier, and extend if needed.

### Plugin-granular context loading as a cortina injection model

CEK installs plugins that each contribute a bounded set of agents, commands, and skills. Cortina's hook injection could adopt the same model: hook bundles that each inject a defined slice of context at session start, rather than a monolithic injection. Adapt the manifest pattern (name, source, version, category) to cortina's hook registration, not the full plugin marketplace mechanism.

Best fit: `cortina`. No septa contract needed at this stage.

---

## What not to borrow

### The plugin marketplace runtime (full install/sync mechanism)

CEK's `/plugin marketplace add` and `/plugin install` commands are a user-facing distribution layer built on the agentskills.io standard. Basidiocarp has `lamella` for skill packaging and its own distribution path. Importing the marketplace runtime would create an overlapping distribution mechanism.

### The kaizen skill as an always-on context contributor

The kaizen plugin is an always-on skill that injects continuous improvement principles into every code interaction. At roughly 3k–5k tokens of body content, it is the kind of always-on context contributor that the progressive disclosure rule argues against. The principles themselves are worth reading; the always-on injection pattern is not.

### DDD rules as inline context

The ddd plugin installs fourteen rules (clean-architecture-ddd.md, domain-specific-naming.md, library-first-approach.md, etc.) that inject into context automatically when writing code. Basidiocarp's Rust rules in `.claude/rules/rust/` already cover equivalent ground with the same targeted rule files. No additional import needed.

### TypeScript hook runtime as a dependency

CEK's hooks are TypeScript compiled with bun, with a full package.json, vitest config, and lockfile. Cortina is a Rust CLI. The pattern (session accumulation, trigger detection, cycle prevention) is borrowable; the runtime is not.

### Third-party integrations (minibeads, context7, paper search MCP)

CEK's CLAUDE.md documents minibeads (task tracking), context7 MCP (documentation fetching), and paper search MCP (arxiv/pubmed). These are project-specific tool wiring for NeoLabHQ's workflow, not context engineering patterns.

---

## How context-engineering-kit fits the ecosystem

| Feature | Evidence | Best fit | Needs septa contract? | Borrow / adapt / skip |
|---|---|---|---|---|
| Progressive disclosure rule | CLAUDE.md authoring rules; multi-agent-patterns SKILL.md | `lamella` | No | Borrow |
| Trigger-word Stop hook with cycle prevention | `onStopHandler.ts`; `session.ts`; `hooks.json` | `cortina` | No | Borrow |
| Degradation placement rules (lost-in-middle) | `context-engineering` SKILL.md; 10–40% recall loss data | `hyphae` | No (reuse existing schema fields) | Borrow |
| ACE memorize pattern | `memorize` SKILL.md; ACE paper citation | `lamella` + `hyphae` | No | Borrow |
| Meta-judge / judge quality gate | `judge` SKILL.md; `do-and-judge` SKILL.md | `canopy` | Possibly (handoff-evaluation-v1) | Adapt |
| Token overhead cost model | README reliability table | `lamella` | No | Borrow |
| Degradation tier telemetry | `context-engineering` SKILL.md thresholds | `hyphae` | Check `degradation-tier-v1` first | Adapt |
| Plugin-granular injection model | plugin manifest; CLAUDE.md plugin design philosophy | `cortina` | No | Adapt |
| Plugin marketplace runtime | `/plugin install` commands | — | — | Skip |
| Always-on kaizen skill | `kaizen` SKILL.md | — | — | Skip |
| DDD inline rule injection | `ddd/rules/*.md` | — | — | Skip |
| TypeScript bun hook runtime | package.json, vitest, lockfile | — | — | Skip |

---

## What context-engineering-kit suggests improving in your ecosystem

### 1. Hyphae context assembly has no placement convention

`hyphae_gather_context` returns ranked chunks. CEK's degradation research makes clear that placement order within the assembled window matters as much as what is included: high-relevance content belongs at the beginning and end, not the middle. Hyphae should document an expected ordering convention and provide a CLI flag or API parameter to surface a degradation-tier warning when `tokens_used` crosses 70% of `tokens_budget`.

### 2. Lamella skill descriptions have no token budget

CEK enforces a hard design rule: descriptions load into context; bodies load on activation. Lamella has no equivalent constraint on description length or a documented token budget for the description field. An authoring checklist with a description character limit (e.g., 280 characters or roughly 70 tokens) and a trigger-phrase requirement would close this gap.

### 3. Cortina hooks fire unconditionally with no session-history check

CEK's Stop hook reads the session history before deciding whether to block. Cortina's `PostToolUse` and `Stop` hooks currently fire and emit events without examining prior session events. A session accumulator (per-session event log in a tmpdir file, keyed by session_id) would let cortina hooks make context-aware decisions — for example, suppressing a duplicate signal if the same event was already captured earlier in the session.

### 4. No curated write path from hyphae lessons to CLAUDE.md

Hyphae stores lessons and memories. CLAUDE.md is the flat context injected at session start. There is no defined workflow for moving insights from hyphae into CLAUDE.md with quality gates (atomicity, non-redundancy, evidence-backed). CEK's memorize skill is this workflow. Lamella should ship an equivalent skill that reads `hyphae_extract_lessons` output and writes curated bullets to the project CLAUDE.md.

### 5. Canopy has no structured quality gate protocol for handoff verification

CEK's meta-judge → judge pipeline is the most mature agent quality gate pattern surveyed in the audit corpus. Canopy tracks handoffs and evidence but has no protocol for generating rubrics before implementation and evaluating against them with fresh-context judges. Formalizing this as a canopy workflow — even a lightweight two-agent version without the full meta-judge tier — would close the largest gap between CEK's reliability model and basidiocarp's multi-agent coordination.

---

## Verification context

- Repo: `github.com/NeoLabHQ/context-engineering-kit` at `master` branch, v3.0.0 marketplace.
- Files read directly: `README.md`, `CLAUDE.md`, `.claude-plugin/marketplace.json`, all 13 plugin manifests and selected skill files including `reflexion/skills/reflect/SKILL.md`, `reflexion/skills/memorize/SKILL.md`, `reflexion/hooks/src/onStopHandler.ts`, `reflexion/hooks/src/session.ts`, `sadd/skills/judge/SKILL.md`, `sadd/skills/do-and-judge/SKILL.md`, `sadd/skills/do-in-steps/SKILL.md`, `sadd/skills/multi-agent-patterns/SKILL.md`, `sadd/skills/subagent-driven-development/SKILL.md`, `customaize-agent/skills/context-engineering/SKILL.md`, `customaize-agent/skills/prompt-engineering/SKILL.md`, `tech-stack/rules/typescript-best-practices.md`.
- Septa schemas cross-referenced: `hyphae-context-v1`, `mycelium-summary-v1`, `cortina-lifecycle-event-v1`, `degradation-tier-v1` (existence confirmed, content not audited for context assembly scope).
- Stars at time of audit: ~857.

---

## Final read

CEK is the most context-engineering-aware skill collection in the audit corpus. Its strongest ideas are not about prompts — they are about architecture: keep context lean by loading descriptions not bodies, isolate sub-agents to prevent context poisoning, mine session reflections and write structured lessons back to the working context, and block session end with a trigger-aware hook when a reflection pass was earned but not started.

**Borrow directly:** progressive disclosure as a lamella authoring rule; trigger-word Stop hook with cycle prevention into cortina; degradation placement convention (high relevance at edges) into hyphae context assembly; ACE memorize skill into lamella consuming hyphae lessons.

**Adapt:** meta-judge / judge quality gate pipeline into canopy's handoff verification model; degradation-tier telemetry in hyphae using existing `tokens_budget`/`tokens_used` schema fields; plugin-granular injection model into cortina hook bundles.

**Skip:** plugin marketplace runtime, kaizen as always-on context contributor, DDD inline rule injection, TypeScript bun hook runtime, third-party tool integrations.

No new septa schema is needed for the direct borrows. A `handoff-evaluation-v1` schema is worth investigating if the meta-judge / judge adaptation into canopy requires cross-tool readable rubrics — check the existing `evidence-ref-v1` and `canopy-task-detail-v1` schemas first before adding one.
