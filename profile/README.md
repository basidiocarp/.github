# Basidiocarp

Tools that make AI coding agents better at their job. Memory that persists across sessions, token compression that cuts costs 60-90%, code intelligence across 32 languages, and feedback capture that turns mistakes into lessons.

Everything runs locally. No cloud services, no API keys for the core stack. SQLite all the way down.

## Install

On macOS and Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
```

On Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/basidiocarp/.github/main/install.ps1 | iex
```

The bootstrap scripts install the default local runtime set, then hand host setup to `stipe`. Today that means `stipe`, `mycelium`, `hyphae`, `rhizome`, and `cortina`. `canopy` is optional, `cap` is a separate dashboard surface, `lamella` is the packaging layer, and `spore` is a shared library. Run `stipe doctor` to confirm everything landed.

Both scripts install into a local user bin directory by default:

- macOS and Linux: `~/.local/bin`
- Windows: `%LOCALAPPDATA%\Basidiocarp\bin`

## First Run

```bash
stipe init
stipe doctor
```

Use [Operator Quickstart](../docs/OPERATOR-QUICKSTART.md) for the task-oriented path after the binaries land.

## Projects

| Project | What it does |
|---------|-------------|
| [Mycelium](https://github.com/basidiocarp/mycelium) | CLI proxy. Rewrites command output before it reaches the agent. 70+ filters, 60-90% token savings. [Docs](https://github.com/basidiocarp/mycelium/tree/main/docs) |
| [Hyphae](https://github.com/basidiocarp/hyphae) | Agent memory. Episodic recall, knowledge graphs, RAG with hybrid search, training data export, and MCP tool workflows. [Docs](https://github.com/basidiocarp/hyphae/tree/main/docs) |
| [Rhizome](https://github.com/basidiocarp/rhizome) | Code intelligence. Tree-sitter + LSP, symbol extraction, file editing, code graphs. 37 MCP tools, 32 languages. [Docs](https://github.com/basidiocarp/rhizome/tree/main/docs) |
| [Cap](https://github.com/basidiocarp/cap) | Web dashboard. Browse memories, view token analytics, inspect resolved config paths, and see why each path was chosen. [Docs](https://github.com/basidiocarp/cap/tree/main/docs) |
| [Spore](https://github.com/basidiocarp/spore) | Shared Rust library. Discovery, JSON-RPC, editor config registration, self-update, platform paths. |
| [Stipe](https://github.com/basidiocarp/stipe) | Ecosystem manager. Multi-host, platform-aware install, init, doctor, and update. |
| [Cortina](https://github.com/basidiocarp/cortina) | Adapter-first lifecycle runner. Captures errors, corrections, code changes, and session summaries in Rust. |
| [Canopy](https://github.com/basidiocarp/canopy) | Coordination runtime. Tracks active agents, task ownership, handoffs, and operator attention for multi-agent work. |
| [Lamella](https://github.com/basidiocarp/lamella) | Plugin system. 230 skills and 175 agents for Claude Code. [Docs](https://github.com/basidiocarp/lamella/blob/main/docs) |

## Guides

| Guide | Covers |
|-------|--------|
| [Docs Index](../docs/README.md) | Entry point for the full docs set |
| [Operator Quickstart](../docs/OPERATOR-QUICKSTART.md) | Install, init, doctor, and the first commands to run |
| [Troubleshooting](../docs/TROUBLESHOOTING.md) | Common failures, recovery commands, and doctor routing |
| [Tool Selection](../docs/TOOL-SELECTION.md) | Which tool owns which operator task |
| [Data and State Locations](../docs/STATE-LOCATIONS.md) | What state each tool owns and how to inspect active paths |
| [Cap](../docs/CAP.md) | When to use the dashboard versus CLI tools |
| [Canopy](../docs/CANOPY.md) | When coordination runtime matters and when it does not |
| [Release and Install Matrix](../docs/RELEASE-AND-INSTALL-MATRIX.md) | Platform and delivery-mode summary |
| [What Gets Installed](../docs/INSTALL-SCOPE.md) | Default bootstrap binaries, optional tools, source-only surfaces |
| [Host Support](../docs/HOST-SUPPORT.md) | First-class host modes, shared MCP clients, setup expectations |
| [Ecosystem Architecture](../docs/ECOSYSTEM-ARCHITECTURE.md) | Ownership boundaries, host adapters, platform paths, memory vs memoirs |
| [Integration](../docs/INTEGRATION.md) | How the projects connect, protocols, failure modes |
| [AI Concepts](../docs/AI-CONCEPTS.md) | RAG, DPO, fine-tuning, self-hosting, Bedrock comparison |
| [LLM Training](../docs/LLM-TRAINING.md) | Data export, Axolotl, Together.ai, Ollama serving |
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
    Canopy["Canopy\nCoordination Runtime"]
    Stipe["Stipe\nEcosystem Manager"]
    Spore["Spore\nShared Infrastructure"]

    Agent -- "commands" --> Mycelium
    Mycelium -- "60-90% fewer tokens" --> Agent
    Agent -- "MCP tools" --> Hyphae
    Hyphae -- "memories, context, lessons" --> Agent
    Agent -- "MCP (37 tools)" --> Rhizome
    Rhizome -- "symbols, edits, analysis" --> Agent
    Cortina -- "hooks" --> Agent
    Cortina -- "errors, corrections, changes" --> Hyphae
    Rhizome -- "code graphs" --> Hyphae
    Mycelium -- "large outputs" --> Hyphae
    Cap -- "reads" --> Hyphae
    Cap -- "queries" --> Rhizome
    Cap -- "operator view" --> Canopy
    Canopy -- "evidence refs" --> Hyphae
    Canopy -- "runtime links" --> Cortina
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
    style Canopy fill:#8777d9,stroke:#5e4db2,color:#fff
    style Stipe fill:#97a0af,stroke:#6b778c,color:#fff
    style Spore fill:#ffab00,stroke:#ff8b00,color:#fff
    style Agent fill:#505f79,stroke:#344563,color:#fff
```

## Install and Runtime Surfaces

```mermaid
flowchart TD
    Bootstrap["Bootstrap install"] --> Default["stipe\nmycelium\nhyphae\nrhizome\ncortina"]
    Default --> Init["stipe init"]
    Init --> Hosts["Host integrations"]
    Optional["Optional runtime"] --> Canopy["canopy"]
    Source["Run separately"] --> Cap["cap"]
    Packaging["Packaging layer"] --> Lamella["lamella"]
    Shared["Shared library"] --> Spore["spore"]
```

## How It Works

Hyphae stores two kinds of data in one SQLite database. Memories are episodic: they decay over time based on importance and access frequency. Memoirs are permanent knowledge graphs with typed relations between concepts. Search blends FTS5 full-text (30% weight) with cosine vector similarity (70%) using fastembed locally or any OpenAI-compatible endpoint.

`effective_decay = base_rate * importance_multiplier / (1 + access_count * 0.1)`

Critical memories never decay. Frequently accessed ones slow down. The decay runs automatically on every recall.

Rhizome parses code with tree-sitter (18 languages, 10 with dedicated queries) and fills gaps with LSP servers (32 languages, 20+ auto-installed). The `BackendSelector` picks the right backend per tool call: tree-sitter for symbol extraction, LSP for references and renames. It also exports code structure graphs into Hyphae memoirs so the agent can query "what calls this function?" from memory.

Mycelium sits between the agent and the shell. `git log -20` returns 5 lines instead of 200. `cargo test` with 500 passing tests returns only the 2 failures. Small outputs pass through untouched; medium ones get filtered; large ones get chunked into Hyphae for later retrieval. 70+ filters cover git, cargo, npm, docker, kubectl, and more.

Cortina now uses an adapter-first event model. Today the Claude Code adapter has the richest lifecycle coverage, but the core signal pipeline is no longer tied to one host envelope. On each event it checks for errors, self-corrections, and code changes. On session end, it writes structured feedback into Hyphae and exports the code graph to Rhizome. Over time, `extract_lessons` surfaces patterns from these signals, and `evaluate` measures whether the agent is getting better. The accumulated data exports as SFT/DPO pairs for fine-tuning via `hyphae export-training`. See the [AI Concepts](../docs/AI-CONCEPTS.md) and [Training](../docs/LLM-TRAINING.md) guides.

Canopy is the optional coordination runtime. It is not part of the default bootstrap install, but it becomes the place to track active agents, task ownership, handoffs, and operator attention when you need multi-agent runtime state instead of just memory or lifecycle capture.

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
    participant P as Cap

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
    P->>H: read status and memory
```
