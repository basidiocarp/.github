# Claude Code

Use this page when the host is Claude Code and the question is "where does a behavior come from?" rather than "which
Basidiocarp tool owns this?"

For harness concepts that apply beyond Claude Code, start with [Agent Harness](../concepts/agent-harness.md)
and [Prompting and Control Surfaces](../concepts/prompting-and-control-surfaces.md).

## What Basidiocarp Configures

For Claude Code, the Basidiocarp stack usually contributes four things:

- MCP servers for `hyphae` and `rhizome`
- lifecycle hooks through `cortina`
- shared prompts, skills, wrappers, and templates through `lamella`
- install, repair, and doctor flows through `stipe`

Claude Code itself still owns the host runtime. Basidiocarp adds memory, code intelligence, lifecycle capture, and
packaging around it.

## Configuration Scopes

When something behaves unexpectedly, check scope before assuming the wrong repo or tool is responsible.

| Scope   | Typical location                | Shared? | What usually lives here                                     |
|---------|---------------------------------|---------|-------------------------------------------------------------|
| Managed | host or admin-managed settings  | Depends | org policy, managed allowlists, centrally enforced defaults |
| User    | `~/.claude/`                    | No      | personal settings, user skills, user agents                 |
| Project | repo `.claude/` and `.mcp.json` | Yes     | team-shared host behavior for this workspace                |
| Local   | `.claude/settings.local.json`   | No      | machine-specific overrides and experiments                  |

Higher-precedence scopes can hide lower-precedence settings. Check local and managed state before assuming the project
config is wrong.

## Where to Look

| Surface       | Usual file or directory                                | Purpose                                                  |
|---------------|--------------------------------------------------------|----------------------------------------------------------|
| Settings      | `.claude/settings.json`, `.claude/settings.local.json` | permissions, sandbox, hooks, model defaults, environment |
| MCP           | `.mcp.json`                                            | project-scoped tool servers                              |
| Hooks         | settings `hooks` blocks or packaged Lamella content    | lifecycle enforcement and automation                     |
| Skills        | `.claude/skills/` or packaged Lamella content          | reusable prompt capabilities                             |
| Subagents     | `.claude/agents/`                                      | specialized delegated behavior                           |
| Repo guidance | `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`          | routing rules, repo boundaries, workflow constraints     |

## Basidiocarp Boundary Map

Use this table when you need to decide whether a fix belongs in the workspace or in Claude Code host config.

| Need                                                | Owning surface                |
|-----------------------------------------------------|-------------------------------|
| Host install, repair, doctor, shared registration   | `stipe`                       |
| Memory and recall tools                             | `hyphae`                      |
| Code intelligence and symbol-aware edits            | `rhizome`                     |
| Lifecycle capture and session signals               | `cortina`                     |
| Shared skills, commands, hooks, wrappers, templates | `lamella`                     |
| Local repo behavior and permissions                 | `.claude/` in the active repo |

## Debugging Order

When Claude Code behavior looks wrong, check in this order:

1. Run `stipe host doctor` and `stipe doctor`.
2. Confirm the host is actually Claude Code, not a shared MCP client path.
3. Inspect `.claude/settings.local.json` for local overrides.
4. Inspect `.claude/settings.json` and `.mcp.json` for project-shared behavior.
5. Inspect `CLAUDE.md`, `.claude/CLAUDE.md`, and `AGENTS.md` for routing or workflow constraints.
6. If the issue involves shared prompts, hooks, or wrappers, inspect `lamella/resources/` rather than only generated
   output.

## Common Failure Shapes

### "The tool is missing"

Check `.mcp.json`, then run the relevant `stipe` doctor flow. Missing tools are usually MCP registration or host-setup
problems, not memory or prompt problems.

### "The model is behaving differently in this repo"

Check repo guidance and project settings first. Project `CLAUDE.md`, `AGENTS.md`, or `.claude/settings.json` often
explains the difference.

### "A hook is blocking or rewriting behavior"

Check settings hook blocks and any Lamella-packaged hook content. For Basidiocarp workspaces, lifecycle behavior usually
points back to `cortina` plus packaged hook definitions.

### "The agent cannot remember prior work"

That is usually a `hyphae` availability, config, or recall issue, not a Claude Code settings problem.

## Related

- [Host Support](./host-support.md)
- [Tool Selection](./tool-selection.md)
- [Ecosystem Architecture](../architecture/ecosystem-architecture.md)
