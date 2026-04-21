# Global Ecosystem Audit

Three-layer audit of the entire Basidiocarp ecosystem: automated metrics,
structural review, and cross-project consistency.

**Prerequisite:** canopy >= 0.3.1 (`canopy -V` to check). If the installed
binary is stale, rebuild it from the workspace repo and copy it into
`~/.local/bin` so your shell picks up the new version:

```bash
cd canopy && cargo install --path . && cp ~/.cargo/bin/canopy ~/.local/bin/canopy
```

This README also assumes the completed `Orchestration 01-06` work listed in
`.handoffs/HANDOFFS.md` is already shipped.

Set the common values once before you start:

```bash
export PROJECT_ROOT="$(pwd)"
export WORKTREE_ID=main   # replace if your checkout uses a different worktree id
export ORCHESTRATOR_AGENT_ID=will-orchestrator
```

`canopy task create` returns JSON, so the examples below use `jq -r '.task_id'`
to capture new task IDs.

---

## Deploy via Canopy

### Step 0: Register Agents

```bash
# Register yourself as orchestrator
canopy agent register \
  --agent-id "$ORCHESTRATOR_AGENT_ID" \
  --host-id will-orchestrator \
  --host-type claude-code \
  --host-instance local \
  --model claude-sonnet-4.5 \
  --project-root "$PROJECT_ROOT" \
  --worktree-id "$WORKTREE_ID" \
  --role orchestrator \
  --capabilities architecture,code-review

# Register implementer agents (one or more; reuse across tasks)
canopy agent register \
  --agent-id codex-impl-rust \
  --host-id codex-impl-rust \
  --host-type codex \
  --host-instance local \
  --model gpt-5.4 \
  --project-root "$PROJECT_ROOT" \
  --worktree-id "$WORKTREE_ID" \
  --role implementer \
  --capabilities rust,code-review,hyphae,mycelium,rhizome,cortina,canopy,spore,stipe,volva

canopy agent register \
  --agent-id codex-impl-ts \
  --host-id codex-impl-ts \
  --host-type codex \
  --host-instance local \
  --model gpt-5.4 \
  --project-root "$PROJECT_ROOT" \
  --worktree-id "$WORKTREE_ID" \
  --role implementer \
  --capabilities typescript,code-review,cap

# Register validator agents
canopy agent register \
  --agent-id haiku-validator-rust \
  --host-id haiku-validator-rust \
  --host-type claude-code \
  --host-instance local \
  --model claude-haiku-4.5 \
  --project-root "$PROJECT_ROOT" \
  --worktree-id "$WORKTREE_ID" \
  --role validator \
  --capabilities rust,hyphae,mycelium,rhizome,cortina,canopy,spore,stipe,volva

canopy agent register \
  --agent-id haiku-validator-ts \
  --host-id haiku-validator-ts \
  --host-type claude-code \
  --host-instance local \
  --model claude-haiku-4.5 \
  --project-root "$PROJECT_ROOT" \
  --worktree-id "$WORKTREE_ID" \
  --role validator \
  --capabilities typescript,cap
```

### Step 1: Create Parent Task

```bash
export AUDIT_PARENT=$(
  canopy task create \
    --title "Global ecosystem quality audit" \
    --requested-by "$ORCHESTRATOR_AGENT_ID" \
    --project-root "$PROJECT_ROOT" \
    --description "Three-layer audit: automated metrics, structural review, cross-project consistency, and boundary/doc fidelity. See .handoffs/archive/campaigns/global-audit/" \
  | jq -r '.task_id'
)

echo "$AUDIT_PARENT"
```

Worker lifecycle uses two commands once a task has been assigned:

```bash
canopy task status --task-id <task_id> --status in_progress --changed-by <agent_id>
canopy task complete --agent-id <agent_id> --summary "what changed" <task_id>
```

### Step 2: Layer 0 - Baseline Script

```bash
canopy task create \
  --title "Create audit baseline script" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" \
  --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" \
  --required-role implementer \
  --required-capabilities rust \
  --description "See .handoffs/archive/campaigns/global-audit/00-baseline-script.md"
```

Assign it to `codex-impl-rust`, wait for completion, and verify the generated
artifact:

```bash
canopy task complete --agent-id codex-impl-rust --summary "baseline script added and validated" <task_id>
jq . audit-baseline.json
```

### Step 3: Layer 1 - Lint Audits (parallel)

Create all 9 lint tasks. These can run in parallel.

```bash
canopy task create --title "Lint audit: hyphae" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,hyphae \
  --description "See .handoffs/archive/campaigns/global-audit/01-lint-hyphae.md"

canopy task create --title "Lint audit: mycelium" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,mycelium \
  --description "See .handoffs/archive/campaigns/global-audit/02-lint-mycelium.md"

canopy task create --title "Lint audit: rhizome" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,rhizome \
  --description "See .handoffs/archive/campaigns/global-audit/03-lint-rhizome.md"

canopy task create --title "Lint audit: cap" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities typescript,cap \
  --description "See .handoffs/archive/campaigns/global-audit/04-lint-cap.md"

canopy task create --title "Lint audit: cortina" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,cortina \
  --description "See .handoffs/archive/campaigns/global-audit/05-lint-cortina.md"

canopy task create --title "Lint audit: canopy" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,canopy \
  --description "See .handoffs/archive/campaigns/global-audit/06-lint-canopy.md"

canopy task create --title "Lint audit: spore" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,spore \
  --description "See .handoffs/archive/campaigns/global-audit/07-lint-spore.md"

canopy task create --title "Lint audit: stipe" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,stipe \
  --description "See .handoffs/archive/campaigns/global-audit/08-lint-stipe.md"

canopy task create --title "Lint audit: volva" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role validator \
  --required-capabilities rust,volva \
  --description "See .handoffs/archive/campaigns/global-audit/19-lint-volva.md"
```

