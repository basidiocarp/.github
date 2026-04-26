# Rhizome: Blast-Radius Simulation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/src/` — read existing structure before writing; add `blast_radius.rs` or extend existing impact analysis module
- **Cross-repo edits:** none
- **Non-goals:** no runtime execution tracing; dependency graph is static analysis only; no cross-repo blast radius in this handoff; no UI rendering of the impact graph
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the depwire Wave 3 audit (`.audit/external/audits/depwire-wave3-audit.md`):

> "depwire's blast-radius simulation: given a symbol, walk the dependency graph and return direct dependents, transitive dependents, affected test files, and a composite risk score. The output is a ranked list ordered by propagation depth."

> "Best fit: `rhizome` (code intelligence MCP server) — extend or parallel the existing analyze_impact tool if it exists; expose as rhizome MCP tool rhizome_simulate_change."

## Implementation Seam

- **Likely repo:** `rhizome` (Rust code intelligence MCP server)
- **Likely files/modules:**
  - `src/blast_radius.rs` (new) — `BlastRadius` and `SymbolRef` structs, BFS graph walk, risk score calculation
  - `src/tools/` or `src/mcp/` (update) — expose `rhizome_simulate_change` as an MCP tool
  - Possibly extend `src/impact.rs` or equivalent if `analyze_impact` already exists
- **Reference seams (read before writing):**
  - `rhizome/src/` — read full directory listing to find existing module structure
  - Find whether `analyze_impact` already exists — if it does, extend it; if not, add `blast_radius.rs`
  - Find how existing MCP tools are registered to match the pattern
- **Spawn gate:** Step 0 (seam-finding pass) is mandatory before any code is written

## Problem

Rhizome provides code navigation (symbol search, reference lookup, definition jump) but has no impact simulation. When an operator asks "what breaks if I change this function?", rhizome cannot answer. depwire's blast-radius simulation shows the right approach: a breadth-first walk of the static dependency graph that classifies each reachable node by propagation depth, then computes a composite risk score from the counts.

This is a high-value addition to rhizome's MCP tool surface because it answers a question that is otherwise expensive for a model to answer by reading code — and it answers it structurally, not by reading file contents.

## What needs doing (intent)

1. Determine whether `analyze_impact` already exists in rhizome (Step 0 is mandatory)
2. Define `BlastRadius` and `SymbolRef` structs
3. Implement `simulate_change(symbol_name, file_path)` — BFS walk of the dependency graph, classify nodes by depth
4. Compute `risk_score` from direct, transitive, and test counts
5. Expose as rhizome MCP tool `rhizome_simulate_change(symbol, file)` — extend `analyze_impact` if it exists, otherwise add new tool

## Data model

```rust
pub struct BlastRadius {
    pub symbol: String,
    pub file_path: String,
    pub direct_dependents: Vec<SymbolRef>,
    pub transitive_dependents: Vec<SymbolRef>,
    pub affected_tests: Vec<String>,      // file paths of affected test files
    pub risk_score: f32,                  // 0.0–1.0
}

pub struct SymbolRef {
    pub name: String,
    pub file_path: String,
    pub kind: SymbolKind,                 // use existing rhizome SymbolKind if available
    pub depth: u32,                       // BFS depth from root symbol
}
```

## Risk score formula

```rust
fn compute_risk_score(
    direct_count: usize,
    transitive_count: usize,
    test_count: usize,
) -> f32 {
    let raw = direct_count as f32 * 2.0
        + transitive_count as f32 * 0.5
        + test_count as f32 * 1.0;
    (raw / 10.0).min(1.0)
}
```

## BFS walk algorithm

```
simulate_change(symbol_name, file_path):
  1. resolve symbol_name in file_path to a graph node
  2. BFS from that node over the dependency graph (who depends on me?)
  3. depth 1 nodes → direct_dependents
  4. depth 2+ nodes → transitive_dependents
  5. any node whose file_path contains "/test" or "_test" or starts with "tests/" → affected_tests
  6. compute risk_score from counts
  7. sort direct_dependents and transitive_dependents by depth ASC, then name ASC
```

## MCP tool interface

```
Tool: rhizome_simulate_change
Input:
  symbol: string   — name of the symbol to simulate changing
  file: string     — file path where the symbol is defined
Output: BlastRadius serialized as JSON
```

If `analyze_impact` already exists and accepts a symbol + file, add `blast_radius` as an additional field in its response rather than creating a duplicate tool.

## Scope

- **Allowed files:** `rhizome/src/blast_radius.rs` (new) or extend existing impact analysis module; MCP tool registration file (extend, not replace)
- **Explicit non-goals:**
  - No runtime execution tracing — static analysis only
  - No cross-repo blast radius (single repo scope)
  - No UI rendering of the impact graph
  - No incremental graph caching in this handoff

---

### Step 0: Seam-finding pass (mandatory)

**Effort:** tiny
**Depends on:** nothing

