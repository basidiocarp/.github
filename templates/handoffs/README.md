# Handoff Templates

These templates support operational planning and session continuity. They are not stakeholder reports; those live under `templates/reports/`.

## Templates

- `WORK-ITEM-TEMPLATE.md`: active handoff with verification gates, seam table, Review Record, and disposition vocabulary (the canonical flat format)
- `ENVELOPE-TEMPLATE/`: directory envelope for complex handoffs (`handoff.md` + `verify.sh` + `evidence/` + optional `contracts/`); see its README for when to prefer it over flat
- `SEAM-PASS-CHECKLIST.md`: recurring-finding checklist run during every seam pass — the durable sink for lessons promoted out of individual handoffs
- `SESSION-NOTE-TEMPLATE.md`: short resume note for a later session
- `CAMPAIGN-README-TEMPLATE.md`: top-level README for a multi-step campaign folder

## How to use them

1. Pick the template that matches the artifact you are creating.
2. Copy it into the right live folder.
3. Fill in real details, not placeholders padded into prose.
4. Link to related handoffs, campaigns, or reports instead of duplicating the same context.
