# Cortina: Compact Summary Artifact Integrity

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/hooks/pre_compact.rs`, `cortina/src/utils/hyphae_client.rs`, `cortina/tests/`
- **Cross-repo edits:** `hyphae/` only if a CLI artifact-store surface is required and does not exist
- **Non-goals:** no general Hyphae artifact model redesign and no pre-compact trigger redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-compact-summary-artifact-integrity.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** pre-compact hook payload, Hyphae client command construction, artifact-store tests
- **Reference seams:** Hyphae `hyphae_artifact_store` MCP tool and `artifacts` table
- **Spawn gate:** do not launch an implementer until the parent agent confirms whether Cortina should call Hyphae MCP or a CLI artifact-store command

## Problem

Cortina compact summary "artifacts" are stored as ordinary Hyphae memories. Typed artifact queries miss them, and repeated pre-compact events can create memory duplicates instead of stable artifact records keyed by session/source identity.

## What needs doing

1. Store compact summaries through Hyphae's typed artifact path with `artifact_type=compact_summary`.
2. Include project and `source_id=session_id` or equivalent stable identity.
3. Add command-construction tests in Cortina and query tests in Hyphae if needed.

## Verification

```bash
cd cortina && cargo test pre_compact hyphae_client
cd hyphae && cargo test -p hyphae-mcp artifact
bash .handoffs/cortina/verify-compact-summary-artifact-integrity.sh
```

**Output:**
<!-- PASTE START -->
PASS: Cortina compact/Hyphae client tests run
PASS: Hyphae artifact tests run
PASS: compact summary uses artifact identity
Results: 3 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] compact summaries are stored as typed artifacts, not only memories
- [x] artifact identity includes project and stable session/source id
- [x] repeated pre-compact events do not create ambiguous duplicates
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: medium.
