# Composite Recall Resources in Hyphae

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Every session start requires multiple separate recall queries: recent errors, active
decisions, session context, relevant memories. There is no pre-assembled bundle
that fits within a hard token budget. Agents spend tokens on recall query overhead
and often receive more context than the budget can sustain. The data exists; the
packaging doesn't.

## What exists (state)

- **`hyphae session context`**: returns session context as structured output; not
  token-budget-aware
- **`hyphae memory recall`**: semantic search across all memories; no budget
  capping
- **Memory types**: episodic (with decay), memoir (permanent knowledge graph);
  both available for bundling
- **Session-start MCP injection**: Claude Code sessions get hyphae context via MCP
  at session start; the content is assembled dynamically without a token cap
- **`hyphae evaluate`**: measures recall effectiveness; not used for pre-assembling
  bundles

## What needs doing (intent)

Add a `hyphae recall-bundle --budget <tokens>` command that pre-assembles the
highest-value context for session start within a hard token budget. The bundle
prioritizes: active errors > recent decisions > effective recalled memories
(boosted by recall scoring from gap #1) > session summary.

The recall bundle should align with a layered wake-up model drawn from the
mempalace ecosystem borrow audit:

- **L0** — Session identity and project context: always included, minimal tokens;
  this is the floor that every session receives regardless of budget pressure
- **L1** — Active errors and recent decisions: high priority, included first after
  L0; these are the items most likely to determine what the agent does next
- **L2** — Effective memories by recall score: on-demand, fills the remaining budget
  in score order (or recency order if scoring is not yet complete)
- **L3** — Deep search results: included only when explicitly requested or when
  budget allows after L0–L2 are satisfied

The existing Step 1 priority ordering (active errors → decisions → effective
memories → session summary) already maps directly onto this model. The update is
naming the layers explicitly so that operators, hosts, and future implementers can
reason about budget allocation by layer rather than by ad-hoc priority integers.

---

### Step 1: Implement recall bundle assembler

**Project:** `hyphae/`
**Effort:** 1–2 days
**Depends on:** Recall effectiveness scoring (gap #1) recommended but not strictly required

Create `hyphae recall-bundle --budget <N>` that:

1. Queries active errors (topic `errors/active`) — highest priority, always include
2. Queries recent decisions (topic `decisions/{project}`) — include top 3
3. Queries effective memories (sorted by recall score if available, else recency)
4. Queries session context summary
5. Fills the token budget greedily in priority order, truncating the lowest-priority
   items if over budget
6. Returns a structured bundle as JSON or formatted text

Token counting: use a character-based approximation (4 chars ≈ 1 token) as a fast
budget estimate. Exact tokenization is not required.

#### Files to modify

**`hyphae-core/src/recall/bundle.rs`** — new file:

```rust
pub struct RecallBundle {
    pub active_errors: Vec<Memory>,
    pub decisions: Vec<Memory>,
    pub effective_memories: Vec<Memory>,
    pub session_summary: Option<String>,
    pub total_tokens_estimated: usize,
    pub budget: usize,
    pub truncated: bool,
}

impl RecallBundle {
    pub fn assemble(conn: &Connection, project: &str, budget: usize) -> Result<Self>;
    pub fn format_for_injection(&self) -> String;
}
```

**`hyphae-cli/src/cmd/recall_bundle.rs`** — new command:

```rust
/// Assemble a session-start context bundle within a token budget.
#[derive(Args)]
pub struct RecallBundleArgs {
    #[arg(long, default_value = "4000")]
    pub budget: usize,
    #[arg(long, default_value = "text", value_enum)]
    pub format: OutputFormat,
}
```

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
hyphae recall-bundle --budget 2000 2>&1 | head -30
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `hyphae recall-bundle --budget <N>` runs without error
- [ ] Output respects the token budget (estimated tokens ≤ budget)
- [ ] Active errors included first when present
- [ ] Bundle marked `truncated: true` when budget was binding
- [ ] Build and tests pass

---

### Step 2: Expose bundle as JSON for MCP injection

**Project:** `hyphae/`
**Effort:** 2–4 hours
**Depends on:** Step 1

Add `--format json` to `hyphae recall-bundle`:

```json
{
  "schema_version": "1.0",
  "budget": 4000,
  "estimated_tokens": 1823,
  "truncated": false,
  "sections": {
    "active_errors": [...],
    "decisions": [...],
    "effective_memories": [...],
    "session_summary": "..."
  }
}
```

This is the format for programmatic consumption — volva recall injection (gap #10)
and the existing MCP session-start injection can use this instead of ad-hoc queries.

#### Verification

```bash
hyphae recall-bundle --budget 4000 --format json 2>&1 | python3 -m json.tool | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] JSON output validates (parseable by `python3 -m json.tool`)
- [ ] `schema_version: "1.0"` present
- [ ] All sections present even when empty (empty arrays, not missing keys)

---

### Step 3: Use recall-bundle in volva pre-run injection

**Project:** `volva/`
**Effort:** 1–2 hours
**Depends on:** Step 2, gap #10 (volva hyphae recall injection)

If gap #10 is in progress, update `HyphaeRecallInjector` to call
`hyphae recall-bundle --budget 4000 --format json` instead of
`hyphae session context --format json`. The bundle is more complete and
budget-aware.

If gap #10 is not yet started, note this dependency and skip this step.

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Volva uses `recall-bundle` command for pre-run injection
- [ ] Budget configurable via volva config (default 4000 tokens)
- [ ] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `hyphae/`
3. `hyphae recall-bundle --budget 2000` returns a bundle within the budget
4. JSON format validates and includes `schema_version: "1.0"`
5. All checklist items are checked

### Final Verification

```bash
cd hyphae && cargo test --workspace 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, no failures.

## Context

Gap #20 in `docs/workspace/ECOSYSTEM-REVIEW.md`. The "data exists; packaging
doesn't" gap. Without a budget-aware bundle, session-start context is unbounded
and can dominate the context window before the agent has done any work. The token
budget is an explicit design constraint, not an optimization — it must be a hard
limit, not a soft preference. If gap #1 (recall effectiveness scoring) is complete,
the bundle benefits immediately from score-ordered selection.

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsThe mempalace ecosystem borrow audit introduces an explicit L0/L1/L2/L3 layered
wake-up model that directly informs how the bundle should be structured. See
`mempalace-ecosystem-borrow-audit.md` — "Add first-class wake-up stack." The
layers defined in the "What needs doing" section above describe what each level
contains; handoff #84 (Memory-Use Protocol) defines when each layer should be
activated. Together, this handoff and #84 form the full layered recall contract:
#80 owns bundle assembly and layer contents, #84 owns the protocol for when hosts
and agents invoke each layer.
