# Cross-Project Unified Output Principles

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

Before adding new code surfaces, the ecosystem needs a short architectural document
that states the rule: one aggregation path, many renderers. Without that, Annulus
and Cap will drift again.

## What needs doing

Add `docs/architecture/unified-output-aggregation.md` describing:

- one aggregation path
- multiple rendering surfaces
- late rendering
- graceful degradation
- which tools are data sources
- why Annulus is the operator-facing aggregation host

Keep this handoff documentation-only. Do not modify Annulus or Cap code here.

## Files to modify

- `docs/architecture/unified-output-aggregation.md`
- `docs/architecture/README.md` or nearby index if needed

## Verification

```bash
ls docs/architecture/unified-output-aggregation.md
bash .handoffs/cross-project/verify-unified-output-principles.sh
```

## Checklist

- [ ] architecture doc exists
- [ ] the four principles are named explicitly
- [ ] data sources and consumers are listed
- [ ] the doc is linked from an architecture index if one exists
- [ ] verify script passes with `Results: N passed, 0 failed`
