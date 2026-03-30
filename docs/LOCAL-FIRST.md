# Local-First Architecture

Everything runs on your machine. SQLite databases, fastembed for local embeddings, local binaries for the core runtime, and no cloud accounts needed for the default stack. Your code never leaves your network.

## What This Means in Practice

Memory data stays in the active local Hyphae database. Embeddings compute locally using fastembed (384 dimensions). Cortina captures lifecycle signals without uploading anything. Cap's dashboard runs locally and reads the database directly. No telemetry. No analytics. No usage tracking.

You own the data. You control the backup strategy. You decide what gets remembered and what gets forgotten.

The only external dependency is optional: you can point embeddings at Ollama or OpenAI-compatible endpoints if you want. But the defaults work entirely offline.

Not every Basidiocarp project is a bootstrap-installed binary. The default local runtime is `stipe`, `mycelium`, `hyphae`, `rhizome`, and `cortina`. `canopy` is optional, `cap` is a separate dashboard surface, `lamella` is packaging, and `spore` is shared library code. See [What Gets Installed](./INSTALL-SCOPE.md).

## Trade-offs with Cloud Alternatives

| Aspect | Basidiocarp | Mem0 | LangChain Memory | Cursor's Memory |
|--------|-------------|------|------------------|-----------------|
| Data location | Your machine | Cloud servers | Pinecone/Weaviate (cloud) | Cursor's servers |
| Setup required | `stipe init` | API key + account | Framework + vector DB | Cursor editor |
| Sharing memories | Export/import | Team API | Deploy shared DB | Proprietary tie-in |
| Editor lock-in | Works across multiple local hosts and MCP clients | Cursor or API | Framework-specific | Cursor only |
| Embedding dimensions | 384 (fastembed) | 1536 (ada-002) | Varies | Proprietary |
| Costs | Your infra only | $0-50/month + API | Your vector DB + compute | Cursor license |
| Offline mode | Full stack | No | No | No |

Mem0 has better embedding quality and team collaboration. LangChain Memory is flexible and mature. Cursor's memory integrates seamlessly with the editor. Basidiocarp trades those conveniences for ownership and portability.

## Local Limitations

SQLite runs on one machine. Your memories live where your database file lives. There's no built-in team sharing—you export memories as JSON and import them elsewhere. There's no cross-machine sync; move to a new laptop and your history stays behind unless you copy the database.

Local embeddings (384 dims) are smaller than cloud models (OpenAI ada-002 at 1536 dims), which means some nuance gets compressed. Search still works well for concrete facts and code patterns, but subtle semantic relationships may fall through. Hybrid search (30% full-text + 70% vector) helps, but it's not a substitute for larger embedding space.

Backups are your responsibility. SQLite is resilient, but a corrupted database is a corrupted database. No redundancy. No managed recovery.

The `access_count` in decay math means frequently accessed memories survive longer, which is usually what you want. But it also means a memory you stopped consulting gets dropped automatically. Critical memories never decay, but you have to mark them manually.

## The Escape Hatches

Point Hyphae's embedder at Ollama for larger local models (Nomic Embed Text is 768 dims, runs locally, free). Or use OpenAI-compatible endpoints. You get better search quality without moving your data to the cloud.

`hyphae export` writes memories as JSON; `hyphae import` reads them back. Share a file with a colleague and they pull those memories into their database. Not instant, not real-time, but portable.

Cap's dashboard runs locally but can be exposed to a network if you own the infrastructure. Run it behind a reverse proxy and access from another machine on your LAN. Hyphae stays local; Cap just reads it.

The architecture doesn't lock you in. You can move to a cloud memory system later if local stops making sense. Export your data, migrate, and keep going.

## Host Coverage

Local-first does not mean single-host.

Today the strongest managed paths are:

- Claude Code
- Codex CLI
- Cursor

Shared MCP coverage also exists for clients such as Windsurf, Claude Desktop, Continue, Cline, Gemini CLI, and Copilot CLI. See [Host Support](./HOST-SUPPORT.md).
