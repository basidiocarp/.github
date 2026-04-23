# Cognee Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `cognee`
Lens: what to borrow from cognee, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Cognee is a production knowledge-engineering platform combining ontology-grounded knowledge graphs, multi-backend support (Kuzu, Neo4j, PostgreSQL), rich search types (15+ modes), and agent memory decoration for function instrumentation. The strongest portable ideas are: pluggable multi-backend graph/vector/relational abstractions, ontology-based entity grounding with fuzzy matching, search type registry with dispatcher, and decorator-based agent memory tracing. Most features fit into `hyphae` (graph backends, search types, memoirs), `lamella` (ontology management, task composition), and `cortina` (memory instrumentation). Cognee's tight coupling to FastAPI routers and multi-tenant access control are product-specific; the underlying patterns are portable.

## What Cognee is doing that is solid

### 1. Pluggable multi-backend architecture

Cognee abstracts graph, vector, and relational databases behind interface-based adapters. Users configure via environment variables (`GRAPH_DATABASE_PROVIDER`, `VECTOR_DB_PROVIDER`, `DB_PROVIDER`) and get isolated tenant databases (Kuzu, Neo4j, PostgreSQL, etc.). Backends implement common interfaces (`GraphDBInterface`, `VectorDBInterface`) enabling swapping at runtime.

Evidence:
- `cognee/infrastructure/databases/graph/graph_db_interface.py`: Abstract `GraphDBInterface` with node/edge/query methods, consistent across Kuzu, Neo4j, Neptune, Postgres
- `cognee/infrastructure/databases/vector/vector_db_interface.py`: Abstract `VectorDBInterface` for similarity search, implemented by LanceDB, ChromaDB, PGVector, Qdrant, Weaviate, Milvus
- Environment variables: `GRAPH_DATABASE_PROVIDER` (kuzu, neo4j, neptune, postgres), `VECTOR_DB_PROVIDER` (lancedb, chromadb, pgvector, etc.) with defaults

Why that matters here:
- `hyphae` storage layer should adopt interface-based backends with factory pattern.
- `septa` should define contracts for backend adapters (nodes, edges, query protocols).
- This eliminates vendor lock-in and enables multi-cloud deployments with no code changes.

### 2. Ontology-based entity grounding

Cognee supports OWL ontologies for entity grounding. Extraction tasks match LLM-extracted entities against ontology classes. Fuzzy matching with configurable similarity (default 80%) allows approximate alignment. Fallback to free-form extraction if ontology not configured.

Evidence:
- `cognee/modules/ontology/` directory provides ontology resolution
- `ONTOLOGY_RESOLVER` (rdflib), `MATCHING_STRATEGY` (fuzzy), `ONTOLOGY_FILE_PATH` environment variables
- Entity extraction uses Instructor structured output framework with ontology validation gates

Why that matters here:
- `hyphae` memoirs could support optional ontology grounding for controlled vocabularies and semantic alignment.
- `septa` should define ontology contract (OWL classes, properties, constraints, matching rules).
- This bridges knowledge graphs and semantic web standards (Linked Data, SKOS).

### 3. Search type registry with 15+ modes

Cognee exposes multiple search types (`CHUNKS`, `GRAPH_COMPLETION`, `TRIPLET_COMPLETION`, `RAG_COMPLETION`, `SUMMARIES`, `CYPHER`, `NATURAL_LANGUAGE`, `TEMPORAL`, `FEELING_LUCKY`, `CODING_RULES`, etc.). Each route to a different retriever. `SearchType` enum allows querying to specify intent without reimplementing.

Evidence:
- `cognee/modules/search/types/SearchType.py`: Enum with 20 values (SUMMARIES, CHUNKS, RAG_COMPLETION, TRIPLET_COMPLETION, GRAPH_COMPLETION, GRAPH_COMPLETION_DECOMPOSITION, GRAPH_SUMMARY_COMPLETION, CYPHER, NATURAL_LANGUAGE, GRAPH_COMPLETION_COT, GRAPH_COMPLETION_CONTEXT_EXTENSION, FEELING_LUCKY, TEMPORAL, CODING_RULES, CHUNKS_LEXICAL)
- `cognee/modules/retrieval/`: ChunksRetriever, TripletSearchContextProvider, SummarizedTripletSearchContextProvider with consistent interface
- `FEELING_LUCKY` mode auto-selects best search type for query using heuristics

Why that matters here:
- `hyphae` should support a search type registry and dispatcher with pluggable retrievers.
- `septa` should define search result contracts per type (chunks vs. triplets vs. summaries).
- This gives users control over retrieval strategy without reimplementing; enables A/B testing.

### 4. Decorator-based agent memory instrumentation

Cognee provides `@agent_memory` decorator that wraps functions and auto-traces execution. Traces include function call, memory context, return value, and error state. Uses `contextvars` for async-safe context propagation.

Evidence:
- `cognee/modules/agent_memory/decorator.py`: `@agent_memory` decorator with config parameter
- `AgentMemoryContext` dataclass with config, scope, memory_query, memory_context, method_params, return_value, status, error_message
- `AgentTrace` DataPoint with origin_function, with_memory, memory_query, memory_context, status, error_message, text
- `contextvars.ContextVar` for async-safe storage with set/get/reset token pattern

