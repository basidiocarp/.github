# Audit Lane 3: Low Item Prioritization

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only across `.handoffs/`)
- **Allowed write scope:** `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane3-low-item-prioritization.md`
- **Cross-repo edits:** none (read-only audit)
- **Non-goals:** does not modify any handoff file, does not promote/demote priorities directly, does not close any handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane3-low-item-prioritization.sh`
- **Completion update:** once findings file is written and verification is green, update `.handoffs/HANDOFFS.md` campaigns row to reflect lane 3 complete

## Implementation Seam

- **Likely repo:** workspace root
- **Likely files/modules:**
  - `.handoffs/HANDOFFS.md` (the dashboard — ~40 Low-priority handoffs across cap, stipe, lamella, hyphae, cortina, rhizome, mycelium, septa, spore, canopy, hymenium, volva, cross-project)
  - `docs/foundations/core-hardening-freeze-roadmap.md` (F1 — exit criteria + active/frozen split)
  - Each Low handoff's content (read each one to assess relevance)
- **Reference seams:** the prior two campaigns' completion summaries (ecosystem-health-audit, sequential-audit-hardening) — they show what "fix-phase ready" looked like
- **Spawn gate:** the audit is read-only and the seam is well-known — proceed directly

## Problem

The dashboard tracks ~40 Low-priority handoffs. After the F1 freeze roadmap and F2 scope reset, the active/frozen repo split is now explicit. No one has re-evaluated which Low items:

1. Actually block the F1 exit criteria (should be promoted)
2. Are aimed at frozen repos (should be demoted/closed under freeze)
3. Are stale or duplicate after the recent migrations (should be closed)
4. Reference handoffs that were already completed in the 2026-04-29 batch (should be closed)
5. Have a "Decision Required before starting" tag and need triage

## What exists (state)

- **Dashboard active section:** ~40 Low-priority rows under "—" priority across 13 sections (Cap, Stipe, Lamella, Hyphae, Cortina, Rhizome, Mycelium, Septa, Spore, Canopy, Hymenium, Volva, Cross-Project)
- **F1 freeze policy:** active hardening repos are hyphae, mycelium, rhizome, septa, spore, stipe, cortina; frozen repos are cap, canopy, hymenium, lamella, annulus, volva
- **F2 cap scope cuts:** /code, /symbols, /api/rhizome, /api/lsp are slated for removal — handoffs targeting those routes are obsolete

## What needs doing (intent)

Produce a findings file that classifies each Low-priority handoff as:

- **Promote** — work that blocks an F1 exit criterion (rare; should be Medium or High instead)
- **Keep** — relevant, scoped to an active hardening repo, still well-defined
- **Demote/Defer** — relevant but aimed at a frozen repo or beyond F1 exit
- **Close (stale)** — superseded by recent migrations or no longer applicable
- **Close (out-of-scope under freeze)** — net-new feature or expansion that the freeze defers
- **Triage required** — has "Decision Required" tag or scope unclear

Each classification gets a one-line justification. The findings file becomes the input to a dashboard cleanup pass (separate fix-phase handoff).

## Scope

- **Primary seam:** the active handoff queue in `.handoffs/HANDOFFS.md`
- **Allowed files:** read everything under `.handoffs/`; write only `findings/lane3-low-item-prioritization.md`
- **Explicit non-goals:**
  - Modifying any handoff
  - Modifying the dashboard directly
  - Auditing CLI coupling (lane 1 owns that)
  - Auditing schemas (lane 2 owns that)

---

### Step 1: Capture the current Low-priority queue

**Project:** workspace root
**Effort:** small
**Depends on:** nothing

Snapshot every row in `.handoffs/HANDOFFS.md` where the `#` column is `—` (i.e., not numbered Foundation/Tier/Audit work) — this is the Low queue.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -c "^| — |" .handoffs/HANDOFFS.md)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Total Low-priority count captured
- [ ] Per-section breakdown captured (Cap N, Stipe N, …)

---

### Step 2: Classify each Low handoff

**Project:** workspace root
**Effort:** medium
**Depends on:** Step 1

For each Low handoff, open the file and assess against the F1 lens. Apply one of the six classifications. Justification must be one short line citing either:
- An F1 exit criterion (1-5)
- The active/frozen repo split
- A specific recent commit or migration that supersedes the handoff
- A "Decision Required" tag

Capture the result as a table in the findings file.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && ls .handoffs/cap/ | head -10)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Every Low handoff has exactly one classification
- [ ] Every classification has a one-line justification
- [ ] Decision Required handoffs flagged separately for operator triage

---

### Step 3: Identify F1-blocking promotion candidates

**Project:** workspace root
**Effort:** small
**Depends on:** Step 2

Re-read the handoffs classified as "Promote" and confirm they actually block an F1 exit criterion. If a handoff is mislabeled (i.e. it was Low for a reason and shouldn't be promoted), correct the classification. Promotion candidates should be rare.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -A2 "Exit Criteria" docs/foundations/core-hardening-freeze-roadmap.md | head -30)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Promotion candidates each cite a specific F1 exit criterion
- [ ] Promotion is calibrated — most Low items should not promote

---

### Step 4: Write findings file

**Project:** workspace root
**Effort:** small
**Depends on:** Steps 1-3

Write `findings/lane3-low-item-prioritization.md`:

```markdown
# Lane 3: Low Item Prioritization Findings (2026-04-29)

## Summary
[total Low count, classification breakdown]

## Classification Table

| Handoff | Section | Classification | Justification |
|---------|---------|----------------|---------------|
| [Title](path) | Cap | Close (stale) | superseded by F2 cap cuts |
| ... | ... | ... | ... |

## Promote (F1 blockers)
[list with one-line F1 criterion link per item]

## Close (stale)
[list with superseding commit/migration per item]

## Close (out-of-scope under freeze)
[list with freeze-policy reference per item]

## Demote/Defer
[list with rationale]

## Triage Required (Decision pending)
[list — operator must answer before classifying further]

## Recommended Dashboard Actions
[1-3 paragraphs: what the next dashboard cleanup pass should do]
```

#### Verification

```bash
test -f /Users/williamnewton/projects/personal/basidiocarp/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane3-low-item-prioritization.md && echo "findings file exists"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Findings file exists with all 7 sections
- [ ] Every Low handoff appears exactly once in the classification table
- [ ] No fixes attempted in this run (no handoff files modified)

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane3-low-item-prioritization.sh`
3. All checklist items are checked
4. The campaign README's lane table is updated (lane 3 row marked complete)

### Final Verification

```bash
bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane3-low-item-prioritization.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

The Low queue tends to grow without active triage. After the freeze policy is written down, there's a one-time opportunity to align the queue with the policy. This audit produces that alignment input without making any changes itself.

## Style Notes

- Findings are evidence-only. Do not modify any handoff files.
- "Promote" should be rare. If many items want to promote, the F1 exit criteria need re-examination, not the queue.
- "Close (stale)" must cite the superseding work — vague "looks old" is not enough.
