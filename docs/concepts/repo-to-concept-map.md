# Repo to Concept Map

Use this page when you want to connect an AI concept to the repo that implements it in Basidiocarp.

## Why This Page Exists

The ecosystem is easier to understand when you read it in this order:

1. concept
2. harness role
3. repo
4. operator surface

This page handles step 3 from the concept side.

## High-Level Map

| Repo       | Main concept                 | Secondary concepts                                                      |
|------------|------------------------------|-------------------------------------------------------------------------|
| `volva`    | execution-host runtime       | backend routing, host-context shaping, runtime dispatch                 |
| `mycelium` | context shaping              | prompt compression, command filtering, runtime input control            |
| `hyphae`   | memory and retrieval         | RAG, episodic memory, semantic memory, session recall, knowledge graphs |
| `rhizome`  | tool use over code structure | code intelligence, symbolic editing, structured program navigation      |
| `cortina`  | lifecycle learning signals   | feedback capture, correction logging, session summarization             |
| `lamella`  | control-surface packaging    | skills, hooks, commands, reusable prompt assets                         |
| `septa`    | cross-tool contracts         | payload schemas, fixtures, seam governance                              |
| `stipe`    | host adaptation              | installation, registration, repair, policy application                  |
| `cap`      | operator observability       | read models, operational review, state presentation                     |
| `canopy`   | multi-agent coordination     | task ownership, handoffs, attention management                          |
| `spore`    | shared substrate             | path resolution, host primitives, subprocess and config plumbing        |

## Repo by Repo

### `volva`

Implements the execution-host boundary for workloads that should run through a dedicated runtime surface.

AI concepts in play:

- backend routing
- host-context shaping
- execution-host orchestration

What it is not:

- not the long-term memory layer
- not the shared contract registry

### `mycelium`

Implements the idea that context quality matters as much as model quality.

AI concepts in play:

- prompt compression
- context-window budgeting
- command-output shaping
- retrieval deferral for large outputs

What it is not:

- not long-term memory
- not a code-intelligence engine
- not a host installer

### `hyphae`

Implements the memory side of the harness.

AI concepts in play:

- RAG and document retrieval
- episodic memory
- semantic memory
- structured knowledge graphs
- cross-session recall

What it is not:

- not the host event adapter
- not the code-aware editing layer

### `rhizome`

Implements tool use over program structure instead of raw text.

AI concepts in play:

- tool-augmented reasoning
- code intelligence
- symbolic navigation
- structured edits with AST or LSP support

What it is not:

- not long-term memory
- not lifecycle capture

### `cortina`

Implements the learning-signal side of the harness.

AI concepts in play:

- lifecycle capture
- feedback loops
- correction logging
- session summarization
- data collection for future training or recall

What it is not:

- not the durable memory store
- not the packaging layer

### `lamella`

Implements reusable control surfaces.

AI concepts in play:

- prompt modularity
- workflow standardization
- reusable skills and wrappers
- packaged behavior across hosts

What it is not:

- not the lifecycle runtime
- not the primary memory system

### `septa`

Implements explicit contracts at cross-tool seams.

AI concepts in play:

- schema governance
- shared payload contracts
- fixtures for producer-consumer compatibility

What it is not:

- not the execution runtime
- not the memory or retrieval layer

### `stipe`

Implements host adaptation and policy application.

AI concepts in play:

- host integration
- deployment and registration
- environment-specific policy application

What it is not:

- not the retrieval layer
- not the symbolic code layer

### `cap`

Implements human-readable observability around the harness.

AI concepts in play:

- operator review
- read models over memory and runtime state
- transparency into system health and provenance

What it is not:

- not the main write path for knowledge
- not the lifecycle capture source

### `canopy`

Implements coordination once multiple active agents become a real system concern.

AI concepts in play:

- multi-agent orchestration
- handoffs
- ownership and attention routing

What it is not:

- not the long-term memory system
- not the underlying lifecycle adapter

### `spore`

Implements the shared substrate beneath several other repos.

AI concepts in play:

- reusable infrastructure for host and tool composition
- shared path and config primitives

What it is not:

- not the high-level harness policy layer

## Concept-to-Repo Crosswalk

| Concept                    | Primary repo                 | Notes                                                  |
|----------------------------|------------------------------|--------------------------------------------------------|
| Execution-host runtime     | `volva`                      | backend dispatch and host-context shaping live here    |
| RAG                        | `hyphae`                     | retrieval and document storage live here               |
| Episodic memory            | `hyphae`                     | often fed by `cortina` signals                         |
| Semantic memory            | `hyphae`                     | memoirs and concept graphs                             |
| Context compression        | `mycelium`                   | active-loop efficiency rather than durable storage     |
| Tool use                   | `hyphae`, `rhizome`          | retrieval tools and code tools are distinct categories |
| Symbol-aware code actions  | `rhizome`                    | AST and LSP-backed operations                          |
| Lifecycle learning signals | `cortina`                    | corrections and summaries become useful data           |
| Prompt control surfaces    | `lamella` plus repo guidance | packaging and distribution are the Lamella side        |
| Cross-tool contracts       | `septa`                      | shared payloads and fixtures should become explicit    |
| Host adaptation            | `stipe`                      | integrates the harness into concrete clients           |
| Multi-agent coordination   | `canopy`                     | only when coordination is truly needed                 |
| Operator observability     | `cap`                        | read and review surface over the harness               |

## Practical Reading Path

If you are trying to understand the ecosystem by concept:

1. [Agent Harness](./agent-harness.md)
2. [Context and Memory](./context-and-memory.md)
3. [Tool Use and MCP](./tool-use-and-mcp.md)
4. this page
5. [Harness Composition](../architecture/harness-composition.md)

## Related

- [Agent Harness](./agent-harness.md)
- [Context and Memory](./context-and-memory.md)
- [Tool Use and MCP](./tool-use-and-mcp.md)
- [Harness Composition](../architecture/harness-composition.md)
