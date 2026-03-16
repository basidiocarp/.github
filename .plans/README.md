# Basidiocarp Ecosystem Plans

Ecosystem-level plans that span multiple repositories. Project-specific plans live in each repo's `.plans/` directory.

## Plans in This Repo

| Plan | Description | Status |
|------|-------------|--------|
| [unified-installer.md](unified-installer.md) | Single install command + CI/CD for all repos | Complete |
| [shared-ipc.md](shared-ipc.md) | Spore: shared Rust crate for tool discovery and IPC | Complete |

## Plans by Repository

### [mycelium](https://github.com/basidiocarp/mycelium)
| Plan | Description | Status |
|------|-------------|--------|
| `hyphae-integration` | Large outputs chunked into Hyphae instead of destructive filtering | Complete |
| `rhizome-integration` | `mycelium read` delegates to Rhizome for code files | Complete |

### [hyphae](https://github.com/basidiocarp/hyphae)
| Plan | Description | Status |
|------|-------------|--------|
| `mycelium-chunking` | Hyphae-side: chunker strategy, ephemeral storage, new MCP tools | Complete |
| `rhizome-symbol-import` | Receive code symbol graphs from Rhizome as memoirs | Complete |
| `context-aware-recall` | Use Rhizome code context to enhance memory recall | Complete |

### [rhizome](https://github.com/basidiocarp/rhizome) — 26 tools, 32 languages
| Plan | Description | Status |
|------|-------------|--------|
| `initial-build` | Core types, tree-sitter, LSP, MCP server, CLI | Complete (exceeded: 26 tools, 32 languages, auto-install, backend selector) |
| `hyphae-memoir-export` | Export code symbols to Hyphae as knowledge graphs | Complete |

### [cap](https://github.com/basidiocarp/cap) — 8 pages, 15+ endpoints
| Plan | Description | Status |
|------|-------------|--------|
| `rhizome-integration` | Code Explorer, Symbol Search, Diagnostics, Status pages | Complete |
| `cross-tool-analytics` | Unified analytics across all ecosystem tools | Backend complete, frontend not started |

### [spore](https://github.com/basidiocarp/spore) — 16 tests
Shared IPC crate. Plan tracked in [shared-ipc.md](shared-ipc.md). Complete.

### [lamella](https://github.com/basidiocarp/lamella) — 230 skills, 20 plugins
Plugin system. All cleanup phases complete. Hooks fixed and wired.

## Remaining Work

See `claude-mycelium/.plans/remaining-items.md` for the consolidated list of remaining items:
- 5 quick wins (clippy, dead code, config tests, spore detect_project, hyphae prune)
- 4 medium items (Cap analytics dashboard, call graph viz, cache invalidation)
- 2 larger items (Cap settings page, E2E integration test suite)

## Completed Dependency Chain

All items in the original dependency chain are complete:

```
1. ✅ Rhizome MCP + CLI              (26 tools, 32 languages, auto-install)
      │
      ├──► ✅ Mycelium → Rhizome     (read command delegates to rhizome)
      ├──► ✅ Cap ← Rhizome pages    (8 pages, 15+ endpoints, annotations + complexity)
      └──► ✅ Rhizome → Hyphae       (code graph export, incremental caching)
               │
2. ✅ Hyphae chunking infra          (ByStructuredOutput, ephemeral TTL, pagination)
      │        │
      ▼        ▼
3. ✅ Mycelium → Hyphae chunks       (route_or_filter in 6 handlers)
               │
4. ✅ Hyphae ← Rhizome import        (upsert_concepts, code_query tool)
      │
      ▼
5. ✅ Context-aware recall            (FTS expansion with code memoirs)
      │
6. ⬜ Cross-tool analytics frontend   (backend done, UI not started)
      │
7. ✅ Spore adopted                   (mycelium + rhizome)
      │
8. ✅ Installer + CI                  (install.sh, shared workflows, release workflows)
```
