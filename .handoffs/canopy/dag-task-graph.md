# Canopy: DAG-Based Task Graph

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/tasks/` (new DAG module), `canopy/src/store/` (new dag_tasks table), `canopy/src/tools/` (new MCP tools)
- **Cross-repo edits:** none
- **Non-goals:** does not replace the current linear task handoff model (existing tools stay intact); does not add per-node model selection (that's volva's job); does not add visualization (that's cap's job); does not implement hymenium-style workflow execution
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Identified as a recurring pattern across multiple Wave 2 audits:
- crewAI: `@start/@listen/@router` flow-based orchestration
- langgraph: state-machine graph with checkpointing
- OpenHands: structured action/observation with event sourcing
- strands: `graph` tool with per-node DAG execution
- plandb: compound graph model close to what canopy needs

> "canopy task coordination should standardize on DAG topology with explicit dependency declaration and output propagation."

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:**
  - `src/tasks/dag.rs` (new) — `TaskGraph`, `TaskNode`, `TaskEdge` types
  - `src/store/schema.rs` — add `dag_tasks` and `dag_edges` tables
  - `src/store/dag.rs` (new) — DAG persistence layer
  - `src/tools/dag_tools.rs` (new) — MCP tools: `canopy_dag_create`, `canopy_dag_add_node`, `canopy_dag_add_edge`, `canopy_dag_ready_nodes`
- **Reference seams:**
  - `canopy/src/tasks/` — read existing task handling before adding
  - `canopy/src/store/policy_events.rs` — store module pattern to follow
  - `canopy/src/tools/mod.rs` — how tools are registered and dispatched
- **Spawn gate:** read existing task and store structure before spawning

## Problem

Canopy's current task model is linear: task → agent → handoff. There is no way to express:
- "Task B depends on Task A completing" (blocking dependency)
- "Tasks B, C, and D can run in parallel once Task A completes" (fan-out)
- "Task E starts when both B and C complete" (join / fan-in)

Strands, crewAI, and plandb all show that the right model is a DAG (directed acyclic graph): tasks are nodes, dependencies are edges, and the runtime finds the "ready" frontier — nodes whose dependencies are all complete.

The key API primitive from beads (already audited): "give me the set of tasks that are unblocked right now." For a DAG, that's all nodes whose in-edges all point to completed nodes.

## What needs doing (intent)

Add a DAG layer to canopy. A `TaskGraph` is a named collection of `TaskNode` entries connected by directed `TaskEdge` entries. Nodes have a status (`pending`, `ready`, `running`, `complete`, `failed`). The primary query is `canopy_dag_ready_nodes(graph_id)` — return all nodes that are pending and have no incomplete dependencies.

This sits alongside the existing task tools — it doesn't replace them.

## Graph model

```
TaskGraph:  graph_id (ULID), name, created_at, status (open/complete)
TaskNode:   node_id (ULID), graph_id, task_id (optional FK to existing tasks), label, status, created_at, completed_at
TaskEdge:   edge_id, graph_id, from_node_id, to_node_id, edge_type (blocks | informs)
```

`blocks`: to_node cannot start until from_node completes.
`informs`: from_node's output is passed to to_node, but does not block it.

## Scope

- **Allowed files:** `canopy/src/tasks/dag.rs`, `canopy/src/store/schema.rs`, `canopy/src/store/dag.rs`, `canopy/src/tools/dag_tools.rs`, `canopy/src/tools/mod.rs` (register new tools)
- **Explicit non-goals:**
  - No changes to existing `canopy_task_*` tools
  - No execution engine — the DAG describes dependencies; execution stays with agents
  - No cycle detection enforcement at write time (add as a follow-on)

---

### Step 1: Add schema tables

**Project:** `canopy/`
**Effort:** small
**Depends on:** nothing (read `src/store/schema.rs` first)

Add to `BASE_SCHEMA` and `migrate_schema()`:

```sql
CREATE TABLE IF NOT EXISTS dag_graphs (
    graph_id    TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'open'
                    CHECK(status IN ('open', 'complete', 'failed')),
    created_at  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS dag_nodes (
    node_id      TEXT PRIMARY KEY,
    graph_id     TEXT NOT NULL REFERENCES dag_graphs(graph_id),
    label        TEXT NOT NULL,
    status       TEXT NOT NULL DEFAULT 'pending'
                     CHECK(status IN ('pending', 'ready', 'running', 'complete', 'failed')),
    task_id      TEXT,            -- optional FK to existing canopy tasks table
    created_at   INTEGER NOT NULL,
    completed_at INTEGER
);

CREATE TABLE IF NOT EXISTS dag_edges (
    edge_id      TEXT PRIMARY KEY,
    graph_id     TEXT NOT NULL REFERENCES dag_graphs(graph_id),
    from_node_id TEXT NOT NULL REFERENCES dag_nodes(node_id),
    to_node_id   TEXT NOT NULL REFERENCES dag_nodes(node_id),
    edge_type    TEXT NOT NULL DEFAULT 'blocks'
                     CHECK(edge_type IN ('blocks', 'informs'))
);

CREATE INDEX IF NOT EXISTS idx_dag_nodes_graph ON dag_nodes(graph_id);
CREATE INDEX IF NOT EXISTS idx_dag_edges_to ON dag_edges(to_node_id);
```

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build` succeeds with new schema

---

### Step 2: Add DAG store module

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 1

Create `src/store/dag.rs` following the `policy_events.rs` pattern. Key functions:

```rust
pub fn create_graph(conn: &Connection, graph_id: &str, name: &str, created_at: i64) -> StoreResult<()>
pub fn add_node(conn: &Connection, node: &DagNode) -> StoreResult<()>
pub fn add_edge(conn: &Connection, edge: &DagEdge) -> StoreResult<()>
pub fn get_ready_nodes(conn: &Connection, graph_id: &str) -> StoreResult<Vec<DagNode>>
pub fn update_node_status(conn: &Connection, node_id: &str, status: &str, completed_at: Option<i64>) -> StoreResult<()>
```

`get_ready_nodes` is the key query:
```sql
SELECT n.* FROM dag_nodes n
WHERE n.graph_id = ?1
  AND n.status = 'pending'
  AND NOT EXISTS (
    SELECT 1 FROM dag_edges e
    JOIN dag_nodes dep ON e.from_node_id = dep.node_id
    WHERE e.to_node_id = n.node_id
      AND e.edge_type = 'blocks'
      AND dep.status != 'complete'
  )
```

Add `mod dag; pub use dag::{DagNode, DagEdge};` to `src/store/mod.rs`.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] DAG store functions compile
- [ ] `get_ready_nodes` query is correct

