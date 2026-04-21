# Session Handoff — 2026-03-21

## Ecosystem State

8 projects, all released and tagged:

| Project | Version | Purpose |
|---------|---------|---------|
| mycelium | v0.4.3 | Token compression (70+ filters, 60-90% savings) |
| hyphae | v0.6.1 | Persistent memory + RAG (39 MCP tools, vector DB, knowledge graphs) |
| rhizome | v0.5.2 | Code intelligence (37 MCP tools, 18 tree-sitter languages, 32 LSP) |
| cap | v0.6.0 | Web dashboard (11 pages, 60+ API endpoints) |
| spore | v0.2.1 | Shared IPC library (discovery, JSON-RPC, subprocess MCP) |
| lamella | — | Claude Code plugins (hooks, skills — being superseded by cortina) |
| stipe | v0.1.0 | Ecosystem installer/manager (install, init, doctor, update) — NEW |
| cortina | v0.1.0 | Hook runner replacing JS scripts (pre/post/stop hooks) — NEW |

## What Was Built This Session

### Major features
- Cap: config editor, LSP manager, project switcher, 9 new pages (sessions, lessons, cross-project search, memory actions, hook monitor, command history, telemetry)
- Hyphae: memory automation (auto-recall, escalating nudge, consolidation triggers, extract_lessons, promote_to_memoir), training data export, backup/restore, evaluation framework, secrets scanning, purge commands, changelog
- Rhizome: generic tree-sitter fallback (8 languages), 7 new query patterns, LSP CLI commands, path traversal prevention
- Mycelium: capture hook installation via init --ecosystem, find passthrough, test runner truncation fixes
- Spore: line-delimited framing, Cap in Tool enum, McpClient timeout
- Stipe: full ecosystem manager (install from GitHub releases, init, doctor, update)
- Cortina: full hook runner (command rewriting, error/correction/change capture, session summary)

### Documentation
- Org: AI Concepts guide (Bedrock comparison, RAG vs supervised vs unsupervised, DPO, self-hosting), LLM Training guide, Integration guide
- Per-project: INTERNALS.md (all 5 original repos), GETTING-STARTED (Cap), API reference (Cap), LANGUAGE-SETUP + CONFIG + TROUBLESHOOTING (Rhizome), ECOSYSTEM-SETUP + UPDATE + UNINSTALL (Mycelium), TRAINING-DATA (Hyphae), FEEDBACK-CAPTURE (Lamella)

## Remaining Plan Items

File: `.plans/future-improvements.md`

### Done (this session)
- Now items 1-3 (embedder cache, spore alignment, sessions schema)
- Soon items 4-14 (FTS5, search optimization, parse cache, timeout, relations, secrets, purge, changelog, docs)
- Cortina + Stipe bootstrapped and implemented

### Still open
- Later items 17-29 (pagination, tracking.db retention, scaffold-filter, contributor guide, Cap onboarding wizard, CI/CD reporting, auto-consolidation, team export/import, project focus, rusqlite alignment, crates.io publish, Cap launcher/Tauri, memory graph viz)
- Maybe items 28-30 (VS Code extension, Jupyter support, git-backed sync)
- Recall-to-action feedback loop (item 15, moved to Soon)
- Branded installer domain (item 16, moved to Soon)

### Next logical steps
1. Slim down mycelium — move ecosystem management code to stipe, hook code to cortina
2. Update org profile/docs to include stipe and cortina
3. Test the full stipe install → init → cortina hooks flow end-to-end
4. Implement recall-to-action feedback loop in hyphae

## Known Issues
- Cap vitest tests show 7 failures (TypeScript test issues, not Cap bugs)
- Hyphae http_embedder test is env-dependent (fails when HYPHAE_EMBEDDING_URL is set)
- Lamella will eventually be deprecated in favor of cortina for hooks
