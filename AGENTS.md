# Workspace Agent Notes

## Purpose

This workspace is a routing layer, not one big project. Most work here means finding the right subrepo, changing source in that repo, and validating there instead of pretending the root is the build system. Preserve the real repo boundaries; they are the main thing that keeps cross-tool work sane.

---

## Source of Truth

- `*/` top-level subprojects: the real source lives inside the repo you are changing.
- `septa/`: authoritative cross-tool payload shapes and fixtures.
- `ecosystem-versions.toml`: shared dependency pins across repos.
- `docs/foundations/`: workspace Rust architecture standards, checklist, and audit template.
- `.audit/external/SYNTHESIS.md`: current cross-example ecosystem takeaways from the external audit corpus.
- `.audit/external/AUDITING.md`: method for repo-level external borrow audits and feature-to-ecosystem mapping.
- `lamella/resources/` and `lamella/manifests/`: source for Lamella content and packaging.
- `dist/`, `target/`, and similar build output: generated output. Do not hand-edit unless the task is explicitly about generated artifacts.

When the workspace root and a subproject disagree, the subproject wins. When code and `septa/` disagree on a cross-tool payload, update `septa/` first.

---

## Before You Start

Before writing code, verify:

1. **Owning repo**: identify which top-level project actually owns the change.
2. **Contracts**: if the task crosses a tool boundary, read `septa/README.md` first.
3. **Versions**: check `ecosystem-versions.toml` before changing shared dependencies.
4. **Foundation standards**: for Rust architecture or repo-boundary work, read `docs/foundations/` before editing repo guidance or alignment handoffs.
5. **Build surface**: switch into the touched repo before running git, build, or test commands.
6. **Lamella context**: for substantial Lamella work, read `lamella/docs/authoring/` before editing content or manifests.
7. **External audit context**: when evaluating ideas borrowed from outside tools, read `.audit/external/SYNTHESIS.md` first and `.audit/external/AUDITING.md` if you are writing or refreshing an audit.

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

This workspace is intentionally loose. Each top-level project owns its own code, tests, and git history; the root only holds shared docs, cross-project contracts, and coordination notes.

Key boundaries:

- `septa/`: owns cross-tool schemas and fixtures; do not treat payloads as informal.
- `docs/`: workspace-level notes, not a substitute for project-local docs.
- `lamella/`: packages shared content; generated output is not the source of truth.
- top-level project dirs: build, test, and commit inside the repo you touched.

Current direction:

- Keep cross-tool coupling explicit through `septa/`.
- Keep shared dependency drift visible through `ecosystem-versions.toml`.
- Keep root guidance thin enough that it does not override project-local rules.

---

## Working Rules

- Run project-local commands in the repo you changed, not at the workspace root.
- Prefer Rhizome or targeted reads over dumping whole files when code structure matters.
- Use `rg` over `grep` and `fd` over `find`.
- For Lamella audits, review manifests, docs, and source content together instead of only changed files.
- When a task crosses tool boundaries, update schemas, fixtures, and all affected producers or consumers in the same change.
- When a task changes Rust repo structure or maintainer guidance, keep `docs/foundations/` as the standards source of truth instead of pointing back into `.audit/external/`.
- If validation was skipped in a touched repo, say so clearly in the final response.

---

## Multi-Agent Patterns

For substantial workspace-spanning work, use at least two agents:

**1. Primary implementation worker**
- Owns the actual write scope in the touched repo or repos
- Does not drift into unrelated sibling projects just because they are nearby

**2. Independent validator**
- Reviews the broader shape rather than redoing the implementation
- Specifically looks for contract drift across repos, root-vs-subrepo confusion, missed validation in a touched project, and stale Lamella source-vs-generated output mistakes

**3. Docs worker**
- Use when README, CLAUDE, AGENTS, or authoring docs changed materially
- Owns prose cleanup and cross-link consistency

Sequencing: do not stop local work just because a validator is running. Wait only when the next edit depends on the review result.

---

## Skills to Load

Use these for most work in this workspace:

- `basidiocarp-workspace-router`: routes the task to the right repo and command set.
- `writing-voice`: use when touching READMEs, CLAUDE files, AGENTS files, or authoring docs.
- `systematic-debugging`: use before changing code in response to a failure you have not explained yet.

Use these when the task needs them:

- `basidiocarp-lamella`: when editing Lamella skills, agents, manifests, hooks, or authoring docs.
- `tool-preferences`: when you need a reminder to stay token-efficient during exploration.
- `test-writing`: when behavior changes need new tests rather than just code edits.

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