---

### Step 3: Add MCP tools

**Project:** `canopy/`
**Effort:** medium
**Depends on:** Step 2

Create `src/tools/dag_tools.rs` with four tools:

- `canopy_dag_create(name: str) → {graph_id}` — create a new task graph
- `canopy_dag_add_node(graph_id: str, label: str, task_id?: str) → {node_id}` — add a node to a graph
- `canopy_dag_add_edge(graph_id: str, from_node_id: str, to_node_id: str, edge_type?: "blocks"|"informs") → {edge_id}` — add a dependency edge
- `canopy_dag_ready_nodes(graph_id: str) → [{node_id, label, task_id}]` — query unblocked nodes
- `canopy_dag_complete_node(node_id: str) → {}` — mark a node complete and update downstream readiness

Register the new tools in `src/tools/mod.rs`.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] All 5 tools compile and are registered
- [ ] Tool schemas documented correctly

---

### Step 4: Unit tests

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 3

Test the DAG logic directly against an in-memory SQLite connection:

```rust
#[test]
fn ready_nodes_respects_blocking_edges() {
    // A → B → C; only A should be ready initially
}

#[test]
fn completing_node_makes_downstream_ready() {
    // A → B; complete A; B becomes ready
}

#[test]
fn fan_out_all_downstream_ready_when_source_complete() {
    // A → B, A → C; complete A; both B and C ready
}

#[test]
fn fan_in_blocked_until_all_upstream_complete() {
    // A → C, B → C; complete A but not B; C still pending
}
```

```bash
cd canopy && cargo test dag 2>&1
```

**Checklist:**
- [ ] All 4 topology tests pass
- [ ] Edge cases (empty graph, single node) covered

---

### Step 5: Full suite

```bash
cd canopy && cargo test 2>&1 | tail -20
cd canopy && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd canopy && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The full test suite passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` updated to reflect completion

## Follow-on work (not in scope here)

- Cycle detection: validate no cycles when adding an edge
- `canopy_dag_status(graph_id)` — aggregate graph completion status
- `septa/dag-task-graph-v1.schema.json` — if graphs need to cross tool boundaries
- `cap` operator view for visualizing DAG structure and frontier
- Per-node model selection (volva integration)

## Context

Spawned from Wave 2 audit program (2026-04-23). crewAI, langgraph, strands, and plandb all converge on the same pattern: task coordination needs DAG topology. The `get_ready_nodes` query (find pending nodes with all blocking dependencies complete) is the single most important primitive — it's the equivalent of beads' `bd ready` for graph-structured work. The implementation is additive: existing canopy tools remain unchanged; the DAG layer is a new surface that agents can opt into for complex multi-step work.
