# Low Queue Prioritization Audit Template

Classifies the dashboard's Low-priority queue against the current freeze policy / roadmap. Hygiene rather than drift, but the queue grows without active triage and umbrella handoffs go stale.

**Cadence:** once per freeze period, or whenever the roadmap shifts.
**Maps to:** dashboard hygiene; supports F1 exit criterion #5 ("no open Medium handoffs") by ensuring nothing in Low is misclassified.
**Runtime:** ~2–4 hours depending on queue depth.

---

## Handoff Metadata (instance)

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only across `.handoffs/`)
- **Allowed write scope:** `.handoffs/campaigns/<campaign-name>/findings/lane<N>-low-item-prioritization.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not modify any handoff file; does not modify the dashboard directly; does not promote/demote priorities (that's a follow-up cleanup pass)

## Classifications

For each Low-priority handoff (rows in `.handoffs/HANDOFFS.md` where `#` column is `—`), assign exactly one:

| Classification | Meaning |
|----------------|---------|
| Promote | Work that blocks an exit criterion (rare; should be Medium or High instead). |
| Keep | Relevant, scoped to an active hardening repo, still well-defined. |
| Demote / Defer | Relevant but aimed at a frozen repo or beyond the current exit. |
| Close (stale) | Superseded by recent migrations or no longer applicable. |
| Close (out-of-scope under freeze) | Net-new feature or expansion that the freeze defers. |
| Triage Required | Has "Decision Required" tag or scope unclear. |

## Method

### Step 1 — Capture the current Low queue

```bash
grep -c "^| — |" .handoffs/HANDOFFS.md  # total count
grep -E "^### |^| — |" .handoffs/HANDOFFS.md  # per-section breakdown
```

Capture:
- Total Low count
- Per-section breakdown (Cap, Stipe, Lamella, Hyphae, Cortina, etc.)

### Step 2 — Per-handoff classification

For each Low handoff:
1. Open the file. Read the scope.
2. Check against the current freeze roadmap (which repos are active vs frozen; which work is explicitly deferred).
3. Check against recent fix-phase work — was this superseded by a 2026-XX-XX commit batch?
4. Apply one classification.
5. Write a one-line justification citing either:
   - An exit criterion (1–5)
   - The active/frozen repo split
   - A specific superseding commit or migration
   - A "Decision Required" tag

### Step 3 — Stale umbrella detection

An "umbrella" handoff coordinates a child set. When all children are archived, the umbrella is stale. For each candidate umbrella in the Low queue:
- Identify its child handoffs (named in the umbrella's body or by section convention).
- Check `.handoffs/archive/<section>/` for each.
- If all children are archived, the umbrella is `Close (stale)`.

### Step 4 — Promotion calibration

Promotion candidates should be **rare**. Re-read each one and confirm it actually blocks an exit criterion. If it's labeled Promote but doesn't block, re-classify down. The point is to find F1-blocking work that was misfiled as Low, not to grade-inflate.

## Findings File Format

Write `findings/lane<N>-low-item-prioritization.md`:

```markdown
# Lane N: Low Item Prioritization Findings (YYYY-MM-DD)

## Summary
[total Low count, classification breakdown]

## Classification Table
| Handoff | Section | Classification | Justification |
|---------|---------|----------------|---------------|
| ... | ... | ... | ... |

## Promote
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

## Severity Calibration

This audit doesn't use blocker/concern/nit. Instead:
- Each row gets a definitive classification.
- The cleanup pass that follows opens specific archive/move handoffs based on the table.

## Verify Script

Pair with `verify-lane<N>-low-item-prioritization.sh`. Confirms:
- Findings file exists with required sections (Summary, Classification Table, Promote, Close (stale), Close (out-of-scope under freeze), Demote/Defer, Triage Required, Recommended Dashboard Actions)
- Classification Table has rows
- F1 freeze roadmap is referenced
- HANDOFFS.md not modified by the audit (scope discipline — this audit is read-only)

## Style Notes

- Be precise about superseding work. "Looks old" is not enough — name the commit or PR that replaced it.
- Promotion should be the smallest bucket. If many items want to promote, the exit criteria need re-examination, not the queue.
- Decision Required rows go straight to Triage Required, even if the topic is otherwise clear.
- When children of an umbrella are split between archived and active, the umbrella's classification depends on whether it adds coordination value beyond tracking the remaining child(ren). Usually it doesn't.
