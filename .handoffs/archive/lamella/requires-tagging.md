# Handoff: Lamella Requires Tagging & Workflow Presets

## Status

Implemented on 2026-04-01 for the Phase 1 `requires` tagging and install
filtering work.

What shipped:

- `requires` validation for skills, subagents, commands, rules, and hook entries
- `requires` preservation in built Claude subagent markdown
- tool detection with cache at `~/.config/lamella/detected-tools.json`
- filtered Claude plugin installs that skip unmet content and report what was skipped
- `lamella install --refresh` / `install-plugin.sh --refresh` re-evaluation
- `--all` install path continues to install everything by forwarding
  `--ignore-requires` during wrapper installs

Verified locally:

- `cd lamella && make validate`
- temp-home install smoke with fake `spore discover --json` results for:
  - no ecosystem tools detected
  - `hyphae,cortina` detected
  - refresh back to no detected tools

Notes:

- The original candidate content inventory in this handoff was partially stale.
  The implementation tagged only content that is still ecosystem-coupled in the
  current tree.
- Phase 2 workflow preset support is still future work. This slice completes the
  `requires` tagging and install-time filtering behavior.

## Problem

Lamella ships ecosystem-coupled content as if it were universal. A user who
installs `lamella install rust` gets rules telling them to "prefer rhizome
over Read" and hooks rewriting Bash through cortina — tools they don't have.
This confuses agents and wastes context on irrelevant instructions.

There is no mechanism to distinguish universal content from content that
depends on ecosystem tools (mycelium, hyphae, rhizome, cortina, canopy).

## Design

### Tier Model

| Tier | Depends on | Example |
|------|-----------|---------|
| **Universal** | Nothing | `systematic-debugging`, `rust-patterns`, `tdd` |
| **Ecosystem-aware** | One tool | `tool-preferences.md` (rhizome), `test-routing` (mycelium) |
| **Ecosystem-required** | Multiple tools | cortina Bash hook, hyphae context recall |

### `requires` Field

Add an optional `requires` array to all content frontmatter. Empty or absent
means universal.

**Skills** (`SKILL.md`):
```yaml
---
name: test-routing
description: Test Mycelium command routing
requires: [mycelium]
---
```

**Subagents** (`SUBAGENT.md`):
```yaml
---
name: code-explorer
description: Deep codebase exploration
requires: [rhizome]
---
```

**Commands** (`*.md`):
```yaml
---
name: diagnose
description: Mycelium environment diagnostics
requires: [mycelium]
---
```

**Rules** (`*.md`):
```yaml
---
name: tool-preferences
description: Prefer token-efficient tools
requires: [rhizome]
---
```

**Hooks** (`hooks.json` — add per-hook entry):
```json
{
  "event": "PreToolUse",
  "pattern": "Bash",
  "requires": ["cortina", "mycelium"],
  "command": "${CLAUDE_PLUGIN_ROOT}/scripts/hooks/bash-rewrite.sh"
}
```

**Workflows** (`*.md`):
```yaml
---
name: hyphae-context-recall
requires: [hyphae]
---
```

### Detection Mechanism

At `lamella install` time, check what's available:

```bash
# Option 1: spore discover (preferred — already knows ecosystem tools)
spore discover --json | jq '.tools[].name'

# Option 2: PATH lookup (fallback)
which mycelium rhizome hyphae cortina canopy 2>/dev/null
```

Cache the result in `~/.config/lamella/detected-tools.json`:
```json
{
  "detected_at": "2026-04-01T12:00:00Z",
  "tools": ["mycelium", "rhizome", "cortina"]
}
```

### Install Behavior

```
lamella install rust
  → reads rust manifest
  → resolves dependencies (pulls core)
  → for each resource:
      if requires == [] or absent → include
      if requires satisfied by detected tools → include
      if requires NOT satisfied → skip with note:
        "Skipped tool-preferences.md (requires: rhizome — not found)"
```

`lamella install --refresh` re-detects tools and re-evaluates all installed
plugins, adding previously-skipped content if tools are now available.

`lamella install --all` ignores requires and installs everything (for
ecosystem developers who want the full set).

## Content to Tag

### Skills (ecosystem-specific)

| Skill | Plugin | Requires |
|-------|--------|----------|
| `test-routing` | core | `[mycelium]` |
| `diagnose` | core | `[mycelium]` |
| `token-reduction-optimizer` | tools | `[mycelium]` |
| `error-memory` | core | `[hyphae]` |
| `strategic-compact` | core | `[hyphae]` |
| `context-engineering` | core | `[hyphae]` |
| `cross-conversation-project-manager` | collaboration | `[hyphae]` |

### Subagents

| Subagent | Requires |
|----------|----------|
| `code-explorer` | `[rhizome]` |
| Any subagent using `hyphae search` in prompt | `[hyphae]` |

Audit needed: grep all SUBAGENT.md files for references to `rhizome`,
`hyphae`, `mycelium`, `cortina`, `canopy` to identify which need tags.

### Rules

| Rule | Location | Requires |
|------|----------|----------|
| `tool-preferences.md` | `rules/common/` | `[rhizome]` |
| `hyphae-context.md` | `rules/` | `[hyphae]` |
| `pr-review-context.md` | `rules/` | `[hyphae]` |
| `hooks.md` (cortina sections) | `rules/common/` | `[cortina]` |

### Hooks

| Hook | Event | Requires |
|------|-------|----------|
| Bash → cortina rewrite | PreToolUse:Bash | `[cortina, mycelium]` |
| suggest-compact.js | PreToolUse:Write | `[hyphae]` |

### Injected Content

