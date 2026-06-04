# [Title]

<!-- Save as: .handoffs/work-items/<project>/<topic>.md -->
<!-- Create verify script: .handoffs/work-items/<project>/verify-<topic>.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `[repo-name]`
- **Allowed write scope:** `[repo]/...`
- **Cross-repo edits:** `none` | `[allowed repo paths only]`
- **Hot shared files touched:** `none` | `[Cargo.toml, Cargo.lock, ecosystem-versions.toml, mod.rs/lib.rs hub, septa/** fixtures]` — if any are listed, this handoff cannot run in parallel with another lane that touches the same file; serialize behind a checkpoint or use a worktree.
- **Contract dependency:** `none` | `[slug of the §septa contract-definition handoff this one waits on]` — if set, this handoff is `blocked-§septa` and cannot be marked Done until that contract handoff is committed and `septa/validate-all.sh` + `scripts/test-integration.sh` pass (see Completion Protocol).
- **Non-goals:** [1 short sentence stating what this handoff does not include]
- **Assignee type:** `unassigned` | `human` | `agent` | `subagent`
- **Assignee id:** optional — stable identifier for the assigned agent or person
- **Graph:** `optional` — path to a `HandoffGraph` JSON file declaring dependencies between steps (e.g. `.handoffs/graphs/my-release.json`)
- **Wave:** `optional` — which wave this handoff belongs to (e.g. `1`, `2`); handoffs in the same wave may run in parallel if scopes are disjoint
- **Depends-on:** `optional` — comma-separated slugs of handoffs that must complete before this one starts (e.g. `septa-heartbeat-schema, canopy-dag-topology`)
- **Step parallelism:** Tag independent steps with `[P: <group>]` in the step header (e.g. `### Step 2: Build widget [P: build-phase]`). Steps sharing the same group name can run in parallel. Steps without a tag are sequential. A group boundary (different group names) implies a checkpoint — all steps in the earlier group must complete before the later group starts.
- **Branch of:** — (task ID if this is a branch exploration; leave empty for main tasks)
- **Branch outcome:** — (merged | discarded; only filled after parallel exploration resolves)
- **Produces:** `optional` — artifacts other handoffs may consume (e.g. `septa/agent-heartbeat-v1.schema.json`, `cortina/src/signals.rs`)
- **Verification contract:** run the repo-local commands below and `bash .handoffs/work-items/<project>/verify-<topic>.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `[repo-name]`
- **Likely files/modules:** [name the most likely files or modules to change; if exact files are not known yet, name the owning seam and tighten this before spawning an implementer]
- **Reference seams:** [existing files, commands, or surfaces to imitate rather than parallel implementations]

_Completed by the parent during the seam-finding pass — required before dispatch:_

| File | Symbol / anchor | Callers | Captured @ commit | Change |
|------|-----------------|---------|-------------------|--------|
| `[path]` | `[function_or_type_name]` | `[N callers from find_references / get_call_sites; note any cross-repo]` | `[git -C <repo> log -1 --format=%h -- <file>]` | [what to add or change] |

> Use function or symbol names as anchors, not line numbers. Line numbers go stale when agents touch the same file concurrently. Use Rhizome (`mcp__rhizome__search_symbols`, `mcp__rhizome__get_definition`) to locate the exact symbol during the seam pass.
>
> **Caller census:** fill the Callers column with `find_references` / `get_call_sites` (or `analyze_impact`). If a symbol has > 5 callers or any cross-repo caller, at least one invariant below must cover cross-call behavior and the verification must include the callers' tests.
>
> **Staleness stamp:** the `Captured @ commit` hash records the file's latest commit when the seam was written. At dispatch, if the file's current `log -1` differs, re-verify the whole seam (anchor + invariants + callers), not just that the problem still exists.

**Behavioral invariants:** 2-3 constraints the implementation must not violate:
- _(example: `handle_empty` must return `Ok(())` when given an empty slice)_
- _(example: the JSON round-trip for existing fixture payloads must be lossless)_
- _(if the symbol has many callers: a cross-call invariant — e.g. "all existing call sites compile and pass their tests unchanged")_

- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands
- **Clarification gate:** resolve all `[NEEDS CLARIFICATION]`, `[TBD]`, and `[OPEN QUESTION]` markers in this document before dispatching — unresolved markers block dispatch

## Problem

[1-3 sentences: what's broken or missing, and why it matters]

## What exists (state)

- **[Component]:** [Current state — what's built, what's not]
- **[File/Feature]:** [Current state]

## What needs doing (intent)

[High-level description of the work]

## Scope

- **Primary seam:** [the one subsystem or boundary this handoff owns]
- **Allowed files:** [specific paths or path prefixes]
- **Explicit non-goals:** [bullets for nearby work that should not be folded into this handoff]

> **Execution freeze:** once this handoff is dispatched, the sections above (Problem, What exists, What needs doing, Scope, Allowed files, Non-goals) are read-only. If the plan turns out to be wrong during implementation, raise a flag to the orchestrator — do not silently rewrite scope to fit the diff. Only status, verification output blocks, and Completion fields are mutable during execution.

---

### Step 1: [Step Title] `[P: group-name]` _(optional — tag only if this step is independent)_

> **Parallel group:** `group-name` — steps sharing the same group name can run concurrently.
> Steps without a `[P: ...]` tag are sequential. A group boundary (different group names)
> implies a checkpoint — all steps in the earlier group must complete before the later group starts.

**Project:** `[directory/]`
**Effort:** [estimate]
**Depends on:** [nothing / Step N]

[Description of what to do, with code snippets if helpful]

#### Files to modify

**`path/to/file`** — [what to change]:

```
[code snippet or pseudocode]
```

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

When running from the workspace root, use subshells to ensure correct working directory.
Record the **exact command** and its **raw exit code** — not a prose summary. The exit code
is what Stage 2 re-runs and compares against; a pasted "looks green" is an unverified claim.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
(cd <repo> && [verification command]); echo "exit:$?"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Exit code:** `[the exit:N line above — must be exit:0 to pass]`

**Checklist:**
- [ ] [Specific, testable assertion]
- [ ] [Specific, testable assertion]

---

### Step 2: [Step Title]

[Repeat structure for each step]

---

## Residual Work

Any review finding that was not fixed in this handoff must be logged here before signoff. Leaving this section empty is valid only when every finding from Stage 1 and Stage 2 review was fixed. If findings were accepted as-is, each needs an entry with a durable disposition.

| Finding | Disposition | Link / Note |
|---------|-------------|-------------|
| _(example: unused import in foo.rs)_ | Follow-up handoff | `.handoffs/work-items/canopy/cleanup-foo-imports.md` |

**Allowed dispositions:** Fixed (no entry needed) · Follow-up handoff (link it) · Filed ticket (link it) · Accepted with note (permanent codebase comment or doc)

> **Recurring-finding feedback:** if a finding here repeats a class seen in earlier handoffs (same bug pattern, same omission), don't just log it — promote it into the seam-pass checklist or a lamella rule and capture it with `hyphae extract-lessons`, so the next handoff doesn't re-make the same mistake.

---

## Failure Breadcrumb _(fill on relaunch only — leave empty on first dispatch)_

If this handoff is being relaunched after a failed attempt, record what was tried so the next agent doesn't repeat the same dead end.

> **Relaunch cap:** maximum 2 relaunches (attempts 1, 2, 3). If attempt 3 fails, do not re-dispatch — escalate the handoff for re-planning (the problem is likely in the design, seam, or spec, not the execution) and note the escalation in the carry-forward column below.

| Attempt | Approach tried | Root cause of failure | Carry-forward context |
|---------|----------------|-----------------------|----------------------|
| _(none)_ | — | — | — |

## Completion

- **Disposition:** keep | discard | crash
- **Disposition reason:** _(required for discard or crash; empty for keep)_
- **Commit:** _(git short hash if keep)_

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers, each with its `exit:0` line
2. The verification script passes: `bash .handoffs/work-items/<project>/verify-<topic>.sh`
3. **Stage 2 re-ran the verification itself** (did not read the implementer's paste) and saw the same `exit:0` against the final diff
4. All checklist items are checked
5. The Residual Work section is filled or confirmed empty (only valid when Stage 2 reports zero open findings)
6. **Contract barrier (only if `Contract dependency` is set):** the named contract-definition handoff is committed, and `cd septa && bash validate-all.sh` + `./scripts/test-integration.sh` both pass
7. The active handoff dashboard is updated to reflect completion
8. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/work-items/<project>/verify-<topic>.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

[Why this work exists, links to related handoffs or issues]

## Style Notes

- Prefer one repo, one primary seam, and one verification surface per handoff.
- If the work spans multiple repos or phases, create an umbrella handoff and split it into child handoffs before dispatch.
- Use `Dispatch: umbrella` only for decomposition or coordination notes. Umbrella handoffs should not be sent to implementers directly.
