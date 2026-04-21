# Cap: Inline Diff-Comment Review Loops

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

<!-- Save as: .handoffs/cap/inline-diff-review.md -->

## Problem

Cap's review surfaces show file-level diffs but do not support inline commenting.
Operators can see what an agent changed but cannot annotate a specific line, mark
a hunk as approved or rejected, or feed a correction back into the agent's
context. Without inline review, quality control in canopy multi-agent workflows
requires operators to exit cap, craft feedback manually, and inject it through a
separate channel. The feedback loop is broken at the UI boundary.

## What exists (state)

- **Cap review surfaces**: `cap` renders diffs from canopy and rhizome; current
  implementation is read-only at the file level
- **Canopy task ledger**: tasks carry evidence and completion state; no
  annotation or review-feedback record exists
- **Septa**: no review-annotation event contract exists today
- **`#24` (Live Operator Views)**: the broader review surface work; this handoff
  extends the diff view within that surface rather than replacing it
- **`#90` (Replay and Eval Surfaces)**: separate concern; that handoff is about
  temporal replays, not synchronous review feedback

## What needs doing (intent)

Add inline annotation support to cap's diff view, backed by a data model that
records line-range comments with an action (approve / reject / revise). Wire
those annotations back to canopy as structured feedback events so agents can
consume operator corrections without manual context injection. Design the data
model before building the UI.

---

### Step 1: Design the inline annotation data model

**Project:** `cap/` (data model), `septa/`
**Effort:** 1 day (design-first)
**Depends on:** nothing

Define the annotation record that backs all inline review interactions:

- **Line range**: file path, start line, end line (single-line annotations have
  equal start and end)
- **Comment**: free-text operator note
- **Action**: one of `approve`, `reject`, `revise` (revise implies the comment
  carries the correction)
- **Anchor**: a content hash of the annotated lines so the annotation can detect
  stale anchors if the diff changes
- **Identity**: annotation ID, task ID or session ID, operator ID (from cap
  auth), timestamp

Write this as a septa schema before touching cap UI code. The schema drives
both the cap data layer and the canopy feedback event shape.

#### Verification

- [ ] Annotation record schema written and placed in `septa/`
- [ ] Schema covers line range, comment, action, anchor, and identity fields
- [ ] At least one example fixture for each action type (approve, reject, revise)

---

### Step 2: Add cap UI component for inline diff commenting

**Project:** `cap/`
**Effort:** 3–5 days
**Depends on:** Step 1 (schema defined)

Extend the diff view to support inline annotations:

- Line-level click or selection opens an annotation panel anchored to the
  selected hunk
- Panel supports comment text entry and action selection (approve / reject /
  revise)
- Submitted annotations are stored locally in cap's data layer (indexed by
  task ID + file path + line range)
- Existing annotations render inline in the diff — approved lines marked green,
  rejected lines marked red, revise lines marked amber with the comment visible
- Stale anchors (where the underlying diff changed) render with a warning badge
  rather than silently disappearing

The UI does not need to call canopy in this step; persistence is local first.

#### Verification

```bash
cd cap && npm run build && npm test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Inline annotation panel opens on line/hunk selection
- [ ] Comment + action submission stores annotation in local data layer
- [ ] Annotations render inline with approve/reject/revise styling
- [ ] Stale anchor detection works and shows warning badge
- [ ] Build and tests pass

---

### Step 3: Wire review annotations back to canopy as structured feedback

**Project:** `cap/`, `canopy/`
**Effort:** 2–3 days
**Depends on:** Steps 1–2

Connect the annotation store to canopy's task ledger:

- When an operator submits a `reject` or `revise` annotation, cap emits a
  review-annotation event to canopy: `canopy review annotate --task <id>
  --file <path> --lines <start>-<end> --action revise --comment "..."`
- Canopy stores the annotation in the task record and marks the task with a
  `review_feedback_pending` status
- Agents polling canopy for task updates receive the annotation as structured
  context on their next check-in — no manual context injection needed
- `approve` annotations update the task toward `review_approved`; all hunks
  approved closes the review gate

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
cd cap && npm run build && npm test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Cap emits annotation event to canopy on submit
- [ ] Canopy stores annotation in task record
- [ ] Task status reflects `review_feedback_pending` on reject/revise
- [ ] Task status reflects `review_approved` when all hunks approved
- [ ] Agent task check-in returns annotation as structured context
- [ ] Build and tests pass in both projects

---

### Step 4: Add septa contract for review-annotation events

**Project:** `septa/`
**Effort:** 1 day
**Depends on:** Steps 1–3

Promote the review-annotation event to a formal septa contract:

- `review_annotation_submitted`: task ID, file, line range, action, comment,
  operator ID, timestamp
- `review_gate_approved`: task ID, operator ID, all-hunks-approved timestamp
- `review_gate_rejected`: task ID, operator ID, rejection summary

These events make review outcomes observable by hyphae (for memory) and by
future cap analytics surfaces without tight coupling to canopy internals.

#### Verification

```bash
cd septa && ./validate.sh 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Schema covers annotation-submitted, gate-approved, and gate-rejected events
- [ ] Example fixtures for all three event types
- [ ] Validation script passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. The annotation data model from Step 1 is written and placed in `septa/`
2. Every subsequent step has verification output pasted between the markers
3. `npm run build && npm test` passes in `cap/`
4. `cargo build --workspace && cargo test --workspace` passes in `canopy/`
5. Septa validation passes with the new review-annotation event schema
6. All checklist items are checked

### Final Verification

```bash
cd cap && npm run build && npm test 2>&1 | tail -5
cd canopy && cargo test --workspace 2>&1 | tail -5
cd septa && ./validate.sh 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, validation passes, no failures.

## Context

Source: Vibe Kanban audit. Priority: **Lower** — depends on cap's review
surfaces from `#24` (Live Operator Views) maturing first. Inline diff commenting
is only useful once there is a stable diff view to annotate.

This handoff also relates to `#90` (Replay and Eval Surfaces), but addresses a
different layer: `#90` is about reviewing what happened in the past; this
handoff is about correcting agent output in the present review cycle. The two
can coexist without coupling.

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsThe stale anchor detection in Step 2 is important for correctness. Annotations
that silently point to the wrong lines after a diff update would mislead agents
rather than help them. Implement anchor detection before wiring to canopy in
Step 3.
