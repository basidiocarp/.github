# GraphRAG Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `graphrag` (Microsoft)
Lens: what to borrow from GraphRAG, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Microsoft's GraphRAG is a mature knowledge graph construction and querying framework with strong patterns for hierarchical indexing, dual-search modes (local/global), community detection, and graph-to-context builders. The strongest portable ideas are: multi-modal search (local entity-driven + global community-driven), context builders with structured data extraction, dynamic community selection with ranking, and map-reduce-style aggregation for global search. Most of these fit into `hyphae` (graph indexing and storage), `rhizome` (code-graph understanding), and a potential new search orchestration layer. The indexing pipeline (entity extraction, chunking, graph construction) is data-specific and should be adapted, not copied.

## What GraphRAG is doing that is solid

### 1. Dual-search architecture with local and global paths

GraphRAG separates local search (entity-centric, one-hop reasoning) from global search (map-reduce over communities). Local uses entity grounding; global uses community reports and map-reduce aggregation. Each has its own context builder, prompt strategy, and result aggregation with conversation history threading.

Evidence:
- `packages/graphrag/graphrag/query/structured_search/local_search/search.py` lines 56-80: `LocalSearch.search()` with `LocalContextBuilder`, `drift_query` parameter, incremental response building
- `packages/graphrag/graphrag/query/structured_search/global_search/search.py` lines 55-100: `GlobalSearch` with `map_system_prompt`, `reduce_system_prompt`, `concurrent_coroutines`, JSON mode toggle, `max_data_tokens`

Why that matters here:
- `hyphae` should expose both local (single entity/triple neighborhood) and global (aggregated summaries) retrieval modes as first-class operations.
- This suggests a `septa` contract for dual-mode search signatures with result normalization.

### 2. Community detection and hierarchical summaries

GraphRAG detects communities in the knowledge graph and generates ranked summaries ("Reports"). Communities are weighted by entity frequency, ranked by importance. Context builders can filter by `min_community_rank` and include/exclude community weights with deterministic shuffling.

Evidence:
- `packages/graphrag/graphrag/query/context_builder/community_context.py` lines 24-48: `build_community_context()` with rank filtering, weight normalization, shuffle with `random_state`, `max_context_tokens`, `context_name` parametrization
- `CommunityReport` data model with short_id, title, summary, full_content, rank, attributes, occurrence weight
- Dynamic community selection based on entity overlap with query for relevance filtering

Why that matters here:
- `hyphae` memoirs should support community detection for organizing related concepts with queryable summaries.
- `rhizome` code graphs could identify "communities" of tightly coupled functions and auto-generate summaries.
- This points to a `septa` contract for ranked, hierarchical knowledge structures with aggregation rules.

### 3. Context builders with multi-source aggregation

Context builders (`LocalContextBuilder`, `GlobalContextBuilder`) are abstract and pluggable. They compose multiple data sources: entities, community reports, source documents, and conversation history. Results are `ContextBuilderResult` with token counts, LLM call counts, and structured records.

Evidence:
- `packages/graphrag/graphrag/query/context_builder/builders.py` lines 16-76: `ContextBuilderResult` dataclass with `context_chunks`, `context_records` (DataFrame), `llm_calls`, `prompt_tokens`, `output_tokens`
- Community context, entity extraction, source context, conversation history are composed via separate builder functions with configurable inclusion
- `ConversationHistory` passed through to maintain turn-taking context and prevent redundant retrieval

Why that matters here:
- `hyphae` should adopt modular context builders with pluggable data sources and composition APIs.
- This suggests normalizing context composition as a `septa` contract with versioning.
- `cortina` could use this for dynamic prompt injection with tracked data lineage.

### 4. Token-aware context assembly

GraphRAG tracks `prompt_tokens`, `output_tokens`, and `llm_calls` per `ContextBuilderResult`. Context builders respect `max_context_tokens` and adjust data inclusion dynamically. Results include structured data (DataFrames) and textual summaries.

