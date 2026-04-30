# Cross-Project: Workspace CLAUDE.md MCP Tool Coverage (F4.3 + F4.4)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (and per-repo CLAUDE.md files)
- **Allowed write scope:** `CLAUDE.md` (workspace root), `hyphae/CLAUDE.md`, `rhizome/CLAUDE.md` (description corrections / count fixes)
- **Cross-repo edits:** documentation only across hyphae and rhizome
- **Non-goals:** does not modify any MCP server's tool registrations; does not add new tools; does not change tool behavior
- **Verification contract:** `bash .handoffs/cross-project/verify-workspace-claude-md-mcp-tool-coverage.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem (F4.3 + F4.4, concerns)

Lane 4 of the 2026-04-30 audit found:
- Workspace `CLAUDE.md`'s "Tool Selection Guide" names only **2 of 40 hyphae tools** and **3 of 40 rhizome tools**. The remaining 75 MCP tools are entirely invisible to Claude Code agents reading the doc.
- Per-repo `hyphae/CLAUDE.md` claims "37 default tools" — actual count is 40 (off by 3).
- Per-repo `rhizome/CLAUDE.md` claims "38 tools" — actual count is 40 (off by 2; omits `rhizome_simulate_change` and miscounts the read/edit buckets).
- Per-repo `CLAUDE.md` files don't list their own MCP surface in callable `mcp__*` form, so an agent reading the per-repo guide can't discover the calls.

## Scope

Three coupled doc updates:

### 1. Workspace `CLAUDE.md` Tool Selection Guide (F4.3 + F4.4)

Expand the existing "Tool Selection Guide" section with grouped, callable lists for hyphae and rhizome. Don't enumerate every tool individually — group by purpose (memory recall vs. memoir graph vs. session management for hyphae; structural read vs. structural edit vs. export for rhizome). Each group names the canonical `mcp__<server>__<tool>` calls and a one-line "use this when…" anchor.

Reference the lane 4 findings file (`.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane4-mcp-surface-drift.md`) for the full registered tool list.

### 2. Per-repo count refresh

- `hyphae/CLAUDE.md`: change "37 default tools" → "40 tools (default; +1 conditional `hyphae_memory_embed_all` when an embedder is configured)".
- `rhizome/CLAUDE.md`: change "38 tools" → "40 tools" and add `rhizome_simulate_change` to whatever bucket-listing the doc has.

### 3. Per-repo MCP surface listing

In `hyphae/CLAUDE.md` and `rhizome/CLAUDE.md`, add a short "MCP Tools" section that lists the `mcp__<server>__<tool>` callable names grouped by purpose. Match the workspace-root structure so the two views stay consistent.

## Step 1 — Capture the registered set

```bash
# Hyphae (find the actual registration file/loop)
grep -rEn 'name:\s*"[a-z_]+"' hyphae/crates/hyphae-mcp/src/ 2>/dev/null | head -50

# Rhizome
grep -rEn 'name:\s*"[a-z_]+"|register_tool\("[a-z_]+"' rhizome/src/ 2>/dev/null | head -50
```

Cross-reference with the lane 4 findings file to confirm the canonical 40+40 list.

## Step 2 — Expand workspace CLAUDE.md

In `/Users/williamnewton/projects/personal/basidiocarp/CLAUDE.md`'s "Tool Selection Guide" section:

- Under "Rhizome (code navigation)": list `mcp__rhizome__search_symbols`, `mcp__rhizome__find_references`, `mcp__rhizome__analyze_impact`, `mcp__rhizome__get_definition`, `mcp__rhizome__get_structure`, `mcp__rhizome__summarize_file`, `mcp__rhizome__rhizome_simulate_change`, plus the structural-edit family (`mcp__rhizome__rename_symbol`, `mcp__rhizome__move_symbol`, etc.) and export (`mcp__rhizome__export_repo_understanding`, `mcp__rhizome__export_to_hyphae`).
- Under "Hyphae (memory and recall)": list the memory family (`mcp__hyphae__hyphae_memory_recall`, `_store`, `_consolidate`, `_invalidate`, `_health`, `_stats`), the memoir graph (`_memoir_create`, `_add_concept`, `_link`, `_refine`, `_search`, `_inspect`, `_show`), session management (`_session_start`, `_end`, `_context`), the recall_global, extract_lessons, artifact_query/store, gather_context, onboard, and ingest_file utilities.

Keep the language operational ("call X when Y") rather than encyclopedic.

## Step 3 — Update per-repo CLAUDE.md files

Hyphae:
- Replace any literal count (e.g. "37 default tools") with "40 tools (default; +1 conditional `hyphae_memory_embed_all`)".
- Add an "MCP Tools" section listing the callable names grouped by purpose, mirroring the workspace doc.

Rhizome:
- Replace "38 tools" with "40 tools".
- Add `rhizome_simulate_change` to the bucket list (likely under "structural reads" or a new "what-if" group).
- Add an "MCP Tools" section listing callable names grouped by purpose.

## Style Notes

- Don't enumerate every tool individually if the group has many — group by purpose with examples.
- Keep the workspace doc and per-repo doc consistent; don't duplicate the entire registered list.
- Don't add tools to the doc that aren't actually registered.
- If a tool is conditional (e.g. `hyphae_memory_embed_all`), mark it as such.

## Verify Script

`bash .handoffs/cross-project/verify-workspace-claude-md-mcp-tool-coverage.sh` confirms:
- Workspace CLAUDE.md references at least 8 hyphae mcp tools and 8 rhizome mcp tools (up from 2 and 3)
- hyphae/CLAUDE.md no longer claims "37 tools"
- rhizome/CLAUDE.md no longer claims "38 tools"
- Per-repo CLAUDE.md files contain at least one `mcp__hyphae__` or `mcp__rhizome__` reference respectively

## Context

Closes lane 4 concerns F4.3 and F4.4 from the 2026-04-30 audit. Doc-only fix; no source changes.
