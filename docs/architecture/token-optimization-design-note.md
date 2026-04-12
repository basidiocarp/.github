# Token Optimization Strategy

Token reduction in the ecosystem is a layered problem. The strategies below are ordered by
reliability and ROI. Implement in order — later layers depend on the foundation earlier layers
provide.

## The Problem Space

Mycelium's current regex-based filters strip content from command output before it reaches the
model. Regex stripping is fragile: it treats structured output as text, breaks across tool
versions, and can silently remove information the agent needed. The reliability failure compounds
the token savings — saving tokens by dropping context the model had to re-request is no savings
at all.

The goal is not to strip output. It is to give the model the right information at the right
granularity, with the ability to drill down when it matters.

---

## Strategy 1: Structural Parsing over Regex Filtering

**What it means:** Use native structured output formats — JSON flags, format strings, AST parsers,
machine-readable output modes — instead of post-processing human-readable text.

**Why it comes first:** Every other strategy depends on reliable parsing. Regex stripping on top
of human-readable output is the failure mode to eliminate, not the baseline to optimize.

**Concrete changes in mycelium:**

| Output source | Current | Target |
|---|---|---|
| `cargo test` | strip ANSI, regex on prose | `--format json` |
| `git log` | regex on human format | `--format=%H%x09%s%x09%ae` |
| `jq` / JSON tools | pass through unchanged | already structured |
| `eslint` / `tsc` | regex on prose | `--format json` |

When a tool offers no structured mode, parse the stable machine-readable parts (exit codes,
line:col patterns) and treat the rest as opaque. Do not regex-strip opaque prose and call it
filtering.

---

## Strategy 2: Summary + Detail-on-Demand

**What it means:** For large command outputs, mycelium emits a compact summary inline and stores
the full output in hyphae. The agent retrieves full detail via MCP tool call only when it needs it.

This is the progressive disclosure model. Rhizome already uses it for code intelligence — the
same pattern applies to command output.

**Flow:**

```
command output → mycelium structural parse → compact summary → model context
                                           → full output → hyphae (background store)
                                           → agent calls hyphae MCP for details if needed
```

**What the summary contains:** counts, statuses, and the signal items — test failures, lint
errors, file paths. Not full stack traces, not passing-test verbose output, not repeated header
lines.

**What hyphae stores:** the full structured output, keyed by command + session + timestamp. The
agent can retrieve it with `hyphae_get_command_chunks` when it needs to read the full trace.

**Threshold:** apply this pattern when output exceeds roughly 2K tokens. Below that threshold, the
round-trip cost of the MCP retrieval exceeds the savings.

---

## Strategy 3: Cache-Friendly Context Layout

**What it means:** Structure context assembly so that stable content is placed at positions where
Anthropic's prompt cache hits, and dynamic content is isolated to the end where cache misses are
expected.

**Cache layers:**

| Layer | Content | Cache behavior |
|---|---|---|
| L0 | System instructions, CLAUDE.md, project rules | Stable — cached across sessions |
| L1 | Hyphae recalls, active task context | Mostly stable within a session |
| L2 | Command output, current file diffs | Dynamic — cache misses expected here |

Token reduction effort at L2 has the highest ROI. Reducing L2 content also means fewer tokens
that need to be re-fed on subsequent turns.

**Practical constraint:** do not let L2 content drift into positions that break L0/L1 cache hits.
Cortina's context assembly order matters.

---

## Strategy 4: Compressed Structured Formats

**What it means:** For structured data payloads that are not code — JSON config, test result
summaries, dependency trees — use compact representation formats (TOON or equivalent) to reduce
token count without semantic loss.

**Scope:** applies to data payloads only. Do not apply to code context or prose. Models have
training bias toward standard code formats; unusual representations degrade reasoning quality on
code even when they reduce token count.

**Status:** experimental. Implement structural parsing (Strategy 1) and summary-on-demand
(Strategy 2) first. Evaluate compact formats only when those are proven and stable.

---

## Strategy 5: Vector-Enriched Context (Future)

**What it means:** Instead of including raw prior command output or file content, embed it in
hyphae, retrieve the relevant chunks via vector search, and annotate the inline summary with that
context. The model sees a compressed, contextually enriched view rather than raw output.

**Why it is deferred:** Depends on the summary + detail pattern being validated first. The
retrieval quality and latency profile need to be established at Strategy 2 scale before extending
it to context enrichment. Premature adoption would increase latency and complexity without proven
benefit.

---

## What Doesn't Belong Here

- **Real-time RAG for command filtering:** Embedding and retrieving on every command output adds
  latency in the critical path. The round-trip cost is higher than the token savings at current
  output sizes.
- **Novel token formats for code:** Models are trained on standard code formats. Exotic compact
  representations harm reasoning quality on code even when they reduce count.
- **Lossless compression:** Models read and generate tokens, not bytes. Lossless compression does
  not reduce model-visible token count.

---

## Integration Points

| Component | Role in token optimization |
|---|---|
| `mycelium` | Structural parsing, summary emission, filter layer |
| `hyphae` | Full-output storage, retrieval via MCP, vector search for enrichment (future) |
| `rhizome` | Structural code summaries — already implements progressive disclosure |
| `cortina` | Captures which commands ran; enables smart caching decisions and output keying |
| Annulus statusline | Consumes aggregated structured data; benefits from compact formats at L2 |

---

## Related

- Handoff #84: Memory-Use Protocol
- Handoff #95: Layered Instruction Loading
- [platform-layer-model.md](./platform-layer-model.md)
