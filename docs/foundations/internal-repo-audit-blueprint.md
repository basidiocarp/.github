# Internal Repo Audit Blueprint

Date: 2026-04-09
Scope: internal repos in the `basidiocarp` workspace
Companion docs:

- [docs/foundations/rust-workspace-architecture-standards.md](/docs/foundations/rust-workspace-architecture-standards.md)
- [docs/foundations/rust-workspace-standards-applied.md](/docs/foundations/rust-workspace-standards-applied.md)
- [docs/foundations/rust-repo-audit-checklist.md](/docs/foundations/rust-repo-audit-checklist.md)
- [docs/foundations/rust-repo-audit-report-template.md](/docs/foundations/rust-repo-audit-report-template.md)

This is the reusable part of the old global audit. It is the spec to use when auditing workspace repos now. The old campaign had useful structure, but too much of it was tied to one moment, one Canopy rollout, and one baseline file. This document keeps the repeatable method and drops the one-off orchestration.

## What an internal audit is for

An internal repo audit is not just a lint run and not just an architecture essay. It should answer five questions:

1. Does the repo still own the thing it claims to own?
2. Does the code shape match that ownership?
3. Do contracts, docs, and runtime behavior agree?
4. Is the repo green in a way that actually means something?
5. What should turn into handoffs, and what should stay as a campaign?

If the audit cannot answer those, it is too shallow.

## Default audit outputs

Every internal audit should produce these outputs:

- one repo-level audit note or report
- a short keep or tighten or watch summary
- a validation record with the commands that were actually run
- follow-up handoffs only for concrete repo-owned work
- a campaign only when the work crosses repos or needs sequencing

Do not skip the output shaping step. A good audit that produces no clear next move is mostly wasted.

## Audit layers

Use four layers in order. You can stop after a layer if the audit goal is narrow, but do not skip straight to synthesis.

### Layer 0: Baseline and verification surface

Start by establishing the narrowest honest baseline for the repo:

- repo path and owning boundary
- crate or package layout
- current version or release marker if relevant
- basic verification commands
- known environment assumptions

For Rust repos, this usually means some subset of:

```bash
cd <repo> && cargo check
cd <repo> && cargo test
cd <repo> && cargo clippy --all-targets
cd <repo> && cargo fmt -- --check
```

For `cap`, it usually means:

```bash
cd cap && npm run build
cd cap && npm test
```

For `lamella`, use its content or packaging validation path instead of pretending it is a Rust crate.

The point of Layer 0 is to answer: what does green mean here, and can I run it locally?

### Layer 1: Structural review

This is the core of the audit. Review the repo as a system, not as a diff.

Questions to answer:

- what does the repo own and not own
- what is the composition root
- where do dependencies flow
- what are the core abstractions
- which files or modules are turning into hotspots
- where config, policy, or operator UX is accumulating
- whether tests match the real product surface

For Rust repos, use the checklist directly:

- [rust-repo-audit-checklist.md](/docs/foundations/rust-repo-audit-checklist.md)

For non-Rust repos, use the same shape even if the crate-language wording does not apply exactly.

### Layer 2: Boundary, contract, and documentation fidelity

This is the most reusable lesson from the old global audit. A repo can look fine internally and still drift at the edges.

Check three things:

1. Boundary fidelity
   Does the repo still behave within the scope described by its README, CLAUDE, AGENTS, or architecture notes?

2. Contract fidelity
   If the repo emits or consumes shared payloads, do those shapes still match the contract source of truth?
   For this workspace, shared payload work should be checked against `septa/`.

3. Documentation fidelity
   Do maintainer docs, command examples, config paths, and capability claims still match the code?

This layer is where false “read-only”, “observation only”, “tool count”, “graceful degradation”, and path claims usually break down.

### Layer 3: Synthesis and action shaping

Finish the audit by turning findings into the smallest useful action set.

Use three buckets:

- `Keep`
- `Tighten`
- `Watch`

Then decide whether each issue becomes:

- a repo-owned handoff
- a cross-project handoff
- a campaign
- a deferred note because the boundary is not crisp enough yet

This is where the audit becomes operational instead of archival.

## Audit modes

Use the smallest audit mode that still answers the real question.

### 1. Full repo audit

Use when:

- a repo has not been audited recently
- a repo is about to absorb a major new feature area
- you suspect boundary drift, hotspot growth, or weak contracts

Run all four layers.

### 2. Focused follow-up audit

Use when:

- one subsystem is under pressure
- a prior audit already covered the rest of the repo
- you only need to verify one concern like logging, contracts, policy, or operator UX

Run Layer 0, the relevant part of Layer 1, the relevant part of Layer 2, then Layer 3.

### 3. Campaign audit

Use when:

- the concern crosses multiple repos
- sequencing matters
- the same contract or operator surface spans producers and consumers

In a campaign audit, each repo still gets a bounded review, but synthesis happens at the campaign level. The old logging audit is the pattern to follow here: bounded per-repo notes, then one summary.

## Repo-specific emphasis

Not every repo should be audited with the same weight.

### Rust service and CLI repos

Bias toward:

- dependency direction
- hotspot files
- config and policy modeling
- contracts with sibling tools
- authoritative local verification

Repos:

- `hyphae`
- `mycelium`
- `rhizome`
- `stipe`
- `cortina`
- `canopy`
- `volva`
- `spore`

### Frontend and operator surface repos

Bias toward:

- route and API ownership
- typed client and server boundaries
- read versus write claims
- actual feature surface versus dashboard docs
- test coverage on the interaction seams that matter

Repo:

- `cap`

### Packaging and authoring repos

Bias toward:

- source of truth versus generated output
- manifest validity
- packaging contracts
- host-specific export drift
- authoring docs matching real packaging behavior

Repo:

- `lamella`

## Evidence rules

Keep the audit concrete:

- cite files when a claim depends on code or docs
- record which commands actually ran
- distinguish verified facts from inference
- do not mark a repo green just because the tree looks tidy

When something cannot be verified locally, say that directly.

## What should become a handoff

Create a handoff when all three are true:

- the owning repo is clear
- the work is concrete enough to implement
- the verification surface is knowable

Do not create a handoff when the issue is still one of these:

- repo ownership is unclear
- the contract source of truth does not exist yet
- the work only makes sense as part of a larger rollout

That is when you create a campaign or defer the issue.

## Short runbook

Use this sequence:

1. Identify the owning repo.
2. Run Layer 0 commands and record what passes.
3. Run the structural review.
4. Check boundary, contract, and documentation fidelity.
5. Write `Keep`, `Tighten`, and `Watch`.
6. Convert only the crisp items into handoffs.
7. Group the cross-repo remainder into campaigns.

## What to reuse from the archived audits

These archived campaigns are still useful as source material:

- [global-audit](/.handoffs/archive/campaigns/global-audit/README.md)
  Use for the layer structure, baseline thinking, and boundary/doc-fidelity pass.
- [logging-audit](/.handoffs/archive/campaigns/logging-audit/README.md)
  Use for the pattern of bounded per-repo audit notes plus one shared synthesis.

Do not reuse their queue mechanics or one-off orchestration commands as the default method.

## Final read

The reusable lesson from the old global audit is simple: a good repo audit is layered.

First prove what green means.

Then inspect structure.

Then inspect the edges: boundaries, contracts, and docs.

Then turn only the crisp findings into action.
