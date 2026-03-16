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

# Pin a version
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh -s -- --version 0.3.0

# Uninstall
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh -s -- --uninstall
```

The installer downloads pre-built binaries, configures Claude Code (MCP servers + hooks), and verifies the installation. Supports macOS (arm64/x86_64) and Linux (x86_64/aarch64).

If you already have mycelium installed:

```bash
mycelium init --ecosystem
```

## Projects

### [Mycelium](https://github.com/basidiocarp/mycelium)
Token-optimized CLI proxy. Intercepts command output and compresses it before it reaches the LLM, cutting token usage by 60-90% on common dev operations. Routes large outputs to Hyphae for chunked storage instead of destructive filtering. Single Rust binary, integrates with Claude Code via hooks.

### [Hyphae](https://github.com/basidiocarp/hyphae)
Persistent memory for AI agents. Two complementary models: **episodic memories** (temporal, decay-based, topic-organized) and **semantic memoirs** (permanent knowledge graphs with typed concept relations). Code-aware recall expands search queries with Rhizome's symbol graph. MCP server with 20+ tools + CLI with 29 commands. Rust, SQLite, FTS5, sqlite-vec.

### [Rhizome](https://github.com/basidiocarp/rhizome)
Code intelligence MCP server. 26 tools across 32 programming languages. Dual backend: tree-sitter (instant offline parsing, zero setup) and LSP (cross-file references, rename, diagnostics — auto-installed). Backend auto-selected per tool call. Exports code symbol graphs to Hyphae as persistent knowledge. Rust.

### [Cap](https://github.com/basidiocarp/cap)
Web dashboard for the ecosystem. Browse memories, explore knowledge graphs, view token savings analytics, navigate code with symbol outlines, annotations, and complexity metrics. 8 pages, 15+ API endpoints. React, Mantine, Hono, Vite.

### [Spore](https://github.com/basidiocarp/spore)
Shared IPC library. Tool discovery, JSON-RPC 2.0 primitives, and subprocess MCP communication used by mycelium and rhizome. Rust.

### [Lamella](https://github.com/basidiocarp/lamella)
Plugin system for Claude Code. 230 curated skills, 175 agents, 213 commands across 20 plugins. Official Claude Code plugin format with marketplace support.

## How They Connect

```mermaid
graph TD
    Cap["<b>Cap</b><br/>Web Dashboard<br/><i>React + Hono</i>"]
    Hyphae["<b>Hyphae</b><br/>Agent Memory<br/><i>SQLite + FTS5 + sqlite-vec</i>"]
    Mycelium["<b>Mycelium</b><br/>Token Savings<br/><i>SQLite</i>"]
    Rhizome["<b>Rhizome</b><br/>Code Intelligence<br/><i>26 tools, 32 languages</i>"]
    Spore["<b>Spore</b><br/>Shared IPC<br/><i>Discovery + JSON-RPC</i>"]
    Lamella["<b>Lamella</b><br/>Skills & Agents<br/><i>230 skills, 20 plugins</i>"]
    Agent["AI Coding Agent"]

    Agent -- "commands" --> Mycelium
    Mycelium -- "filtered output<br/>60-90% fewer tokens" --> Agent
    Agent -- "MCP tools" --> Hyphae
    Hyphae -- "memories &<br/>knowledge graphs" --> Agent
    Agent -- "MCP tools" --> Rhizome
    Rhizome -- "symbols, refs,<br/>definitions" --> Agent
    Lamella -. "skills &<br/>agents" .-> Agent
    Cap -- "reads" --> Hyphae
    Cap -- "reads" --> Mycelium
    Cap -- "MCP" --> Rhizome
    Rhizome -- "code symbols → memoirs" --> Hyphae
    Mycelium -- "large outputs → chunks" --> Hyphae
    Spore -. "discovery &<br/>IPC" .-> Mycelium
    Spore -. "discovery &<br/>IPC" .-> Rhizome

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
    participant M as Mycelium
    participant H as Hyphae
    participant R as Rhizome

    Note over Agent,R: Typical agent session

    Agent->>M: git log -20
    M-->>Agent: 5 lines (was 200, 90% saved)

    Agent->>H: recall "auth middleware"
    H-->>Agent: 3 memories (code-aware: expanded via Rhizome symbol graph)

    Agent->>R: get_symbols src/auth.rs
    R-->>Agent: structs, fns, impls (no file reading needed)

    Agent->>R: get_complexity src/auth.rs
    R-->>Agent: cyclomatic complexity per function

    Agent->>R: find_references AuthMiddleware
    R-->>Agent: 4 locations across project (LSP auto-selected)

    Agent->>H: store memory about refactor
    H-->>Agent: stored with importance: high

    Agent->>M: cargo test
    M-->>Agent: 2 failures (was 500 lines, 99% saved)
```

## Built With

Rust (mycelium, hyphae, rhizome, spore) and TypeScript (cap). All Rust projects target edition 2024, use clippy pedantic linting, and follow anyhow/thiserror error handling conventions.
