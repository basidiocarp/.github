# Lamella: Session Logger Secret Redaction

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/scripts/hooks/session-logger.js`, `lamella/resources/hooks/hooks/bash/session-logger.sh`, `lamella/resources/hooks/settings.json`, `lamella/tests/`, `lamella/scripts/ci/`, `lamella/resources/hooks/hooks.json`
- **Cross-repo edits:** none
- **Non-goals:** no hook manifest redesign and no telemetry backend
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-session-logger-secret-redaction.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** JS and shell session loggers, hook validation fixtures, settings defaults
- **Reference seams:** existing Lamella hook validation and `make validate`
- **Spawn gate:** do not launch an implementer until the parent agent identifies whether both JS and shell logger variants are still distributed

## Problem

Lamella's default session logger records Bash command snippets into JSONL logs without redaction or restrictive permission checks. Inline API keys, bearer headers, or curl tokens can be persisted under `~/.claude/logs` or `CLAUDE_LOG_DIR`.

The security audit also found packaged inline hook configs that echo complete hook payloads. If those inline hooks remain shipped, remove raw `console.log(d)` behavior or redact the payload before any stdout/log surface sees it.

## What needs doing

1. Redact common secret patterns before logging command snippets.
2. Ensure log files are created with restrictive permissions on Unix.
3. Add fixture tests for JS and shell logger variants if both are shipped.
4. Keep default logging useful without storing secrets.
5. Remove or redact packaged inline hook payload echoing in source hook configs and generated output.

## Verification

```bash
cd lamella && make validate
bash .handoffs/lamella/verify-session-logger-secret-redaction.sh
```

**Output:**
<!-- PASTE START -->
PASS: session logger redacts common secrets
PASS: session logger sets restrictive permissions
PASS: session logger remains in validation surface
Results: 3 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] Bash command snippets redact bearer tokens, API keys, and common secret assignments
- [x] log files are `0600` or equivalent on Unix
- [x] JS and shell logger behavior are consistent
- [x] packaged hook configs do not echo raw PreToolUse/PostToolUse payloads
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit and expanded by Phase 5 security audit. Severity: medium/high.
