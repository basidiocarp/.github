# Hymenium: Read-Only Audit Packet Quality

<!-- Save as: .handoffs/hymenium/read-only-audit-packet-quality.md -->
<!-- Create verify script: .handoffs/hymenium/verify-read-only-audit-packet-quality.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/dispatch/orchestrate.rs`, `hymenium/src/dispatch/task_packet.rs`, `hymenium/src/parser/`, `hymenium/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no parser heading normalization and no Canopy storage changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hymenium/verify-read-only-audit-packet-quality.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hymenium`
- **Likely files/modules:** task packet builder, constraint extraction, title generation, capability requirements
- **Reference seams:** `build_constraints`, `build_acceptance_criteria`, `TaskPacket`, CentralCommand dogfood task JSON
- **Spawn gate:** do not launch an implementer until the parent agent identifies the exact packet fields expected for read-only audit work

## Spawn Gate Decision

- **Title format:** `"[{role}] {phase_id} — {handoff_title}"`. Example: `"[implementer] implement — Hymenium Parser Refactor"`.
- **Non-goals:** stop splitting on commas. Change the parser to store the full non-goals string as a single item (`vec![value.trim().to_string()]`), not `split_list`. A sentence like `"no foo, bar, or baz"` must stay intact.
- **Write capability:** derive from `allowed_write_scope`. If any path contains source patterns (`src/`, `.rs`, `.ts`, `.py`, `lib/`) → include `"write"`. Otherwise use `["bash", "read"]` only. This correctly marks read-only audit tasks as source-read-only.
- **Artifact write note:** when write scope is present, add a constraint `"Artifact write scope: <paths>"` so workers know the exact write boundary.

## Problem

The dogfood task packet was mechanically correct but low quality. It generated a generic title, split non-goals on commas into awkward constraints, and requested broad `write` capability even though source code was read-only and only audit artifacts were writable.

Poor task packets make workers easier to misdirect and make review harder.

## What exists (state)

- **Title:** Canopy task title looked like `[implementer] implement`
- **Constraints:** non-goals were split into fragments such as `migrations` and `or remediation steps`
- **Capabilities:** read-only audit tasks still advertised `write`

## What needs doing (intent)

Generate task packets that reflect the actual handoff semantics: meaningful titles, intact non-goals, clear source-vs-artifact write boundaries, and minimal tool requirements.

## Scope

- **Primary seam:** Hymenium task packet construction
- **Allowed files:** task packet builder, dispatch orchestration, parser metadata if needed, tests
- **Explicit non-goals:** no task execution runtime, no phase reconciliation, no CentralCommand report generation

## Verification

```bash
cd hymenium && cargo test task_packet
cd hymenium && cargo test dispatch
bash .handoffs/hymenium/verify-read-only-audit-packet-quality.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] task titles include handoff title and phase purpose
- [ ] non-goals remain intact as authored sentences or list items
- [ ] read-only source scope does not imply broad source write authority
- [ ] artifact write scope is explicit when report or verify-script writes are allowed
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run. This improves worker packet clarity after the dispatch path itself is stable.

