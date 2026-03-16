# Basidiocarp Ecosystem Plans

Ecosystem-level plans that span multiple repositories. Project-specific plans live in each repo's `.plans/` directory.

## Plans in This Repo

| Plan | Description | Status |
|------|-------------|--------|
| [unified-installer.md](unified-installer.md) | Single install command + CI/CD for all repos | Not started |
| [shared-ipc.md](shared-ipc.md) | Shared Rust crate for tool discovery and IPC | Not started |

## Plans by Repository

### [mycelium](https://github.com/basidiocarp/mycelium)
| Plan | Description |
|------|-------------|
| `hyphae-integration` | Large outputs chunked into Hyphae instead of destructive filtering |
| `rhizome-integration` | `mycelium read` delegates to Rhizome for code files |

### [hyphae](https://github.com/basidiocarp/hyphae)
| Plan | Description |
|------|-------------|
| `mycelium-chunking` | Hyphae-side: chunker strategy, ephemeral storage, new MCP tools |
| `rhizome-symbol-import` | Receive code symbol graphs from Rhizome as memoirs |
| `context-aware-recall` | Use Rhizome code context to enhance memory recall |

### [rhizome](https://github.com/basidiocarp/rhizome)
| Plan | Description |
|------|-------------|
| `initial-build` | Core types, tree-sitter, LSP, MCP server, CLI (Phases 1-2 done) |
| `hyphae-memoir-export` | Export extracted code symbols to Hyphae as knowledge graphs |

### [cap](https://github.com/basidiocarp/cap)
| Plan | Description |
|------|-------------|
| `rhizome-integration` | Code Explorer, Symbol Search, Diagnostics, Status pages |
| `cross-tool-analytics` | Unified analytics across all ecosystem tools |

## Dependency Chain

```
1. Finish Rhizome MCP + CLI          (rhizome/initial-build)
      │
      ├──► Mycelium → Rhizome        (mycelium/rhizome-integration)
      ├──► Cap ← Rhizome pages       (cap/rhizome-integration)
      └──► Rhizome → Hyphae export   (rhizome/hyphae-memoir-export)
               │
2. Hyphae chunking infra             (hyphae/mycelium-chunking)
      │        │
      ▼        ▼
3. Mycelium → Hyphae chunks          (mycelium/hyphae-integration)
               │
4. Hyphae ← Rhizome import           (hyphae/rhizome-symbol-import)
      │
      ▼
5. Context-aware recall               (hyphae/context-aware-recall)
      │
6. Cross-tool analytics               (cap/cross-tool-analytics)
      │
7. Shared IPC crate                   (.github/shared-ipc)
      │
8. Unified installer + CI             (.github/unified-installer)
```