# Audit Lane 4: MCP Surface vs CLAUDE.md Drift

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only)
- **Allowed write scope:** `.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane4-mcp-surface-drift.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not modify any CLAUDE.md or any MCP server source; does not rename tools; does not regenerate tool registries
- **Verification contract:** `bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane4-mcp-surface-drift.sh`
- **Completion update:** when findings file is written and verification is green, parent updates campaign README + dashboard.

## Problem

`CLAUDE.md` files at the workspace root and per-repo tell Claude Code which `mcp__hyphae__*` and `mcp__rhizome__*` (and similar) MCP tools to invoke. As mycelium / hyphae / rhizome evolve their MCP surfaces, the instructions drift. Calls to renamed or removed tools fail at the MCP boundary, not at code-write time — a class of operator-loop drift the prior campaign did not check.

## Scope

For each MCP server in the ecosystem:
1. Enumerate the actual exposed tool list.
2. Find every reference to `mcp__<server>__<tool>` across CLAUDE.md files.
3. Diff and flag.

Servers to check:
- `mcp__hyphae__*` (hyphae)
- `mcp__rhizome__*` (rhizome)
- Other MCP servers if any are documented in the workspace (check before assuming the list is complete).

## Audit method

```bash
# 1. Find every CLAUDE.md
fd CLAUDE.md /Users/williamnewton/projects/personal/basidiocarp/

# 2. For each, grep mcp__ references
grep -rE 'mcp__[a-z]+__[a-zA-Z_]+' \
  /Users/williamnewton/projects/personal/basidiocarp/CLAUDE.md \
  /Users/williamnewton/projects/personal/basidiocarp/AGENTS.md \
  /Users/williamnewton/projects/personal/basidiocarp/*/CLAUDE.md \
  /Users/williamnewton/projects/personal/basidiocarp/*/AGENTS.md \
  2>/dev/null

# 3. For each MCP server, find the actual tool registration code
# hyphae:
grep -rE 'name:\s*"[a-z_]+"' hyphae/crates/hyphae-mcp/src/ 2>/dev/null | head -40
# rhizome:
grep -rE 'name:\s*"[a-z_]+"' rhizome/src/ 2>/dev/null | head -40

# 4. Cross-reference: for each tool referenced in CLAUDE.md, is it in the registration list?
#    For each tool in the registration list, is it referenced in any CLAUDE.md (or is it undocumented)?
```

The system-reminder injected at the start of every Claude Code session (in this conversation, the long list of `mcp__hyphae__*` and `mcp__rhizome__*` tools) is also a reference point — those names are what Claude Code currently sees as the MCP surface.

## Findings file format

Write `findings/lane4-mcp-surface-drift.md`:

- **Summary** — counts by severity.
- **Hyphae MCP Surface** — table: tool name, registered in hyphae-mcp (✓/✗), referenced in workspace CLAUDE.md (✓/✗), drift verdict.
- **Rhizome MCP Surface** — same table for rhizome.
- **Other MCP Surfaces** — if discovered.
- **Findings** — `[F4.N]` per drift, with severity (`blocker` for CLAUDE.md referencing a removed/renamed tool; `concern` for undocumented new tools; `nit` for minor description drift), location, evidence, proposed fix-phase title.
- **Clean Areas** — surfaces that align cleanly.

## Style Notes

- A tool referenced in CLAUDE.md but not registered = `blocker` (Claude Code will fail when it tries to call).
- A tool registered but not referenced anywhere in CLAUDE.md = `concern` (undocumented; Claude Code may not know to use it).
- Description drift (CLAUDE.md says tool does X; tool actually does Y) = `nit` unless it would mislead operator workflow.
- Deprecation aliases (registered with the old name but documented under the new) — flag as `concern`, not blocker.

## Completion Protocol

1. Hyphae and rhizome MCP surfaces both audited.
2. Findings file written.
3. Verify script exits 0.

```bash
bash .handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/verify-lane4-mcp-surface-drift.sh
```

**Required result:** `Results: N passed, 0 failed`.
