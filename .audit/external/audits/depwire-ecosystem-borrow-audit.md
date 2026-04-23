# Depwire Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `depwire/depwire` (https://github.com/depwire/depwire)
Lens: what to borrow from depwire, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

Depwire is a deterministic, tree-sitter-based dependency graph engine exposing 17 MCP tools and a programmatic SDK for AI-assisted refactoring. Its core strengths are: a clean multi-language symbol extraction pipeline (11 languages, per-language parser modules in `src/parser/`), a well-typed graph schema (`SymbolNode`, `SymbolEdge`, `ProjectGraph` in `src/parser/types.ts`), a six-dimension health scoring system with weighted formulas (`src/health/metrics.ts`), in-memory what-if simulation without file I/O (`src/simulation/engine.ts`), cross-language edge detection linking REST calls to route handlers (`src/cross-language/types.ts`), and temporal graph snapshots from git history (`src/temporal/index.ts`). The primary fit is `rhizome`, which today handles code intelligence for the basidiocarp ecosystem but lacks Rust/Go/C language parsers, impact analysis, health scoring, and change simulation. Secondary fits are `hyphae` (temporal graph caching, dead code as memory signal), `canopy` (blast-radius analysis informing orchestration), `cortina` (security signal integration), and `cap` (arc diagram visualization). The Business Source License (converts Apache 2.0 in 2029) and Node/TypeScript stack limit direct code reuse; the patterns and algorithms are the borrowable surface.

## What Depwire is doing that is solid

### 1. Clean per-language parser interface with consistent output

Each language is its own module in `src/parser/` (`rust.ts`, `go.ts`, `python.ts`, `java.ts`, `kotlin.ts`, `cpp.ts`, `csharp.ts`, `php.ts`, `c.ts`, `javascript.ts`, `typescript.ts`). All implement the `LanguageParser` interface (`src/parser/types.ts`):

```typescript
interface LanguageParser {
  name: string;
  extensions: string[];
  parseFile(content: string, filePath: string): ParsedFile;
}
```

`ParsedFile` is a simple `{ symbols: SymbolNode[], edges: SymbolEdge[] }`. `SymbolNode` carries `id` (globally unique as `"path.ts::symbolName"`), `name`, `kind` (14-value union: `'function' | 'class' | 'variable' | 'constant' | 'type_alias' | 'interface' | 'enum' | 'import' | 'export' | 'method' | 'property' | 'decorator' | 'module'`), `filePath`, `startLine`, `endLine`, `exported`, and optional `scope`. `SymbolEdge` carries `source`, `target`, `kind` (8-value union: `'imports' | 'calls' | 'extends' | 'implements' | 'inherits' | 'decorates' | 'references' | 'type_references'`), `filePath`, and `line`.

The Rust parser (`src/parser/rust.ts`) specifically tracks: `function_item`, `struct_item`, `enum_item`, `trait_item` (mapped to kind `'interface'`), impl block methods, `const_item`, `type_item`, and `mod_item`. It resolves `crate::`, `super::`, and `self::` import paths and attempts both `module_name.rs` and `module_name/mod.rs` layouts. Built-in macros (`println!`, `vec!`) are filtered from call edges.

Why that matters here: `rhizome` is the code intelligence MCP server and the natural home for multi-language symbol analysis. Depwire's parser contract is clean enough to port directly to Rust as a trait.

### 2. Well-typed graph schema with round-trip serialization

`src/graph/serializer.ts` exports `exportToJSON()` and `importFromJSON()` producing a `ProjectGraph` with deterministic structure:

- `projectRoot: string`
- `files: string[]` (sorted)
- `nodes: SymbolNode[]`
- `edges: SymbolEdge[]`
- `metadata: { parsedAt: string, fileCount: number, symbolCount: number, edgeCount: number }`

The graph is built on `graphology` (a `DirectedGraph`) and serializes to plain JSON. `importFromJSON()` reconstructs the directed graph from JSON, skipping edges whose endpoints are not present (defensive). This round-trip design means the graph can be cached, versioned, and diffed.

Why that matters here: `septa` should own a language-agnostic symbol graph contract. `rhizome` can produce it; `hyphae` can index it; `canopy` can query it for orchestration decisions.

### 3. Six-dimension architecture health scoring

