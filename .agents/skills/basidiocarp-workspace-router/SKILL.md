---
name: basidiocarp-workspace-router
description: Routes work in the basidiocarp workspace to the right project, commands, MCPs, and nearby skills. Use when a request spans multiple repos or when the correct implementation home is not obvious.
---

# Basidiocarp Workspace Router

Use this skill first when the task starts at the workspace root or mixes multiple ecosystem projects.

## Project Map

- `mycelium`, `hyphae`, `rhizome`, `stipe`, `cortina`, `spore`, `canopy`, `volva`: Rust projects. Run `cargo build` and `cargo test` from the touched repo.
- `cap`: React, TypeScript, Vite, Vitest, and a small server. Use `npm run build`, `npm test`, and `npm run dev:all`.
- `lamella`: plugin packaging, skills, commands, hooks, manifests, and Codex or Claude exports. Read `lamella/docs/authoring/` before larger content or migration work. Run `make validate`.
- `septa`: cross-tool schemas, fixtures, and payload contracts. Read `septa/README.md` first when the task crosses repo or tool boundaries.

## Routing Rules

1. Start by identifying the repo that should own the change. Do not implement from the workspace root if the real boundary is a subproject.
2. If the request is mostly storage, recall, transcript, or memory behavior, bias toward `hyphae`.
3. If the request is symbol analysis, code navigation, or language intelligence, bias toward `rhizome` or `spore`.
4. If the request is host setup, install, doctor, or repair behavior, bias toward `stipe`.
5. If the request is hook runtime capture or session lifecycle behavior, bias toward `cortina`.
6. If the request is dashboard or UI behavior, bias toward `cap`.
7. If the request is packaging, skill authoring, manifests, or plugin export behavior, bias toward `lamella`.
8. If the request is execution-host runtime, provider routing, backend selection, or host-context shaping, bias toward `volva`.
9. If the request is a shared payload, schema, fixture, or contract across tools, bias toward `septa`.

## MCP Guidance

- Use `hyphae` when recent session memory or stored decisions would help.
- Use `rhizome` when cross-file code navigation or symbol-level inspection is faster than raw file reads.
- Use `context7` when current library docs matter.
- Use `playwright` for `cap` browser workflows, UI verification, or screenshots.

## Done

- The owning repo is explicit.
- Commands and validation match that repo.
- Cross-repo edits happen only when the boundary genuinely requires them.
