# Workspace Agent Notes

## Purpose

This workspace is a routing layer, not one unified project. Most tasks mean finding the owning repo, changing source there, and validating there. Preserve repo boundaries; they are what keep cross-tool work sane.

---

## Source of Truth

- top-level project dirs: the real source lives inside the repo you are changing.
- `septa/`: authoritative cross-tool payload shapes and fixtures.
- `ecosystem-versions.toml`: shared dependency pins across repos.
- `docs/foundations/`: workspace Rust architecture standards, checklist, and audit template.
- `.audit/external/SYNTHESIS.md`: current cross-example ecosystem takeaways from the external audit corpus.
- `.audit/external/AUDITING.md`: method for repo-level external borrow audits and feature-to-ecosystem mapping.
- `lamella/resources/` and `lamella/manifests/`: source for Lamella content and packaging.
- `dist/`, `target/`, and similar build output: generated output. Do not hand-edit unless the task is explicitly about generated artifacts.

If the workspace root and a subproject disagree, the subproject wins. If code and `septa/` disagree on a cross-tool payload, update `septa/` first.

---

## Before You Start

Before writing code, verify:

1. **Owning repo**: identify which project actually owns the change.
2. **Contracts**: if the task crosses a tool boundary, read `septa/README.md` first.
3. **Versions**: check `ecosystem-versions.toml` before changing shared dependencies.
4. **Foundation standards**: for Rust architecture or repo-boundary work, read `docs/foundations/`.
5. **Build surface**: switch into the touched repo before running git, build, or test commands.
6. **Lamella context**: for substantial Lamella work, read `lamella/docs/authoring/`.
7. **External audit context**: when evaluating borrowed ideas, read `.audit/external/SYNTHESIS.md` first and `.audit/external/AUDITING.md` if you are writing or refreshing an audit.

---

## Preferred Commands

Use these for most work:

```bash
rg <pattern> <path>                     # fast text search
fd <name> <path>                        # fast file and directory discovery
```

For targeted work:

```bash
cd <repo> && cargo build --release && cargo test   # Rust repos
cd cap && npm run build && npm test                # dashboard work
cd lamella && make validate                        # Lamella content and packaging checks
```

---

## Repo Architecture

Each top-level project owns its own code, tests, and git history. The root owns shared docs, cross-project contracts, version pins, and coordination notes.

Key boundaries:

- `septa/`: owns cross-tool schemas and fixtures; do not treat payloads as informal.
- `docs/`: workspace-level notes, not a substitute for project-local docs.
- `lamella/`: packages shared content; generated output is not the source of truth.
- `hymenium/`: owns workflow orchestration, dispatch, phase gating, and retry and recovery.
- `annulus/`: owns cross-ecosystem operator utilities and statusline tooling.
- top-level project dirs: build, test, and commit inside the repo you touched.

Current direction:

- Keep cross-tool coupling explicit through `septa/`.
- Keep shared dependency drift visible through `ecosystem-versions.toml`.
- Keep root guidance thin enough that it does not override project-local rules.

---

## Cross-Tool Integration Rules

CLIs are human and operator surfaces. Do not use them as system-to-system APIs.

New cross-tool calls must go through one of:

1. **Library/crate dependency** — compile-time link via `spore` or `ecosystem-versions.toml` pins (preferred)
2. **Local service endpoint** — Unix socket, loopback TCP, or HTTP typed via `septa/local-service-endpoint-v1.schema.json`
3. **CLI fallback** — temporary compatibility adapter only; must emit a visible warning at runtime and be documented in `septa/integration-patterns.md` with a replacement handoff noted

If you are about to shell out to a sibling tool, read `docs/foundations/inter-app-communication.md` first and use the appropriate integration path instead.

---

## Working Rules

- Run project-local commands in the repo you changed, not at the workspace root.
- Prefer Rhizome or targeted reads over dumping whole files when code structure matters.
- Use `rg` over `grep` and `fd` over `find`.
- For Lamella audits, review manifests, docs, and source content together instead of only changed files.
- When a task crosses tool boundaries, update schemas, fixtures, and all affected producers or consumers in the same change.
- When a task changes Rust repo structure or maintainer guidance, keep `docs/foundations/` as the standards source of truth.
- If validation was skipped in a touched repo, say so clearly in the final response.

---

## Multi-Agent Patterns

For substantial workspace-spanning work, default to two agents:

**1. Primary implementation worker**
- Owns the actual write scope in the touched repo or repos
- Does not drift into unrelated sibling projects just because they are nearby

**2. Independent validator**
- Reviews the broader shape rather than redoing the implementation
- Specifically looks for contract drift across repos, root-vs-subrepo confusion, missed validation in a touched project, and stale Lamella source-vs-generated output mistakes

Add a docs worker when README, `CLAUDE.md`, `AGENTS.md`, or authoring docs changed materially.

Sequencing: do not stop local work just because a validator is running. Wait only when the next edit depends on the review result.

### Strict Implementer/Auditor Workflow

When the user asks for the implementer/auditor pattern, follow this protocol exactly:

1. Spawn exactly one implementation agent for one concrete handoff or child handoff.
2. The implementation agent must:
   - stay inside the owning repo and assigned handoff scope
   - do implementation only; orchestration, decomposition, relaunch decisions, dashboard edits, and archive moves stay with the parent agent
   - start by inspecting repo state and the named target files, then move directly into code changes
   - make the code changes
   - update the handoff when the handoff requires verification evidence
   - run the repo-local verification named in the handoff
   - send occasional progress updates back to the parent agent
   - return changed files, verification output, and any blockers
