# Septa Workflow Participant Runtime Identity Contract

## Problem

The expanded audit wave increased pressure on a missing cross-tool contract: workflow ids, participant ids, scoped session ids, and runtime identity are being implied in multiple repos, but not yet standardized in one contract source of truth. Without that, `volva`, `canopy`, `cortina`, and downstream operator surfaces will keep inventing slightly different identities for the same workflow state.

## What exists (state)

- **`septa/`:** already owns schema and fixture contracts for multiple cross-tool payloads
- **Existing identity-adjacent contracts:** canopy snapshots, task detail, evidence refs, session events, and Volva hook events already exist
- **No shared workflow identity contract:** there is no first-class schema for workflow, participant, and runtime-session identity
- **Examples:** `autogen`, `cmux`, `mem0`, `vibe-kanban`, and `claude-squad` all reinforced the same need from different directions

## What needs doing (intent)

Add a schema-first contract for:

- workflow id
- participant id
- runtime-session id
- workspace or worktree ref
- host or backend ref where needed

Keep the first version small, explicit, and paired with fixtures before asking multiple repos to rely on it.

---

### Step 1: Add a first versioned schema and example fixture

**Project:** `septa/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create a new versioned schema and matching example fixture for workflow and participant runtime identity.

#### Files to modify

**`septa/workflow-participant-runtime-identity-v1.schema.json`** — define the contract.

**`septa/fixtures/workflow-participant-runtime-identity-v1.example.json`** — add a matching fixture.

**`septa/README.md`** — document where this contract fits into the existing schema inventory.

#### Verification

```bash
rg -n 'workflow-participant-runtime-identity-v1' septa
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] a new versioned schema exists in `septa/`
- [ ] a matching example fixture exists
- [ ] the README or contract inventory mentions the new schema

---

### Step 2: Identify the first producer and consumer boundaries

**Project:** `septa/`, `volva/`, `canopy/`, `cortina/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Do not wire this into every repo at once. Start by naming the first realistic producer and consumer paths for the contract.

Likely candidates:

- `volva` produces execution-host session identity
- `canopy` consumes or links workflow identity
- `cortina` forwards lifecycle events with the same identity fields

#### Files to modify

**`septa/integration-patterns.md`** — document the first producer/consumer pattern.

**`volva/docs/VOLVA-ARCHITECTURE.md`** — note how `volva` will produce or use the contract.

**`canopy/README.md`** or adjacent docs — note how `canopy` will consume or link the contract.

#### Verification

```bash
rg -n 'workflow|participant|runtime identity|session id' septa volva/docs canopy/README.md cortina 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] the first producer and consumer boundaries are named explicitly
- [ ] the contract is described as cross-tool identity, not a repo-local schema
- [ ] docs reflect the new boundary

---

### Step 3: Add one narrow validation seam

**Project:** `septa/` and first producer or consumer repo
**Effort:** 2-3 hours
**Depends on:** Step 2

Add one narrow validation seam so this is not just a document. This can be a fixture validation test, a schema reference in a consumer, or a producer-side serialization check.

#### Files to modify

**`septa/`** — add any missing fixture or inventory updates.

**First producer or consumer repo** — add one narrow validation path that references the contract.

#### Verification

```bash
bash .handoffs/archive/septa/verify-workflow-participant-runtime-identity-contract.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] at least one producer or consumer path references the new contract
- [ ] the schema and fixture are consistent with that path
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/septa/verify-workflow-participant-runtime-identity-contract.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/septa/verify-workflow-participant-runtime-identity-contract.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/autogen/ecosystem-borrow-audit.md`
- `.audit/external/audits/cmux/ecosystem-borrow-audit.md`
- `.audit/external/audits/mem0/ecosystem-borrow-audit.md`
- `.audit/external/audits/vibe-kanban/ecosystem-borrow-audit.md`
- `.audit/external/audits/claude-squad/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/next-session-context-second-wave-handoffs.md`
