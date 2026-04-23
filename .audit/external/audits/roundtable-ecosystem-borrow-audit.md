# Roundtable Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `askbudi/roundtable`
Lens: what to borrow from the tool, how it fits the `basidiocarp` ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

Roundtable is a Python MCP server (v0.5.0, AGPL-3.0) that exposes per-agent `check_*` and `execute_*` tools so a primary AI assistant can delegate tasks to Codex, Claude Code, Cursor, and Gemini in parallel, then receive a synthesized response. Its strongest idea is the uniform adapter interface: every agent behind a common async `execute_with_streaming(instruction, project_path, session_id, model, is_initial_prompt)` generator that yields typed `Message` objects. The weakest parts are the flat parallel-fan-out model with no routing policy, the string-based response synthesis, and the shell-command availability check that relies on `--help` exit codes cached in a JSON file. The primary ecosystem fit is `volva` (adapter contract and multi-backend dispatch) with a supporting role for `septa` (typed adapter contract), `stipe` (availability discovery and registration), and `canopy` (parallel fan-out as a coordination pattern).

## What Roundtable is doing that is solid

### 1. The adapter interface is uniform and composable

Every CLI backend is wrapped behind one async generator interface: `execute_with_streaming(instruction, project_path, session_id, model, is_initial_prompt) -> AsyncGenerator[Message, None]`. Each `Message` carries a typed `message_type` enum and a `role`. The MCP server layer is purely a dispatcher; it does not know how Codex differs from Gemini internally.

Evidence: `roundtable_mcp_server/cli_subagent.py` adapter consumption pattern; `CodexCLI`, `ClaudeCodeCLI`, `CursorAgentCLI`, `GeminiCLI` all conform to the same call signature.

### 2. Agent availability is separated from execution

`CLIAvailabilityChecker` runs `[tool] --help`, caches results as JSON in `~/.roundtable/availability_check.json` (with `available`, `status`, `last_checked`, `error` per tool), and exposes `get_available_clis()` independently of the execution path. The MCP server reads the cache at startup and gates each tool on `"agent_name" in enabled_subagents`.

Evidence: `roundtable_mcp_server/availability_checker.py`; `ServerConfig.subagents` gating in `server.py`.

### 3. Session identity is a first-class parameter

`session_id` flows all the way down to `execute_with_streaming()`. Docstrings describe this as enabling conversation continuity. The interface acknowledges that multi-turn context is a property of the execution layer, not just the prompt layer.

Evidence: `codex_subagent(instruction, project_path, session_id, model, is_initial_prompt)` and equivalent signatures for all four adapters.

### 4. Message categorization is explicit and typed

The streaming loop categorizes output into `agent_responses`, `tool_uses`, and terminal `result` or `error` states before any synthesis. This makes the downstream aggregation step data-driven rather than string-heuristic.

Evidence: message loop in `server.py` tool functions; categories driven by `message_type.value` and `message.role == "assistant"`.

### 5. Configuration is environment-variable driven with a clear priority chain

`parse_config_from_env()` checks `CLI_MCP_SUBAGENTS` first, then the availability cache, then falls back to all agents. `CLI_MCP_IGNORE_AVAILABILITY` overrides discovery for CI or forced-enable scenarios. The server exposes no runtime mutation surface; config is resolved once at startup.

Evidence: `ServerConfig(BaseModel)` with env-var parse; `initialize_config()` global setup.

## What to borrow directly

### Borrow: the uniform streaming adapter interface

The `execute_with_streaming` signature — instruction, project_path, session_id, model, is_initial_prompt, returning typed Message objects — is the right shape for `volva-adapters`. Today `volva-adapters` is a thin stub crate. This interface pattern is a concrete, tested model for what each backend adapter should expose.

Best fit: `volva-adapters` (Rust trait equivalent) and `septa` (typed contract for the cross-adapter message shape).

### Borrow: the availability-check-then-gate pattern

Running a capability check at startup and caching the result, then gating dispatch on the cached availability set, is the right operational discipline. `stipe doctor` already checks prerequisites; the roundtable pattern makes per-backend availability a named, persistable fact rather than an implicit assumption.

Best fit: `stipe` (the check-and-gate logic), with the cache schema landing in `septa`.

### Borrow: message-type categorization before synthesis

Separating agent_responses, tool_uses, errors, and terminal result events before attempting any synthesis is cleaner than post-hoc string parsing. The ecosystem needs this at the boundary between `volva` (raw backend output) and `canopy` (coordination reasoning).

Best fit: `volva-runtime` message classification; `septa` typed event shape.

## What to adapt, not copy

### Adapt: the parallel fan-out model

Roundtable fans out every task to all available agents simultaneously and concatenates results. That is the simplest possible coordination policy. The ecosystem should treat parallel fan-out as one dispatch mode among several — `canopy` and `hymenium` already have richer dispatch and phase-gating semantics. The fan-out itself is useful; making it unconditional is not.

Adaptation: `hymenium` should support a parallel-fan-out dispatch mode as a first-class workflow primitive, consuming the standardized adapter interface from `volva-adapters`.

### Adapt: the availability cache format

The JSON cache (`available`, `status`, `last_checked`, `error` per tool) is sensible but ad hoc. The ecosystem already has a septa schema pattern. Adapt this into a `septa` agent-backend-availability schema so that `stipe`, `volva`, and any operator surface in `cap` or `annulus` share one source of truth.

### Adapt: the `is_initial_prompt` flag

This flag indicates whether the agent should establish fresh context or continue an existing session. The underlying concept — distinguishing session initialization from continuation — belongs in a typed message-kind or dispatch-context enum, not a bare boolean. Adapt into a `septa` dispatch context type.

## What not to borrow

### Skip: string-based response synthesis

