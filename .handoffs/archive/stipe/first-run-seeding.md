# First-Run Seeding

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** stipe/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

When a user installs the basidiocarp ecosystem for the first time, hyphae's memory is empty, cortina has no signal history, and canopy has no task state. The first session gets no benefit from the memory layer. Mempalace addresses this with an onboarding flow that seeds initial context — project identity, user preferences, and baseline knowledge — so the first session isn't starting cold.

## What exists (state)

- **stipe init**: handles install and host setup but doesn't seed any project-level context.
- **hyphae onboard**: MCP tool that accepts initial context, but requires the user or agent to explicitly call it.
- **lamella**: packages skills that could include onboarding prompts.
- **No automatic first-run detection or seeding workflow.**

## What needs doing (intent)

Add lightweight first-run seeding to `stipe init` — automatic project detection and context seeding so the first session isn't cold, plus an optional interactive mode for users who want to provide more context.

---

### Step 1: Add first-run detection to stipe init

**Project:** `stipe/`
**Effort:** 4-8 hours
**Depends on:** nothing

After `stipe init` completes host setup, check whether hyphae has any memories for the current project. If the hyphae database is empty or has no project-scoped memories:
- Detect project type from repo markers (Cargo.toml → Rust, package.json → JS/TS, etc.).
- Gather basic project identity: repo name, primary language, directory structure summary.
- Call `hyphae memory store` with topic `context/{project}` and importance `high` to seed baseline project context.
- Print a message: "Seeded initial project context for {project}. Hyphae will learn more as you work."

This is lightweight seeding, not a full onboarding wizard. The goal is "first session isn't cold" not "comprehensive project understanding."

#### Verification

```bash
cd stipe && cargo build --release && cargo test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe init` detects empty hyphae state for current project
- [ ] Basic project identity is seeded into hyphae
- [ ] Seeding is idempotent (running init twice doesn't duplicate memories)
- [ ] Seeding is skipped gracefully if hyphae is not installed

---

### Step 2: Add optional seeding prompts to stipe init --interactive

**Project:** `stipe/`
**Effort:** 2-4 hours
**Depends on:** Step 1

Add an `--interactive` flag to `stipe init` that asks the user a few optional questions:
- "What's the primary purpose of this project?" (free text, stored as project context)
- "Any key architectural decisions worth remembering?" (free text, stored as decision memory)
- Skip with Enter for any question. Non-interactive mode (default) does automatic seeding only.

#### Verification

```bash
cd stipe && cargo build --release && cargo test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `--interactive` flag prompts for optional context
- [ ] Answers are stored as hyphae memories with appropriate topics
- [ ] Default (non-interactive) behavior unchanged from Step 1

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/stipe/verify-first-run-seeding.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/stipe/verify-first-run-seeding.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `stipe` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom the mempalace borrow audit ("Adapt" category). Mempalace's onboarding seeds initial identity context so the first session has memory to work with. This adaptation is lighter — automatic project detection via stipe rather than a personal taxonomy model. Borrow the first-run seeding idea, not the whole personal-taxonomy model.
