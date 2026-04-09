# Tool Selection

Use this page when the question is not "how does the ecosystem work?" but "which tool should I use right now?"

## Short Version

| Need                                                     | Tool       |
|----------------------------------------------------------|------------|
| Run through a dedicated execution-host runtime           | `volva`    |
| Install, configure, repair, or update the stack          | `stipe`    |
| Reduce command output and token usage                    | `mycelium` |
| Store or recall memory                                   | `hyphae`   |
| Inspect symbols or make code-intelligent edits           | `rhizome`  |
| Capture lifecycle signals and session outcomes           | `cortina`  |
| Review status and memory in a dashboard                  | `cap`      |
| Coordinate multiple agents and handoffs                  | `canopy`   |
| Package templates, hooks, skills, commands, and wrappers | `lamella`  |
| Define a shared payload, schema, or cross-tool fixture   | `septa`    |
| Reuse shared editor and path primitives in Rust tools    | `spore`    |

## Decision Guide

```mermaid
flowchart TD
    Start["What do you need?"] --> Install{"Install or repair?"}
    Install -->|"Yes"| Stipe["stipe"]
    Install -->|"No"| Runtime{"Runtime problem or workflow?"}
    Runtime -->|"Execution host / backend routing"| Volva["volva"]
    Runtime -->|"Command output"| Mycelium["mycelium"]
    Runtime -->|"Memory / recall"| Hyphae["hyphae"]
    Runtime -->|"Code intelligence"| Rhizome["rhizome"]
    Runtime -->|"Lifecycle capture"| Cortina["cortina"]
    Runtime -->|"Operator review"| Cap["cap"]
    Runtime -->|"Multi-agent coordination"| Canopy["canopy"]
    Runtime -->|"Packaging / templates"| Lamella["lamella"]
    Runtime -->|"Shared contract / schema"| Septa["septa"]
```

## Common Scenarios

### "The host cannot see the tools"

Use `stipe`.

```bash
stipe doctor
stipe host doctor
```

### "I need backend routing or a dedicated execution-host runtime"

Use `volva`.

### "The agent is wasting tokens on shell output"

Use `mycelium`.

### "I need the agent to remember previous sessions"

Use `hyphae`.

### "I need references, renames, or symbol-level edits"

Use `rhizome`.

### "I need to know what happened during the session"

Use `cortina`.

### "I need a human-readable operational view"

Use `cap`.

### "I need to coordinate multiple active agents"

Use `canopy`.

### "I need to package or export shared prompts and hook templates"

Use `lamella`.

### "I need a shared schema or fixture that multiple tools depend on"

Use `septa`.

### "I am writing Rust tooling that needs shared editor primitives"

Use `spore`.

## Boundary Reminders

- `stipe` owns ecosystem policy.
- `volva` owns execution-host runtime and backend routing.
- `spore` owns shared editor primitives.
- `cortina` owns lifecycle runtime semantics.
- `lamella` owns packaging and templates.
- `canopy` owns coordination runtime state, not long-term memory.
- `hyphae` owns long-term memory and structured recall.
- `septa` owns shared payload contracts and fixtures.

## Related

- [Ecosystem Architecture](../architecture/ecosystem-architecture.md)
- [Operator Quickstart](./operator-quickstart.md)
- [What Gets Installed](./install-scope.md)
