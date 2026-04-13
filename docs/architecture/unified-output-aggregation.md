# Unified Output Aggregation

Data flows through one aggregation path, then renders to many surfaces.
This document establishes the pattern so Annulus and Cap stay aligned.

## Four Core Principles

### One aggregation path

All output data converges in **Annulus**, the operator-facing aggregation host.
Annulus reads from multiple data sources, assembles a canonical payload, and
holds a single source of truth for what the operator sees.

No other tool aggregates or merges output. All rendering flows from Annulus.

### Multiple rendering surfaces

Once aggregated, data flows to multiple renderers:

- **Terminal statusline** — two-line bar in hooks or shell prompts
- **JSON export** — structured output for programmatic use or integration
- **Cap panel** — web dashboard showing ecosystem state and task progress

Each renderer consumes the same canonical Annulus payload but shapes it for its
surface.

### Late rendering

Aggregate once, render late. Annulus handles all collection, deduplication, and
assembly. Renderers receive complete data and apply only surface-specific
formatting.

This prevents duplicate aggregation logic, avoids inconsistency when two tools
independently fetch the same data, and makes cache strategy and timing decisions
local to Annulus.

### Graceful degradation

When a data source is unavailable (hyphae offline, git not available, cortina
stopped), its segment appears in the payload with `available: false` and a
`reason` field explaining the outage.

Renderers show degraded state without crashing. Operators see what is available
and why something is missing.

## Data Sources

Tools that **produce** data:

- **Claude transcript (JSONL)** — model interaction, token counts, response shape
- **mycelium SQLite** — command output cache, estimated token savings
- **hyphae** — memory system health, topic counts, memory stats
- **cortina** — hook signal events, execution signals
- **git** — current branch, commit count, dirty/clean state
- **workspace path** — project root, active subproject, file paths

## Consumers

Tools that **render** data:

- **Annulus** — reads all sources, aggregates, serves terminal statusline + JSON
- **Cap** — reads Annulus output (or direct sources when needed), renders dashboard panels

## Why Annulus is the Aggregation Host

1. **Terminal-native** — must live where hooks can find it and statusline can
   embed it cheaply
2. **Already reads transcript + mycelium** — no new I/O logic needed to access
   two major sources
3. **Cheapest to embed** — small, fast, can run in hook context without
   heavyweight dependencies
4. **Decouples Cap from polling** — Cap consumes the payload; it does not need
   to coordinate source reads itself

This leaves Cap free to focus on its UI concerns: dashboard rendering, operator
actions, state browsing. It consumes Annulus output and renders it for web.

## Contract

- Annulus publishes a stable JSON schema for its output.
- Cap and statusline consume that schema as their contract.
- Schema changes go through `septa/` and are versioned.
- When a source fails, segments include `available: false` rather than
  omitting data.
