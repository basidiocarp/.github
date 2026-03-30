# Basidiocarp Ecosystem Architecture

This page covers boundaries. Use it to answer "which tool owns this concern?" Use [How the Projects Connect](./INTEGRATION.md) for runtime flow, protocols, and failure modes.

## Overview

Basidiocarp splits the stack into a few clear layers. `mycelium` handles command shaping, `hyphae` handles memory, `rhizome` handles code intelligence, `stipe` handles installation and host policy, and `cap` surfaces the state of the system. The supporting tools stay narrower: `spore` is shared plumbing, `lamella` packages agent assets, `cortina` runs host-side lifecycle adapters, and `canopy` is the optional coordination runtime.

## Core services

- `mycelium`
  - Command rewrite, compaction, discovery, learning, and explicit runtime invocation.
  - Best thought of as the command and token-efficiency layer.
- `hyphae`
  - Persistent memory system.
  - Stores episodic memories in `memories` and structured knowledge graphs in `memoirs`.
  - Claude hooks and Codex notifications both feed this layer.
- `rhizome`
  - Code intelligence and code-edit MCP server.
  - Provides symbol lookup, navigation, diagnostics, rename, copy-symbol, and move-symbol workflows.
- `stipe`
  - Ecosystem installer, repair tool, and host-mode manager.
  - Owns MCP registration, Claude hook setup, Codex notify setup, platform-aware config paths, and host-aware repair guidance.
- `cap`
  - Dashboard and operational surface.
  - Reads Hyphae, Rhizome, Mycelium, and runtime health to expose status, onboarding, memory review, code workflows, and resolved path provenance.
- `canopy`
  - Optional coordination runtime for multi-agent work.
  - Tracks active agents, task ownership, handoffs, attention, and evidence references.

## Supporting tools

- `spore`
  - Shared low-level tool discovery, subprocess, editor config registration, and runtime plumbing.
  - Not the place for host orchestration or UI policy.
- `lamella`
  - Packaging and export layer for commands, skills, prompts, hooks, and marketplace bundles.
- `cortina`
  - Local lifecycle orchestration and session/runtime support within the ecosystem.
  - Core events are host-neutral; host-specific envelopes belong in adapters.
- `canopy`
  - Coordination runtime, not long-term memory.
  - Should reference Hyphae sessions and Cortina events instead of replacing them.

## Install scope

The ecosystem repo contains more projects than the default bootstrap install.

- bootstrap-installed by default
  - `stipe`, `mycelium`, `hyphae`, `rhizome`, `cortina`
- optional runtime install
  - `canopy`
- source or packaging surfaces
  - `cap`, `lamella`, `spore`

Use [What Gets Installed](./INSTALL-SCOPE.md) for the operator-facing matrix.

## Host adapters

The ecosystem treats hosts as adapters instead of assuming everything is Claude-shaped.

First-class host modes today:

- `Claude Code`
  - MCP + lifecycle hooks
  - strongest automatic event coverage
- `Codex CLI`
  - MCP + `notify = ["hyphae", "codex-notify"]`
  - explicit runtime entry via `mycelium invoke`
- `Cursor`
  - MCP-focused host mode

Shared MCP client coverage today:

- `Windsurf`
- `Claude Desktop`
- `Continue`
- `Cline`
- `Gemini CLI`
- `Copilot CLI`

Those shared clients use the same editor primitives through `spore` and shared registration flows in `stipe`, but they do not all get their own dedicated host-mode lifecycle path.

## Platform paths

Platform-aware config and data path resolution is now a first-class boundary:

- `spore` owns reusable editor config paths and MCP registration mechanics.
- `stipe` owns host inventory and platform-aware setup policy.
- `mycelium`, `hyphae`, and `rhizome` resolve cache, config, and data paths through shared helpers rather than hardcoded Unix defaults.
- `cap` consumes those resolved paths and shows the provenance of each value: config file, environment override, or platform default.
- `canopy` should consume explicit runtime evidence and read surfaces rather than re-deriving session state from scratch.

## Data flow

### Claude Code path

1. Claude runs MCP tools from `hyphae` and `rhizome`.
2. Claude lifecycle hooks write session and tool context into `hyphae`.
3. `cap` reads the resulting memories, memoirs, and status.

### Codex path

1. Codex runs MCP tools from `hyphae` and `rhizome`.
2. Codex `notify` invokes `hyphae codex-notify`.
3. `hyphae codex-notify` stores episodic session memories under `session/{project}` and lifecycle notes under `session/{project}/codex-lifecycle`.
4. `cap` reads those memories from Hyphae and exposes adapter health, onboarding, and review flows.

## Memory vs memoirs

- `memories`
  - Event-like or recallable facts.
  - Codex notify writes here.
  - Typical topics include `session/{project}` and `session/{project}/codex-lifecycle`.
- `memoirs`
  - Structured concept graphs.
  - These are not created automatically from Codex notify events.
  - Today they are built either manually through Hyphae memoir tools or imported from Rhizome as `code:{project}` memoirs.

## Current boundary decisions

- Host-mode policy belongs in `stipe`, not `spore`.
- Codex lifecycle normalization belongs in `hyphae`, not `cap`.
- Lifecycle capture belongs in `cortina`, not `lamella`.
- Session discovery and runtime-specific parsing belong in `mycelium`, split by source.
- Coordination-runtime state belongs in `canopy`, not `hyphae`.
- `cap` should consume shared presentation models rather than re-derive readiness state in each page.
- Platform path discovery belongs in shared low-level helpers, not scattered through each CLI or UI surface.

## Related

- [How the Projects Connect](./INTEGRATION.md)
- [What Gets Installed](./INSTALL-SCOPE.md)
- [Host Support](./HOST-SUPPORT.md)
- [AI Concepts](./AI-CONCEPTS.md)
- [LLM Training](./LLM-TRAINING.md)
- [Local-First Design](./LOCAL-FIRST.md)