This step is required before any code is written. Read:
1. `rhizome/src/` — list all files and module structure
2. Does `analyze_impact` exist? What file? What signature?
3. How are existing MCP tools registered? (find the registration pattern)
4. Does rhizome have an existing `SymbolKind` enum to reuse?
5. Does rhizome have a dependency graph representation to walk?

Record findings before proceeding. If `analyze_impact` exists, the implementation in Step 2 extends it. If the dependency graph representation does not exist, Step 1 must build a minimal one.

---

### Step 1: Define structs

**Project:** `rhizome/`
**Effort:** tiny
**Depends on:** Step 0

Add `BlastRadius` and `SymbolRef` structs as specified in the data model. Place them in `src/blast_radius.rs` (new) unless Step 0 finds a more appropriate existing module. Derive `Debug`, `Clone`, `serde::Serialize`, and `serde::Deserialize`. Reuse rhizome's existing `SymbolKind` enum if one exists.

#### Verification

```bash
cd rhizome && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `BlastRadius` struct compiles with all fields
- [ ] `SymbolRef` struct compiles with all fields
- [ ] Serde derives present
- [ ] No duplicate type definitions with existing types

---

### Step 2: Implement simulate_change

**Project:** `rhizome/`
**Effort:** medium
**Depends on:** Step 1

Implement `simulate_change(symbol_name: &str, file_path: &str) -> Result<BlastRadius>`. Use BFS over rhizome's dependency graph. Classify nodes by depth. Identify affected test files by path pattern. Compute `risk_score` using the formula above. If `analyze_impact` exists, call it internally or share graph-walk logic rather than duplicating.

#### Verification

```bash
cd rhizome && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `simulate_change` compiles and returns `BlastRadius`
- [ ] BFS correctly separates depth-1 (direct) from depth-2+ (transitive) nodes
- [ ] Test file detection works for `/test`, `_test`, and `tests/` path patterns
- [ ] `risk_score` is clamped to 0.0–1.0

---

### Step 3: Add unit tests

**Project:** `rhizome/`
**Effort:** small
**Depends on:** Step 2

Add a `#[cfg(test)]` module in `src/blast_radius.rs`. Test:
- `compute_risk_score` at zero counts, low counts, and counts that would exceed 1.0 (clamped)
- BFS depth classification: verify a known 2-hop graph produces correct direct/transitive split
- Test file detection: paths containing `/test`, `_test`, and `tests/` prefix are correctly classified

#### Verification

```bash
cd rhizome && cargo test blast_radius 2>&1 | tail -20
```

**Checklist:**
- [ ] `compute_risk_score` tests pass including clamp case
- [ ] BFS depth test passes
- [ ] Test file path detection tests pass
- [ ] All blast_radius tests pass with zero failures

---

### Step 4: Expose as MCP tool

**Project:** `rhizome/`
**Effort:** small
**Depends on:** Step 3

Register `rhizome_simulate_change` as an MCP tool following the pattern from Step 0's findings. Input: `symbol` (string) and `file` (string). Output: `BlastRadius` serialized as JSON. If `analyze_impact` already exists and is extensible, add `blast_radius` as an optional output field rather than a separate tool.

#### Verification

```bash
cd rhizome && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] MCP tool registered with correct name
- [ ] Tool accepts `symbol` and `file` inputs
- [ ] Tool returns `BlastRadius` JSON
- [ ] No naming conflict with existing MCP tools

---

### Step 5: Full suite

```bash
cd rhizome && cargo build 2>&1 | tail -5
cd rhizome && cargo test 2>&1 | tail -20
```

**Checklist:**
- [ ] Build succeeds with no errors or new warnings
- [ ] All tests pass including new blast_radius tests
- [ ] No regressions in existing rhizome tests

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Step 0 seam-finding findings recorded before any code was written
2. Every step has verification output
3. Full build and test suite pass in rhizome
4. All checklist items checked
5. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- Cross-repo blast radius: extend the walk to follow imports across repo boundaries
- Incremental graph caching: cache the dependency graph with invalidation on file change
- cap integration: display blast-radius results in the cap dashboard when an operator changes a symbol
- Blast-radius-gated CI: block merges when risk_score exceeds a configurable threshold
- `septa/blast-radius-v1.schema.json` — define the contract for cross-tool consumption of blast-radius results

## Context

Spawned from Wave 3 audit program (2026-04-23). depwire's blast-radius simulation is the reference pattern — it identifies that the most useful output is not just a list of dependents, but a ranked and scored impact graph that tells the operator whether a change is low-risk (a leaf function with two callers) or high-risk (a shared utility with 40 transitive dependents and 12 affected test files). The risk score formula is intentionally simple and hardcoded — it can be tuned in follow-on work once operators have used it. Step 0 is marked mandatory because the right implementation path (extend `analyze_impact` vs. add new module) depends entirely on what exists in rhizome/src/, and that is unknown without reading the repo.
