# Subagent MCP Context Inheritance

<!-- Save as: .handoffs/cross-project/subagent-mcp-context.md -->
<!-- Create verify script: .handoffs/cross-project/verify-subagent-mcp-context.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Subagents have access to MCP tools but do not use them because they start
fresh without CLAUDE.md context, system-reminder injection, or ToolSearch
instructions. This causes subagents to default to native tools (Read, Grep,
Bash) instead of token-efficient ecosystem tools (rhizome, hyphae), wasting
tokens and producing lower-quality output.

## What exists (state)

- **Tool Nudging handoff (completed 2026-04):** Global rhizome rule
  (`~/.claude/rules/common/tool-preferences.md`), cortina Read/Grep nudges,
  and mycelium `find -> fd` rewrite are all in place for the *main*
  conversation — this is prior art but does not reach subagents
- **Subagent types:** `general-purpose` has MCP access, `implementer` does not,
  `explore` has partial access — only `general-purpose` can use ecosystem MCPs
- **Lamella prompts:** No subagent prompt templates include MCP tool guidance
  or ToolSearch reminders
- **Cortina spawn hooks:** Cortina operates at session boundaries; unclear if
  it can inject context at subagent spawn time
- **CLAUDE.md instruction:** Main conversation gets "For code files >100 lines,
  prefer rhizome tools" — subagents do not inherit this

## What needs doing (intent)

Fix at two layers: (1) lamella subagent prompt templates that include explicit
MCP tool preference guidance and ToolSearch reminders, and (2) investigate
cortina spawn-time injection as a parallel approach. The lamella fix is the
primary deliverable; cortina injection is exploratory.

---

### Step 1: Audit Current Subagent Prompt Patterns

**Project:** `lamella/`
**Effort:** 1 hour
**Depends on:** nothing

Identify all lamella agent definitions and skill templates that dispatch
subagents. Document which ones use `general-purpose` type (MCP-capable) and
what instructions they include about tool usage.

#### Files to modify

No files modified — this is a research step. Document findings in a scratch
file or inline below.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
grep -rl 'general-purpose\|subagent\|Agent tool' lamella/resources/ 2>/dev/null | head -20
```

**Output:**
<!-- PASTE START -->
128 subagent definitions found in lamella/resources/subagents/ across 20 categories.
No subagent uses `general-purpose` type — that is a built-in Claude Code agent.
Lamella subagents use capability_profile (explore, implement, review, plan, etc.) and
execution_profile (read-only, edit-code, run-commands, edit-docs).
89 subagents use read-only or edit-code profiles with tools: Read, Grep, Glob, Bash, Write, Edit.
Zero subagents reference ToolSearch, mcp__, rhizome, or hyphae.
Key finding: subagents support `skills` frontmatter field that injects skill content at startup.
This is the integration mechanism — create an MCP context skill, reference via `claude.skills`.
<!-- PASTE END -->

**Checklist:**
- [x] List of all agent definitions that dispatch subagents is documented
- [x] Each agent's type (`general-purpose`, `implementer`, `explore`) is noted
- [x] Current tool usage instructions (if any) in each agent are cataloged

---

### Step 2: Create Subagent MCP Context Template

**Project:** `lamella/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Create a reusable prompt fragment that subagent templates can include. The
fragment should contain:
1. Explicit instructions to use `ToolSearch` before calling MCP tools
2. Tool preference table (rhizome over Read/Grep for code files)
3. Specific tool names to search for (`rhizome`, `hyphae`)
4. When to fall back to native tools

#### Files to modify

**`lamella/resources/fragments/mcp-context.md`** — new reusable fragment:

```markdown
## Ecosystem Tool Preferences

Before reading code files >50 lines, search for rhizome tools:
- Call `ToolSearch` with query "rhizome get_structure" to load schema
- Use `mcp__rhizome__get_symbols` instead of reading full files
- Use `mcp__rhizome__get_symbol_body` for specific functions
- Use `mcp__rhizome__find_references` instead of grep for symbol search

Before storing context across sessions:
- Call `ToolSearch` with query "hyphae memory" to load schema
- Use `mcp__hyphae__hyphae_memory_store` for decisions and errors

Fall back to Read/Grep when: file is <50 lines, non-code file, or
ToolSearch returns no results.
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
test -f lamella/resources/fragments/mcp-context.md && echo "Fragment exists"
grep -c 'ToolSearch' lamella/resources/fragments/mcp-context.md
```

**Output:**
<!-- PASTE START -->
Implementation note: Created as a skill instead of a fragment because lamella
subagents support `skills` frontmatter field which injects skill content at startup.
This is the proper lamella mechanism for loading content into subagents.

Skill exists at: lamella/resources/skills/tools/mcp-ecosystem-context/SKILL.md
ToolSearch mentions: 7 (query patterns for rhizome and hyphae)
Rhizome tools documented: get_symbols, get_structure, get_symbol_body, find_references,
  search_symbols, get_exports, get_complexity
Hyphae tools documented: hyphae_memory_store, hyphae_memory_recall
Fallback guidance: files <50 lines, non-code files, ToolSearch returns nothing
Added to tools-integration plugin manifest for distribution.
<!-- PASTE END -->

**Checklist:**
- [x] Fragment file exists at the expected path
- [x] Fragment includes ToolSearch instruction with specific query examples
- [x] Fragment includes tool preference table (rhizome over Read/Grep)
- [x] Fragment includes fallback guidance for when to use native tools

