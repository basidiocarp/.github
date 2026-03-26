# Basidiocarp

Tools that make AI coding agents better at their job. Memory that persists across sessions, token compression that cuts costs 60-90%, code intelligence across 32 languages, and feedback capture that turns mistakes into lessons.

Everything runs locally. No cloud services, no API keys for the core stack. SQLite all the way down.

## Install

On macOS and Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
```

The bootstrap script installs the stack, detects supported hosts, registers MCP servers, and wires up host-specific lifecycle integrations. Run `stipe doctor` to confirm everything landed.

Windows support is now a first-class goal across the Rust toolchain and dashboard surfaces. The one-command bootstrap path is still shell-first today, so use the per-project setup docs if you are bringing the stack up on Windows before the bootstrap script catches up.

## Projects

| Project | What it does |
|---------|-------------|
| [Mycelium](https://github.com/basidiocarp/mycelium) | CLI proxy. Rewrites command output before it reaches the agent. 70+ filters, 60-90% token savings. [Docs](https://github.com/basidiocarp/mycelium/tree/main/docs) |
| [Hyphae](https://github.com/basidiocarp/hyphae) | Agent memory. Episodic recall, knowledge graphs, RAG with hybrid search, training data export. 39 MCP tools. [Docs](https://github.com/basidiocarp/hyphae/tree/main/docs) |
| [Rhizome](https://github.com/basidiocarp/rhizome) | Code intelligence. Tree-sitter + LSP, symbol extraction, file editing, code graphs. 37 MCP tools, 32 languages. [Docs](https://github.com/basidiocarp/rhizome/tree/main/docs) |
| [Cap](https://github.com/basidiocarp/cap) | Web dashboard. Browse memories, view token analytics, inspect resolved config paths, and see why each path was chosen. [Docs](https://github.com/basidiocarp/cap/tree/main/docs) |
| [Spore](https://github.com/basidiocarp/spore) | Shared Rust library. Discovery, JSON-RPC, editor config registration, self-update, platform paths. |
| [Stipe](https://github.com/basidiocarp/stipe) | Ecosystem manager. Multi-host, platform-aware install, init, doctor, and update. |
| [Cortina](https://github.com/basidiocarp/cortina) | Adapter-first lifecycle runner. Captures errors, corrections, code changes, and session summaries in Rust. |
| [Lamella](https://github.com/basidiocarp/lamella) | Plugin system. 230 skills and 175 agents for Claude Code. [Docs](https://github.com/basidiocarp/lamella/blob/main/docs) |

## Guides

| Guide | Covers |
|-------|--------|
| [Ecosystem Architecture](docs/ECOSYSTEM-ARCHITECTURE.md) | Ownership boundaries, host adapters, platform paths, memory vs memoirs |
| [Integration](docs/INTEGRATION.md) | How the projects connect, protocols, failure modes |
| [AI Concepts](docs/AI-CONCEPTS.md) | RAG, DPO, fine-tuning, self-hosting, Bedrock comparison |
| [LLM Training](docs/LLM-TRAINING.md) | Data export, Axolotl, Together.ai, Ollama serving |
| [Training Data](https://github.com/basidiocarp/hyphae/blob/main/docs/TRAINING-DATA.md) | Formats, volume estimates, SQL export |

## Architecture

```mermaid
graph TD
    Agent["AI Coding Host"]
    Mycelium["Mycelium\nToken Compression"]
    Hyphae["Hyphae\nMemory + RAG"]
    Rhizome["Rhizome\nCode Intelligence"]
    Cap["Cap\nDashboard"]
    Cortina["Cortina\nHook Runner"]
    Stipe["Stipe\nEcosystem Manager"]
    Spore["Spore\nShared Infrastructure"]

    Agent -- "commands" --> Mycelium
    Mycelium -- "60-90% fewer tokens" --> Agent
    Agent -- "MCP (35 tools)" --> Hyphae
    Hyphae -- "memories, context, lessons" --> Agent
    Agent -- "MCP (37 tools)" --> Rhizome
    Rhizome -- "symbols, edits, analysis" --> Agent
    Cortina -- "hooks" --> Agent
    Cortina -- "errors, corrections, changes" --> Hyphae
    Rhizome -- "code graphs" --> Hyphae
    Mycelium -- "large outputs" --> Hyphae
    Cap -- "reads" --> Hyphae
    Cap -- "queries" --> Rhizome
    Stipe -. "installs + configures" .-> Mycelium
    Stipe -. "installs + configures" .-> Hyphae
    Stipe -. "installs + configures" .-> Rhizome
    Spore -. "shared lib" .-> Mycelium
    Spore -. "shared lib" .-> Rhizome
    Spore -. "shared lib" .-> Hyphae

    style Hyphae fill:#36b37e,stroke:#1f8a5a,color:#fff
    style Mycelium fill:#ff7452,stroke:#de350b,color:#fff
    style Rhizome fill:#6554c0,stroke:#403294,color:#fff
    style Cap fill:#4c9aff,stroke:#2571cc,color:#fff
    style Cortina fill:#00b8d9,stroke:#0095b3,color:#fff
    style Stipe fill:#97a0af,stroke:#6b778c,color:#fff
    style Spore fill:#ffab00,stroke:#ff8b00,color:#fff
    style Agent fill:#505f79,stroke:#344563,color:#fff