Why that matters here:
- `cortina` should adopt decorator-based hook instrumentation for non-invasive function instrumentation.
- `septa` should define trace contracts for function instrumentation (function name, params, return, status, memory context).
- This enables observability and memory injection at function boundaries without modifying application code.

### 5. Modular pipeline-based processing with composable tasks

Cognee processes data through pipelines composed of `Task` objects. Tasks are async functions returning Task instances with dependencies declared. Pipelines run sequentially or in parallel based on dependency graph resolution.

Evidence:
- `cognee/modules/pipelines/` directory with Task composition framework
- `cognee/tasks/` covers: ingestion (ingest_data.py), graph extraction (extract_graph_from_data.py), storage (add_data_points.py), memify, temporal awareness
- Task results are typed; dependencies resolved before execution with proper await semantics

Why that matters here:
- `cortina` should expose task composition and dependency resolution as core orchestration primitive.
- `lamella` should manage task registration, discovery, and version compatibility checking.

## What to borrow directly

### Borrow now

- Pluggable multi-backend architecture with interface adapters.
  Best fit: `hyphae` (storage layer) with `septa` (backend contracts for nodes, edges, queries).

- Ontology-based entity grounding with fuzzy matching.
  Best fit: `hyphae` (optional ontology validation for memoirs), `septa` (ontology contracts).

- Search type registry with dispatcher pattern.
  Best fit: `hyphae` (retrieval modes), `septa` (search result contracts per type).

- Decorator-based agent memory instrumentation.
  Best fit: `cortina` (hook instrumentation), `septa` (trace contracts with function signature).

- Task-based pipeline composition with dependency resolution.
  Best fit: `cortina` (orchestration), `lamella` (task management and discovery).

## What to adapt, not copy

### Adapt

- FastAPI router structure and multi-tenant access control.
  Adaptation: Extract permission model and multi-tenancy patterns to `septa`; keep FastAPI as product-layer detail.

- LLM provider abstraction (Cognee's LLMGateway).
  Adaptation: Already exists in basidiocarp; extend with Cognee's Instructor mode and provider cascade patterns.

- Document loading and chunking strategies.
  Adaptation: Move to task layer in `lamella`; keep interfaces and result contracts in `septa`.

- Temporal awareness for graphs (`temporal_graph` module).
  Adaptation: Make optional in `hyphae` memoirs; temporal constraints in `septa` contracts.

## What not to borrow

### Skip

- FastAPI application structure.
  This is product-specific; use your own API framework or extend existing basidiocarp API.

- Multi-tenant database isolation implementation.
  Cognee's implementation is tightly coupled to their backends; design your own or use service-level isolation.

- Full LLM provider cascade (Cognee's fallback logic).
  This is operational policy; should be in user config, not infrastructure layer.

- Domain-specific entity types and relationship schemas.
  These are application-specific (users, documents, organizations); borrow the extraction pattern, not the taxonomy.

## How Cognee fits the ecosystem

### Best fit by repo

- `hyphae`: Strong fit for multi-backend adapters, search type registry, ontology grounding, and graph storage with tenant isolation.
- `septa`: Strong fit for backend contracts, ontology schemas, search result contracts, trace schemas, and multi-tenancy models.
- `cortina`: Strong fit for decorator-based instrumentation, memory injection hooks, pipeline orchestration, and policy selection.
- `lamella`: Strong fit for task composition, document loading plugins, search type registration, and provider discovery.
- `spore`: Moderate fit for multi-backend discovery and transport.

## What Cognee suggests improving in your ecosystem

### 1. Add pluggable backend adapters to hyphae

Cognee's multi-backend pattern (Kuzu, Neo4j, Postgres, etc.) should become standard in `hyphae`. Define backend interfaces in `septa` and allow swapping at runtime via configuration with zero code changes.

### 2. Support ontology-based grounding in memoirs

Cognee's ontology validation shows that knowledge graphs benefit from semantic grounding against controlled vocabularies. Add optional ontology support to `hyphae` memoirs with `septa` contracts for ontology schemas and matching rules.

### 3. Create a search type registry in hyphae

Instead of embedding search logic in application code, expose a registry of search types (local, global, semantic, keyword, temporal, code-aware). Let users and tools select retrieval strategy declaratively with pluggable retrievers.

### 4. Add decorator-based instrumentation to cortina

Cognee's `@agent_memory` pattern is cleaner than manual hook registration. Add decorator-based hooks to `cortina` for non-invasive function instrumentation, memory injection, and distributed tracing.

### 5. Standardize trace and metadata contracts

Cognee traces function calls, memory context, and outcomes. Define these as `septa` contracts (function signature, parameters, return type, status, memory context, error messages) so all tools can produce compatible traces.

### 6. Make temporal constraints explicit in graph models

Cognee's `temporal_graph` module shows that time-aware queries are important for event-based knowledge. Add temporal support to `septa` knowledge graph contracts with timestamp fields and temporal filters.

## Final read

**Borrow:** pluggable multi-backend adapters with factory pattern, ontology-based grounding, search type registry with dispatcher, decorator-based memory instrumentation, task-based pipeline composition.

**Adapt:** FastAPI routing (keep product-specific), multi-tenant access control (design for your needs), LLM provider abstraction (extend existing), temporal awareness (make optional and configurable).

**Skip:** FastAPI-specific implementation, multi-tenant database isolation strategies, LLM provider fallback cascade, domain-specific entity/relationship taxonomies.
