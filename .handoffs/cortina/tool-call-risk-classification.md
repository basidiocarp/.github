# Tool Call Risk Classification

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** enforcement (volva concern); blocking tool execution in cortina; UI surfaces (cap concern)
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-tool-call-risk-classification.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** `src/` tool classification and signal emission modules — wherever lifecycle signals are constructed and emitted
- **Reference seams:** ecc2 alpha observability module, 4-axis risk scoring model for tool calls
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Cortina captures lifecycle signals and runs hooks but does not classify tool calls by risk level. ECC's ecc2 alpha includes a 4-axis risk scoring model for tool calls: base tool risk (how dangerous is the tool category), file sensitivity (is the target file in a critical path), blast radius (how many files/systems are affected), and irreversibility (can the action be undone). The composite score (0.0–1.0) produces Allow/Review/Block recommendations. Without risk classification, cortina cannot emit richer lifecycle signals or enable volva to enforce risk-based policies.

## What exists (state)

- **`cortina`:** captures lifecycle signals for tool calls and hook events; no risk scoring is present
- **ecc2 reference:** 4-axis composite risk model producing Allow/Review/Block recommendations from a 0.0–1.0 score; base risk table keyed by tool category

## What needs doing (intent)

1. Define a `ToolRisk` struct with four `f32` axes: `base_risk`, `file_sensitivity`, `blast_radius`, `irreversibility`.
2. Define a `RiskLevel` enum: `Allow`, `Review`, `Block` with configurable composite score thresholds.
3. Implement a classifier that scores tool calls based on tool name and target path.
4. Emit the risk classification as part of cortina's lifecycle signal for the tool call.

## Scope

- **Primary seam:** tool classification and signal emission modules in `cortina/src/`
- **Allowed files:** `cortina/src/` tool classification and signal emission modules
- **Explicit non-goals:**
  - Do not implement enforcement (volva concern)
  - Do not block tool execution in cortina — it captures signals, it does not enforce policy
  - Do not add UI surfaces (cap concern)

---

### Step 1: Define ToolRisk struct and RiskLevel enum

**Project:** `cortina/`
**Effort:** 0.5 day
**Depends on:** nothing

Define `ToolRisk` with four `f32` fields: `base_risk`, `file_sensitivity`, `blast_radius`, `irreversibility`. Define `RiskLevel` as an enum with `Allow`, `Review`, and `Block` variants. Add configurable thresholds that map a composite score to a `RiskLevel`. The composite score is a weighted average of the four axes, yielding a value in 0.0–1.0.

#### Verification

```bash
cd cortina && cargo check 2>&1
```

**Checklist:**
- [ ] `ToolRisk` struct is defined with four `f32` axes
- [ ] `RiskLevel` enum has `Allow`, `Review`, and `Block` variants
- [ ] Composite score thresholds are configurable, not hardcoded constants buried in logic
- [ ] No existing tests regress

---

### Step 2: Implement classifier with base risk table for known tool categories

**Project:** `cortina/`
**Effort:** 0.5 day
**Depends on:** Step 1

Implement a classifier that accepts a tool name and target path and returns a `ToolRisk`. Build a base risk table keyed by tool category (read, write, execute, network, delete). Use the target path to score `file_sensitivity` (config files, secrets paths, and source roots score higher). Score `blast_radius` from the tool category and any available scope hints. Score `irreversibility` from whether the operation can be undone (delete and overwrite score high; read scores zero).

#### Verification

```bash
cd cortina && cargo test risk 2>&1
cd cortina && cargo test classifier 2>&1
```

**Checklist:**
- [ ] Classifier produces a `ToolRisk` for known tool categories
- [ ] Base risk table covers at minimum: read, write, execute, network, delete categories
- [ ] File sensitivity scoring treats config paths and secret paths as higher sensitivity
- [ ] Unit tests cover at least one tool from each risk category
- [ ] No existing tests regress

---

### Step 3: Wire classification into lifecycle signal emission

**Project:** `cortina/`
**Effort:** 0.5 day
**Depends on:** Step 2

Call the classifier for each tool call event and attach the resulting `ToolRisk` and `RiskLevel` to the lifecycle signal emitted by cortina. The signal consumer (volva) can then read the classification without cortina needing to act on it. Ensure the classification is present in the emitted payload and add a test that a tool call signal includes risk fields.

#### Verification

```bash
cd cortina && cargo test 2>&1
cd cortina && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Lifecycle signal for tool calls includes `ToolRisk` and `RiskLevel` fields
- [ ] A test verifies the emitted signal contains risk classification
- [ ] Cortina does not block or modify tool execution based on the classification
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cortina/verify-tool-call-risk-classification.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/cortina/verify-tool-call-risk-classification.sh
```

## Context

Source: ECC audit (ecc2 observability module, 4-axis risk scoring). See `.audit/external/audits/everything-claude-code-ecosystem-borrow-audit.md` section "Tool call risk scoring."

Related handoffs: #123 Cortina Hook Registry Hardening, #114b Cortina Tool Usage Emission. This handoff extends cortina's signal fidelity and is a prerequisite for any volva enforcement policy that needs to consume risk-level recommendations.
