# Headroom Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `headroom`
Lens: what to borrow from headroom, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Headroom is a context compression and memory optimization layer for LLM applications with claimed 87% token savings on real workloads via content-aware routing, lossless reversible compression (CCR), and schema-aware JSON stripping. Its strongest portable ideas are: ContentRouter that directs payloads to specialized compressors by content type, reversible compression where the model can retrieve original bytes on demand, a canonical request lifecycle pipeline with hooks, and a cross-agent memory system with failure learning that writes corrections back to config files. Basidiocarp benefits most in `mycelium` (content-aware output filtering), `cortina` (lifecycle pipeline model), and `hyphae` (cross-agent memory and failure learning). Specific ML models and tool-specific wrap commands should be skipped.

## What headroom is doing that is solid

### 1. Content-aware routing to specialized compressors

ContentRouter directs payloads to specialized compressors based on content type detection: SmartCrusher (JSON), CodeCompressor (AST-aware for 6 languages), Kompress-base (ML model trained on agentic traces). Signal (errors, anomalies, relevant items) is preserved while stripping boilerplate.

Evidence:
- `ContentRouter` class with `detect_content_type()` and `route_to_compressor()` methods
- `SmartCrusher`: JSON-aware stripper (removes null/empty fields, flattens single-item arrays)
- `CodeCompressor`: AST-aware compressor for Python, JS, TS, Rust, Go, Java
- `Kompress-base`: ML model trained on agentic execution traces for general compression

Why that matters here:
- `mycelium` output filtering should use a similar content-aware router instead of treating all output as plain text.
- The same structure (detect type → route to handler) applies to `mycelium`'s existing filter dispatch.

### 2. Reversible compression (CCR)

Compression is not deletion. The model can call `headroom_retrieve` to pull original bytes when needed. Nothing is discarded — content is elided, not deleted. Compressed handles reference original content in storage.

Evidence:
- CCR (Claude Compression Retrieval) protocol: compressed output includes retrieval handle
- `headroom_retrieve(handle)` MCP tool for pulling full content on demand
- Original content stored in SQLite with handle → content mapping

Why that matters here:
- `mycelium` should implement CCR-style handles for elided output, pointing to `hyphae` chunked storage.
- This completes the "full output always available" invariant: compressed in context, retrievable on demand.

### 3. Canonical request lifecycle pipeline with hooks

Canonical 8-stage pipeline: Setup → Pre-Start → Post-Start → Input Received → Input Cached → Input Routed → Input Compressed → Input Remembered → Pre-Send → Post-Send → Response Received. Extensions observe/customize lifecycle stages at well-defined hooks.

Evidence:
- `LifecyclePipeline` class with `register_hook(stage, handler)` method
- Each stage has pre/post variants for before/after semantics
- Extensions add observability (logging, metrics), caching, and transformation at hooks

Why that matters here:
- `cortina` should adopt this canonical pipeline model for lifecycle signal capture.
- The named stages map well to cortina's existing hook types (PreToolUse, PostToolUse, Stop/SessionEnd).

### 4. Cross-agent memory and failure learning

`SharedContext().put/.get` for passing compressed context across multi-agent workflows. `headroom learn` mines failed sessions and writes corrections directly to CLAUDE.md/AGENTS.md/GEMINI.md, compounding reliability over time.

Evidence:
- `SharedContext` class with `put(key, value, ttl)` / `get(key)` for inter-agent state
- `headroom learn` command: parses session transcripts for failures, extracts correction patterns, writes to config files
- Correction categories: tool misuse, prompt misunderstanding, context confusion

Why that matters here:
- `hyphae` SharedContext pattern should be formalized in the memory store API for inter-agent state passing.
- `headroom learn` is the failure learning pattern basidiocarp needs — formalize in `hyphae` memory consolidation.

## What to borrow directly

### Borrow now

- Content type detection and routing.
  Best fit: `mycelium` (output filtering should use content-aware router).

- Reversible compression with retrieval handles.
  Best fit: `mycelium` (elide output, store handle in `hyphae` chunked storage for on-demand retrieval).

- Request lifecycle hooks (canonical pipeline model).
  Best fit: `cortina` (should adopt named pipeline stages for lifecycle signal capture).

- Cross-agent memory system.
  Best fit: `hyphae` (SharedContext pattern should be formalized in memory store API).

- Failure learning pipeline.
  Best fit: `hyphae` (auto-write corrections to config files after mining failed sessions).

## What to adapt, not copy

### Adapt

- Compression algorithm composition (SmartCrusher + CodeCompressor + Kompress-base).
  Adapt for basidiocarp domains: the routing and composition pattern is portable, the specific algorithms need calibration for basidiocarp outputs.

- Provider backend abstraction.
  Adapt for other backends (Bedrock, Vertex, etc.) in `spore`; headroom's unified provider pattern is clean.

- Proxy architecture (request transformation pipeline).
  Adapt for other proxies (authentication, caching, routing) in `volva`.

## What not to borrow

### Skip

- Specific compression models (Kompress-base).
  Train or configure models for basidiocarp domains; don't import opaque ML models.

- Tool-specific wrap commands (`headroom wrap claude`, `headroom wrap codex`).
  These belong in per-tool integrations, not core infrastructure.

- Token budget enforcement as a headroom responsibility.
  Token budgets should be enforced by the orchestration layer (`canopy`/`mycelium`), not the compression proxy.

## How headroom fits the ecosystem

### Best fit by repo

- `mycelium`: Token-optimized output filtering via content-aware routing and reversible compression.
- `cortina`: Canonical lifecycle pipeline model with named stages and hook registration.
- `hyphae`: Cross-agent memory and failure learning patterns.
- `spore`: Provider backend abstraction and service discovery.
- `volva`: Proxy middleware and request transformation pipeline.

## What headroom suggests improving in your ecosystem

### 1. No context budget enforcement

Headroom compresses but doesn't reserve token budgets per agent. `mycelium` should enforce per-agent token ceilings with explicit elision and retrieval handles.

### 2. Learning is file-based

`headroom learn` writes directly to CLAUDE.md. Should integrate with `hyphae` memory store for structured learning with topic, importance, and expiry metadata.

### 3. No schema-aware compression

Headroom compresses JSON without knowing `septa` contracts. `mycelium` should be schema-aware: for known `septa` payload types, preserve semantically important fields and elide boilerplate fields by schema definition.

## Final read

**Borrow:** content-aware routing, reversible compression with retrieval handles, lifecycle pipeline model, cross-agent memory, failure learning.

**Adapt:** compression algorithm composition, provider abstraction, proxy middleware patterns.

**Skip:** specific ML models and tool-specific wrap commands; focus on infrastructure.