`src/health/metrics.ts` implements six weighted dimensions:

| Dimension | Weight | Algorithm summary |
|---|---|---|
| Coupling | 25% | Average cross-file connections; god file penalty at 3× average; cross-directory excess penalty at >70% |
| Cohesion | 20% | Internal dependency ratio per directory; 100→20 scale at five thresholds |
| Circular dependencies | 20% | DFS cycle detection; 100→20 from 0 to >10 cycles |
| God files | 15% | Files at >3× average connections; 100→20 from 0 to >5 god files |
| Orphans and dead code | 10% | Combined orphan file and dead symbol percentage; 100→20 at >20% |
| Dependency depth | 10% | Longest chain via recursive DFS; 100→20 from ≤4 to >12 levels |

`scoreToGrade()` maps to A/B/C/D/F. Each dimension emits a human-readable metric string (e.g., `"Average 4.2 connections per file, max 18"`). Overall score is a weighted sum clamped to 0–100.

Why that matters here: `rhizome` currently provides structural queries but no architectural health summary. This scoring model is directly portable.

### 4. In-memory change simulation without file I/O

`src/simulation/engine.ts` defines `SimulationEngine` with five operation types: `delete`, `move`, `rename`, `split`, `merge`. The engine clones the live graph in memory, applies the operation, recomputes health metrics on the clone, and returns a `SimulationResult`:

```typescript
interface SimulationResult {
  original: GraphSnapshot;    // node/edge counts, health score
  simulated: GraphSnapshot;
  diff: GraphDiff;            // addedEdges, removedEdges, affectedNodes, brokenImports, circularDepsIntroduced, circularDepsResolved
  healthDelta: HealthDelta;   // before/after per dimension
}
```

`BrokenImport` tracks which external file references a deleted/moved node and which line. Path normalization (`normalizePath()`) strips `./` and trailing slashes; `fileMatch()` does flexible node-attribute matching. The simulation produces `circularDepsIntroduced` and `circularDepsResolved` arrays via custom DFS.

Why that matters here: `canopy` manages agent task ownership and handoffs. Knowing which files break before a change is exactly the kind of pre-condition analysis canopy needs before dispatching an implementation agent. The `simulate_change` tool surfaced via MCP is the sharpest idea in the project.

### 5. Cross-language edge detection with confidence levels

`src/cross-language/types.ts` defines `CrossLanguageEdge`:

```typescript
interface CrossLanguageEdge {
  sourceFile: string;
  targetFile: string;
  type: 'rest-api' | 'subprocess';
  confidence: 'high' | 'medium' | 'low';
  sourceLang: string;
  targetLang: string;
  callLine?: number;
  metadata: {
    httpMethod?: string;
    apiPath?: string;
    rawCommand?: string;
  };
}
```

REST-API edges match TypeScript `fetch()` / `axios` calls to Python `@app.get()` / FastAPI / Flask / Express routes by HTTP method and path pattern. Subprocess edges match `execSync` / `subprocess.run` / `os.system` calls to target file definitions. Both flow through impact analysis, simulation, security scanning, and visualization.

Why that matters here: `rhizome` operates on single-language call graphs today. Cross-language edges would make `rhizome`'s impact analysis accurate across full polyglot stacks (e.g., a TypeScript frontend calling a Rust service via REST).

### 6. Temporal graph snapshots from git history

`src/temporal/index.ts` implements `runTemporalAnalysis()`: checks out sampled git commits (via 'even', 'weekly', or 'monthly' strategies), parses the project at each revision, serializes the graph, and caches snapshots under `.depwire/temporal/`. Each snapshot stores commit hash, date, message, author, and graph statistics (`totalFiles`, `totalSymbols`, `totalEdges`). `loadAllSnapshots()` enables programmatic access to all cached snapshots.

Why that matters here: `hyphae` already stores session memories and memoirs across time. Architectural snapshots keyed to git commits would give `hyphae` a code-structure timeline, not just a conversation timeline. This closes the gap between code structure and session memory.

### 7. MCP tool schema with disambiguation and fallback search

`src/mcp/tools.ts` defines 17 tools with consistent patterns:
- When multiple symbols match a query, return a disambiguation response rather than guessing.
- When an exact lookup fails, offer fuzzy search suggestions.
- Every tool checks whether a project is loaded before executing; returns an informative error if not.

