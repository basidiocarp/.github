# [Tool] Agent Notes

<!-- ─────────────────────────────────────────────
     FILE PURPOSE
     This file is agent-oriented operational guidance for working *in* this repo.
     It is the counterpart to CLAUDE.md, not a replacement for it.

     CLAUDE.md answers: what does this tool do, how does it work, what are its contracts?
     AGENTS.md answers: how do I work effectively in this codebase right now?

     If the repo has no multi-agent workflows and no non-obvious working constraints,
     a thin AGENTS.md is fine. If the repo has complex authoring rules, strong
     architectural direction, or a regular pattern of agent mistakes — this file earns its weight.

     Do not duplicate CLAUDE.md content here. Link to it instead.
     ──────────────────────────────────────────── -->

<!-- ─────────────────────────────────────────────
     SECTION: Purpose
     Required. Two to four sentences.
     Answers: what does work in this repo look like? What does it produce?
     This is NOT a restatement of what the tool does (that's CLAUDE.md ##Project).
     Frame around the contributor/agent perspective, not the end-user perspective.

     Good: "Lamella is a manifest-driven packaging system. It turns source assets
            under resources/ and manifests/ into Claude plugin builds and Codex skill
            exports. Prefer working from source assets and manifests — dist/ is
            generated output."

     Good: "Stipe is the ecosystem control plane. It should stay thin and explicit:
            commands orchestrate, summarize, and repair — they do not implement
            domain logic. Shared tool state is global; host state is per-host."

     Bad:  "This is the stipe repository. Stipe manages the ecosystem."  ← restates the name
     ──────────────────────────────────────────── -->
## Purpose

[What work in this repo produces. The design intent in one sentence. What to preserve.]

---

<!-- ─────────────────────────────────────────────
     SECTION: Source of Truth
     Required when the repo has generated output, a dual source structure,
     or non-obvious ownership rules (e.g., source vs dist, manifests vs built artifacts).
     Skip for repos where the entire src/ tree is authoritative and obvious.

     This section prevents the most common class of agent mistake: editing the wrong file.

     Good (Lamella):
     - resources/ is source. dist/ is generated. Do not hand-edit dist/.
     - manifests/claude/*.json are the primary packaging manifests.
     - When Claude and Codex packaging drift, update source first, then rebuild.

     Good (any multi-crate workspace):
     - crates/ contains source. Do not edit files under target/.
     - Contract schemas in ../septa/ are the authoritative cross-tool shape.
       Change those before changing code that implements them.
     ──────────────────────────────────────────── -->
## Source of Truth

- `[primary source dir]` — [what lives here, treat as authoritative]
- `[secondary source dir]` — [what lives here]
- `[generated output dir]` — generated output. Do not hand-edit unless the task explicitly targets build artifacts.
- `[external authority]` — [e.g., "contract schemas in ../septa/ define cross-tool shapes — update them before changing implementing code"]

When [source A] and [source B] drift, update [source A] first, then rebuild or resync.

---

<!-- ─────────────────────────────────────────────
     SECTION: Before You Start
     Conditional — include when there is a recurring pattern of agents starting work
     without reading required context first. Especially valuable for:
     - repos with cross-tool contracts that break silently
     - repos with strong architectural direction mid-change
     - repos with non-obvious entry point constraints (enums in schemas, pinned deps, etc.)

     Format: numbered checklist, not bullets. Order matters — earlier items gate later ones.
     Keep it short: four to eight items. If it's longer, the items are too granular.

     Good (Canopy):
     1. Contracts: Read ../septa/README.md — find which contracts canopy owns or consumes
     2. Versions: Read ../ecosystem-versions.toml — verify spore pin and shared dep versions
     3. Schemas: If adding/changing a cross-tool payload → update the contract schema FIRST

     Bad: A list of every possible thing to read. This should be the critical path only.
     ──────────────────────────────────────────── -->
## Before You Start

Before writing code, verify:

1. **[Contracts / schemas]**: [Where to find them. What to check. When this applies.]
2. **[Versions / pins]**: [e.g., "Read ../ecosystem-versions.toml — verify spore pin before upgrading shared deps"]
3. **[Architectural constraint]**: [e.g., "New store methods go in the Store trait first, then implement"]
4. **[Cross-tool impact]**: [e.g., "If changing an enum that appears in a contract schema, update both sides"]

---

<!-- ─────────────────────────────────────────────
     SECTION: Preferred Commands
     Required. Split into two tiers when there is a preferred entry point vs targeted tools.
     Tier 1: the default command(s) for most work — use these first.
     Tier 2: focused commands for specific tasks — use when tier 1 is too broad.

     Do not list every possible command. Focus on the non-obvious ones and the ones
     agents tend to reach for incorrectly.

     Good (Lamella):
     Tier 1: ./lamella build-marketplace, make validate
     Tier 2: node scripts/ci/validate-skills.js, bash builders/sync-codex-manifests.sh

     Good (Stipe):
     Tier 1: cargo build --release && cargo test
     Tier 2: cargo test -p [specific crate], cargo insta review
     ──────────────────────────────────────────── -->
## Preferred Commands

Use these for most work:

```bash
[primary build / validate command]      # [what it does]
[primary test command]                  # [what it covers]
```

For targeted work:

```bash
[focused command for task type A]       # [when to use this instead]
[focused command for task type B]       # [when to use this instead]
```

---

<!-- ─────────────────────────────────────────────
     SECTION: Repo Architecture
     Required when the codebase has a non-obvious module ownership model, a
     current directional change underway, or places where agents repeatedly
     add things in the wrong place.

     This is NOT a rehash of CLAUDE.md ##Architecture. That describes what exists.
     This section describes the design intent — what goes where and why.
     It should call out active architectural direction (in-progress refactors,
     patterns to converge toward, things that should not be extended further).

     Good (Stipe):
     - src/commands/ — user-facing command behavior (orchestration only, not domain logic)
     - src/commands/host_policy.rs — source of truth for host metadata, not scattered conditionals
     - Design intent: shared tool state is global, host state is per-host, platform state is per-platform
     - Direction: moving from single-host flows to a host inventory model

     Bad: A file listing that duplicates the CLAUDE.md architecture tree.
     ──────────────────────────────────────────── -->
## Repo Architecture

[One or two sentences stating the design intent — what the codebase is trying to be.]

Key boundaries:

- `[file or module]` — [what it owns, what it should not own]
- `[file or module]` — [what it owns, what it should not own]
- `[file or module]` — [what it owns, what it should not own]

Current direction:

- [Active architectural change in progress — what to move toward]
- [What not to extend further — and why]
- [Platform or portability constraint being addressed]

---

<!-- ─────────────────────────────────────────────
     SECTION: Working Rules
     Required. Short, opinionated, repo-specific.
     These are not generic coding advice — they are the rules specific to this
     codebase that agents tend to violate without explicit guidance.
     Four to eight bullets. If you have more, some are too generic.

     Good: "Prefer extending shared helpers over adding another host-specific branch."
           "Do not let init and doctor invent separate host concepts."
           "Do not commit dist/. It is generated output."
           "When updating docs, link to adjacent reference pages instead of repeating content."

     Bad:  "Write clean code."
           "Test your changes."
           "Use git for version control."
     ──────────────────────────────────────────── -->
## Working Rules

- [Repo-specific rule that prevents a recurring mistake]
- [What to prefer and what to avoid — specific to this codebase]
- [Source-of-truth rule: which file wins when two files disagree]
- [Scope rule: what not to touch, or what to do before touching it]
- [Output rule: what to run before closing a task]

---

<!-- ─────────────────────────────────────────────
     SECTION: Multi-Agent Patterns
     Conditional — include when the repo regularly uses parallel or sequential
     multi-agent workflows. This section defines the roles, scope, and sequencing.
     Skip for repos where a single agent handles all work end-to-end.

     The role breakdown from Stipe is the gold standard:
     - Primary worker: owns write scope for a feature or refactor, specific files listed
     - Validator: independent cross-check, does not duplicate implementation
       Call out SPECIFICALLY what the validator looks for — not just "review the code"
     - Optional docs worker: only when behavior or recommended workflows change

     The validator's job description is the most important part. Be specific:
     "looks for: host-model drift, CLI surface inconsistencies, repair-action mistakes,
      missing tests, platform assumptions that block Windows"

     Audit sequencing matters too:
     - Ask the validator to review the broader shape, not just changed lines
     - Fix structural issues the validator finds before polishing output
     - Do not block on subagents immediately — do local work in parallel
     ──────────────────────────────────────────── -->
## Multi-Agent Patterns

For substantial [feature type / refactor / audit] work, use at least two agents:

**1. Primary implementation worker**
- Owns write scope for the feature or refactor
- Specific files in scope: `[file or module]`, `[file or module]`
- Does not cross into: `[out-of-scope files or concerns]`

**2. Independent validator**
- Does not duplicate implementation — reviews the broader shape
- Specifically looks for:
  - [Recurring structural issue #1 — e.g., "host-model drift"]
  - [Recurring structural issue #2 — e.g., "missing tests"]
  - [Recurring structural issue #3 — e.g., "platform assumptions"]
  - [Cross-boundary concern — e.g., "contract schema drift"]
- If the validator finds real structural issues, fix those before polishing output

**3. Docs worker** (optional — use when behavior or recommended workflows change)
- Owns `README.md` and any affected docs
- Does not modify source code

Sequencing: do not block on the validator immediately after dispatch. Continue local work in parallel, wait only when the next editing decision depends on the review result.

---

<!-- ─────────────────────────────────────────────
     SECTION: Skills to Load
     Conditional — include when there is a meaningful set of Lamella skills that
     apply to common work in this repo.
     Two tiers: default (load for most work) vs situational (load when the task needs it).
     For each skill, say WHY it applies to this repo specifically — not just the skill name.

     Good (Stipe):
     Default:
     - rust-router — default Rust implementation and refactor skill
     - systematic-debugging — use before fixing CLI breakage, test failures, or config drift

     Situational:
     - test-writing — when adding or reshaping command behavior
     - multi-agent-patterns — when splitting command, docs, and audit work across agents

     Bad: A long list of skills with no guidance on when to use each one.
     ──────────────────────────────────────────── -->
## Skills to Load

Use these for most work in this repo:

- `[skill-name]` — [why it applies here, what task type it covers]
- `[skill-name]` — [why it applies here]

Use these when the task needs them:

- `[skill-name]` — [specific trigger: "when adding X" or "when task involves Y"]
- `[skill-name]` — [specific trigger]

---

<!-- ─────────────────────────────────────────────
     SECTION: Authoring Reference
     Conditional — include for repos with significant non-code content (skills,
     agents, manifests, docs) where an agent needs to know which doc to read before
     making a specific type of change. This pattern comes from Lamella's CLAUDE.md
     and is one of the most effective agent-orientation techniques in the codebase.

     Format: two-column table — doc → when to read it.
     "When to Read" column should be specific enough to be actionable.
     Mark the docs that are always required vs situational.

     Good:
     | docs/authoring/skills-spec.md | Always — official skills format spec |
     | docs/authoring/agent-style-guide.md | Always when editing agents |
     | docs/reference/hooks.md | When creating hooks |

     Bad: Listing every doc in the repo without "when to read" guidance.
     ──────────────────────────────────────────── -->
## Authoring Reference

Read before making changes to [content type]:

| Doc | When to Read |
|-----|--------------|
| `[docs/path/to/doc.md]` | **Always** — [what it covers and why it's required] |
| `[docs/path/to/doc.md]` | **Always when [doing X]** — [what it covers] |
| `[docs/path/to/doc.md]` | When [specific trigger] — [what it covers] |

---

<!-- ─────────────────────────────────────────────
     SECTION: Done Means
     Conditional — include when there is a recurring pattern of agents closing tasks
     early (before validation, before updating related files, before noting gaps).
     This section defines the minimum bar for task completion.
     Three to five bullets. Be explicit about what "done" requires — not just
     "tests pass" but which tests, in which project, run how.

     Good (Lamella):
     - Relevant files are updated
     - Obvious validation has been run when practical
     - Final response states any remaining gaps or follow-up work

     Bad: "The task is done when it's done."  ← circular and useless
     ──────────────────────────────────────────── -->
## Done Means

A task is not complete until:

- [ ] [Primary deliverable is in the right place — source, not generated output]
- [ ] [The narrowest relevant validation has been run — name the specific command]
- [ ] [Related files that should change together have been updated]
- [ ] [Any remaining gaps or follow-up work are stated explicitly in the final response]

If validation was skipped, say so clearly and explain why.

---

<!-- ─────────────────────────────────────────────
     SECTION: Near-Term Priorities
     Conditional — include when there is active architectural work underway that
     an agent could unknowingly work against. This prevents agents from implementing
     the old model when the codebase is mid-transition.
     Three to six bullets. These should be the actual current priorities, updated
     as the work completes. Stale priorities are worse than no priorities.

     Good (Stipe):
     - Make init inventory-aware instead of single-target-only
     - Make aggregate doctor reuse per-host checks and reporting
     - Add platform-aware config path handling for Windows-safe repair output

     Bad: A full roadmap. That belongs in ROADMAP.md.
          Completed items. Remove them when done.
     ──────────────────────────────────────────── -->
## Near-Term Priorities

Current direction — do not work against these:

- [Active refactor or migration in progress]
- [Pattern to converge toward — be specific]
- [Platform or compatibility work underway]
