# Basidiocarp

Infrastructure for AI coding agents. Named after the fungal fruiting body — the visible structure that emerges from an underground mycelial network.

## Projects

### [Mycelium](https://github.com/basidiocarp/mycelium)
Token-optimized CLI proxy. Intercepts command output and compresses it before it reaches the LLM, cutting token usage by 60-90% on common dev operations (git, cargo, gh, docker, npm). Single Rust binary, integrates with Claude Code via hooks.

### [Hyphae](https://github.com/basidiocarp/hyphae)
Persistent memory for AI agents. Two complementary models: **episodic memories** (temporal, decay-based, topic-organized) and **semantic memoirs** (permanent knowledge graphs with typed concept relations). MCP server with 18 tools + CLI with 29 commands. Rust, SQLite, FTS5, sqlite-vec.

### [Rhizome](https://github.com/basidiocarp/rhizome)
Code intelligence MCP server. Gives agents symbol-level navigation — definitions, references, structure — instead of reading raw files. Dual backend: tree-sitter for instant offline parsing, LSP for cross-file intelligence when a language server is available. 9 languages, 12 tools. Rust.

### [Cap](https://github.com/basidiocarp/cap)
Web dashboard for the ecosystem. Browse and search agent memories, explore knowledge graphs, view token savings analytics. React, Mantine, Hono, Vite.

## How They Connect

```mermaid
graph TD
    Cap["<b>Cap</b><br/>Web Dashboard<br/><i>React + Hono</i>"]
    Hyphae["<b>Hyphae</b><br/>Agent Memory<br/><i>SQLite + FTS5 + sqlite-vec</i>"]
    Mycelium["<b>Mycelium</b><br/>Token Savings<br/><i>SQLite</i>"]
    Rhizome["<b>Rhizome</b><br/>Code Intelligence<br/><i>Tree-sitter + LSP</i>"]
    Agent["AI Coding Agent"]

    Agent -- "commands" --> Mycelium
    Mycelium -- "filtered output<br/>60-90% fewer tokens" --> Agent
    Agent -- "MCP tools" --> Hyphae
    Hyphae -- "memories &<br/>knowledge graphs" --> Agent
    Agent -- "MCP tools" --> Rhizome
    Rhizome -- "symbols, refs,<br/>definitions" --> Agent
    Cap -- "reads" --> Hyphae
    Cap -- "reads" --> Mycelium
    Rhizome -. "future:<br/>code symbols → memoirs" .-> Hyphae

    style Cap fill:#4c9aff,stroke:#2571cc,color:#fff
    style Hyphae fill:#36b37e,stroke:#1f8a5a,color:#fff
    style Mycelium fill:#ff7452,stroke:#de350b,color:#fff
    style Rhizome fill:#6554c0,stroke:#403294,color:#fff
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
    H-->>Agent: 3 relevant memories

    Agent->>R: get_symbols src/auth.rs
    R-->>Agent: structs, fns, impls (no file reading needed)

    Agent->>R: find_references AuthMiddleware
    R-->>Agent: 4 locations across project

    Agent->>H: store memory about refactor
    H-->>Agent: stored with importance: high

    Agent->>M: cargo test
    M-->>Agent: 2 failures (was 500 lines, 99% saved)
```

## Built With

Rust (mycelium, hyphae, rhizome) and TypeScript (cap). All Rust projects target edition 2024, use clippy pedantic linting, and follow anyhow/thiserror error handling conventions.