The `impact_analysis` tool is notable: it accepts both a symbol name and an optional `file` parameter for disambiguation, covers direct dependents, transitive dependents, and affected files, and includes cross-language edges. The `find_dead_code` tool accepts `confidence` levels (`high`, `medium`, `low`), where `high` means definitely unreferenced.

Why that matters here: `rhizome` exposes MCP tools today. Depwire's tool patterns (disambiguation protocol, fallback search, project-not-loaded guard) are worth adopting verbatim.

### 8. Graph-aware security scanning

The security scanner elevates severity when a vulnerable pattern is reachable from an exposed HTTP route or MCP tool. Ten check categories: CVE dependencies, shell injection, hardcoded secrets, path traversal, auth bypass, input validation gaps, information leaks, cryptographic weaknesses, XSS, and architecture risks. The `graphAware` flag re-scores findings based on graph reachability: a hardcoded secret in a file only reached by test code scores lower than one reachable from a public route.

Why that matters here: `cortina` captures lifecycle signals; a graph-aware security signal as a cortina hook would let the ecosystem flag high-reachability vulnerabilities at the point where code changes.

## What to borrow directly

### Borrow now

- `LanguageParser` interface contract and per-language module structure.
  Best fit: `rhizome`. Port the trait as a Rust `trait LanguageParser { fn parse_file(...) -> ParsedFile; }`. Use depwire's `SymbolNode` / `SymbolEdge` / `EdgeKind` / `SymbolKind` type definitions as the septa contract for symbol graphs.

- `ProjectGraph` JSON schema as a `septa` cross-tool contract.
  Best fit: `septa`. Define a JSON Schema or Rust struct that captures `{ projectRoot, files, nodes[], edges[], metadata }`. Any tool producing or consuming symbol graphs speaks this contract. `rhizome` produces; `hyphae` indexes; `canopy` queries; `cap` visualizes.

- Six-dimension health scoring algorithm.
  Best fit: `rhizome`. The formulas (weighted coupling/cohesion/cycles/god-files/orphans/depth) are self-contained and directly translatable. Expose as a `get_health_score` MCP tool in `rhizome`.

- `SimulationEngine` concept: in-memory clone-and-diff for change impact.
  Best fit: `rhizome`. Implement `simulate_change` as an MCP tool accepting the same five operations (delete/move/rename/split/merge). Return `SimulationResult` via the septa contract.

- MCP tool patterns: disambiguation protocol, fallback search, project-not-loaded guard.
  Best fit: `rhizome`. These are implementation conventions for any MCP server that resolves symbols by name.

- Dead code detection with confidence levels.
  Best fit: `rhizome`. Three-tier confidence (`high`, `medium`, `low`) maps cleanly to an enum in Rust. High confidence = zero incoming edges from non-test files.

- `impact_analysis` tool with direct + transitive + cross-language scope.
  Best fit: `rhizome`. The current `find_references` tool in rhizome covers direct dependents. Extend to transitive BFS and include cross-language edges.

### Borrow later

- Cross-language edge detection (REST-API and subprocess matching).
  Best fit: `rhizome`. The two edge types (`rest-api`, `subprocess`) and confidence model are clean. Port as a post-parse enrichment step. Needs REST route pattern libraries per language before landing.

- Temporal graph snapshots from git history.
  Best fit: `hyphae`. Cache `ProjectGraph` snapshots per git commit in hyphae storage. `septa` defines the temporal snapshot contract (commit hash, graph stats, serialized graph). Expose via `hyphae_code_query` with time filters.

## What to adapt, not copy

### Adapt

- Cloud dashboard and arc diagram visualization.
  Depwire's arc diagram uses D3.js and is tightly coupled to a local Express server (`src/viz/`). The concept of visualizing dependency arcs interactively belongs in `cap`. Adapt the D3-based arc layout idea for cap's React frontend rather than porting the Express server.

- GitHub Actions integration (`depwire/depwire-action@v1`).
  Depwire triggers on PRs and comments impact analysis. The integration pattern is right for `canopy` (orchestration) and `cortina` (lifecycle signal on PR events), but implement against basidiocarp's own signal schema rather than depwire's proprietary action.

