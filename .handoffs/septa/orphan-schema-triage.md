# Septa: Orphan Schema Triage (F2.10)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:**
  - `septa/<orphan>.schema.json` for any schemas the triage decides to delete or mark draft
  - `septa/fixtures/<orphan>.*.json` (delete with the schema if the schema is removed)
  - `septa/integration-patterns.md` (remove rows if rows exist for deleted schemas)
  - `septa/README.md` (refresh contract inventory if it lists orphan counts)
  - **NEW**: `septa/draft/` directory may be created if "mark draft" is the chosen disposition for any schema
  - **REPORT**: `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-orphan-triage-decisions.md` — the per-schema triage decision report
- **Cross-repo edits:** none — schemas are self-contained in septa
- **Non-goals:** does not land producers or consumers for orphans (that's separate per-schema work, deferred); does not modify cap, cortina, hyphae, or any other repo
- **Verification contract:** `bash .handoffs/septa/verify-orphan-schema-triage.sh`
- **Completion update:** Stage 1 + Stage 2 → commit → dashboard

## Implementation Seam

- **Likely files/modules:** the 12 orphan schemas listed in lane 2 findings:
  - `context-envelope-v1`
  - `credential-v1`
  - `degradation-tier-v1`
  - `dependency-types-v1`
  - `handoff-context-v1`
  - `hook-execution-v1`
  - `host-identifier-v1`
  - `local-service-endpoint-v1`
  - `mycelium-summary-v1`
  - `resolved-status-customization-v1`
  - `tool-relevance-rules-v1`
  - `task-output-v1`
- **Reference seams:**
  - Lane 2 findings: `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-septa-contract-accuracy.md` (search for "F2.10")
  - F1 freeze roadmap: `docs/foundations/core-hardening-freeze-roadmap.md` (active vs frozen repos — frozen-repo orphans are higher-confidence "delete or draft" because their producers/consumers are explicitly deferred)
- **Spawn gate:** locations are precise; can dispatch directly

## Problem

Twelve schemas in `septa/` have no first-party producer or consumer in the workspace per lane 2's code search. They pass `validate-all.sh` via fixtures alone, hiding rot — fixtures may not match what producers/consumers eventually need. Each one needs a triage decision: **delete**, **mark draft**, or **keep + plan to land producer/consumer**.

## What exists (state)

- 12 orphan schemas (per lane 2 findings)
- Each has at least one fixture that validates against it
- Some may be aspirational designs that pre-dated their producer; others may have had producers/consumers that were later removed
- F1 freeze roadmap explicitly defers new producer/consumer work in some areas (e.g. volva, lamella) — schemas tied to those areas are likely "draft until freeze lifts"

## What needs doing (intent)

For each of the 12 orphan schemas:

1. Investigate **why** it's orphan (read the schema description; grep for any partial usage; check git log for original commit context)
2. Choose one of three dispositions:
   - **Delete** — schema is dead, no producer or consumer is coming, fixture has no value
   - **Mark draft** — schema is intentional but producer/consumer is deferred (e.g. behind F1 freeze); move to `septa/draft/<schema>.schema.json` so it doesn't pollute `validate-all.sh`'s active set, and add a one-line note in `septa/integration-patterns.md` documenting the deferral
   - **Keep + plan** — producer/consumer is missed by the lane 2 grep but actually exists, OR a new producer/consumer is being landed soon; produce a short justification and leave the schema in place
3. Apply the chosen action
4. Produce a per-schema decision report at `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-orphan-triage-decisions.md` so future audits can see the reasoning

## Scope

- **Primary seam:** the orphan schemas themselves and their integration-patterns rows (if any)
- **Allowed files:** see Handoff Metadata
- **Explicit non-goals:**
  - Landing any producer or consumer
  - Touching schemas that aren't in the orphan list
  - Modifying `validate-all.sh` (if "mark draft" requires excluding `draft/` from validation, do that as a minimal scope-creep edit ONLY if the implementer concludes it's necessary)

---

### Step 1: Per-schema investigation

**Project:** workspace root (read-only)
**Effort:** medium

For each of the 12 schemas:

```bash
SCHEMA=context-envelope-v1   # repeat per schema
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && jq '.description' "$SCHEMA.schema.json")
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && git log --oneline -5 "$SCHEMA.schema.json")
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -rE "$SCHEMA|$(echo "$SCHEMA" | sed 's/-v1//')" --include="*.rs" --include="*.ts" -l 2>/dev/null | head)
```

Capture for each:
- Stated purpose (description)
- Original landing commit message (intent)
- Any partial uses in code (lane 2 may have missed some — try varied search terms: schema name with and without version suffix, `$id` URL, top-level type name)
- Whether the schema is named in F1 deferred-work or active-hardening context

**Output:** capture per-schema notes in the decision report.

#### Verification

```bash
test -f /Users/williamnewton/projects/personal/basidiocarp/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-orphan-triage-decisions.md && echo "report exists"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All 12 schemas investigated
- [ ] Per-schema notes captured

---

### Step 2: Apply dispositions

**Project:** `septa/`
**Effort:** small to medium (depends on how many "delete" or "mark draft" decisions land)

Per schema:

- **Delete**: `git rm <schema>.schema.json` and any matching `fixtures/<schema>*.json`. Remove any row in `septa/integration-patterns.md` that references it.
- **Mark draft**: `mkdir -p septa/draft/` and `git mv <schema>.schema.json draft/`. Move fixtures the same way (or delete them — fixtures for draft schemas are optional). Add a one-line note in `septa/integration-patterns.md` under a new "Drafts (deferred)" section listing each draft schema with a short justification.
- **Keep + plan**: leave files in place; document the missed producer/consumer in the decision report.

If "mark draft" is chosen for any schema, the implementer should consider whether `validate-all.sh` should skip the `draft/` directory. Inspect `septa/validate-all.sh` to confirm — it currently does `schema_dir.glob("*.schema.json")` which won't recurse into `draft/`, so the move alone should be sufficient. If recursive globbing is observed, leave a note in the decision report and do NOT modify the validator (out of scope).

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && bash validate-all.sh 2>&1 | tail -3)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `validate-all.sh` still exits 0
- [ ] All 12 schemas have a disposition applied
- [ ] If "delete", schema and fixtures are gone
- [ ] If "mark draft", schema is in `septa/draft/` and integration-patterns.md notes the deferral
- [ ] If "keep + plan", report explains why

---

### Step 3: Update integration-patterns.md as needed

**Project:** `septa/`
**Effort:** small

Remove rows for deleted schemas. Add a "Drafts (deferred)" subsection if any schemas were marked draft. Don't reorder existing rows.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && git diff --stat integration-patterns.md)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Rows removed for deleted schemas (none orphaned in the table)
- [ ] Drafts section added if any schemas marked draft
- [ ] No unrelated edits

---

### Step 4: Write the decision report

**Project:** `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/`
**Effort:** small

Write `lane2-orphan-triage-decisions.md` with this structure:

```markdown
# Lane 2: Orphan Schema Triage Decisions (2026-04-29)

## Summary

[counts by disposition: deleted, marked draft, kept]

## Per-Schema Decisions

### context-envelope-v1 — disposition: [delete | draft | keep]
- **Description:** [from schema]
- **Original intent:** [from git log]
- **Investigation:** [what searches found, missed producers/consumers if any]
- **Decision rationale:** [why this disposition]
- **Action taken:** [delete / mv to draft / keep]

[repeat for all 12]

## Follow-up Handoffs

[for each "keep + plan" entry, name the producer/consumer handoff that should land next]
```

#### Verification

```bash
wc -l /Users/williamnewton/projects/personal/basidiocarp/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-orphan-triage-decisions.md
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All 12 schemas have a per-schema entry
- [ ] Each entry has all 5 sub-bullets (description, intent, investigation, rationale, action)
- [ ] Summary count totals to 12

---

## Completion Protocol

1. All steps verified
2. `bash .handoffs/septa/verify-orphan-schema-triage.sh` passes
3. Stage 1 + Stage 2 pass
4. Commit + dashboard

### Final Verification

```bash
bash .handoffs/septa/verify-orphan-schema-triage.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Closes lane 2 concern F2.10 from the post-execution boundary compliance audit. The 12 orphan schemas were identified by lane 2's grep across cap/canopy/cortina/hyphae/hymenium/mycelium/volva/spore/stipe/annulus/lamella for any reference to the schema name, $id, or top-level type. The triage may discover that some references were missed; that's fine — those schemas land in "keep + plan" with a note about how the grep missed them.

## Style Notes

- Bias toward "mark draft" over "delete" when the schema's intent is clearly aspirational and tied to a roadmap area (e.g. `volva-*-v1`, `local-service-endpoint-v1`).
- Bias toward "delete" when the schema appears to be a dead architectural sketch with no path to land.
- "Keep + plan" requires naming a specific follow-up handoff. If the report can't name one, the disposition isn't actually "keep + plan" — re-classify to draft.
- Keep the decision report concise — one screen per schema is enough.
