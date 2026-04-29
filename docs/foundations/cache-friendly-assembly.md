# Cache-Friendly Instruction Assembly

This document describes the optimal order for assembling instruction layers to maximize Anthropic prompt cache hits across conversational turns. It complements [instruction-loading.md](./instruction-loading.md), which focuses on layer semantics and precedence.

---

## Anthropic Prompt Cache Constraints

The Anthropic API offer prompt caching with the following guarantees and limitations:

- **Cache TTL**: 5 minutes. Content must appear identically across consecutive API calls within the 5-minute window to be cached.
- **Cache granularity**: ~1024-token blocks. Caches are measured at checkpoint boundaries, so large stable sections are more likely to hit.
- **Content stability**: Only content that does not change between requests can be cached. Dynamic content (tool results, turn-by-turn conversation state) cannot be cached.
- **Billing impact**: Cached content counts as 90% of input tokens, reducing cost per cached turn significantly.

Key implication: **Maximize cache hits by placing stable, reusable content as early as possible in the system prompt.**

---

## Cache-Friendly Assembly Order

This is the order in which instruction layers should be assembled in the system prompt to maximize cache hits:

### 1. L0 — Global User Rules (Most Stable)

**Location**: `~/.claude/rules/`

**Why first**: User rules are personal preferences that rarely change within or between sessions. They form the most stable foundation and should be cached early to anchor the rest of the context.

**Cache behavior**:
- Typically unchanged across many sessions
- Good cache anchor — content before this point rarely changes
- 5-minute TTL usually exceeds a user's multi-turn conversation

**Content**: Personal coding style, error handling conventions, testing preferences, communication guidelines.

### 2. L1 — Workspace Root Guidance

**Location**: `CLAUDE.md` and `AGENTS.md` at the workspace root

**Why second**: Workspace conventions are updated less frequently than project-specific guidance. They document shared policies that apply across the entire ecosystem.

**Cache behavior**:
- Changes when workspace conventions evolve (rare)
- Benefits from L0 being cached first — frees cache space for L1
- Typically stable for weeks or months within a project

**Content**: Operating model, cross-project contracts, shared dependency management, delegation patterns.

### 3. L2 — Project-Specific Guidance

**Location**: `<project>/CLAUDE.md` (e.g., `cortina/CLAUDE.md`)

**Why third**: Project guidance is more dynamic than L1 but more stable than L3. It changes when the project's design or responsibilities shift.

**Cache behavior**:
- Changes when the project's architecture evolves (less frequent than per-session changes)
- Cached only if project context remains constant across turns
- May miss cache if the user works across multiple projects in one session

**Content**: Project role, build and test commands, state locations, architecture, project-specific failure modes.

### 4. L3 — Directory or Module-Level Guidance

**Location**: `CLAUDE.md` in subdirectories (e.g., `stipe/src/commands/CLAUDE.md`)

**Why fourth**: Directory-level guidance is specific to fine-grained scopes and may change more often than project-level guidance.

**Cache behavior**:
- Most likely to change between turns (e.g., when editing different features or modules in the same project)
- May cache within a focused session but rarely across sessions
- Should be kept brief to avoid wasting cache space on volatile content

**Content**: Tight-scope overrides, module-specific patterns, feature-area guidance.

### 5. Conversation Context (Dynamic, Not Cached)

**Content**: 
- User's current message
- Tool results (bash output, file reads, search results)
- In-flight turn state
- Inline instructions for this specific request

**Cache behavior**:
- Cannot be cached — changes on every turn
- Must appear after all stable layers to avoid busting caches unnecessarily

---

## Cache Hit Scenarios

### Ideal: Multi-turn conversation, same project, same scope

1. Turn 1: L0, L1, L2, L3 loaded into cache → L3 onwards cached
2. Turn 2: L0, L1, L2, L3 identical → cache hit on L2 or L3 depending on size → new conversation content loads
3. Turn 3: Same conditions → cache hit again

**Cache benefit**: Turns 2–5 (within 5-minute TTL) save ~20–40% of input tokens.

### Good: Multi-turn conversation, same project, different scopes

1. Turn 1: L0, L1, L2, L3a (feature A) cached
2. Turn 2: L0, L1, L2, L3b (feature B) differs from L3a → cache miss on L3 → cache hit on L1–L2
3. Turn 3: Back to feature A, L3a → cache miss because L3 changed → but L1–L2 cached

**Cache benefit**: Turns with L1–L2 unchanged save ~10–20% of input tokens.

### Poor: Multi-turn conversation, multiple projects

1. Turn 1: L0, L1a, L2a (project A), L3a cached
2. Turn 2: L0, L1b (workspace docs may differ), L2b (project B) → different L1–L2 → cache miss on L1
3. Turn 3: Back to project A → L2a reappears → misses cache because L1 changed

**Cache benefit**: Only L0 cached consistently; other layers miss. Save ~5% of input tokens.

### Worst: Dynamic content injected before stable layers

1. Turn 1: timestamp, session ID, volatile block A, then L0–L3 → everything after volatile block uncached
2. Turn 2: Different timestamp/session ID → entire cache invalidated
3. Turn 3: Cache still invalid

**Cache impact**: No caching of any instruction layers.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Volatile Content Before Stable Layers

**Bad**: Inject a timestamp, session ID, or dynamically fetched policy before L0.

