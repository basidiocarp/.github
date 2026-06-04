# [Title]

<!-- Save as: .handoffs/work-items/<project>/<topic>.md -->
<!-- Create verify script: .handoffs/work-items/<project>/verify-<topic>.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct` | `umbrella`
- **Owning repo:** `[repo-name]`
- **Allowed write scope:** `[repo]/...`
- **Cross-repo edits:** `none` | `[allowed repo paths only]`
- **Hot shared files touched:** `none` | `[Cargo.toml, Cargo.lock, ecosystem-versions.toml, mod.rs/lib.rs hub, septa/** fixtures]` — listed files force serialization; a lane touching them cannot run in parallel with another lane touching the same file (use a checkpoint or worktree)
- **Contract dependency:** `none` | `[slug of the §septa contract-definition handoff this waits on]` — if set, this is `blocked-§septa` and cannot be marked Done until that contract is committed and `septa/validate-all.sh` + `scripts/test-integration.sh` pass
- **Non-goals:** [1 short sentence stating what this handoff does not include]
- **Assignee type:** `unassigned` | `human` | `agent` | `subagent`
- **Assignee id:** optional — stable identifier for the assigned agent or person
- **Graph:** optional — path to a `HandoffGraph` JSON file (e.g. `.handoffs/graphs/my-release.json`)
- **Wave:** optional — which wave this belongs to; same-wave handoffs may run in parallel if scopes are disjoint
- **Depends-on:** optional — comma-separated slugs of handoffs that must complete first
- **Step parallelism:** Tag independent steps with `[P: <group>]` in the step header. Steps sharing a group name run concurrently. A group boundary implies a checkpoint — all steps in the earlier group must complete before the later group starts.
- **Branch of:** optional — task ID if this is a branch exploration
- **Branch outcome:** optional — `merged` | `discarded`; filled after parallel exploration resolves
- **Produces:** optional — artifacts other handoffs may consume
- **Verification contract:** run the repo-local commands below and `bash .handoffs/work-items/<project>/verify-<topic>.sh`

## Implementation Seam

_Written when the handoff is created (initial estimate):_

- **Likely repo:** `[repo-name]`
- **Likely files/modules:** [name the most likely files or modules; if unknown, name the owning seam and tighten before dispatching]
- **Reference seams:** [existing files, commands, or surfaces to imitate rather than build in parallel]

_Completed by the parent during the seam-finding pass — required before dispatch:_

| File | Symbol / anchor | Callers | Captured @ commit | Change |
|------|-----------------|---------|-------------------|--------|
| `[path]` | `[function_or_type_name]` | `[N from find_references; note cross-repo]` | `[git -C <repo> log -1 --format=%h -- <file>]` | [what to add or change] |

> Use function or symbol names as anchors, not line numbers. Line numbers go stale when agents touch the same file concurrently. If you must reference a line, always pair it with the enclosing symbol name. Use Rhizome (`mcp__rhizome__search_symbols`, `mcp__rhizome__get_definition`) to locate the exact symbol during the seam pass.
>
> **Caller census:** fill Callers via `find_references` / `get_call_sites` / `analyze_impact`. If > 5 callers or any cross-repo caller, an invariant must cover cross-call behavior and verification must include the callers' tests.
>
> **Staleness stamp:** `Captured @ commit` is the file's latest commit at seam-write time. If it differs at dispatch, re-verify the whole seam, not just problem existence.

**Behavioral invariants:** 2-3 constraints the implementation must not violate, stated as observable conditions:
- _(example: `handle_empty` must return `Ok(())` when given an empty slice)_
- _(example: the JSON round-trip for existing fixture payloads must be lossless)_
- _(if many callers: a cross-call invariant — e.g. "all existing call sites compile and pass their tests unchanged")_

- **Verification command:** `(cd [repo] && [command])`
- **Dispatch gate:** `[ ]` seam confirmed — [1-line summary of exact insertion point once found]
- **Clarification gate:** resolve all `[NEEDS CLARIFICATION]`, `[TBD]`, and `[OPEN QUESTION]` markers before dispatching — unresolved markers block dispatch

> **Spawn gate:** do not launch an implementer until the dispatch gate is checked and the seam table is filled.

## Problem

[1-3 sentences: what's broken or missing and why it matters]

## What exists (state)

- **[Component]:** [current state — what's built, what's not]
- **[File/Feature]:** [current state]

## What needs doing (intent)

[High-level description of the work]

## Scope

- **Primary seam:** [the one subsystem or boundary this handoff owns]
- **Allowed files:** [specific paths or path prefixes]
- **Explicit non-goals:**
  - [nearby work that must not be folded into this handoff]

> **Execution freeze:** once dispatched, the sections above (Problem, What exists, What needs doing, Scope, Allowed files, Non-goals) are read-only. If the plan turns out to be wrong during implementation, raise a flag to the orchestrator — do not silently rewrite scope to fit the diff. Only status, verification output blocks, and Completion fields are mutable during execution.

---

### Step 1: [Step Title] `[P: group-name]`

**Project:** `[directory/]`
**Effort:** [estimate]
**Depends on:** nothing | Step N

[Description of what to do, with code snippets if helpful]

#### Files to modify

**`path/to/file`** — [what to change]:

```rust
// code snippet or pseudocode
```

#### Verification

Run these commands and **paste the full output** into the sections below. Do NOT mark this step complete until output is pasted. Use subshells when running from workspace root to ensure the correct working directory. Capture the **raw exit code** — Stage 2 re-runs and compares against it; a "looks green" paste is an unverified claim.

```bash
(cd [repo] && [verification command]); echo "exit:$?"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Exit code:** `[exit:N line — must be exit:0 to pass]`

**Checklist:**
- [ ] [specific, testable assertion]
- [ ] [specific, testable assertion]

---

### Step 2: [Step Title]

[Repeat structure for each step]

---

## Residual Work

Any finding not fixed in this handoff must be logged here before signoff. Leaving this section empty is only valid when every finding from review was fixed.

| Finding | Disposition | Link / Note |
|---------|-------------|-------------|
| _(none)_ | | |

**Allowed dispositions:** Fixed (no entry needed) · Follow-up handoff (link it) · Filed ticket (link it) · Accepted with note (permanent codebase comment or doc)

> **Recurring-finding feedback:** if a finding here repeats a class seen in earlier handoffs, promote it into the seam-pass checklist or a lamella rule and capture it with `hyphae extract-lessons` so the next handoff doesn't re-make the same mistake.

---

## Completion

**This handoff is NOT complete until ALL of the following are true:**

- [ ] Every step has verification output pasted between the markers, each with its `exit:0` line
- [ ] Verification script passes: `bash .handoffs/work-items/<project>/verify-<topic>.sh`
- [ ] **Stage 2 re-ran the verification itself** (did not read the implementer's paste) and saw the same `exit:0` against the final diff
- [ ] All step checklists are checked
- [ ] Residual Work section is filled or confirmed empty (only valid when Stage 2 reports zero open findings)
- [ ] **Contract barrier (only if `Contract dependency` is set):** the named contract handoff is committed and `cd septa && bash validate-all.sh` + `./scripts/test-integration.sh` both pass
- [ ] `.handoffs/HANDOFFS.md` updated to reflect completion

**Final verification — run and paste output:**

```bash
bash .handoffs/work-items/<project>/verify-<topic>.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

- **Disposition:** `keep` | `discard` | `crash`
- **Disposition reason:** _(required for discard or crash)_
- **Commit:** _(git short hash)_

---

## Failure Breadcrumb _(fill on relaunch only — leave empty on first dispatch)_

If this handoff is being relaunched after a failed attempt, record what was tried so the next agent doesn't repeat the same dead end.

> **Relaunch cap:** maximum 2 relaunches (attempts 1, 2, 3). If attempt 3 fails, do not re-dispatch — escalate for re-planning (the problem is likely in the design, seam, or spec, not the execution) and note the escalation in the carry-forward column.

| Attempt | Approach tried | Root cause of failure | Carry-forward context |
|---------|----------------|-----------------------|----------------------|
| _(none)_ | — | — | — |

## Context

[Why this work exists, links to related handoffs or issues]

---

> **Style notes:** One repo, one primary seam, one verification surface per handoff. If work spans multiple repos or phases, create an umbrella handoff and split into children before dispatch. Use `Dispatch: umbrella` only for decomposition or coordination — umbrella handoffs are never sent to implementers directly.
