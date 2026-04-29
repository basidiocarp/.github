# Cross-Project: Dashboard Low Queue Cleanup (Lane 3)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root
- **Allowed write scope:**
  - `.handoffs/HANDOFFS.md` (the dashboard)
  - `.handoffs/<section>/<umbrella>.md` for each umbrella being closed (move to `.handoffs/archive/<section>/`)
  - `.handoffs/archive/<section>/` for the moved files
- **Cross-repo edits:** none — pure dashboard hygiene
- **Non-goals:** does not modify any active handoff content; does not touch the Decision Required handoffs (those are operator gates); does not promote anything (lane 3 said no promotions); does not classify the 19 demote/defer items beyond what lane 3 already classified
- **Verification contract:** `bash .handoffs/cross-project/verify-dashboard-low-queue-cleanup.sh`
- **Completion update:** Stage 1 + Stage 2 → commit; this handoff archives itself when done

## Implementation Seam

- **Likely files/modules:**
  - `.handoffs/HANDOFFS.md` — the active dashboard
  - The 7 stale umbrella handoff files (paths from lane 3 findings)
  - `.handoffs/archive/<section>/` — destination for archived umbrellas
- **Reference seams:** lane 3 findings file at `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane3-low-item-prioritization.md` — sections "Close (stale)" and "Classification Table"
- **Spawn gate:** locations are precise; can dispatch directly

## Problem

Lane 3 of the post-execution boundary audit classified the 36 Low-priority handoffs against the F1 freeze policy. Two cleanup actions were identified:

1. **7 stale umbrellas** — handoffs whose child handoffs are already archived. The umbrella entries occupy dashboard rows but coordinate nothing. Close them.
2. **1 misfile** — `Cap: Operator Surface Socket Endpoints` is currently listed in the Canopy section of the dashboard but is a cap-owned handoff. Move the row to the Cap section.

The 7 stale umbrellas (per lane 3 §Close (stale)):

1. `cap/service-health-panel.md`
2. `hyphae/memory-use-protocol.md`
3. `hyphae/structured-export-archive.md`
4. `cross-project/cache-friendly-context-layout.md`
5. `cross-project/graceful-degradation-classification.md`
6. `cross-project/lamella-cortina-boundary-phase2.md`
7. `cross-project/summary-detail-on-demand.md`

The 19 Demote/Defer items, 7 Close-under-freeze items, and 3 Triage items are NOT touched by this handoff — they are correctly classified as Low and either await freeze lift or operator decision; lane 3's finding was that no further dashboard action is required for them today.

## Scope

- **Primary seam:** the dashboard's Low queue
- **Allowed files:** see Handoff Metadata
- **Explicit non-goals:**
  - Touching the 19 Demote/Defer rows
  - Touching the 7 Close-under-freeze rows (lane 3 noted these "are not cancelled; they move when the freeze lifts" — they should remain on the dashboard for visibility)
  - Touching the 3 Triage Required handoffs
  - Modifying handoff content beyond moving the file
  - Renaming or refactoring the dashboard structure

---

### Step 1: Archive the 7 stale umbrellas

**Project:** workspace root
**Effort:** small

For each of the 7 paths above, move the file from `.handoffs/<section>/<umbrella>.md` to `.handoffs/archive/<section>/<umbrella>.md`. Use `git mv` so history is preserved (this directory is gitignored at the workspace root, so use `git mv -f` if needed, or fall back to `mv` if git refuses).

If a paired verify script exists for any umbrella (`verify-<umbrella>.sh`), archive it alongside.

```bash
cd /Users/williamnewton/projects/personal/basidiocarp/.handoffs

# Repeat per umbrella
mkdir -p archive/cap archive/hyphae archive/cross-project
mv cap/service-health-panel.md archive/cap/ 2>&1 || echo "skip"
mv hyphae/memory-use-protocol.md archive/hyphae/ 2>&1 || echo "skip"
mv hyphae/structured-export-archive.md archive/hyphae/ 2>&1 || echo "skip"
mv cross-project/cache-friendly-context-layout.md archive/cross-project/ 2>&1 || echo "skip"
mv cross-project/graceful-degradation-classification.md archive/cross-project/ 2>&1 || echo "skip"
mv cross-project/lamella-cortina-boundary-phase2.md archive/cross-project/ 2>&1 || echo "skip"
mv cross-project/summary-detail-on-demand.md archive/cross-project/ 2>&1 || echo "skip"
```

