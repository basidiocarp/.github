# Handoffs

This folder keeps active operational work close to the workspace, but it no longer tries to be an active queue, a session-notes folder, an archive, and a template library at the same time.

## What goes where

- `HANDOFFS.md`: active dashboard only
- `<project>/` and `cross-project/`: active work items with paired `verify-*.sh` scripts
- `campaigns/`: longer multi-step efforts such as audits or rollout waves
- `sessions/open/`: current session notes that still matter
- `sessions/archive/YYYY/MM/`: old session notes kept for lookup
- `archive/`: completed handoffs and old verification scripts
- `state/`: local status files such as runner state
- `scripts/`: local maintenance helpers for this folder

Templates live outside this folder in `templates/handoffs/`.

## Naming rules

- Work item: `topic.md`
- Verify script: `verify-topic.sh`
- Session note: `YYYY-MM-DD-topic.md`
- Campaign: directory with a `README.md`

## Required handoff fields

Every active handoff should include a `Handoff Metadata` block near the top with:

- dispatchability: `direct` or `umbrella`
- owning repo or repos
- allowed write scope
- cross-repo edit rule
- non-goals
- verification contract
- completion update rule

Every active handoff should also include an `Implementation Seam` block with:

- likely repo
- likely files or modules
- reference seams
- spawn gate

Use [WORK-ITEM-TEMPLATE.md](../templates/handoffs/WORK-ITEM-TEMPLATE.md) as the canonical source for that structure.

## Working rules

- New actionable work goes under `.handoffs/<project>/` or `.handoffs/cross-project/`.
- Finished work moves to `.handoffs/archive/`.
- Session resume notes do not belong in the active queue.
- Campaign folders are for multi-file or multi-repo programs, not one-off handoffs.
- Keep `.handoffs/HANDOFFS.md` short. It should point at active work, not become a historical ledger.
- When delegated work uses the implementer/auditor pattern, follow the strict workflow in [AGENTS.md](/Users/williamnewton/projects/basidiocarp/AGENTS.md): implementer first, auditor only after a real diff and verification output, findings fixed before signoff, the dashboard updated when the work is complete, and both agents closed when done. Parallel workflows are fine when they own different concrete handoffs and disjoint write scopes.
- Name strict-workflow agents as `<role>/<repo>/<handoff-slug>/<run>`, with any human nickname shown secondarily, for example `impl/spore/otel-foundation/1 (Dalton)`.
- Triage delegated lanes actively. Empty lanes and off-scope lanes should be closed quickly instead of being carried forward to audit.
- Keep orchestration local. Parent agents audit handoffs, split umbrellas, relaunch lanes, update dashboards, and archive completed work. Implementation agents do code-only work inside the owning repo.
- Before launching an implementation agent, do a short local seam-finding pass so the worker gets the likely file set and exact repo-local verification commands instead of only the handoff prose.
- Launch implementation agents with a required first-action sequence: inspect repo state, read the named target files, make code changes, run the named verification, then report changed files and exact command output.
- Workflow summaries, relaunch notes, and other meta-status replies without a repo diff count as failure and should be closed quickly.

## Compatibility note

Some local tooling still looks for `.handoffs/HANDOFFS.md` and active handoffs under `.handoffs/<project>/`. This layout keeps those paths stable on purpose.
