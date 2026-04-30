# Cross-Project: Hyphae recall→search Doc Fix (Lane 1 concern)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (`.handoffs/`, `templates/`, possibly `CLAUDE.md`)
- **Allowed write scope:** workspace docs that incorrectly invoke `hyphae memory recall`
- **Cross-repo edits:** none — hyphae source is correct
- **Non-goals:** does not change hyphae's actual CLI; does not rename anything in hyphae
- **Verification contract:** `bash .handoffs/cross-project/verify-hyphae-recall-vs-search-doc-fix.sh`
- **Completion update:** Stage 1 + Stage 2 review pass → commit → dashboard

## Problem

Lane 1 of the 2026-04-30 audit found that some workspace handoff docs and audit templates invoke `hyphae memory recall --query …` — but that subcommand does not exist in the current hyphae CLI. The actual recall surface is `hyphae search --query …`.

This is doc drift: the docs are wrong; the CLI is right. Agents executing the docs verbatim will hit `unrecognized subcommand 'recall'` and waste time diagnosing.

## Step 1 — Find every occurrence

```bash
grep -rnE "hyphae memory recall" /Users/williamnewton/projects/personal/basidiocarp/
```

Likely hits:
- `.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/lane1-end-to-end-smoke.md`
- `templates/audits/end-to-end-smoke-audit.md`
- possibly `CLAUDE.md`, `~/.claude/rules/hyphae-context.md`, or per-repo CLAUDE.md files

## Step 2 — Replace

For each occurrence, replace `hyphae memory recall` with `hyphae search`. Confirm the surrounding flag list still makes sense (`--query`, `--limit`, etc. are valid for `search`; `--topic` may need adjustment).

If the doc is a template, also fix the template so future copies don't regenerate the drift.

## Step 3 — Sanity-check

```bash
hyphae search --help 2>&1 | head -20
```

Confirm the flags used in the corrected docs all exist on `hyphae search`.

## Verify Script

`bash .handoffs/cross-project/verify-hyphae-recall-vs-search-doc-fix.sh` confirms:
- No remaining occurrences of `hyphae memory recall` in workspace docs
- `hyphae search` references appear (sanity)

## Context

Closes the lane 1 concern about hyphae handoff command drift.
