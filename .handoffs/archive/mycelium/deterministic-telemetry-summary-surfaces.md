# Deterministic Telemetry Summary Surfaces in Mycelium

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** mycelium/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Mycelium tracks token savings but does not expose deterministic, machine-readable
telemetry summaries. The synthesis (DX-6) calls for summaries that can feed JSON,
MCP, and UI surfaces from one aggregation path. Currently `mycelium gain` shows
human-readable output against no stable schema. Downstream consumers — cap's cost
view, potential MCP surfaces — have no structured intake format to rely on.

## What exists (state)

- **`mycelium gain`**: shows token savings; human-readable output, not structured
- **`septa/mycelium-gain-v1`**: contract exists for gain data, used by cap
- **cortina statusline**: consumes mycelium savings in a display-only path, not
  machine-readable for further aggregation
- No JSON or MCP surface for telemetry summaries beyond `mycelium gain`

## What needs doing (intent)

Add `mycelium telemetry --format json` that outputs a normalized, deterministic
summary in a stable JSON shape. Expose the same aggregation core to a passive MCP
resource or document the interim CLI consumption path for cap.

---

### Step 1: Add structured JSON output to mycelium telemetry

**Project:** `mycelium/`
**Effort:** 1 day
**Depends on:** nothing

Add a `mycelium telemetry` subcommand with `--format json` (and `--format text` as
default to keep existing behavior intact). The JSON output should include:

- `session_savings` — tokens saved and compression ratio for the current or last
  session
- `cumulative_savings` — lifetime totals (tokens, estimated cost delta)
- `filter_breakdown` — per-filter contribution: filter name, calls, tokens saved,
  percentage of total
- `trend` — last N sessions if session records are available (session_id, savings,
  ratio)
- `schema_version: "1.0"`
- `generated_at` — ISO 8601 timestamp

Output must be deterministic: same input state produces identical JSON. No embedded
timestamps or random identifiers that vary between runs given the same underlying
data.

#### Files to modify

**`mycelium/src/cli/telemetry.rs`** — new subcommand:

```rust
#[derive(Debug, clap::Args)]
pub struct TelemetryArgs {
    #[arg(long, default_value = "text", value_enum)]
    pub format: OutputFormat,
    #[arg(long, default_value = "5")]
    pub sessions: usize,
}

pub fn run(args: TelemetryArgs, store: &SavingsStore) -> Result<()>;
```

**`mycelium/src/telemetry/summary.rs`** — aggregation core:

```rust
#[derive(Debug, Serialize)]
pub struct TelemetrySummary {
    pub session_savings: SessionSavings,
    pub cumulative_savings: CumulativeSavings,
    pub filter_breakdown: Vec<FilterContribution>,
    pub trend: Vec<SessionTrend>,
    pub schema_version: String,
    pub generated_at: String,
}

impl TelemetrySummary {
    pub fn build(store: &SavingsStore, session_limit: usize) -> Result<Self>;
}
```

#### Verification

```bash
cd mycelium && cargo build --release 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
mycelium telemetry --format json 2>&1 | head -30
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `mycelium telemetry --format json` emits valid JSON
- [ ] Per-filter breakdown included with names, call counts, and tokens saved
- [ ] `schema_version: "1.0"` present
- [ ] Output is deterministic (same store state → same JSON)
- [ ] `mycelium telemetry` (no flags) still produces human-readable text
- [ ] Build and tests pass

---

### Step 2: Wire usage-event data when available

**Project:** `mycelium/`
**Effort:** 4–8 hours
**Depends on:** Step 1, and Cross-Project Usage Event Contract (#96)

When cortina emits a `usage-event-v1` record (#62) for the session, mycelium's
telemetry summary should optionally enrich its output with those fields — model,
host, actual token counts, cost — rather than estimating from its own savings data
alone.

Add an optional `--usage-event <path>` flag that reads a usage-event JSON file and
merges the relevant fields into the summary output. This keeps the aggregation core
independent but allows richer output when cortina data is available.

If no usage-event file is provided, the summary is still complete — it just uses
mycelium's own savings estimates.

#### Verification

```bash
cd mycelium && cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `--usage-event <path>` flag accepted and documented in `--help`
- [ ] When a valid usage-event file is provided, `model` and `host` appear in output
- [ ] Missing or invalid usage-event file degrades gracefully (warning, not error)
- [ ] Tests cover both the enriched and the standalone paths

---

### Step 3: Document MCP resource path or defer decision

**Project:** `mycelium/`
**Effort:** 2–4 hours
**Depends on:** Step 1

If mycelium has an MCP surface (or plans one), expose the telemetry summary as a
passive MCP resource — a read-only resource that cap or other MCP clients can poll
without invoking the CLI.

If mycelium does not plan an MCP surface, document the interim consumption pattern
explicitly: cap consumes `mycelium telemetry --format json` via CLI invocation, and
the resource path is a future integration point.

Either outcome should be captured in a short decision note in
`mycelium/docs/telemetry-mcp.md` or equivalent.

#### Verification

```bash
ls mycelium/docs/telemetry-mcp.md 2>&1 || echo "decision note missing"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] MCP resource implemented OR decision to defer documented with rationale
- [ ] Cap consumption pattern documented for the interim CLI path
- [ ] Decision note exists in `mycelium/docs/` or equivalent location

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --release` and `cargo test --workspace` pass in `mycelium/`
3. `mycelium telemetry --format json` outputs valid, deterministic JSON
4. MCP surface or decision to defer is documented
5. All checklist items are checked

### Final Verification

```bash
cd mycelium && cargo build --release 2>&1 | tail -5 && cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** build clean, all tests pass.

## Context

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DX-6 ("Add deterministic operator telemetry summaries in Mycelium
that can feed JSON, MCP, and UI surfaces"). CCUsage and RTK audits converge on one
aggregation path feeding JSON, terminal, and MCP surfaces. The synthesis notes
mycelium has a stronger case for deterministic reporting and evidence-backed summary
surfaces than for new processing responsibilities. Depends on Cross-Project Usage
Event Contract (#96) for Step 2. Feeds cap's cost and usage views (#29) and agent
telemetry view (#33).
