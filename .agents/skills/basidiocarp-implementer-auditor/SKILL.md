---
name: basidiocarp-implementer-auditor
description: Use when the user explicitly asks for the implementer or auditor pattern, the strict implementer-then-auditor workflow, or wants one agent to implement a concrete handoff and a separate agent to audit it after real code and verification exist.
---

# Basidiocarp Implementer Auditor

Use this skill only when the user explicitly asks for the implementer/auditor pattern. This is a strict workflow, not a loose suggestion.

## Core Rule

Implementation comes first. Audit comes second. Do not start the auditor until there is a real repo diff and verification output from the implementer.

Use this naming convention for strict-workflow agents:

`<role>/<repo>/<handoff-slug>/<run>`

Examples:

- `impl/spore/otel-foundation/1`
- `audit/spore/otel-foundation/1`
- `impl/cortina/handoff-path-extraction/1`
- `audit/cortina/handoff-path-extraction/1`

If a human nickname is available, keep it secondary:

- `impl/spore/otel-foundation/1 (Dalton)`
- `audit/spore/otel-foundation/1 (Lorentz)`

## Workflow

1. Pick one concrete handoff or child handoff. If the source handoff is broad, decompose it first and choose one child.
2. Before spawning, do a short local seam-finding pass:
   - confirm the owning repo
   - identify the likely files or modules to change
   - identify the exact repo-local verification commands
   If you cannot name the likely file set yet, keep the work local until the seam is clearer.
3. Spawn exactly one implementation agent for that one scoped task.
   Name it with the stable workflow label for that handoff and run.
4. Tell the implementation agent:
   - the owning repo and files it owns
   - not to drift into sibling repos or umbrella planning
   - that the parent agent owns orchestration, decomposition, relaunch decisions, dashboard edits, and archive moves
   - that it is a code-only worker, not a workflow narrator
   - that its first actions are: inspect repo state, read target files, then make code changes
   - to make the code changes
   - to update the handoff when the handoff expects pasted verification evidence
   - to run the repo-local verification named in the handoff
   - to send occasional progress updates back to the parent agent
   - to return changed files, exact verification output, and blockers
5. Wait for evidence of real progress:
   - code diff in the owning repo
   - verification output from the implementer
6. Only then spawn a separate auditor agent.
   Reuse the same repo, handoff slug, and run number, changing only `impl` to `audit`.
7. Tell the auditor:
   - review the changed code and the handoff together
   - look for regressions, incomplete work, and new bugs
   - report findings first
   - send occasional progress updates back to the parent agent
8. If the auditor finds issues:
   - fix them
   - rerun the relevant verification
   - do not mark the handoff complete until the fixes are reviewed
9. Once the audit is clean and verification is green, update the handoff dashboard to reflect completion. If the dashboard tracks active work only, archive or remove the completed entry in the same close-out flow.
10. Close the implementer after implementation is accepted.
11. Close the auditor after the audit is accepted.

## Hard Gates

- Do not launch two implementation agents for the same handoff.
- Do not launch the auditor before there is a real diff.
- Do not treat status chatter as progress.
- Do not treat orchestration summaries, relaunch notes, or dashboard commentary as task completion.
- Do not leave stalled or completed agents open.
- Parallel strict workflows are allowed only when they target different concrete handoffs with disjoint write scopes.
- Do not spawn an implementer before the likely file set and verification commands are known.

## Lane Triage

Check each implementation lane early.

- If there is no real repo diff yet, treat the lane as at risk.
- If there is a repo diff but it is off-scope for the handoff, close the lane immediately.
- Only lanes with an on-scope diff plus repo-local verification output are allowed to advance to audit.
- Do not keep weak lanes alive out of optimism. Close them, narrow the scope, and relaunch only if the task is concrete enough.

## Failure Handling

If the implementer reports orchestration chatter, nested delegation, or no repo diff:

1. Close that agent.
2. Narrow the scope further or take the work locally.
3. Relaunch only when the task is concrete enough to finish inside one repo.

If the implementer reports meta-status such as "relaunch complete," "audit complete," or "workflow started" without a repo diff in the owning repo, treat that as failure, not progress.

If the auditor reports findings, surface them clearly with file references and fix them before signoff.

## Parent Agent Checklist

- [ ] one concrete handoff chosen
- [ ] one implementer spawned
- [ ] worker prompt keeps orchestration local and makes the implementer code-only
- [ ] real diff observed
- [ ] verification output observed
- [ ] one auditor spawned after the diff
- [ ] findings fixed if needed
- [ ] dashboard updated when work is complete
- [ ] implementer closed
- [ ] auditor closed
