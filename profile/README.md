# Basidiocarp

Infrastructure for AI coding agents. Named after the fungal fruiting body — the visible structure that emerges from an underground mycelial network.

## Install

```bash
# Install everything (mycelium, hyphae, rhizome)
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh

# Install specific tools
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh -s -- --tools mycelium,hyphae

# Custom install directory
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh -s -- --prefix /usr/local/bin

# Uninstall
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh -s -- --uninstall
```

The installer downloads pre-built binaries, auto-detects your MCP clients (Claude Code, Cursor, Windsurf, Continue, Claude Desktop), configures MCP servers and hooks, and verifies the installation. Supports macOS (arm64/x86_64) and Linux (x86_64/aarch64).

### Configure

```bash
# Auto-detect all editors and configure everything
mycelium init --ecosystem

# Interactive guided setup (recommended for first time)
mycelium init --onboard

# Configure a specific editor
mycelium init --ecosystem --client cursor
mycelium init --ecosystem --client windsurf
mycelium init --ecosystem --client continue
mycelium init --ecosystem --client claude-desktop

# Print JSON config for any MCP client
mycelium init --ecosystem --client generic
```

### Verify

```bash
mycelium doctor    # Token proxy health
hyphae doctor      # Memory system health (DB integrity, FTS, MCP registration)
rhizome doctor     # Code intelligence health (parsers, LSP servers, export cache)
```

## Update

```bash
# Update all installed tools
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/update.sh | sh

# Check for updates without installing
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/update.sh | sh -s -- --check

# Or individually
mycelium self-update
hyphae self-update
rhizome self-update
```

## Projects

### [Mycelium](https://github.com/basidiocarp/mycelium)
Token-optimized CLI proxy. Intercepts command output and compresses it before it reaches the LLM, cutting token usage by 60-90% on 70+ command types. Routes large outputs to Hyphae for chunked storage. Includes `mycelium context <task>` for smart context briefings and `mycelium init --onboard` for guided ecosystem setup. Single Rust binary, works with any MCP client.

### [Hyphae](https://github.com/basidiocarp/hyphae)
Persistent memory for AI agents with 31+ MCP tools. Two memory models: **episodic memories** (temporal, decay-based, cross-project sharing via `_shared` pool) and **semantic memoirs** (knowledge graphs with typed concept relations). Code-aware recall expands search queries with Rhizome's symbol graph. Session lifecycle tracking (`session_start/end/context`). Imports Claude Code auto-memories. Conversation search across past sessions. HTTP embedding support (Ollama, OpenAI-compatible). Rust, SQLite, FTS5, sqlite-vec.

### [Rhizome](https://github.com/basidiocarp/rhizome)
Code intelligence MCP server with 35 tools across 32 languages. Dual backend: tree-sitter (instant offline parsing for 10 languages, zero setup) and LSP (cross-file references, rename, diagnostics — auto-installed). Includes 7 file editing tools (`replace_symbol_body`, `insert_after/before_symbol`, line-level edits, `create_file`), project summarization, and code graph export to Hyphae. Backend auto-selected per tool call. Rust.

### [Cap](https://github.com/basidiocarp/cap)
Web dashboard with 9+ pages and 50+ API endpoints. Memory browser, knowledge graph explorer (force-graph), token savings analytics, code explorer with annotations + complexity, ecosystem architecture diagram (ReactFlow), usage & cost tracking, agent telemetry, operational modes (Explore/Develop/Review), and quick context search. React 19, Mantine 8, Hono, Vite.

### [Spore](https://github.com/basidiocarp/spore)
Shared IPC library. Tool discovery, JSON-RPC 2.0 primitives, project detection, and subprocess MCP communication. Used by mycelium and rhizome. Rust.

### [Lamella](https://github.com/basidiocarp/lamella)
Plugin system for Claude Code. 230 curated skills, 175 agents, 213 commands across 20 plugins. Real-time hooks that capture errors, corrections, test results, and PR reviews into Hyphae memory. LSP configs for Rust, TypeScript, Python. Official Claude Code plugin format with marketplace support.

## How They Connect