- Security scanner with graph-aware severity.
  The check categories (injection, secrets, path traversal, auth bypass) are well chosen. Adapt as a `cortina` hook pattern: run after code parse, elevate severity by reachability from exposed surfaces. Do not copy the scanner logic directly; implement using Rust-native AST analysis rather than tree-sitter-WASM-in-Node.

- Telemetry with opt-in usage reporting.
  Depwire has `src/telemetry.ts` for anonymous usage stats. The idea of structured telemetry is right for `cortina` (lifecycle signals), but implement as a cortina signal type in septa rather than ad hoc telemetry.

## What not to borrow

### Skip

- NPM package and Node/TypeScript runtime.
  The basidiocarp toolchain is Rust. Depwire's entire runtime is Node + WASM tree-sitter. Do not port the Node runtime; use native tree-sitter Rust bindings (`tree-sitter` crate) instead.

- Business Source License code.
  BUSL-1.1 restricts commercial use until 2029. Do not copy source files. Borrow algorithms and schemas only; implement them independently.

- Cloud dashboard and AI chat at `app.depwire.dev`.
  This is a SaaS product surface with proprietary backend. The arc diagram concept is portable; the cloud product is not.

- SDK version constant as a public API commitment.
  Depwire exposes `DepwireSDKVersion` as a public export. Version negotiation should live in `septa` contracts (schema versioning), not in library version strings.

- `detect.ts` language auto-detection from file extensions.
  This is trivially reimplementable. Don't port; write a two-line match in Rust.

- WebSocket-based visualization server architecture.
  Depwire binds a local WebSocket server for live graph updates. `cap` has its own architecture; don't import Depwire's server model.

## How Depwire fits the ecosystem

### By repo

- `rhizome` (primary fit): Depwire is rhizome's closest external reference implementation. The multi-language parser pipeline, symbol graph schema, impact analysis, health scoring, simulation, dead code detection, and MCP tool patterns all belong here. Rhizome should aim to be depwire's Rust-native equivalent with deeper basidiocarp integration.

- `septa` (contract fit): `ProjectGraph`, `SymbolNode`, `SymbolEdge`, `SymbolKind`, `EdgeKind`, `SimulationResult`, `HealthScore`, and the temporal snapshot structure should all become septa-defined schemas. Any tool that produces or consumes symbol graphs speaks these contracts.

- `hyphae` (temporal fit): The git-history snapshot model belongs in hyphae. Architectural evolution keyed to commits extends hyphae's time-aware memory beyond session conversations. The `loadAllSnapshots()` pattern maps to `hyphae_code_query` with commit-range filters.

- `canopy` (pre-flight fit): `simulate_change` via rhizome should become a pre-flight check in canopy's agent dispatch workflow. Before handing off an implementation task to an agent, canopy calls `simulate_change` to scope blast radius and detect broken imports.

- `cortina` (signal fit): Graph-aware security findings should emit as cortina signals (hook events) after a parse. Dead code findings can emit as low-priority cortina signals during lifecycle events.

- `cap` (visualization fit): The arc diagram concept belongs in cap's dashboard as a dependency graph view. Cap renders the `ProjectGraph` septa contract; rhizome serves it.

- `lamella` (skill fit): A `depgraph` skill that wraps rhizome's symbol graph and health tools would follow depwire's usage patterns (connect, summary, impact, health, dead-code) without requiring users to know individual tool names.

- `spore` (infrastructure fit): Path normalization, parser discovery, and graph file caching utilities should land in spore as shared primitives reused by rhizome and hyphae.

## What Depwire suggests improving in your ecosystem

### 1. Rhizome needs Rust-native multi-language symbol parsers

Rhizome likely handles some languages today but depwire's 11-language coverage with a clean `LanguageParser` interface exposes any gap. The per-file module structure (`rust.ts`, `go.ts`, `python.ts`, etc.) is the right organizational pattern. Rhizome should audit which languages it covers and add the missing parsers using the `tree-sitter` Rust crate with the same `{ symbols, edges }` output contract.

### 2. Septa is missing a symbol graph schema

There is no septa-defined contract for symbol graphs today. Depwire's `ProjectGraph` / `SymbolNode` / `SymbolEdge` types define a clear, portable format. Landing this in septa would let rhizome, hyphae, canopy, and cap speak the same graph vocabulary.

