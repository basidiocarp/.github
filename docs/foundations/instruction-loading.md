# Layered Instruction Loading

This document describes the four-layer instruction loading model for the Basidiocarp ecosystem. Claude Code loads `CLAUDE.md` and `AGENTS.md` files at different levels, with each layer refining guidance for its scope.

## The Four Layers

### L0 — Global User Rules

**Location**: `~/.claude/rules/`

User-level preferences that apply everywhere across all projects and workspaces. These are personal conventions, coding style rules, authentication defaults, and operational workflows that the user brings into every session.

Examples:
- Personal git commit conventions
- Preferred error-handling patterns
- Testing methodology preferences
- Communication and writing style
- Tool-specific best practices

### L1 — Workspace Root

**Location**: `CLAUDE.md` and `AGENTS.md` at the basidiocarp workspace root

Workspace-wide guidance that applies across all projects within the ecosystem. This layer documents the meta-policies, shared architecture decisions, and cross-project communication contracts that bind the workspace together.

Examples (from basidiocarp):
- Operating model (separate build/test commands per subproject)
- Failure modes and how to detect them
- Communication contracts between tools
- Shared dependency management via `ecosystem-versions.toml`
- Schema validation through `septa/`
- Delegation patterns for multi-agent work

### L2 — Project Level

**Location**: `<project>/CLAUDE.md` (e.g., `cortina/CLAUDE.md`)

Project-specific guidance that narrows and contextualizes L1 for a single tool or service. This layer speaks to the project's role in the ecosystem, its key design decisions, and its local operating conventions.

Examples:
- Project's role and responsibilities
- Tool-specific build and test commands
- State locations and data ownership
- Architecture and module structure
- Project-specific failure modes

### L3 — Directory Level

**Location**: `CLAUDE.md` in subdirectories (e.g., `stipe/src/commands/CLAUDE.md`)

Tight-scope overrides for a specific module or subsystem. This layer provides guidance for a narrower context, such as a feature area or a group of related commands.

## Precedence and Scope

Later layers override earlier layers when they address the same topic:

- **L3 wins over L2, L1, L0** when L3 speaks directly to a question
- **L2 wins over L1, L0** when L2 provides project-specific guidance
- **L1 and L2 are complementary** — L1 sets ecosystem policy; L2 narrows it
- **L0 is universal** — user rules apply unless explicitly overridden by later layers

Example: If L0 says "always use `anyhow::Result` in applications" and L2 (stipe) says "use typed errors from `thiserror` for library boundaries," then work at stipe's library boundary uses L2's guidance.

## Claude Code Native Loading

Claude Code loads these files automatically based on file proximity:

1. When opening a file or directory, Claude Code looks for `CLAUDE.md` and `AGENTS.md` at that location
2. If not found, it searches up the directory tree toward the workspace root
3. L0 (`~/.claude/rules/`) is loaded first as global context
4. Later layers override or extend earlier guidance

This document makes the model explicit so that:
- The ecosystem contract is documented and testable
- Intentional gaps (missing layers) can be detected
- Overlapping or conflicting guidance can be flagged
- New projects can bootstrap with the right layer structure

## Validation

The `stipe doctor` command checks that expected instruction files exist at each layer. Run:

```bash
stipe doctor
```

This reports warnings if:
- L0: `~/.claude/rules/` directory is missing
- L1: workspace root `CLAUDE.md` or `AGENTS.md` is missing
- L2: expected project `CLAUDE.md` is missing for active subprojects
- L3: subdirectory-level guidance is expected but not present

Warnings help keep the ecosystem well-documented without blocking operation.

## Related Files

- [CLAUDE.md](../../CLAUDE.md) — workspace root L1 guidance
- [AGENTS.md](../../AGENTS.md) — workspace root L1 delegation patterns
- [stipe/CLAUDE.md](../../stipe/CLAUDE.md) — stipe L2 project guidance