```

## How It Works

Hyphae stores two kinds of data in one SQLite database. Memories are episodic: they decay over time based on importance and access frequency. Memoirs are permanent knowledge graphs with typed relations between concepts. Search blends FTS5 full-text (30% weight) with cosine vector similarity (70%) using fastembed locally or any OpenAI-compatible endpoint.

`effective_decay = base_rate * importance_multiplier / (1 + access_count * 0.1)`

Critical memories never decay. Frequently accessed ones slow down. The decay runs automatically on every recall.

Rhizome parses code with tree-sitter (18 languages, 10 with dedicated queries) and fills gaps with LSP servers (32 languages, 20+ auto-installed). The `BackendSelector` picks the right backend per tool call: tree-sitter for symbol extraction, LSP for references and renames. It also exports code structure graphs into Hyphae memoirs so the agent can query "what calls this function?" from memory.

Mycelium sits between the agent and the shell. `git log -20` returns 5 lines instead of 200. `cargo test` with 500 passing tests returns only the 2 failures. Small outputs pass through untouched; medium ones get filtered; large ones get chunked into Hyphae for later retrieval. 70+ filters cover git, cargo, npm, docker, kubectl, and more.

Cortina now uses an adapter-first event model. Today the Claude Code adapter has the richest lifecycle coverage, but the core signal pipeline is no longer tied to one host envelope. On each event it checks for errors, self-corrections, and code changes. On session end, it writes a summary to Hyphae and exports the code graph to Rhizome. Over time, `extract_lessons` surfaces patterns from these signals, and `evaluate` measures whether the agent is getting better. The accumulated data exports as SFT/DPO pairs for fine-tuning via Ollama. See the [AI Concepts](docs/AI-CONCEPTS.md) and [Training](docs/LLM-TRAINING.md) guides.

## Platform Status

The core Rust services now centralize path resolution and host config handling instead of assuming one Unix shell layout:

- `stipe` owns host inventory, repair guidance, and platform-aware setup policy.
- `spore` owns shared editor detection and MCP config registration paths.
- `mycelium`, `hyphae`, and `rhizome` now resolve config, cache, and data paths through shared platform-aware layers.
- `cap` shows both the resolved path and the provenance for that path: config file, environment override, or platform default.

The shared Rust CI now runs on Linux, macOS, and Windows so portability regressions show up earlier.

```mermaid
flowchart LR
    Ingest["Ingest"] --> Chunk["Chunk"] --> Embed["Embed"] --> Store["Store"] --> Search["Search"] --> Inject["Inject"] --> Response["Response"]
    style Ingest fill:#36b37e,stroke:#1f8a5a,color:#fff
    style Search fill:#6554c0,stroke:#403294,color:#fff
```

## Session Flow

```mermaid
sequenceDiagram
    participant A as Agent
    participant C as Cortina
    participant M as Mycelium
    participant H as Hyphae
    participant R as Rhizome

    A->>H: initialize
    H-->>A: auto-recalled context
    A->>M: git log -20
    M-->>A: 5 lines (90% saved)
    A->>R: get_symbols + edit
    C->>H: track edits, capture errors
    A->>H: extract_lessons
    H-->>A: patterns from past mistakes
    A->>H: session_end
    C->>R: export code graph
```
