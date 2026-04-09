# Context and Memory

Use this page when the problem is "what should the model know right now?" or "what should survive after the session
ends?"

## Context Is Not Memory

These get conflated constantly.

- context is what the model can see in the current turn
- memory is what the system can retrieve again later

Context is short-lived and expensive. Memory is durable but only helps if retrieval is good.

## Four Useful Buckets

| Bucket               | Lifetime      | What it is                                          | Basidiocarp surface                           |
|----------------------|---------------|-----------------------------------------------------|-----------------------------------------------|
| Working context      | current turn  | prompt, recent tool outputs, active instructions    | host prompt window, `mycelium`                |
| Retrieved context    | current turn  | documents or memories fetched just in time          | `hyphae` recall and docs search               |
| Episodic memory      | cross-session | what happened, decisions made, failures, outcomes   | `hyphae` memories, `cortina` events           |
| Structured knowledge | longer-lived  | concepts, relationships, code graphs, durable facts | `hyphae` memoirs, `rhizome` code graph import |

## Practical Flow

```mermaid
flowchart LR
    Past["Past sessions and docs"] --> Recall["Retrieve what matters"]
    Recall --> Prompt["Current prompt window"]
    Prompt --> Model["Model"]
    Model --> Outcome["Answer or action"]
    Outcome --> Capture["Capture events and decisions"]
    Capture --> Past

    style Recall fill:#36b37e,stroke:#1f8a5a,color:#fff
    style Prompt fill:#6554c0,stroke:#403294,color:#fff
    style Capture fill:#ff7452,stroke:#de350b,color:#fff
```

The goal is not to remember everything. The goal is to retrieve the right few things at the right time.

## What Usually Goes Wrong

### Too much context

The model gets overloaded with logs, boilerplate, or duplicated instructions. Quality drops before you hit the hard
token limit.

This is where `mycelium` matters: less prompt waste, tighter inputs.

### Too little context

The model lacks the one design decision or repo rule that actually controls the answer.

This is where repo guidance, handoffs, and targeted retrieval matter more than general background.

### Bad memory capture

If corrections, outcomes, and decisions never get stored, the system cannot improve across sessions.

This is where `cortina` and `hyphae` work together.

### Bad memory retrieval

If memory exists but recall is noisy or irrelevant, the harness behaves like it has no memory at all.

Good memory systems are retrieval systems, not just storage systems.

## Basidiocarp Split

Use these boundaries:

- `mycelium` shapes and compresses what enters the active prompt
- `hyphae` stores and retrieves long-term knowledge
- `cortina` captures lifecycle events worth turning into memory
- `canopy` may coordinate active work, but it is not the long-term memory layer

## Design Rule

Before adding more prompt text, ask:

1. should this be current-turn context?
2. should this be retrieved on demand?
3. should this be durable memory?
4. should this be structured knowledge instead of prose?

That is the harness version of "put the data in the right store."

## Related

- [Agent Harness](./agent-harness.md)
- [Tool Use and MCP](./tool-use-and-mcp.md)
- [LLM Training](./llm-training.md)
