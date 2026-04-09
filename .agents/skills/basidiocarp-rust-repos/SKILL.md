---
name: basidiocarp-rust-repos
description: Guides work in the Rust projects inside basidiocarp. Use when changing mycelium, hyphae, rhizome, stipe, cortina, spore, canopy, or volva and you need the right repo-local commands, boundaries, and verification habits.
---

# Basidiocarp Rust Repos

Apply this skill when the task lives in one of the Rust ecosystem repos.

## Applies To

- `mycelium`
- `hyphae`
- `rhizome`
- `stipe`
- `cortina`
- `spore`
- `canopy`
- `volva`

## Working Rules

1. Run all build and test commands from the touched repo, not the workspace root.
2. Follow the workspace convention: Rust 2024, `cargo fmt`, and clippy pedantic.
3. Prefer `anyhow` for app-level errors and `thiserror` for library errors.
4. Keep boundaries clear:
   `hyphae` owns memory and transcripts.
   `rhizome` owns code intelligence.
   `spore` owns editor and MCP plumbing primitives.
   `stipe` owns install, host setup, and doctor or repair orchestration.
   `cortina` owns lifecycle capture runtime and hook-side outcome handling.
   `volva` owns execution-host runtime, backend routing, and host-context shaping before execution.
5. Use `rhizome` MCP for symbol navigation when the code path spans many files.
6. Use `hyphae` MCP if prior session decisions or stored context matter.

## Verification

- Run `cargo build` and `cargo test` in the affected repo.
- Run narrower commands when the repo already uses them, but do not skip the repo-local verification surface without a reason.
- Call out any tooling noise separately from real failures.
