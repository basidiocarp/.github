# Cross-Project: Tool Preference Instructions

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** basidiocarp (workspace root)
- **Allowed write scope:** `CLAUDE.md` at workspace root; per-repo `CLAUDE.md` files where relevant
- **Cross-repo edits:** mycelium/CLAUDE.md, hyphae/CLAUDE.md, rhizome/CLAUDE.md tool-guidance sections
- **Non-goals:** changing tool behavior; adding new MCP tools; modifying hook scripts
- **Verification contract:** a new Claude Code session in this repo shows tool-choice guidance in its loaded context
- **Completion update:** update dashboard and archive when CLAUDE.md changes are merged

## Context

The ecosystem health audit confirmed that hyphae MCP and rhizome MCP are globally registered in `~/.claude/settings.json` — they are available in every session. But the workspace `CLAUDE.md` describes *what* each tool is, not *when agents should use it* over native alternatives. Agents default to `Read`, `Grep`, and `Glob` because nothing in their loaded context tells them to prefer `mcp__rhizome__search_symbols` or `mcp__hyphae__hyphae_memory_recall` for the tasks those tools handle better.

This is the cheapest and highest-leverage fix in the cohesion path. It requires no code changes.

## Implementation Seam

- **Likely files:** `/Users/williamnewton/projects/basidiocarp/CLAUDE.md` (primary); optionally per-repo CLAUDE.md files
- **Reference seams:** the hyphae-context.md global rule already exists as an example of this pattern — extend that model
- **Spawn gate:** do not spawn an implementer; this is a CLAUDE.md edit that should be reviewed before committing

## Problem

Agents have access to rhizome, hyphae, and mycelium but aren't told when to use them. The current CLAUDE.md describes the architecture. It doesn't say:
- "Use `mcp__rhizome__search_symbols` instead of Grep when finding callers, definitions, or references"
- "Call `mcp__hyphae__hyphae_memory_recall` before starting a task in a module you haven't worked in recently"
- "Mycelium is automatically proxying your Bash commands via cortina — you don't need to invoke it manually"

## What needs doing (intent)

Add a **Tool Selection Guide** section to the workspace `CLAUDE.md` with concrete, actionable guidance. The guidance should specify:

1. **When to use rhizome instead of Grep/Glob/Read**
2. **When and how to use hyphae recall**
3. **What mycelium does automatically (so agents don't try to manually invoke it)**
4. **When NOT to use ecosystem tools (some tasks don't benefit)**

## Scope

- **Primary seam:** workspace CLAUDE.md — a new section, not a rewrite
- **Allowed files:** `CLAUDE.md` at workspace root; optionally `mycelium/CLAUDE.md`, `rhizome/CLAUDE.md`, `hyphae/CLAUDE.md` for repo-local guidance
- **Explicit non-goals:** changing tool implementations; adding new instructions to global user rules (those go in `~/.claude/rules/`)

---

### Step 1: Draft the Tool Selection Guide

**Project:** basidiocarp root
**Effort:** 30-60 min
**Depends on:** nothing

Add the following section to the workspace `CLAUDE.md`, after the Architecture section and before Key Design Decisions:

```markdown
## Tool Selection Guide

The ecosystem tools are globally available. Use them instead of native fallbacks
when the task fits:

### Rhizome (code navigation)

Prefer `mcp__rhizome__search_symbols` over `Grep` when:
- Finding all callers of a function or all uses of a type
- Navigating to a definition you can't locate by filename
- Checking what imports a module or struct

Prefer `mcp__rhizome__get_structure` or `mcp__rhizome__summarize_file` over
`Read` when you need to understand a file's shape without reading every line.

Use `Grep` when: searching for a string pattern across files, or when the search
is purely textual (not structural). Rhizome does not replace text search.

### Hyphae (memory and recall)

Call `mcp__hyphae__hyphae_memory_recall` before starting work in any area you
haven't touched in this session if you want prior-session decisions, errors
resolved, or relevant context loaded.

Call `mcp__hyphae__hyphae_memory_store` after resolving a non-obvious error,
making an architecture decision, or discovering a non-obvious constraint. Use
topic `"errors/resolved"` for error fixes, `"decisions/{project}"` for
architecture choices.

Do NOT recall at every step. One recall at the start of a task is usually
enough. Hyphae is for prior-session continuity, not in-session notes.

### Mycelium (command output compression)

You do not invoke mycelium directly. The cortina pre-tool-use hook automatically
pipes verbose Bash command output through mycelium before it reaches the model.
This is active for: git log, cargo test, cargo build, and other high-volume
commands.

If you see compressed/summarized command output, that is mycelium working.
Do not attempt to "undo" the compression — the full output is available via
hyphae chunked storage if needed.

### When to use native tools

- `Read` for reading a specific file when you already know the path
- `Glob` for file discovery by name pattern
- `Grep` for text/regex search across files
- `Bash` for commands not covered by the above

Native tools are fine when the task is bounded. The ecosystem tools add value
for cross-session continuity (hyphae), structural code navigation (rhizome),
and output compression (mycelium/cortina).
```

#### Verification

```bash
# Confirm the section appears in CLAUDE.md
grep -n "Tool Selection Guide" CLAUDE.md
grep -n "mcp__rhizome__search_symbols" CLAUDE.md
grep -n "hyphae_memory_recall" CLAUDE.md
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `Tool Selection Guide` section added to workspace CLAUDE.md
- [ ] rhizome guidance present with specific tool names
- [ ] hyphae guidance present with topic conventions
- [ ] mycelium/cortina relationship explained (automatic, not manual)
- [ ] "When to use native tools" section present (avoid over-prescription)

---

### Step 2: Verify guidance loads in a new session

**Project:** basidiocarp root
**Effort:** 5 min
**Depends on:** Step 1

Open a new Claude Code session in this directory. In the first turn, ask:
"What tool should I use to find all callers of a Rust function?"

The answer should reference `mcp__rhizome__search_symbols`, not just Grep.

#### Verification

```bash
# CLAUDE.md is loaded automatically; verify it's the right file
head -5 CLAUDE.md
wc -l CLAUDE.md  # should be larger than before
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] CLAUDE.md loads in the session (it always does for workspace root)
- [ ] Response to navigation questions references ecosystem tools

---

## Completion Protocol

1. Tool Selection Guide section added to workspace CLAUDE.md
2. Section is accurate (tool names match actual MCP tool IDs)
3. No code changes made
4. Dashboard updated

### Final Verification

```bash
bash .handoffs/cross-project/verify-tool-preference-instructions.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