Evidence:
- `ContextBuilderResult` dataclass with `llm_calls: int`, `prompt_tokens: int`, `output_tokens: int` fields
- `build_community_context()` respects `max_context_tokens` and `single_batch` flag
- Context records are pandas DataFrames for structured analysis and export

Why that matters here:
- `mycelium` should track token budgets during output formatting and truncate gracefully.
- `hyphae` retrieval should be aware of context window and suggest truncation with ranked importance.

## What to borrow directly

### Borrow now

- Dual-mode search (local entity + global community).
  Best fit: `hyphae` as retrieval modes with `septa` contract, dispatcher in `cortina`.

- Community detection and ranked hierarchical summaries.
  Best fit: `hyphae` memoirs (auto-discover concept clusters), `rhizome` (detect function communities).

- Pluggable context builders with source composition.
  Best fit: `hyphae` (modular retrieval), `cortina` (prompt injection with data lineage).

- Token-aware context assembly with structured output.
  Best fit: `mycelium` (output formatting aware of token budgets), `septa` (context contracts).

## What to adapt, not copy

### Adapt

- Entity extraction and graph construction pipeline.
  Adaptation: Move extraction to user tasks; borrow the pipeline pattern (LLM → validation → storage), not the LLM prompts.

- Indexing strategies (chunking, entity recognition, relationship extraction).
  Adaptation: These are task-specific; make them pluggable in `lamella` (tasks), not hardcoded as pipeline steps.

- Map-reduce aggregation for global search.
  Adaptation: Expose as a reusable `cortina` pattern with configurable map/reduce prompts and concurrency controls.

## What not to borrow

### Skip

- Specific entity types and relationship schemas.
  These are domain-specific (organizations, people, locations); borrow the extraction pattern, not the taxonomy.

- The full indexing pipeline (extract_graph, summarize_communities, chunk documents).
  This is a product feature; extract the building blocks for `lamella`.

- DRIFT search and other specialized modes.
  These are interesting but over-specific; focus on local/global pattern first, make other modes pluggable.

## How GraphRAG fits the ecosystem

### Best fit by repo

- `hyphae`: Strong fit for dual-mode retrieval, community detection, hierarchical context building, and structured export.
- `rhizome`: Moderate fit for community detection in code graphs and identifying tightly-coupled symbol groups.
- `septa`: Strong fit for search mode contracts, context builder signatures, and ranked result schemas.
- `cortina`: Moderate fit for pluggable context builders that inject prompts and track token usage per builder.
- `mycelium`: Moderate fit for token-aware formatting of context output as tables and summaries.

## What GraphRAG suggests improving in your ecosystem

### 1. Design dual-mode retrieval in hyphae

Add explicit APIs for local (entity-neighborhood) and global (aggregated) retrieval. Expose both raw results and summarized context with ranking.

### 2. Implement community detection as a hyphae service

Auto-discover concept clusters in memoirs and knowledge graphs. Expose as optional indexing layer with query-time ranking and importance filtering.

### 3. Define context builder contracts in septa

Context builders should be pluggable, composable, and token-aware. Define standard signatures for source composition, filtering, aggregation, and result normalization.

### 4. Expose map-reduce patterns in cortina

GraphRAG's global search uses map-reduce over communities. Standardize this as a configurable `cortina` orchestration pattern for cost-effective aggregation over partitioned data.

### 5. Add structured data output to mycelium

Context builders produce both text and structured tables (DataFrames). Extend `mycelium` to format structured outputs for CLI/API consumption (CSV, JSON, tables).

## Final read

**Borrow:** dual-mode search (local/global), community detection with ranking, pluggable context builders, token-aware context assembly.

**Adapt:** entity extraction and indexing pipelines (extract patterns, not prompts), map-reduce aggregation (generalize for any fold operation), prompt templates (move to task layer).

**Skip:** specific entity schemas, full indexing pipelines, specialized search modes (focus on local/global first).
