# Mycelium: Input Size Boundaries

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/fileops/read_cmd.rs`, `mycelium/src/fileops/diff_cmd.rs`, `mycelium/src/json_cmd.rs`, `mycelium/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no output format redesign and no Hyphae storage protocol changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/mycelium/verify-input-size-boundaries.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** read/diff/json command input readers and tests
- **Reference seams:** existing truncation/output cleanliness controls
- **Spawn gate:** do not launch an implementer until the parent agent chooses default byte limits for file, stdin, and JSON inputs

## Problem

Mycelium's public CLI reads whole files and stdin into memory before truncation, parsing, or output shaping. Large piped output, large files, or large JSON can create memory pressure before the tool's output-cleanliness safeguards apply.

## What needs doing

1. Add configurable byte limits for file and stdin reads in `read`, `diff`, and JSON commands.
2. Fail with clear diagnostics before reading/parsing oversized inputs.
3. Preserve explicit override behavior for trusted large inputs if needed.
4. Add tests for oversized stdin/files across read, diff, and JSON paths.

## Verification

```bash
cd mycelium && cargo test read_stdin_rejects_oversized_input json_stdin_rejects_oversized_input diff_stdin_rejects_oversized_input
bash .handoffs/mycelium/verify-input-size-boundaries.sh
```

**Output:**
<!-- PASTE START -->
PASS: read command has input limits
PASS: diff command has input limits
PASS: json command has input limits before parse
PASS: read command size boundary tests exist and pass
PASS: diff command size boundary tests exist and pass
PASS: json command size boundary tests exist and pass
Results: 6 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] read command rejects oversized files/stdin before full processing
- [x] diff command rejects oversized files/stdin before full processing
- [x] JSON command rejects oversized input before full parse
- [x] operators can intentionally override limits if that is the chosen UX
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit. Severity: medium.
