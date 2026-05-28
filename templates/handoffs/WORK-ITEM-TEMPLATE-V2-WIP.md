# [Title]

<!-- Save as: .handoffs/<project>/<topic>.md -->
<!-- Create verify script: .handoffs/<project>/verify-<topic>.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct` | `umbrella`
- **Owning repo:** `[repo-name]`
- **Allowed write scope:** `[repo]/...`
- **Cross-repo edits:** `none` | `[allowed repo paths only]`
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
- **Verification contract:** run the repo-local commands below and `bash .handoffs/<project>/verify-<topic>.sh`

## Implementation Seam

_Written when the handoff is created (initial estimate):_

- **Likely repo:** `[repo-name]`
- **Likely files/modules:** [name the most likely files or modules; if unknown, name the owning seam and tighten before dispatching]
- **Reference seams:** [existing files, commands, or surfaces to imitate rather than build in parallel]

_Completed by the parent during the seam-finding pass — required before dispatch:_

| File | Insertion point | Change |
|------|-----------------|--------|
| `[path]` | `[line/method]` | [what to add or change] |

- **Confirmed deps / invariants:** [patterns, functions, or contracts this implementation must match]
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

Run these commands and **paste the full output** into the sections below. Do NOT mark this step complete until output is pasted. Use subshells when running from workspace root to ensure the correct working directory.

```bash
(cd [repo] && [verification command])
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

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

---

## Completion

**This handoff is NOT complete until ALL of the following are true:**

- [ ] Every step has verification output pasted between the markers
- [ ] Verification script passes: `bash .handoffs/<project>/verify-<topic>.sh`
- [ ] All step checklists are checked
- [ ] Residual Work section is filled or confirmed empty
- [ ] `.handoffs/HANDOFFS.md` updated to reflect completion

**Final verification — run and paste output:**

```bash
bash .handoffs/<project>/verify-<topic>.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

- **Disposition:** `keep` | `discard` | `crash`
- **Disposition reason:** _(required for discard or crash)_
- **Commit:** _(git short hash)_

## Context

[Why this work exists, links to related handoffs or issues]

---

> **Style notes:** One repo, one primary seam, one verification surface per handoff. If work spans multiple repos or phases, create an umbrella handoff and split into children before dispatch. Use `Dispatch: umbrella` only for decomposition or coordination — umbrella handoffs are never sent to implementers directly.