### 3. Impact analysis in rhizome should be transitive and cross-language

`find_references` in rhizome covers direct dependents. Depwire's `getImpact()` in `src/graph/queries.ts` returns direct dependents, transitive dependents, and affected files as three separate lists. Adding transitivity and cross-language scope would make rhizome's impact analysis complete enough for orchestration use.

### 4. Add in-memory change simulation to rhizome

No current basidiocarp tool simulates a rename, delete, or move before the agent touches a file. Depwire's `SimulationEngine` clone-and-diff approach (zero file I/O, graph-level diff) is the right pattern. This is the single highest-value borrow.

### 5. Canopy should use blast-radius analysis before delegating work

The delegation contract in CLAUDE.md requires seam-finding before spawning an agent. Canopy should call rhizome's (future) `simulate_change` tool as part of seam-finding: before dispatching an implementation agent, verify the blast radius is within the intended scope. An agent that would touch 40 files when 4 were expected is a scope violation detectable pre-flight.

### 6. Hyphae should store architectural snapshots per git commit

Hyphae currently stores session memories and memoirs. Depwire's temporal snapshots (parsed graph at each sampled commit) show that architectural evolution is a useful dimension of project memory. Adding code-structure snapshots would let hyphae answer "was this module highly coupled three months ago?" without re-parsing history.

### 7. Cap should visualize dependency arcs

Cap is the operator dashboard. A dependency arc view (files as nodes, import/call edges as arcs colored by distance) would give operators a visual health monitor. The `ProjectGraph` septa contract is the data source; D3 arc diagrams are the display pattern depwire proves works.

## Verification context

- Repo found at: https://github.com/depwire/depwire
- README fetched from both the GitHub HTML page and raw URL.
- Source files read: `src/parser/types.ts`, `src/graph/queries.ts`, `src/graph/serializer.ts`, `src/health/metrics.ts`, `src/simulation/engine.ts`, `src/cross-language/types.ts`, `src/temporal/index.ts`, `src/mcp/tools.ts`, `src/parser/rust.ts`, `src/sdk.ts`, `package.json`.
- Directory listings read: `src/`, `src/parser/`, `src/graph/`, `src/health/`, `src/cross-language/`.
- License confirmed: BUSL-1.1 (converts Apache 2.0 February 2029). No source code may be copied; algorithms and schemas may be independently implemented.
- Version at time of audit: `depwire-cli` v1.0.20.

## Final read

**Borrow:**
- `LanguageParser` interface contract and per-language module structure → `rhizome` (implement as Rust trait).
- `ProjectGraph` / `SymbolNode` / `SymbolEdge` JSON schema → `septa` (define as the ecosystem symbol graph contract).
- Six-dimension health scoring (coupling, cohesion, cycles, god files, orphans, depth) with weighted formulas → `rhizome` MCP tool.
- In-memory change simulation (`simulate_change`) with `SimulationResult` and `HealthDelta` → `rhizome` MCP tool; canopy consumes as pre-flight check.
- Dead code detection with three-tier confidence (`high`, `medium`, `low`) → `rhizome` MCP tool.
- MCP tool patterns: disambiguation protocol, fallback search, project-not-loaded guard → `rhizome` convention.
- Impact analysis returning direct + transitive + affected-files → `rhizome`, extending current `find_references`.

**Adapt:**
- Cross-language edge detection (REST-API and subprocess) → `rhizome` post-parse enrichment; needs per-language route pattern libraries before landing.
- Temporal graph snapshots from git history → `hyphae` code-structure timeline; define snapshot contract in `septa`.
- Arc diagram visualization → `cap` dashboard React component consuming `ProjectGraph` septa contract.
- Graph-aware security signal → `cortina` hook pattern; implement with Rust AST analysis rather than Node scanner.

**Skip:**
- Node/TypeScript runtime and WASM tree-sitter: use native `tree-sitter` Rust crate instead.
- BUSL-1.1 source code: algorithms only; no file copying.
- Cloud dashboard and SaaS AI chat: product-specific, not portable.
- Local WebSocket visualization server: cap has its own architecture.
- SDK version string as public API: use septa schema versioning instead.