Assign each task to a validator agent with the matching capabilities. Give the
agent the corresponding handoff content as context. Wait for all 9 to complete.

```bash
# Check progress on the parent:
canopy api task --task-id "$AUDIT_PARENT"
```

### Step 4: Layer 2 - Structural Reviews (parallel, after Layer 1)

```bash
canopy task create --title "Structure review: hyphae" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,hyphae,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/09-structure-hyphae.md"

canopy task create --title "Structure review: mycelium" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,mycelium,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/10-structure-mycelium.md"

canopy task create --title "Structure review: rhizome" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,rhizome,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/11-structure-rhizome.md"

canopy task create --title "Structure review: cap" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities typescript,cap,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/12-structure-cap.md"

canopy task create --title "Structure review: cortina" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,cortina,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/13-structure-cortina.md"

canopy task create --title "Structure review: canopy" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,canopy,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/14-structure-canopy.md"

canopy task create --title "Structure review: spore" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,spore,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/15-structure-spore.md"

canopy task create --title "Structure review: stipe" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,stipe,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/16-structure-stipe.md"

canopy task create --title "Structure review: volva" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" --required-role implementer \
  --required-capabilities rust,volva,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/20-structure-volva.md"
```

Assign each task to an implementer agent with the matching handoff. Run 2-3 in
parallel if you are managing multiple Codex sessions.

### Step 5: Layer 3 - Cross-Project Consistency (after Layer 2)

```bash
canopy task create \
  --title "Cross-project consistency review" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" \
  --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" \
  --required-role implementer \
  --required-capabilities code-review,architecture \
  --description "See .handoffs/archive/campaigns/global-audit/17-cross-project-consistency.md. Reads all Layer 1 and Layer 2 summaries."
```

Give the agent the 18 Layer 1 and Layer 2 summaries as context, not the raw
handoff files.

### Step 6: Layer 4 - Boundary and Doc Fidelity (after Layer 2)

Use the real workspace template sources during this audit:

- `templates/README-TEMPLATE.md`
- `templates/AGENTS-TEMPLATE.md`
- `templates/CLAUDE-TEMPLATE.md`
- `lamella/resources/templates/`

This workspace does not have a top-level `.templates/` directory.

```bash
canopy task create \
  --title "Boundary verification and documentation fidelity" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" \
  --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" \
  --required-role implementer \
  --required-capabilities architecture,code-review \
  --description "See .handoffs/archive/campaigns/global-audit/21-boundary-and-doc-fidelity.md. Use templates/README-TEMPLATE.md, templates/AGENTS-TEMPLATE.md, templates/CLAUDE-TEMPLATE.md, and lamella/resources/templates/ for template fidelity checks."
```

This can run alongside Layer 3 once Layer 2 is complete.

### Step 7: Synthesis (after Layers 3 and 4)

```bash
canopy task create \
  --title "Audit synthesis and documentation update" \
  --requested-by "$ORCHESTRATOR_AGENT_ID" \
  --project-root "$PROJECT_ROOT" \
  --parent "$AUDIT_PARENT" \
  --required-role orchestrator \
  --description "See .handoffs/archive/campaigns/global-audit/18-synthesis.md. Update ECOSYSTEM-INTERNAL-AUDIT.md."
```

This task is typically the orchestrator closeout step. It reads the structured
summaries from all prior layers and updates the master audit document.

### Step 8: Verify and Close

```bash
# Check that every child task is done:
canopy api task --task-id "$AUDIT_PARENT"

# Close the parent after review:
canopy task status \
  --task-id "$AUDIT_PARENT" \
  --status closed \
  --changed-by "$ORCHESTRATOR_AGENT_ID" \
  --closure-summary "Global ecosystem audit completed"
```

---

## Monitoring Progress

```bash
# See what needs attention across this audit:
canopy api snapshot --project-root "$PROJECT_ROOT" --preset attention

# See full detail on the parent, including child status:
canopy api task --task-id "$AUDIT_PARENT"

# List blocked tasks:
canopy api snapshot --project-root "$PROJECT_ROOT" --preset blocked

# List overdue execution tasks:
canopy api snapshot --project-root "$PROJECT_ROOT" --preset overdue_execution
```

---

## Execution Summary

| Layer | Tasks | Role | Parallel? | Depends On | Est. Time |
|-------|-------|------|-----------|-----------|-----------|
| 0: Baseline script | 1 | implementer | no | nothing | 30min |
| 1: Lint audits | 9 | validator | yes (all 9) | Layer 0 | 5min each |
| 2: Structure reviews | 9 | implementer | yes (2-3 at a time) | Layer 1 | 30min each |
| 3: Cross-project consistency | 1 | implementer | no | Layer 2 | 1hr |
| 4: Boundary + doc fidelity | 1 | implementer | no | Layer 2 | 2-3hrs |
| 5: Synthesis | 1 | orchestrator | no | Layers 3 and 4 | 1hr |
| **Total** | **22** | | | | **~8-11 hrs wall clock** |

With parallel execution: Layer 0 (30min) + Layer 1 (5min) + Layer 2 (~2hrs at
3 parallel) + Layer 3 (1hr) + Layer 4 (2-3hrs, can overlap with Layer 3) +
Layer 5 (1hr) = ~5-7 hours total.