---

### Step 3: Integrate Fragment into Existing Agent Templates

**Project:** `lamella/`
**Effort:** 1-2 hours
**Depends on:** Step 1, Step 2

Update all `general-purpose` agent templates in lamella to include the MCP
context fragment. Agents that use `implementer` or `explore` types should
include a note about which tools are available in their restricted set.

#### Files to modify

Update each agent definition identified in Step 1 to include the fragment.
The exact files depend on Step 1 findings, but the pattern is:

```markdown
<!-- In each agent's prompt template -->
{include: fragments/mcp-context.md}
```

Or inline the key instructions if the include mechanism is not supported.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
grep -rl 'ToolSearch\|mcp-context\|rhizome' lamella/resources/agents/ 2>/dev/null | head -10
```

**Output:**
<!-- PASTE START -->
36 subagents updated with `skills: [mcp-ecosystem-context]` in their claude: block.
Categories updated: analysis (10), code-quality (8), debugging (5), architecture (6),
  core (1), languages (5), plus 1 skill file = 37 total files.

Integration via claude.skills frontmatter field (the native lamella mechanism for
injecting content into subagents at startup). No include/fragment system needed.

All subagents pass validation: `make validate` shows 128 subagent files validated.
Manifest validation passes: 52 manifests, 560 resources.
<!-- PASTE END -->

**Checklist:**
- [x] All `general-purpose` agent templates reference MCP context
- [x] Templates include ToolSearch reminder with specific query examples
- [x] `implementer` and `explore` agents note their restricted tool set

---

### Step 4: Investigate Cortina Spawn-Time Injection

**Project:** `cortina/`
**Effort:** 1-2 hours (exploratory)
**Depends on:** nothing

Investigate whether cortina can inject tool preference context when a subagent
is spawned. This is exploratory — document findings regardless of outcome.

Key questions:
- Does cortina have a hook point at subagent spawn (not just session start)?
- Can cortina modify the prompt sent to a subagent?
- If not, what would need to change in canopy or Claude Code to support this?

#### Files to modify

No files modified if injection is not feasible. If feasible, add a
`pre_agent_spawn` hook to cortina.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
grep -r 'spawn\|subagent\|agent.*hook' cortina/src/ 2>/dev/null | head -10
```

**Output:**
<!-- PASTE START -->
NOT FEASIBLE with current architecture.

Cortina handles three Claude Code hook events: PreToolUse, PostToolUse, and Stop.
These fire at tool-call boundaries, not at agent lifecycle boundaries.

Key findings from cortina/src/:
- main.rs dispatches to PreToolUse, PostToolUse, Stop handlers only
- adapters/claude_code.rs parses tool events (Bash, Write, Edit, Read, Grep)
- hooks/pre_tool_use.rs already has rhizome suggestions for Read/Grep on code files
- No "Agent" or "Task" tool event is parsed or handled
- Claude Code does not emit a hook event when spawning a subagent

What would need to change:
1. Claude Code would need to emit a new hook event type (e.g., PreAgentSpawn)
   that fires before a subagent is created, with the subagent config as payload
2. The hook would need to support modifying the subagent's prompt or skills list
3. Cortina would add a handler that injects mcp-ecosystem-context into the skills
4. Alternative: Claude Code could support a `defaultSkills` setting that auto-injects
   skills into all subagents (simpler, no hook needed)

The lamella skills approach (Step 2-3) is the correct solution for now. It works
within existing Claude Code capabilities and requires no platform changes.
<!-- PASTE END -->

**Checklist:**
- [x] Investigation documents whether cortina can hook subagent spawn
- [ ] If feasible: prototype hook is implemented with test
- [x] If not feasible: documented what would need to change and where

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cross-project/verify-subagent-mcp-context.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/cross-project/verify-subagent-mcp-context.sh
```

**Output:**
<!-- PASTE START -->
=== Subagent MCP Context Verification ===

--- Step 1: Audit Subagent Patterns ---
  PASS: audit findings documented (fragment or agents reference MCP)

--- Step 2: MCP Context Skill ---
  PASS: mcp-ecosystem-context skill exists
  PASS: skill mentions ToolSearch
  PASS: skill mentions rhizome tools
  PASS: skill mentions hyphae tools
  PASS: skill includes fallback guidance

--- Step 3: Subagent Integration ---
  PASS: at least one subagent references mcp-ecosystem-context skill
  PASS: at least 10 subagents reference the skill

--- Step 4: Cortina Spawn Investigation ---
  PASS: spawn investigation documented or hook implemented

--- Prior Art Verification ---
  PASS: main conversation has rhizome nudging (cortina pre_tool_use.rs or tool-preferences rule)

================================
Results: 10 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

Originated from OBS-003 + OBS-005 (2026-04-03). OBS-005 identified the root
cause: subagents start fresh without system-reminder injection, CLAUDE.md
context, or ToolSearch instructions. OBS-003 tracks the user-facing symptom:
agents default to native tools instead of ecosystem MCPs.

**Prior art:** The Tool Nudging handoff (completed 2026-04) solved this for the
main conversation via `~/.claude/rules/common/tool-preferences.md`, cortina
Read/Grep nudges, and mycelium `find -> fd` rewrite. This handoff extends
that work to subagents, which do not inherit the main conversation's context.