Confirm each destination file exists.

#### Verification

```bash
ls /Users/williamnewton/projects/personal/basidiocarp/.handoffs/archive/cap/service-health-panel.md
ls /Users/williamnewton/projects/personal/basidiocarp/.handoffs/archive/hyphae/memory-use-protocol.md
ls /Users/williamnewton/projects/personal/basidiocarp/.handoffs/archive/hyphae/structured-export-archive.md
ls /Users/williamnewton/projects/personal/basidiocarp/.handoffs/archive/cross-project/cache-friendly-context-layout.md
ls /Users/williamnewton/projects/personal/basidiocarp/.handoffs/archive/cross-project/graceful-degradation-classification.md
ls /Users/williamnewton/projects/personal/basidiocarp/.handoffs/archive/cross-project/lamella-cortina-boundary-phase2.md
ls /Users/williamnewton/projects/personal/basidiocarp/.handoffs/archive/cross-project/summary-detail-on-demand.md
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All 7 files moved to archive
- [ ] No broken paths (originals are gone)

---

### Step 2: Remove the 7 rows from `.handoffs/HANDOFFS.md`

**Project:** workspace root
**Effort:** small

Find each row in `HANDOFFS.md` and delete it. For each row, the link path was `<section>/<umbrella>.md`; the row will look something like:

```
| — | [Cap: Service Health Panel](cap/service-health-panel.md) | Low | ... |
```

Delete the entire line for each of the 7 umbrellas.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -nE "service-health-panel\.md|memory-use-protocol\.md|structured-export-archive\.md|cache-friendly-context-layout\.md|graceful-degradation-classification\.md|lamella-cortina-boundary-phase2\.md|summary-detail-on-demand\.md" .handoffs/HANDOFFS.md)
```

This should print nothing.

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All 7 rows removed from HANDOFFS.md
- [ ] No collateral row deletions

---

### Step 3: Move the misfiled "Cap: Operator Surface Socket Endpoints" row from Canopy to Cap section

**Project:** workspace root
**Effort:** trivial

Find the row in HANDOFFS.md:

```
| — | [Cap: Operator Surface Socket Endpoints](cap/operator-surface-socket-endpoints.md) | Low | Migrate cap backend from CLI spawning to socket endpoints; blocked on sibling tool endpoint registration |
```

It's currently under the Canopy section. Move it to the Cap section (insert near the other Cap rows; preserve its priority `—` and the link unchanged).

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && awk '/^### Cap$/,/^---$/' .handoffs/HANDOFFS.md | grep -c "operator-surface-socket-endpoints")
(cd /Users/williamnewton/projects/personal/basidiocarp && awk '/^### Canopy$/,/^---$/' .handoffs/HANDOFFS.md | grep -c "operator-surface-socket-endpoints")
```

The first command should print `1`. The second should print `0`.

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Row appears under Cap section exactly once
- [ ] Row no longer appears under Canopy section
- [ ] Link path unchanged (still `cap/operator-surface-socket-endpoints.md`)

---

### Step 4: Sanity-check the dashboard

**Project:** workspace root
**Effort:** trivial

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -c "^| — |" .handoffs/HANDOFFS.md)
```

Lane 3 said the original Low count was 36. After 7 closures, the count should be 29.

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Low count is 29 (or document any discrepancy)

---

## Completion Protocol

1. All steps verified
2. `bash .handoffs/cross-project/verify-dashboard-low-queue-cleanup.sh` passes
3. Stage 1 + Stage 2 pass
4. Commit (`.handoffs/HANDOFFS.md` + the 7 archive moves)

### Final Verification

```bash
bash .handoffs/cross-project/verify-dashboard-low-queue-cleanup.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Closes the dashboard cleanup actions identified by lane 3 of the post-execution boundary compliance audit. ~20% of the Low queue was dead weight (umbrella entries whose children were already archived). Reduces dashboard noise without touching the underlying classification work.

## Style Notes

- Don't second-guess lane 3's classification. The 7 umbrellas have been verified as orphans; close them.
- Don't archive the misfiled `Cap: Operator Surface Socket Endpoints` — it's an active handoff in the wrong section. Move, don't archive.
- Don't update the campaign README or this handoff itself — the parent agent updates those after Stage 2.
