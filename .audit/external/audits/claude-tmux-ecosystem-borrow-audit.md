# Claude-Tmux Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `claude-tmux`
Lens: what to borrow from claude-tmux, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

claude-tmux is a terminal UI (ratatui-based) that centralizes management of tmux sessions running Claude Code. Its strongest portable ideas are: status detection via pane output pattern matching (busy/idle/waiting states without IPC), pane-to-session attribution via process introspection, git/PR context extraction from working directory, and a minimal stateless CLI popup footprint. Basidiocarp benefits most in `annulus` (status indicator patterns for statusline), `volva` (pane/session discovery for execution hosts), and `spore` (session metadata extraction as shared infrastructure). The tmux-specific bindings and keybinding model are too narrow to borrow directly.

## What claude-tmux is doing that is solid

### 1. Smart status detection from terminal output patterns

Identifies Claude Code busy/idle/waiting states by parsing terminal output patterns (`❯ input prompt`, "ctrl+c to interrupt", `[y/n]` detection) without needing IPC. No background daemon required.

Evidence:
- Status detection regex patterns in session reader logic
- Pane output sampling at configurable intervals
- Three-state model: busy (processing), idle (waiting for input), waiting (permission prompt)

Why that matters here:
- `annulus` needs live status indicators for the statusline — these patterns are directly reusable.
- `volva` needs to detect execution host state (Claude busy vs idle) without IPC.

### 2. Pane routing and session attribution

Maps tmux panes to Claude Code sessions via process introspection, enabling per-session visibility and fuzzy filtering by working directory, project name, or branch.

Evidence:
- Process tree walking to identify pane-to-PID mapping
- Git context extraction (`git branch`, `git rev-parse`) from pane working directory
- Session list with fuzzy filtering (fzf-style)

Why that matters here:
- `volva` (execution-host runtime) needs to track which sessions are associated with which worktrees.
- `spore` discovery module should expose session metadata (git context, working dir, branch) as shared primitives.

### 3. Git/PR context extraction from working directory

Reads git context (branch, root, upstream), PR state via `gh` CLI integration, and project name from the session's current working directory. Context populates the operator view.

Evidence:
- `gh pr list` + `gh pr view` integration for PR status in session list
- Working directory → git root → branch chain for per-session project identification

Why that matters here:
- `spore` should own this discovery logic so all tools share the same session metadata resolution.
- `cortina` lifecycle signals should include git context at session start.

### 4. Minimal stateless footprint

Designed as a tmux `display-popup` invocation — no background service, no persistent state, no daemon process. Opens on demand and exits cleanly.

Evidence:
- Single binary, invoked via tmux keybinding as popup
- All state read from live tmux panes on each invocation

Why that matters here:
- `annulus` and `stipe` should prefer this pattern for operator surface tools: no daemons, no state files, open on demand.

## What to borrow directly

### Borrow now

- Status detection patterns (busy/idle/waiting via output regex).
  Best fit: `annulus` (statusline needs live status indicators without IPC).

- Git context extraction from working directory.
  Best fit: `spore` (shared discovery primitive used by all tools).

- Pane-to-session mapping logic.
  Best fit: `volva` (execution host links sessions to worktrees).

## What to adapt, not copy

### Adapt

- Session list + fuzzy search UX.
  Adapt the ratatui list/filter pattern into a generic session/resource browser for `cap` (dashboard); claude-tmux couples it to tmux panes, but the list-and-filter pattern generalizes.

- Live output preview.
  Adapt the ANSI-to-ratatui rendering for `annulus` statusline widget; decouple from tmux-specific pane output.

## What not to borrow

### Skip

- tmux-specific command bindings and popup integration.
  Too narrow; `volva` and `cap` own session visibility at a different layer.

- Keybinding system (vim-style j/k navigation).
  `annulus` has its own input model; don't import a second one.

## How claude-tmux fits the ecosystem

### Best fit by repo

- `annulus`: Status indicator patterns (busy/idle/waiting) and ANSI rendering for the statusline.
- `volva`: Pane/session discovery logic for linking execution hosts to Claude workspaces.
- `spore`: Session discovery and git context extraction as shared infrastructure.
- `cortina`: Lifecycle signals (session became idle, permission prompt detected) should hook into cortina's event model.

## What claude-tmux suggests improving in your ecosystem

### 1. Standardize session lifecycle events in cortina

No hook system currently exists for "session became idle" or "permission prompt detected"; `cortina` should standardize these signals so multiple tools can subscribe.

### 2. Cross-runtime pane awareness in volva

Currently tmux-only; basidiocarp needs a unified pane abstraction for other terminals (kitty, iterm2, zellij) to avoid re-implementing per-terminal.

### 3. Status persistence in hyphae

Status detection is ephemeral (pane output); store per-session state in `hyphae` sessions for cross-session continuity and operator visibility in `cap`.

## Final read

**Borrow:** status detection patterns, pane-to-session mapping, git context extraction.

**Adapt:** session list UI and ANSI preview rendering into generic `cap`/`annulus` components.

**Skip:** tmux-specific bindings and keybinding model.