```
System prompt:
Current session: 2026-04-20T12:34:56Z
Workspace policy (fetched from API): [dynamic JSON]
... then L0, L1, L2, L3 ...
```

**Why it fails**: The timestamp or fetched policy changes on every turn, invalidating the cache for everything after it. Stable layers cannot be cached.

**Fix**: Place dynamic content after all instruction layers.

```
System prompt:
L0 (rules) → L1 (workspace) → L2 (project) → L3 (directory)
... then conversation context, tool results ...
```

### Anti-Pattern 2: Mixing Stable and Dynamic in One Layer

**Bad**: Embed a timestamp or request-specific note inside L1 or L2.

```
L1 CLAUDE.md:
# Workspace Guidance
Last updated: [auto-inserted date]
Today's requirements: [fetched from database]
... rest of workspace rules ...
```

**Why it fails**: The auto-inserted date changes on every request, invalidating the entire layer and everything after it. The stable rules after the date cannot be cached.

**Fix**: Keep layers pure. Place per-request context outside the layers.

```
L1 CLAUDE.md: (static file, no auto-inserted content)
# Workspace Guidance
... rules ...

Conversation context:
Today's requirements: [fetched for this request]
```

### Anti-Pattern 3: Large Volatile Blocks Between Stable Layers

**Bad**: Insert a large dynamic block between L1 and L2.

```
L1 (workspace guidance)
[Large block: currently active issues, daily briefing, recent deployments — all dynamic]
L2 (project guidance)
L3 (directory guidance)
```

**Why it fails**: The large dynamic block changes on every turn, invalidating everything after it (L2, L3, and conversation context). L2 and L3 never cache.

**Fix**: Place all dynamic content after all instruction layers, as a single block.

```
L0 → L1 → L2 → L3 (all stable, can cache)
... all dynamic content together ...
```

### Anti-Pattern 4: Fetching External Content Into System Instructions Per-Request

**Bad**: Inject the output of an external API call into the system prompt on every request.

```
System prompt assembly:
1. Load L0–L3
2. Fetch live docs from Confluence
3. Insert fetched docs into system prompt
4. Send to API
```

**Why it fails**: Fetched content changes, invalidating cache every request. No instruction layer ever caches.

**Fix**: Keep instruction layers static files only. Pass external content as part of the conversation context if needed, or not at all if it is not essential.

```
System prompt: L0–L3 only (static, cacheable)
Conversation context: "Reference this external resource if relevant" (dynamic, not cached, but cheap)
```

### Anti-Pattern 5: Putting Stable Rules After Frequently-Changed Instructions

**Bad**: Load L0–L3 in reverse order, with volatile content first.

```
Volatile operational context (fetched per-request)
L3 (directory guidance)
L2 (project guidance)
L1 (workspace guidance)
L0 (global rules)
```

**Why it fails**: Volatile content invalidates cache for L3–L0. Even though L0 rules are stable, they appear after dynamic content so they cannot be cached alone. Cache is wasted.

**Fix**: Load in stable-first order: L0, L1, L2, L3, then dynamic context.

```
L0 (rules) → L1 (workspace) → L2 (project) → L3 (directory)
... volatile context ...
```

---

## Implementation Guidance

### For System Prompt Builders

When constructing the system prompt for a Claude Code session:

1. **Load in order**: L0 (user rules), then L1 (workspace), then L2 (project), then L3 (directory).
2. **All layers before conversation**: Complete all instruction layers before adding conversation context or tool results.
3. **Check for volatile content**: Scan each layer file for timestamps, environment variables, or dynamic queries. If found, extract those into separate per-request context blocks.
4. **Do not fetch and inject**: Never run external API calls and inject the output into instruction layers. Layers are static files only.
5. **No embedded session state**: Do not auto-insert session IDs, request IDs, or state into layer files. Those belong in conversation context.

### For Tool Developers

When building tooling that loads or validates instruction layers:

1. **Verify layer order**: Ensure your system prompt builder assembles layers in the stable-first order (L0, L1, L2, L3).
2. **Detect volatile content**: Warn if a layer file contains timestamps, environment variable references, or dynamic markers (e.g., `<!-- AUTOGEN:date -->`).
3. **Separate concerns**: Provide a clear API boundary between static layers and per-request context.
4. **Cache hints**: If possible, include cache statistics in debug logs to show cache hit rates per layer and per session.

---

## Relationship to Instruction Loading

- **[instruction-loading.md](./instruction-loading.md)** describes *what* each layer contains, its scope, and how precedence works when layers overlap.
- **This document** describes *when* to load each layer (order) and *why* that order maximizes cache efficiency.

Both are necessary:
- **Instruction Loading** answers: "What does L2 do? Which layer wins if there is a conflict?"
- **Cache-Friendly Assembly** answers: "In what order do I assemble layers? Why does order matter for cost?"

When implementing system prompt loading, follow cache-friendly assembly order. When resolving conflicting guidance between layers, follow precedence rules from instruction-loading.md.

---

## Further Reading

- [Anthropic Prompt Caching Documentation](https://docs.anthropic.com/en/docs/build-a-system/prompt-caching) — details on TTL, granularity, and cost reduction
- [instruction-loading.md](./instruction-loading.md) — layer semantics and precedence rules
- [CLAUDE.md](../../CLAUDE.md) — workspace root L1 guidance
