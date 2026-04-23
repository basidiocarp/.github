# Letta Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `letta`
Lens: what to borrow from letta, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Letta is a production stateful agent framework with sophisticated memory management, multi-tier archival/recall systems, and real-time streaming. The strongest portable ideas are: tiered memory architecture (core/archival/recall with compression), block-based persistent state with git backing, tool-execution lifecycle tracking with usage metrics, and conversation-window context management. Most features fit cleanly into `hyphae` (persistent memory), `cortina` (lifecycle hooks), and `septa` (memory contracts). The framework's tight coupling to LLM agents means the agentic reasoning layer should stay as reference, not be copied directly.

## What Letta is doing that is solid

### 1. Tiered memory architecture with capacity-aware compression

Letta separates core memory (editable blocks, fixed in context), archival memory (full-text searchable passage store), and recall memory (message history with summarization). Context window fit is monitored and excess messages are summarized and evicted to archival.

Evidence:
- `letta/schemas/memory.py` lines 68-350: Memory class with `_render_memory_blocks_git`, `_render_memory_blocks_standard`, and git-backed structured memory with block labels, descriptions, limits, and value fields
- `letta/services/summarizer/summarizer.py`: Summarization modes (`static_buffer`, `partial_evict`) with configurable `message_buffer_limit` and `message_buffer_min`
- `ArchivalMemorySummary`, `RecallMemorySummary`, `CreateArchivalMemory` schemas showing two-tier external storage with tagging and timestamp support

Why that matters here:
- `hyphae` should adopt this tiering explicitly: persistent knowledge graph (archival), session/working memory (recall), system state (core).
- This reveals a gap: basidiocarp needs context-window-aware memory eviction and compression policies with rollback semantics.

### 2. Block-based persistent state with git backing

Agents manage memory as versioned file blocks (persona, human, skills/, etc.) stored in git repositories. Changes are atomic commits with author, timestamp, and file-change tracking. Blocks have labels, descriptions, limits, and optional read-only flags.

Evidence:
- `letta/schemas/memory_repo.py`: `MemoryCommit`, `FileChange` schemas with SHA, parent_sha, author_type, author_id, timestamp, files_changed, additions/deletions
- `letta/services/block_manager_git.py`: `GitEnabledBlockManager` for atomic versioned updates with MCP-like semantics
- `Memory.compile()` renders blocks as nested XML with projection paths enabling filesystem-like views

Why that matters here:
- `hyphae` memoirs could adopt git-backed versioning for audit trails and rollback support.
- This points to a new `septa` contract: versionable knowledge blocks with lineage and authorship.

### 3. Tool execution with lifecycle tracking and usage metrics

`LettaAgent` tracks token usage per LLM call (prompt_tokens, output_tokens, completion_tokens_details). `StepMetrics` and `UsageStatistics` carry billing context. Tool execution is wrapped with error handling, output validation, and step-level metrics.

Evidence:
- `letta/agents/letta_agent.py` lines 40-100: Imports `LLMClient`, `MessageManager`, `PassageManager` with `step_manager` and `telemetry_manager` for instrumentation
- `letta/schemas/openai/chat_completion_response.py`: `UsageStatistics` with `prompt_tokens_details` (cache_creation, cache_read) and `completion_tokens_details`
- `Agent.step()` returns `LettaResponse` wrapping message, usage, step_metrics, stop_reason

Why that matters here:
- `cortina` should normalize tool execution and collect usage metrics as part of hook payloads.
- This suggests extending `septa` with billing/metering contracts and per-operation cost tracking.

### 4. Conversation window management with streaming and backpressure

Agents stream responses token-by-token (`step_stream`), managing input/output buffers and context fitting. Messages are preprocessed (validate, encode), and response assembly is lazy (deferred token counting).

Evidence:
- `letta/agents/base_agent.py` lines 68-75: `step_stream()` as `AsyncGenerator[LettaMessage | MessageStreamStatus | LegacyLettaMessage]`
- `letta/agents/letta_agent.py`: Stream callback handling with incremental response building and token tracking, supporting both OpenAI and Anthropic streaming

Why that matters here:
- `mycelium` should adopt streaming-aware formatting for large outputs.
- `canopy` should handle backpressure when agents exceed context window during orchestration.

## What to borrow directly

### Borrow now

- Tiered memory with archival/recall compression.
  Best fit: `hyphae` (separate persistent layers), with `cortina` managing eviction signals.

- Git-backed versioned blocks for memory state.
  Best fit: `hyphae` memoirs with `septa` contract for lineage and authorship.

- Tool execution lifecycle with usage tracking.
  Best fit: `cortina` (hooks), `septa` (contracts for usage/billing per operation).

- Context-window-aware message buffering and streaming.
  Best fit: `mycelium` (output formatting), `canopy` (orchestration backpressure).

## What to adapt, not copy

### Adapt

- Agent initialization with memory blocks and tools.
  Adaptation: Keep memory composition in `hyphae`, move tool binding to `lamella`, orchestration to `canopy`.

- Prompt rendering with memory compilation.
  Adaptation: Move memory retrieval to `hyphae`, prompt construction to `cortina` or task layer.

- Multi-agent summarization for context fit.
  Adaptation: Summarization strategy should be configurable in `cortina` hooks with policy engine, not hardcoded in agent classes.

## What not to borrow

### Skip

- Agent step execution loop with LLM reasoning.
  This is Letta's core product logic; extract the patterns (streaming, tool calling), not the loop itself.

- Specific memory block label conventions (system/, skills/).
  These are product-specific; borrow the block model, not the namespace taxonomy.

- OpenAI-specific response parsing and tool-use semantics.
  This is LLM provider coupling; belongs in user code, not ecosystem infrastructure.

## How Letta fits the ecosystem

### Best fit by repo

- `hyphae`: Strong fit for tiered memory, versioning, and archival storage with compression policies.
- `cortina`: Strong fit for memory eviction signals, compression triggers, and lifecycle hooks.
- `septa`: Strong fit for memory block contracts, usage metrics, and versioning lineage.
- `mycelium`: Moderate fit for streaming-aware output formatting with token budgets.
- `canopy`: Moderate fit for context-window orchestration and backpressure handling.

## What Letta suggests improving in your ecosystem

### 1. Define tiered memory contracts in hyphae and septa

Letta's three-tier memory (core/archival/recall) should become a standard `septa` contract. `hyphae` should expose separate APIs for each tier with clear eviction/compression semantics and configurable policies.

### 2. Add context-window eviction policies to cortina

Letta's summarization triggers reveal that `cortina` needs configurable memory-pressure signals: when to compress, what strategy, rollback semantics, and per-tier thresholds.

### 3. Versioning and audit trails for knowledge

Letta's git-backed blocks suggest that all persistent state in the ecosystem should support lineage: who changed what, when, why. Add to `septa` and `hyphae` with commit hooks.

### 4. Usage and billing metrics in all hooks

Every tool invocation, memory access, and LLM call should carry usage metadata for observability and cost tracking. Standardize in `cortina` and `septa` with per-operation granularity.

## Final read

**Borrow:** tiered memory architecture, git-backed versioned blocks, tool execution with usage tracking, streaming-aware context buffering.

**Adapt:** agent initialization, prompt rendering, message preprocessing, multi-agent summarization (extract strategies, not implementations).

**Skip:** agent reasoning loops, LLM-specific tool calling, memory label conventions.