Roundtable concatenates responses with `**[Agent] Response:**\n{content}` separators and lists tool uses with `🔧 **Tools Used ({count}):**`. This is readable for a human in an IDE chat window but is not a structured output format. The ecosystem should not canonize a Markdown string as a cross-tool payload.

### Skip: the Python implementation stack

Roundtable is Python on `fastmcp` and `tinyagent-py`. The ecosystem's runtime layer is Rust. The interface patterns are portable; the implementation is not.

### Skip: the shell `--help` exit-code discovery method

Running `codex --help` and checking the exit code is fragile — it conflates installation, PATH resolution, and feature availability, and it generates no structured information about versions, models, or capabilities. `stipe doctor` already does structured prerequisite checking; that is the right pattern to expand.

### Skip: global subagent-to-user response synthesis at the MCP layer

Roundtable hands the synthesized multi-agent response directly back to the primary assistant via MCP. For the ecosystem, that synthesis step belongs in `canopy` (coordination reasoning) or `hymenium` (workflow outcome assembly), not in the transport or adapter layer. The MCP boundary should carry typed events, not assembled prose.

## How Roundtable fits the ecosystem

### Best fit by repo

- `volva`
  Primary fit. The uniform `execute_with_streaming` adapter interface is what `volva-adapters` should formalize. The availability-gate-then-dispatch pattern is what `volva-runtime` should own for multi-backend scenarios. The `session_id` threading is already directionally correct with how `volva` conceptualizes sessions.

- `septa`
  Strong fit. Three contracts are worth formalizing: an agent-backend adapter message type (typed streaming event shape), an agent-availability record (the cache schema), and an adapter-context type replacing the `is_initial_prompt` boolean.

- `stipe`
  Strong fit for the availability check-and-gate logic. `stipe doctor` already checks for installed binaries; the roundtable cache pattern shows how to make those checks named, persistent, and consumable by other tools.

- `canopy`
  Moderate fit. Parallel fan-out is a coordination pattern that `canopy` should expose as a named dispatch mode, consuming the standardized adapter output from `volva`.

- `hymenium`
  Moderate fit. The parallel work unit (one instruction dispatched to multiple agents, responses collected) maps cleanly to hymenium's workflow dispatch primitives. Fan-out as a workflow phase is more composable than fan-out as a permanent MCP behavior.

- `cap`
  Weak-moderate fit. The availability cache (which agents are up, last-checked timestamps) is operator-visible state that `cap` could surface.

- `cortina`
  Weak fit. The execution lifecycle events (task dispatched, agent response received, synthesis complete) are signals cortina could capture, but this is downstream of the adapter contract work.

- `lamella`
  Weak fit. A "multi-agent delegation" skill pattern is plausible but not the core contribution of roundtable.

## What Roundtable suggests improving in your ecosystem

### 1. Volva-adapters needs a concrete trait, not a stub crate

Roundtable's adapter interface is simple: one async generator, typed message output, session id threading. `volva-adapters` is currently a thin placeholder. Roundtable's interface is a tested model for what the trait surface should look like. Define the Rust trait now; stub backends can implement it one at a time.

### 2. Septa is missing an agent-backend adapter contract

There is no `agent-adapter-v1.schema.json` in septa. The cross-tool payloads for backend dispatch (`dispatch-request-v1`) and workflow participation (`workflow-participant-runtime-identity-v1`) exist, but neither captures the streaming message shape or the per-adapter availability record. This gap means every tool that touches multi-backend dispatch invents its own format.

### 3. Stipe doctor should produce a structured availability record

The `stipe-doctor-v1.schema.json` schema exists in septa. The roundtable availability cache pattern shows what per-backend availability looks like as structured data. Stipe's doctor output should include a per-backend section that volva and canopy can consume without re-running checks.

### 4. The ecosystem lacks a named parallel fan-out dispatch mode

Roundtable's core behavior — fan all agents the same instruction, collect typed responses — is a useful primitive. Neither canopy nor hymenium currently names this as a first-class pattern. It should be. The value is not in doing it unconditionally (roundtable's weakness) but in having a composable, named mode that a workflow can invoke deliberately.

### 5. Session-id threading should be explicit in adapter contracts

Roundtable correctly passes `session_id` through to each adapter but leaves the semantics undefined. The ecosystem should define what session continuity means at the adapter boundary: does a new `session_id` guarantee fresh context? Does a repeated one guarantee continuation? This should be specified in septa, not left to each adapter implementation.

## Verification context

This audit is based on remote source inspection via GitHub. Files reviewed: `roundtable_mcp_server/server.py`, `roundtable_mcp_server/cli_subagent.py`, `roundtable_mcp_server/availability_checker.py`, `pyproject.toml`, and `README.md`. No local checkout was made; no tests were run against the live repo. Version audited: v0.5.0.

## Final read

Borrow: the uniform async streaming adapter interface (`execute_with_streaming` signature), the availability-check-then-gate operational pattern, and the typed message categorization before synthesis.

Adapt: parallel fan-out into a named `hymenium` dispatch mode rather than a hard-wired MCP behavior; availability cache into a `septa` schema; `is_initial_prompt` into a typed dispatch-context field.

Skip: string-based response synthesis as a cross-tool payload, the Python/fastmcp stack, shell `--help` availability discovery, and MCP-layer response assembly.

Best-fit repos: `volva` (adapter trait and multi-backend dispatch), `septa` (adapter message type, availability record, dispatch context), `stipe` (availability check and gate), `canopy`/`hymenium` (fan-out as a named dispatch mode).

Needs septa contract? Yes. Three: `agent-adapter-message-v1` (typed streaming event from an adapter), `agent-backend-availability-v1` (per-backend availability record with timestamp and error), and `adapter-dispatch-context-v1` (session identity and initialization semantics).
