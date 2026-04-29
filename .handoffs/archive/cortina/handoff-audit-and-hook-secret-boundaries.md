# Cortina: Handoff Audit And Hook Secret Boundaries

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/handoff_paths.rs`, `cortina/src/handoff_audit.rs`, `cortina/src/hooks/post_tool_use.rs`, `cortina/src/hooks/post_tool_use/`, `cortina/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no Canopy import workflow redesign and no Hyphae memory schema redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-handoff-audit-and-hook-secret-boundaries.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** handoff path extraction/audit, PostToolUse dispatcher, Bash failure capture
- **Reference seams:** `cortina/src/handoff_audit.rs`, `cortina/src/handoff_paths.rs`, `cortina/src/hooks/post_tool_use/bash.rs`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether out-of-root handoff paths should be rejected with an error or ignored as non-evidence

## Problem

Cortina handoff audit follows absolute paths extracted from handoff text. A crafted handoff can reference a sensitive path outside the workspace and use audit output as a file-existence or content oracle. Canopy invokes Cortina audit during handoff import/assignment flows, so this can be reached through coordination tooling.

Cortina PostToolUse also prints raw hook input and can store failed Bash command snippets and output into Hyphae. Commands such as `ANTHROPIC_API_KEY=... npm test` or outputs containing bearer tokens can be echoed or persisted without redaction.

## What needs doing

1. Canonicalize candidate handoff evidence paths against the workspace/repo root.
2. Reject or ignore absolute/out-of-root paths before existence checks, content reads, or matched-path reporting.
3. Add regression coverage proving audit cannot detect or read a temp secret file outside the repo.
4. Redact secret-like values from PostToolUse stdout and Bash failure capture before printing or storing.
5. Add tests with bearer tokens, `ANTHROPIC_API_KEY=...`, `OPENAI_API_KEY=...`, and password-like assignments in command and output fields.

## Verification

```bash
cd cortina && cargo test handoff_audit
cd cortina && cargo test post_tool_use
bash .handoffs/cortina/verify-handoff-audit-and-hook-secret-boundaries.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] handoff audit does not inspect paths outside the workspace/repo root
- [ ] audit output does not reveal outside-root absolute paths
- [ ] PostToolUse stdout redacts common secret patterns
- [ ] Hyphae-bound Bash failure summaries redact command and output secrets
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 5 security and secrets audit. Severity: high/medium.