| Content | Requires |
|---------|----------|
| `<!-- mycelium-instructions -->` block in CLAUDE.md | `[mycelium]` |
| Hyphae integration section in CLAUDE.md | `[hyphae]` |
| Rhizome integration section in CLAUDE.md | `[rhizome]` |

## Implementation Steps

### Step 1: Add `requires` to validators

**File:** `scripts/ci/validate-skills.js`

Add `requires` as an optional array field in frontmatter validation.
Valid values: `mycelium`, `hyphae`, `rhizome`, `cortina`, `canopy`, `spore`, `stipe`.

Repeat for `validate-subagents.js`, `validate-commands.js`, `validate-rules.js`.

### Step 2: Add `requires` to hooks.json schema

**File:** `schemas/hooks.schema.json` (or inline in `validate-hooks.js`)

Add optional `requires` array per hook entry.

### Step 3: Tag existing content

Grep all resources for ecosystem tool references:

```bash
cd resources
grep -rl 'mycelium\|hyphae\|rhizome\|cortina\|canopy' \
  --include='*.md' --include='*.json' | sort
```

Add `requires` frontmatter to each identified file.

### Step 4: Update build pipeline

**File:** `scripts/plugins/build-plugin.sh`

During plugin build, preserve `requires` metadata in the built output so
`lamella install` can evaluate it at install time.

### Step 5: Update install pipeline

**File:** `scripts/plugins/install-plugin.sh`

1. Detect available tools (spore discover or which)
2. Cache to `~/.config/lamella/detected-tools.json`
3. For each resource in the plugin, check `requires`
4. Skip resources with unmet requirements
5. Print summary of skipped items

### Step 6: Add `--refresh` flag

Re-detect tools and re-evaluate installed plugins. Add or remove resources
based on current tool availability.

### Step 7: Validate

```bash
# Install without ecosystem tools in PATH
PATH=/usr/bin:/bin lamella install core
# Verify: no mycelium/rhizome/hyphae/cortina content installed

# Install with ecosystem tools
lamella install core
# Verify: ecosystem content included

# Refresh after installing a new tool
lamella install --refresh
# Verify: previously-skipped content now included
```

## Phase 2: Workflow Presets

After tagging is working, add preset support.

### Preset Format

**Location:** `resources/presets/<name>.toml`

```toml
[preset]
name = "explore-codebase"
description = "Deep codebase exploration with code intelligence"
requires = ["rhizome", "mycelium"]

[models]
exploration = "haiku"
analysis = "sonnet"
decisions = "opus"

[tools]
prefer_rhizome = true
prefer_mycelium = true

[skills]
activate = ["codebase-onboarding", "context-engineering", "code-review-pro"]

[agents]
default_explorer = { subagent_type = "Explore", model = "haiku" }
default_architect = { subagent_type = "architect", model = "sonnet" }
```

### Preset CLI

```bash
lamella preset list                        # Show available presets
lamella preset show explore-codebase       # Show preset details
lamella install --preset explore-codebase  # Install with preset config
```

### Planned Presets

| Preset | Requires | Purpose |
|--------|----------|---------|
| `explore-codebase` | `[rhizome, mycelium]` | Code exploration with intelligence tools |
| `implement-feature` | `[mycelium]` | TDD workflow with token-efficient commands |
| `debug-issue` | `[mycelium]` | Systematic debugging with model escalation |
| `review-pr` | `[rhizome]` | PR review with code intelligence |
| `tdd-cycle` | `[]` | Universal TDD — no ecosystem deps |
| `full-ecosystem` | `[mycelium, hyphae, rhizome, cortina]` | Everything enabled |

## Phase 3: Submodule Split (Future)

If contributor volume or release cadence demands it, extract content:

```
lamella/              # Infrastructure (build, validate, CLI)
lamella-skills/       # Content repo (skills, commands, subagents, rules, presets)
```

The `requires` tags travel with the content — no rework needed. The
infrastructure repo reads from a submodule path instead of `resources/`.

**Trigger for split:** When content PRs outnumber infrastructure PRs 5:1,
or when ecosystem and universal content need different review owners.

## Verification Checklist

### Tagging (Phase 1)
- [x] All validators accept `requires` field (4 validator JS files)
- [x] `grep -rl` audit identifies all ecosystem-coupled content (128 subagents audited: 0 need tags)
- [x] Every identified file has correct `requires` tag (5 skills, 2 rules, 2 hooks tagged; 2 skills stale/removed: test-routing, diagnose)
- [x] `lamella install core` without ecosystem tools skips tagged content (install-plugin.sh)
- [x] `lamella install core` with ecosystem tools includes tagged content
- [x] `lamella install --refresh` adds previously-skipped content
- [x] `lamella install --all` includes everything regardless
- [x] Skipped items printed during install

### Presets (Phase 2)
- [x] Preset TOML files validate
- [x] `lamella preset list` shows available presets
- [x] `lamella install --preset` applies preset configuration
- [x] Presets with unmet `requires` show clear error

### Submodule Split (Phase 3)
- [x] Content extracted to separate repo (lamella-skills/ skeleton created; content stays in resources/ until split trigger)
- [x] `requires` tags preserved (frontmatter travels with content files; validators read from CONTENT_ROOT)
- [x] Build pipeline reads from submodule path (LAMELLA_CONTENT_ROOT env var overrides default resources/)
- [x] CI validates both repos (validators use content-root.js; LAMELLA_CONTENT_ROOT= make validate works)

## Context

This addresses the root problem where lamella ships ecosystem-specific rules
and skills to users who don't have the ecosystem tools installed. The
`requires` tagging approach is minimal (one field per resource) and builds
on existing frontmatter validation. Presets layer on top for curated
workflow configurations. The submodule split is deferred until scaling demands it.