```mermaid
graph TD
    Cap["<b>Cap</b><br/>Web Dashboard<br/><i>9 pages, 50+ endpoints</i>"]
    Hyphae["<b>Hyphae</b><br/>Agent Memory<br/><i>31+ MCP tools</i>"]
    Mycelium["<b>Mycelium</b><br/>Token Savings<br/><i>70+ command filters</i>"]
    Rhizome["<b>Rhizome</b><br/>Code Intelligence<br/><i>35 tools, 32 languages</i>"]
    Spore["<b>Spore</b><br/>Shared IPC<br/><i>Discovery + JSON-RPC</i>"]
    Lamella["<b>Lamella</b><br/>Skills & Hooks<br/><i>230 skills, 16 hooks</i>"]
    Agent["AI Coding Agent<br/><i>Claude Code, Cursor,<br/>Windsurf, Cline, Continue</i>"]

    Agent -- "commands" --> Mycelium
    Mycelium -- "filtered output<br/>60-90% fewer tokens" --> Agent
    Agent -- "MCP: 31+ tools" --> Hyphae
    Hyphae -- "memories, context,<br/>knowledge graphs" --> Agent
    Agent -- "MCP: 35 tools" --> Rhizome
    Rhizome -- "symbols, edits,<br/>definitions, analysis" --> Agent
    Lamella -- "skills, hooks,<br/>error capture" --> Agent
    Lamella -- "errors, corrections,<br/>test results, PR reviews" --> Hyphae
    Cap -- "reads DB" --> Hyphae
    Cap -- "CLI" --> Mycelium
    Cap -- "MCP" --> Rhizome
    Rhizome -- "code graph export" --> Hyphae
    Mycelium -- "large output chunks" --> Hyphae
    Spore -. "discovery + IPC" .-> Mycelium
    Spore -. "discovery + IPC" .-> Rhizome

    style Cap fill:#4c9aff,stroke:#2571cc,color:#fff
    style Hyphae fill:#36b37e,stroke:#1f8a5a,color:#fff
    style Mycelium fill:#ff7452,stroke:#de350b,color:#fff
    style Rhizome fill:#6554c0,stroke:#403294,color:#fff
    style Spore fill:#ffab00,stroke:#ff8b00,color:#fff
    style Lamella fill:#00b8d9,stroke:#0095b3,color:#fff
    style Agent fill:#505f79,stroke:#344563,color:#fff
```

## Agent Data Flow

```mermaid
sequenceDiagram
    participant Agent as AI Coding Agent
    participant L as Lamella Hooks
    participant M as Mycelium
    participant H as Hyphae
    participant R as Rhizome

    Note over Agent,R: Session start

    Agent->>H: session_start(project: "myapp")
    H-->>Agent: session_id for tracking

    Agent->>H: gather_context(task: "refactor auth")
    H-->>Agent: relevant memories + past errors + code symbols (budget-aware)

    Note over Agent,R: Development work

    Agent->>M: git log -20
    M-->>Agent: 5 lines (was 200, 90% saved)

    Agent->>R: get_symbols src/auth.rs
    R-->>Agent: structs, fns, impls

    Agent->>R: replace_symbol_body(file, symbol, new_code)
    R-->>Agent: file edited, 45 lines replaced

    Agent->>M: cargo test
    M-->>Agent: 2 failures (was 500 lines, 99% saved)
    L->>H: capture_errors("cargo test", failures)

    Agent->>R: get_complexity src/auth.rs
    R-->>Agent: cyclomatic complexity per function

    Note over Agent,R: Session end

    Agent->>H: session_end(summary, files_modified)
    H-->>Agent: stored for next session recall
    L->>H: evaluate_session(patterns learned)
```

## Optional Extras

```bash
# Cap web dashboard
cd cap && npm run dev:all          # http://localhost:5173

# Lamella plugins
cd lamella && make build-marketplace
# In Claude Code: /plugin marketplace add ./dist

# Import existing Claude Code memories
hyphae import-claude-memory

# Index past conversations for search
hyphae ingest-sessions

# Cross-project knowledge
hyphae project list               # See all projects
hyphae project search "auth"      # Search across projects

# Smart context briefing
mycelium context "refactor auth middleware"
```

## Built With

Rust (mycelium, hyphae, rhizome, spore) and TypeScript (cap). All Rust projects target edition 2024, use clippy pedantic linting, and follow anyhow/thiserror error handling conventions. 1,868+ tests across the ecosystem.
