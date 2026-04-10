# Rust Workspace Standards Applied Repo by Repo

Date: 2026-04-07
Scope: `mycelium`, `hyphae`, `rhizome`, `stipe`, `cortina`, `spore`, `canopy`
Companion
doc: [docs/foundations/rust-workspace-architecture-standards.md](./rust-workspace-architecture-standards.md)

This document applies the workspace Rust architecture standards to the current repos. It is not a scorecard. It is a
practical read on what each repo should preserve, what it should tighten, and what to watch as it grows.

## Mycelium

Current shape: one package, one binary, one library surface, many internal modules.
See [mycelium/Cargo.toml](https://github.com/basidiocarp/mycelium/blob/main/Cargo.toml)
and [mycelium/CLAUDE.md](https://github.com/basidiocarp/mycelium/blob/main/CLAUDE.md).

Keep:

- The single-package layout still fits the product. Mycelium is one CLI with one clear job.
- The command-family module split in `vcs/`, `cargo_filters/`, `js/`, `python/`, and `fileops/` is the right way to keep
  one binary from turning into one file.
- Snapshot-heavy testing is aligned with the product because output shape is the product.

Tighten:

- Keep `dispatch.rs` from becoming a composition and policy dump. That file is the highest-risk place for fake
  modularity in a single-binary tool.
- If Hyphae or Rhizome integration logic grows, isolate those boundaries into explicit adapter modules instead of
  letting them spread through filtering code.
- Keep SQLite tracking and learning surfaces from bleeding into command filtering paths.

Watch:

- One-package repos often drift into “internal monoliths.” If the dispatch, tracking, and sibling-tool integrations keep
  expanding, Mycelium may need an internal `core` plus adapter split later even if it stays one published crate.

## Hyphae

Current shape: five-crate workspace with a clean center.
See [hyphae/Cargo.toml](https://github.com/basidiocarp/hyphae/blob/main/Cargo.toml)
and [hyphae/CLAUDE.md](https://github.com/basidiocarp/hyphae/blob/main/CLAUDE.md).

Keep:

- This is the clearest example of the standard working well.
- `hyphae-core` as domain and store traits, `hyphae-store` as SQLite, `hyphae-ingest` as ingestion, `hyphae-mcp` as
  transport, and `hyphae-cli` as operator surface is a good dependency story.
- The repo already treats contracts and read surfaces seriously, which matches the workspace standard.

Tighten:

- Protect `hyphae-core` from convenience imports that drag in transport, config-writing, or CLI concerns.
- Keep Cap-facing read contracts versioned and narrow. Hyphae is already a contract-heavy repo; that tends to expand
  over time.
- Maintain a clear line between memory semantics and operational analytics so the core does not become a reporting
  catch-all.

Watch:

- Hyphae is at the highest risk of domain sprawl because memory, memoirs, retrieval, analytics, ingest, and contracts
  all want to live in the same conceptual center.

## Rhizome

Current shape: five-crate workspace with backend separation.
See [rhizome/Cargo.toml](https://github.com/basidiocarp/rhizome/blob/main/Cargo.toml)
and [rhizome/CLAUDE.md](https://github.com/basidiocarp/rhizome/blob/main/CLAUDE.md).

Keep:

- `rhizome-core`, `rhizome-treesitter`, `rhizome-lsp`, `rhizome-mcp`, and `rhizome-cli` are a strong application of
  explicit composition roots and backend boundaries.
- The backend selector idea is exactly the kind of boundary this workspace should prefer: one shared abstraction,
  different implementations, thin transport surfaces.
- Export to Hyphae is already treated as a contract rather than an incidental side effect.

Tighten:

- Keep backend-specific shortcuts out of higher layers. The MCP and CLI crates should continue to go through shared
  backend selection rather than inventing parallel access paths.
- Avoid letting `rhizome-core` become “everything shared.” It should stay focused on backend selection, root detection,
  graph export, and stable primitives.
- Guard the edit and refactor surfaces carefully. Structural editing tools tend to accumulate one-off logic fast.

Watch:

- Rhizome’s risk is not layering drift so much as capability accretion. The more tools it adds, the more pressure there
  will be to bypass the clean core.

## Stipe

Current shape: one package, one CLI, policy-heavy operator tool over shared Spore primitives.
See [stipe/Cargo.toml](https://github.com/basidiocarp/stipe/blob/main/Cargo.toml)
and [stipe/CLAUDE.md](https://github.com/basidiocarp/stipe/blob/main/CLAUDE.md).

Keep:

- Stipe should remain policy over primitives. The repo-local docs already say that clearly.
- The current split between `commands/` and `ecosystem/` is the right shape for an installer and manager.
- Host-aware setup and doctor flows belong here, not in sibling tools.

Tighten:

- Treat Stipe’s output contracts as first-class architecture. Cap consumes them directly.
- Keep Spore as the shared primitive layer and resist reimplementing editor detection, path logic, or MCP registration
  logic locally.
- If provider UX, approval memory, or unified operator config gets added, this is one of the best homes for it, but it
  must remain host policy rather than runtime behavior for sibling tools.

Watch:

- Stipe is at risk of becoming the ecosystem junk drawer because every shared setup problem is tempted to land here.
  Keep it focused on install, init, doctor, repair, and host registration policy.

## Cortina

Current shape: one binary with adapter-first lifecycle capture.
See [cortina/Cargo.toml](https://github.com/basidiocarp/cortina/blob/main/Cargo.toml)
and [cortina/CLAUDE.md](https://github.com/basidiocarp/cortina/blob/main/CLAUDE.md).

Keep:

- The adapter-first structure is the right application of the standards.
- `adapters/`, `hooks/`, `events/`, and utility helpers give Cortina a clear inward flow from host envelope to
  normalized signal.
- Best-effort persistence is the right failure model for hook-boundary software.

Tighten:

- Keep Hyphae write logic behind a narrow boundary. Cortina should classify and forward, not become a memory client with
  lots of embedded policy.
- Keep host-specific parsing in adapters. Do not let Claude Code or Volva quirks leak into the shared event model.
- If status or policy surfaces grow, make sure they stay operator-facing and do not bleed into capture logic.

Watch:

- Cortina’s main risk is sideways coupling to Hyphae, Volva, or host quirks. It should remain a classifier at the edge,
  not a cross-tool orchestrator.

## Spore

Current shape: shared infrastructure library.
See [spore/Cargo.toml](https://github.com/basidiocarp/spore/blob/main/Cargo.toml)
and [spore/CLAUDE.md](https://github.com/basidiocarp/spore/blob/main/CLAUDE.md).

Keep:

- Spore is already the cleanest expression of “shared primitives, not product policy.”
- Discovery, JSON-RPC, subprocess communication, path handling, config loading, and logging are exactly the sort of
  things that should live here.
- The library-only rule is right.

Tighten:

- Protect the public API aggressively. Changes here are ecosystem-wide changes.
- Keep product semantics out. No tool-specific workflow policy should leak into Spore.
- Keep version coordination disciplined. Shared infrastructure only helps if the consumers move together safely.

Watch:

- Spore’s failure mode is not internal complexity. It is accidental centrality. The more useful it becomes, the easier
  it is for other repos to treat it as a place to stash unrelated shared logic.

## Canopy

Current shape: one binary with SQLite store, transport-neutral tools, and MCP plus CLI surfaces.
See [canopy/Cargo.toml](https://github.com/basidiocarp/canopy/blob/main/Cargo.toml)
and [canopy/CLAUDE.md](https://github.com/basidiocarp/canopy/blob/main/CLAUDE.md).

Keep:

- The split between `store/`, `tools/`, and `mcp/` is the right one.
- Transport-agnostic coordination logic is exactly what the standards call for.
- References instead of copied payloads are a strong boundary choice.

Tighten:

- Keep `models.rs` and `api.rs` from becoming mega-domain surfaces as more coordination views are added.
- Preserve the line between coordination state and memory. Canopy should not become a second Hyphae.
- Keep evidence and handoff contracts explicit and versioned through `septa`.

Watch:

- Canopy is vulnerable to feature pressure from operator UX. Snapshot and task-detail read models are useful, but they
  should not drag presentation and policy logic into the core tool layer.

## Cross-repo recommendations

Apply these consistently:

- Prefer `core` plus `ports` plus adapters when a repo grows past a simple single-binary shape.
- Keep single-package tools honest by watching for internal orchestration hubs.
- Treat Spore as shared infrastructure, not as a dumping ground for convenience code.
- Keep `septa` as the place where cross-project payloads become explicit.
- Make CLI, MCP, and JSON output surfaces versioned when another tool consumes them.
- Put host setup policy in Stipe, lifecycle capture in Cortina, coordination state in Canopy, memory in Hyphae, code
  intelligence in Rhizome, and shell filtering in Mycelium. Do not blur those lines for local convenience.

## Short version

The workspace is already strongest where repo boundaries are real.

Hyphae, Rhizome, Spore, and Canopy are the closest to the target standard today. Stipe and Cortina have the right
boundaries but need active protection against ecosystem creep. Mycelium is healthy as a single-package tool, but it is
the most likely to need internal boundary reinforcement as it grows.
