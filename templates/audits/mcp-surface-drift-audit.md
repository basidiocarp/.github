# MCP Surface Drift Audit Template

Validates that `mcp__<server>__<tool>` references in `CLAUDE.md` and `AGENTS.md` files match the actual MCP tool registrations in each MCP server (hyphae, rhizome, etc.).

**Cadence:** quarterly, or after any MCP server tool-set change.
**Maps to:** operator-loop reliability under F1.
**Runtime:** ~30 minutes per MCP server.

---

## Handoff Metadata (instance)

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only)
- **Allowed write scope:** `.handoffs/campaigns/<campaign-name>/findings/lane<N>-mcp-surface-drift.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not modify any CLAUDE.md / AGENTS.md / MCP server source; does not rename tools

## Method

### Step 1 — Find every workspace doc that names MCP tools

```bash
fd '(CLAUDE|AGENTS)\.md$' /Users/williamnewton/projects/personal/basidiocarp/
grep -rE 'mcp__[a-z]+__[a-zA-Z_]+' \
  /Users/williamnewton/projects/personal/basidiocarp/CLAUDE.md \
  /Users/williamnewton/projects/personal/basidiocarp/AGENTS.md \
  /Users/williamnewton/projects/personal/basidiocarp/*/CLAUDE.md \
  /Users/williamnewton/projects/personal/basidiocarp/*/AGENTS.md \
  2>/dev/null | sort -u
```

Collect the **documented set** as a deduplicated list of `mcp__<server>__<tool>` strings.

### Step 2 — Find each MCP server's actual tool registration

For Rust-based MCP servers (hyphae, rhizome typically):

```bash
# hyphae
grep -rEh 'name:\s*"[a-z_]+"' hyphae/crates/hyphae-mcp/src/ 2>/dev/null

# rhizome
grep -rEh 'name:\s*"[a-z_]+"|register_tool\("[a-z_]+"' rhizome/src/ 2>/dev/null

# Search for the canonical pattern across all repos in case other MCP servers exist
grep -rE 'McpServer|register_tool|tool!' \
  hyphae/ rhizome/ mycelium/ canopy/ stipe/ \
  --include='*.rs' 2>/dev/null | head -40
```

Collect the **registered set** per server.

### Step 3 — Diff the documented and registered sets

For each server:
- Tools documented but not registered → `blocker` (Claude Code will fail when it tries to call).
- Tools registered but not documented → `concern` (undocumented; Claude Code may not know to use it).
- Description in CLAUDE.md doesn't match tool's actual purpose → `nit` (unless misleading enough to harm operator workflow, then `concern`).

### Reference data

The system-reminder injected at the start of every Claude Code session lists the live MCP tool surface as the harness sees it. That list is authoritative when the registration code is hard to find directly — capture it as the "registered set" and proceed with the diff.

## Findings File Format

Write `findings/lane<N>-mcp-surface-drift.md`:

```markdown
# Lane N: MCP Surface vs CLAUDE.md Drift Findings (YYYY-MM-DD)

## Summary
[counts by severity]

## Hyphae MCP Surface
| Tool | Registered (hyphae-mcp) | Referenced (CLAUDE.md/AGENTS.md) | Verdict |
|------|--------------------------|-----------------------------------|---------|
| ... | ✓ / ✗ | ✓ / ✗ | match / drift / undocumented / phantom |

## Rhizome MCP Surface
[same shape]

## Other MCP Surfaces
[only if discovered]

## Findings

### [F#.M] Title — severity: blocker|concern|nit
- **Server:** hyphae | rhizome | other
- **Tool:** mcp__<server>__<tool>
- **Drift:** [phantom (in docs, not registered) | undocumented (registered, not in docs) | description-mismatch]
- **Where referenced:** path:line in CLAUDE.md or AGENTS.md
- **Where registered:** path:line in MCP server source
- **Why it matters:** [agent will fail / operator won't discover / misleading]
- **Proposed handoff:** "[handoff title]"

## Clean Areas
[surfaces that align cleanly]
```

## Severity Calibration

- `blocker` — `mcp__<server>__<tool>` referenced in CLAUDE.md but not registered (Claude Code call fails at the MCP boundary).
- `concern` — registered but not documented (operator won't know to invoke it); description drift that would mislead workflow.
- `nit` — description drift that's purely cosmetic.

## Verify Script

Pair with `verify-lane<N>-mcp-surface-drift.sh`. Confirms:
- Findings file exists with required sections (Summary, Hyphae MCP Surface, Rhizome MCP Surface, Findings, Clean Areas)
- Findings reference at least one `mcp__*` tool
- Hyphae and Rhizome surface tables have rows
- No CLAUDE.md or AGENTS.md modified

## Style Notes

- Don't propose new tools. The audit is about alignment, not surface design.
- Group nits per server rather than spamming individual entries when descriptions are systematically out of date.
- If a server's tool registration is split across multiple files, document the source of truth for each tool in the surface table.
- Deprecation aliases (server registers both old and new names; docs reference one) are `concern` until the alias is removed.
