# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`basidiocarp` is a workspace of related projects for AI coding agent infrastructure. It mixes Rust CLIs and libraries, a React and TypeScript dashboard, Markdown packaging content, and shared cross-project contracts. The workspace root owns conventions, contract governance, shared docs, and version pins. Most major subprojects are their own git repositories, but some directories such as `volva/`, `septa/`, and `docs/` are root-managed.

---

## What This Workspace Does NOT Do

- Does not build or test from the root as one unified project: run commands inside the subproject you change.
- Does not share one git history across all code: run git in the project that actually owns the files you changed.
- Does not treat cross-tool payloads as informal: schema changes must go through `septa/`.
- Does not keep dependency drift implicit: shared pins live in `ecosystem-versions.toml`.
- Does not keep Rust architecture standards buried in examples: workspace guidance lives under `docs/foundations/`.
- Does not treat the external audit corpus as source of truth: use `.audit/external/` to evaluate borrowed ideas, then land the real decisions in the owning repo, `septa/`, or `docs/foundations/`.

---

## Failure Modes

- **Wrong working directory**: Commands fail or hit the wrong repository. Change into the touched subproject before building, testing, or using git.
- **Contract drift**: One tool changes a payload and another breaks later. Check `septa/README.md`, update the schema and fixture first, then update every producer and consumer in the same change.
- **Version drift**: Shared libraries, especially `spore`, move out of sync across projects. Check `ecosystem-versions.toml` before changing shared dependencies.
- **Workspace-level git assumptions**: The root is a small workspace meta-repo, but nested project repos still own their own code history. Use root git for workspace docs, shared config, and coordination assets; use git inside the specific subproject for code changes.

---

## Build & Test Commands

```bash
cd mycelium && cargo build --release && cargo test
cd hyphae && cargo build --release && cargo test
cd rhizome && cargo build && cargo test --all
cd spore && cargo build && cargo test
cd stipe && cargo build --release && cargo test
cd cortina && cargo build --release && cargo test
cd canopy && cargo build --release && cargo test
cd volva && cargo check && cargo test

cd cap && npm run dev:all
cd cap && npm run build && npm test

cd lamella && make validate
cd lamella && make build-marketplace
```

---

## Architecture

```text
basidiocarp/
├── mycelium/   token-optimized CLI proxy
├── hyphae/     persistent memory and RAG
├── cap/        dashboard and operator UI
├── rhizome/    code intelligence MCP server
├── spore/      shared Rust infrastructure
├── stipe/      installer and manager
├── cortina/    lifecycle signal runner
├── lamella/    skills, hooks, and plugin packaging
├── canopy/     multi-agent coordination runtime
├── volva/      execution-host runtime layer
├── septa/  shared schemas and fixtures
└── docs/       workspace-level notes
```

- **mycelium**: Filters command output before it reaches the model.
- **hyphae**: Stores memories, memoirs, sessions, and indexed documents.
- **cap**: Reads ecosystem data, renders operator views, and brokers explicit write-through actions where the UI needs them.
- **rhizome**: Provides structure-aware code intelligence and export.
- **spore**: Supplies shared discovery, transport, config, and path primitives.
- **stipe**: Handles install, init, update, and doctor flows.
- **cortina**: Captures hook events and writes structured signals.
- **lamella**: Packages shared content for Claude and Codex.
- **canopy**: Tracks task ownership, handoffs, and evidence.
- **volva**: Hosts backend orchestration at the runtime seam.

---

## Key Design Decisions

- **Mostly independent repositories**: keeps release cadence and ownership per tool clear without forcing every root-level directory to be a standalone repo.
- **Septa directory**: makes cross-project payload changes explicit and testable.
- **Shared version pin file**: keeps common dependencies, especially `spore`, from drifting silently.
- **Project-local commands**: prevents the root from becoming a fake build system that hides real repo boundaries.

---

## Key Files

| File | Purpose |
|------|---------|
| [AGENTS.md](/Users/williamnewton/projects/basidiocarp/AGENTS.md) | Workspace-wide repo guidance, build commands, and Lamella-specific authoring rules |
| [septa/README.md](/Users/williamnewton/projects/basidiocarp/septa/README.md) | Contract ownership, versioning rules, and validation workflow |
| [ecosystem-versions.toml](/Users/williamnewton/projects/basidiocarp/ecosystem-versions.toml) | Shared dependency pins across projects |
| [docs/foundations/README.md](/Users/williamnewton/projects/basidiocarp/docs/foundations/README.md) | Workspace Rust architecture standards, checklist, and audit templates |
| [.audit/external/SYNTHESIS.md](/Users/williamnewton/projects/basidiocarp/.audit/external/SYNTHESIS.md) | Fast entrypoint to the external audit corpus and current ecosystem-level conclusions |
| [.audit/external/AUDITING.md](/Users/williamnewton/projects/basidiocarp/.audit/external/AUDITING.md) | Method for mapping external features into existing repos, `septa`, or true new-tool candidates |
| [ECOSYSTEM-OVERVIEW.md](/Users/williamnewton/projects/basidiocarp/docs/workspace/ECOSYSTEM-OVERVIEW.md) | Thin ecosystem map, repo responsibilities, and cross-tool boundaries |
| [ECOSYSTEM-REVIEW.md](/Users/williamnewton/projects/basidiocarp/docs/workspace/ECOSYSTEM-REVIEW.md) | Detailed ecosystem state, gap analysis, and near-term review surface |

---

## Communication Contracts

The workspace root does not send or receive runtime payloads. It owns the shared `septa/` directory and the rules for changing those contracts.

- Update the schema and example fixture before changing any cross-tool payload.
- Check downstream consumers before renaming tool names, fields, CLI flags, or SQLite tables.
- Run `./scripts/test-integration.sh` when a change crosses a project boundary.

---

## Testing Strategy

- Use each project's native test command inside that project's directory.
- Treat contract changes as multi-repo work, not local refactors.
- Prefer real fixtures and existing snapshot workflows over synthetic examples.
- Re-run the nearest build, test, and lint commands in every touched subproject.
