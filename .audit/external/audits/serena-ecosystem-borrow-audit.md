# Serena Ecosystem Borrow Audit

Date: 2026-04-07
Re-assessed: 2026-04-23 (Wave 1 re-audit — verdict: Update; spawned septa/context-envelope-v1.md handoff)
Repo reviewed: `serena`
Lens: what to borrow from the tool, how it fits the `basidiocarp` ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

`serena` is a cohesive code-intelligence stack built around a CLI front door, an MCP server, layered config, and project-local memory. Its strongest lesson for this ecosystem is the workflow contract: prefer symbol-level reading over file dumps, merge user, project, and global context cleanly, and expose tool payloads with schema and version discipline. The parts not worth copying wholesale are the monolithic Python surface, the home-directory-centric setup model, and the file-backed memory/runtime coupling.

## What Serena is doing that is solid

### 1. It makes symbol-first reading explicit

The prompt and context files push the user toward token-efficient, symbol-level reads instead of raw file dumping.

Evidence:

- [system_prompt.yml](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/resources/config/prompt_templates/system_prompt.yml#L5)
- [claude-code.yml](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/resources/config/contexts/claude-code.yml#L3)

### 2. It treats MCP tool schemas seriously

Tool descriptions and argument schemas are derived from type metadata and docstrings, with read-only versus destructive distinctions kept explicit.

Evidence:

- [mcp.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/mcp.py#L175)
- [tools_base.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/tools/tools_base.py#L167)

### 3. It handles layered config well

User prompt templates can override built-ins, and project config can override defaults without flattening everything into one source.

Evidence:

- [serena_config.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/config/serena_config.py#L52)
- [prompt_factory.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/prompt_factory.py#L8)

### 4. It distinguishes memory scopes

Global, project, read-only, and ignored memory are not all treated as one generic bag of notes.

Evidence:

- [project.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/project.py#L33)

## What to borrow directly

### Borrow now

- Schema-versioned context envelopes and token-budgeted context assembly.
  Best fit: `hyphae`, then `cap`.

- Symbol-first identities and stable symbol naming.
  Best fit: `rhizome`.

- Global-plus-project override semantics for configuration.
  Best fit: `rhizome` and `stipe`.

- Tool annotations that distinguish read-only from destructive operations.
  Best fit: `hyphae`, `cap`, and `stipe`.

## What to adapt, not copy

### Adapt

- The YAML-driven prompt and mode stack.
  Adaptation: keep the layered override idea, not Serena's exact generated prompt factory or home-dir layout.
  Evidence:
  [prompt_factory.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/prompt_factory.py#L8)
  [system_prompt.yml](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/resources/config/prompt_templates/system_prompt.yml#L1)

- The home-directory ownership model.
  Adaptation: translate it into repo-owned and ecosystem-owned config conventions instead of copying `~/.serena`.
  Evidence:
  [serena_config.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/config/serena_config.py#L58)
  [cli.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/cli.py#L61)

- The OpenAI tool-schema sanitizer.
  Adaptation: keep it as a compatibility shim only where needed, not as a general pattern.
  Evidence:
  [mcp.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/mcp.py#L68)

## What not to borrow

### Skip

- The monolithic Python implementation style.
  Evidence:
  [cli.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/cli.py#L150)
  [mcp.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/mcp.py#L50)
  [project.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/project.py#L33)

- The file-backed memory store as the primary state model.
  Evidence:
  [project.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/project.py#L80)

- The hidden `.serena` and `project.yml` discovery model as a general workspace convention.
  Evidence:
  [cli.py](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/serena/src/serena/cli.py#L61)

## How Serena fits the ecosystem

### Best fit by repo

- `hyphae`
  Best overall fit for context retrieval, token budgeting, and source-tagged envelopes.

- `rhizome`
  Best fit for symbol-first reading and layered language/config handling.

- `stipe`
  Strong fit for idempotent setup, MCP registration, and host-policy-aware wiring.

- `cap`
  Strong fit for typed wrappers around CLI-backed context payloads and project selection.

- `canopy`
  Secondary fit for structured state snapshots and operator summaries.

- `mycelium`
  Limited fit for idempotent install and update ergonomics, not for code-intelligence ownership.

## What Serena suggests improving in your ecosystem

### 1. Make passive, schema-versioned context surfaces more standard

`hyphae` and `cap` should likely lean harder into typed context payloads rather than ad hoc CLI JSON alone.

### 2. Keep symbol-over-file reading central

`rhizome` should continue treating stable symbol identity and token-efficient drill-down as the main workflow.

### 3. Keep setup idempotent and host-aware

`stipe` should keep the setup boundary explicit and avoid drifting into opaque local mutation.

### 4. Keep operator wrappers typed

`cap` should continue preferring typed wrappers over raw process output where Serena-like behavior is exposed.

## Verification context

This audit was based on source review only. No local build, test, or runtime verification was run in this pass.

## Final read

Borrow: symbol-first workflow discipline, schema-versioned context envelopes, layered config overrides, and typed tool capability metadata.

Adapt: layered prompts and mode stacks, but translate them into the ecosystem's repo-owned conventions.

Skip: the monolithic Python implementation style, file-backed memory ownership model, and hidden home-dir discovery pattern.