3. Do not spawn the auditor until there is a real code diff in the target repo and the implementer has reported verification results.
4. The auditor must be a separate agent and must:
   - review the changed code
   - review the handoff against the requested scope
   - check for regressions, incomplete work, and newly introduced bugs
   - report findings first, not summaries
   - send occasional progress updates back to the parent agent
5. If the auditor finds issues, fix them, rerun the relevant verification, and do not treat the work as complete until the fixes are reviewed.
6. Close the implementer agent after the implementation is accepted.
7. Close the auditor agent after the audit is accepted.
8. Once the audit is clean and verification is green, update the handoff dashboard to reflect completion. If the dashboard tracks active work only, archive or remove the completed handoff entry in the same close-out flow.
9. Do not leave completed or stalled agents open.
10. Status-only replies do not count as progress. If an agent returns orchestration chatter without code changes or verification evidence, close it and relaunch with a narrower scope or take the work locally.

Parallel strict workflows are allowed when they own different concrete handoffs and their write scopes are disjoint. For example, one workflow in `mycelium` and another in `hyphae` is fine. Two implementers on the same handoff, or overlapping write ownership inside one repo, is not.

#### Workflow Naming

Name strict-workflow agents with this stable label:

`<role>/<repo>/<handoff-slug>/<run>`

Examples:

- `impl/spore/otel-foundation/1`
- `audit/spore/otel-foundation/1`
- `impl/cortina/handoff-path-extraction/1`
- `audit/cortina/handoff-path-extraction/1`

Rules:

- `role` is `impl` or `audit`
- `repo` is the owning repo
- `handoff-slug` is the handoff file basename without `.md`
- `run` starts at `1` and increments only when the workflow is relaunched
- the implementer and auditor for the same workflow share the same `repo`, `handoff-slug`, and `run`

If the platform also provides a human-readable nickname, keep it secondary:

- `impl/spore/otel-foundation/1 (Dalton)`
- `audit/spore/otel-foundation/1 (Lorentz)`

#### Lane Triage

Strict workflows still need active triage. Do not wait passively for every lane to succeed.

Use this cadence:

1. After launch, check each implementation lane early for a real repo diff.
2. If a lane has no diff after an initial check, treat it as at risk and check again before spending more time on it.
3. If a lane produces a diff that is off-scope for the handoff, close it immediately rather than hoping it will self-correct.
4. Only productive lanes continue toward audit:
   - on-scope repo diff
   - repo-local verification output
   - handoff evidence updated when required
5. If a lane is idle or off-scope, close it and either relaunch with a narrower scope or take the work locally.

The goal is not to keep every lane alive. The goal is to keep only the lanes that are producing trustworthy progress.

#### Code-Only Worker Rule

Keep orchestration and implementation separate.

- The parent agent owns handoff audit, decomposition, relaunch decisions, dashboard edits, and archive moves.
- The implementation agent owns repo-local code changes, repo-local verification, and handoff evidence updates only when the handoff requires pasted output.
- Do not ask an implementation agent to audit the handoff, decide whether to relaunch itself, summarize workflow state as the task result, or perform queue management.

When launching an implementation agent, require this execution shape:

1. inspect repo state in the owning repo
2. read the named target files
3. modify code in the allowed write scope
4. run the named verification
5. return changed files and exact command output

If the first check shows workflow summaries, relaunch notes, or other meta-status replies without a repo diff, treat that as failure and close the lane immediately.

#### Pre-Spawn Seam Finding

Do not spawn an implementation agent until the parent agent has identified the likely file set and command set.

Use a short local seam-finding pass first:

1. confirm the owning repo
2. identify the most likely files or modules to change
3. identify the exact repo-local verification commands
4. then launch the implementer with only that narrowed context

If the parent agent cannot name likely files yet, the task is still too ambiguous for a spawned implementer and should stay local until the seam is clear.

---

## Skills to Load

Use these for most work in this workspace:

- `basidiocarp-workspace-router`: routes the task to the right repo and command set.
- `basidiocarp-implementer-auditor`: use when the user explicitly asks for the strict implementer-then-auditor workflow.
- `systematic-debugging`: use before changing code in response to a failure you have not explained yet.

Use these when the task needs them:

- `basidiocarp-lamella`: when editing Lamella skills, agents, manifests, hooks, or authoring docs.

---

## Authoring Reference

Read before making changes to Lamella content or packaging:

| Doc | When to Read |
|-----|--------------|
| `lamella/docs/authoring/skills-spec.md` | **Always** when editing skills |
| `lamella/docs/authoring/best-practices.md` | **Always** when editing authoring content |
| `lamella/docs/authoring/agent-style-guide.md` | **Always when editing agents** |
| `lamella/docs/reference/claude/` and `lamella/docs/reference/codex/` | When changing packaging or host-specific metadata |

---

## Done Means

A task is not complete until:

- [ ] The change lives in the right repo and the right source files
- [ ] The narrowest relevant validation has run in each touched repo, when practical
- [ ] Related contract, doc, or manifest files that should move together have been updated
- [ ] Any skipped validation or follow-up work is stated clearly in the final response

If validation was skipped, say so clearly and explain why.

---

## Near-Term Priorities

Current direction: do not work against these.

- Keep cross-tool payload changes explicit through `septa/`
- Keep Lamella source and generated output clearly separated
- Keep root guidance lighter than project-local guidance
