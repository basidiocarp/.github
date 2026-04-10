# Rust Workspace Architecture Standards

Date: 2026-04-07
Scope: workspace-wide guidance for Rust repos in `basidiocarp`
Basis: lessons extracted from the ForgeCode audit in:

- [.audit/external/audits/forgecode/audit-initial.md](/.audit/external/audits/forgecode/audit-initial.md)
- [.audit/external/audits/forgecode/borrow-matrix.md](/.audit/external/audits/forgecode/borrow-matrix.md)
- [.audit/external/audits/forgecode/cleanup-map.md](/.audit/external/audits/forgecode/cleanup-map.md)
- [.audit/external/audits/forgecode/feature-comparison.md](/.audit/external/audits/forgecode/feature-comparison.md)

This is not a ForgeCode refactor plan. It is a set of standards for how Rust applications in this workspace should be
structured, verified, and evolved.

## The point

Good crate names do not buy you good architecture. The dependency graph does.

That was the clearest lesson from ForgeCode. It looks modular at first glance, and parts of it are, but some
dependencies cut across the intended layers. The right takeaway for this workspace is simple: every Rust repo should
make its boundaries real in code, not just visible in folder names.

## Core rules

### 1. Keep dependency direction strict

Lower layers must not depend on application or orchestration crates.

The preferred shape is:

- domain or core types in the center
- ports or service contracts around that core
- adapters such as repos, persistence, transport, or host integration outside the ports
- application orchestration above adapters
- binary, CLI, MCP, or composition crates at the edge

If a repo crate named `repo`, `store`, `infra`, `adapter`, or `transport` depends on `app`, `service`, or
`orchestration`, stop and fix the direction.

### 2. Do not let `domain` become a catch-all

A domain crate should hold cohesive business or platform types. It should not quietly become:

- the place for every shared type
- a giant re-export surface
- a dumping ground for shell, config, policy, MCP, HTML, parsing, and transport concerns

If a domain crate starts acting as “everything shared,” split it or narrow its exports.

### 3. Introduce ports explicitly when multiple adapters need them

If both persistence and host-facing code need the same contracts, create a narrow ports layer instead of importing
upward from the app crate.

Typical contents of a ports layer:

- repository traits
- service traits
- execution or environment abstractions
- data flow contracts between orchestration and adapters

The app crate should implement workflows against ports. Adapters should implement those ports. They should not depend on
each other sideways.

### 4. Make composition roots obvious

Every Rust app should have one or two crates that are clearly responsible for wiring the system together. That is where
wide dependency fan-in belongs.

Good homes for composition:

- CLI crates
- API crates
- MCP server crates
- top-level application crates

Bad homes for composition:

- domain crates
- repo crates
- low-level utility crates

### 5. Split hotspot files before they become architecture

Large files are not automatically bad, but giant orchestration files usually signal that boundaries are already leaking.

Watch especially for files that combine:

- policy checks
- provider selection
- tool dispatch
- agent delegation
- config lookup
- retry and timeout handling
- formatting of user-facing output

That code wants smaller modules, even if it still belongs in the same crate.

### 6. Treat config as a product surface

Config is part of the system architecture, not an afterthought.

Every serious Rust application in this workspace should aim for:

- one clear config entry point
- explicit defaults
- schema or machine-readable structure where practical
- stable naming
- narrow write paths for mutation
- validation that fails early

This matters even more for tools that manage hosts, sessions, models, or external services.

### 7. Treat permissions and approvals as runtime state

Approval behavior should not live only in prompts, comments, or user habit.

When a Rust tool executes commands, reads files, writes files, or talks to remote systems, approval behavior should be
modeled explicitly. The ideal shape is:

- a policy model
- persisted decisions where appropriate
- readable default rules
- enforcement in the execution path, not just in UI text

This is especially relevant for host tools and execution surfaces.

### 8. Keep CI authoritative

There should be one obvious answer to “is this repo green?”

Generated workflows are fine. Split-brain success criteria are not.

Preferred CI shape:

- one authoritative path for lint, build, test, and required checks
- optional autofix or helper workflows outside the authority path
- narrow platform expansion only when it adds real confidence
- generator tests if workflow generation is code-driven

If lint lives in a helper workflow and tests live elsewhere, the repo becomes harder to trust.

### 9. Make maintainer docs match repo complexity

User docs and marketing docs are not enough for complex Rust repos.

If a repo has multiple crates, custom generation, or layered config, it should also have:

- a short architecture note
- crate ownership notes
- dependency direction rules
- verification commands
- a clear explanation of what is generated and where the source of truth lives

### 10. Prefer explicit ecosystem boundaries over local convenience

This workspace is not one product. It is an ecosystem.

For Rust repos here, the default should be:

- keep repo-local responsibilities inside the owning repo
- expose shared contracts explicitly
- avoid “just import that other crate” shortcuts across boundaries
- make cross-project coupling visible and deliberate

## Recommended standard crate shapes

These are not mandatory names. They are patterns.

### Pattern A: Small focused tool

- `core`: domain types and pure logic
- `app`: orchestration and use cases
- `cli` or `main`: wiring and command surface

### Pattern B: Tool with adapters

- `core` or `domain`
- `ports`
- `repo` or `store`
- `host` or `infra`
- `app`
- `cli`, `api`, or `mcp`

### Pattern C: Ecosystem service

- `core`
- `store`
- `ingest` or `index`
- `mcp`
- `cli`

The exact split matters less than the dependency direction.

## Smells to watch for

- A crate called `repo` depends on `app`
- A crate called `infra` depends on orchestration code
- A crate called `domain` re-exports nearly everything
- A crate with “service” in the name owns traits, implementations, adapters, and composition
- Giant files accumulate timeout logic, retries, policy, formatting, and dispatch in one place
- CI says green even though lint, autofix, or platform checks live elsewhere
- Tests exist in volume, but a basic crate-local test run still fails in a normal environment

## Verification standards

Every Rust repo should be able to answer these questions quickly:

1. What are the intended layers?
2. Which crate is the composition root?
3. Which crates are allowed to depend on which?
4. What command is the narrowest meaningful verification?
5. What checks are authoritative for merge confidence?
6. What is generated, and where is the source of truth?

If a repo cannot answer those clearly, the architecture is already drifting.

## What to apply now across this workspace

- Add or tighten dependency direction notes in repo-local `AGENTS.md` or `CLAUDE.md` files.
- Prefer a `ports` layer whenever an adapter crate is starting to reach upward into orchestration.
- Audit each Rust repo for “mega domain” behavior and reduce broad re-export surfaces.
- Keep workflow generation only where it reduces repetition and back it with tests.
- Productize config and permission handling in host-facing repos, especially `stipe` and nearby surfaces.
- Preserve the current workspace strength: explicit ownership, explicit contracts, and routing work into the right repo.

## Short version

The standard is simple:

- strict dependency direction
- narrow cores
- explicit ports
- obvious composition roots
- no fake modularity
- authoritative CI
- config and permissions treated as real architecture

If a Rust repo in this workspace follows those rules, it can grow without turning crate names into fiction.
