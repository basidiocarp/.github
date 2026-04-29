# Stipe: Installed Binary Freshness

<!-- Save as: .handoffs/stipe/installed-binary-freshness.md -->
<!-- Create verify script: .handoffs/stipe/verify-installed-binary-freshness.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/doctor/`, `stipe/src/commands/tool_registry/`, `stipe/src/commands/update/`, `stipe/README.md`, `docs/getting-started/`, `docs/operate/`, `stipe/tests/`
- **Cross-repo edits:** workspace docs only
- **Non-goals:** no release provenance implementation and no Hymenium dispatch code changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/stipe/verify-installed-binary-freshness.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** doctor tool checks, tool registry probe/version handling, update/install guidance, operator docs
- **Reference seams:** `tool_registry::probe_with_level`, doctor version drift checks, `ecosystem-versions.toml`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether freshness compares against version pins, source build metadata, or both

## Problem

The dogfood run used a stale installed `hymenium` binary, so the operator had to run from source with `cargo run --manifest-path`. Stipe should make that drift visible before dogfood runs, especially for full-stack tools such as Hymenium and Canopy.

## What exists (state)

- **Doctor:** already has tool probing and some version drift logic
- **Registry:** knows managed tools and install profiles
- **Docs:** describe install/update surfaces but do not give a focused "source vs installed binary is stale" dogfood check

## What needs doing (intent)

Add a freshness check or explicit doctor/update guidance that catches stale installed ecosystem binaries and points the operator at the right update/source-run command.

## Scope

- **Primary seam:** Stipe doctor/update freshness reporting
- **Allowed files:** doctor checks, tool registry, update/install docs and tests
- **Explicit non-goals:** no checksum/provenance verification, no self-update redesign, no Hymenium code changes

## Verification

```bash
cd stipe && cargo test doctor tool_registry update
cd stipe && cargo run -- doctor --developer
bash .handoffs/stipe/verify-installed-binary-freshness.sh
```

**Output:**
<!-- PASTE START -->
PASS: doctor tests pass
PASS: tool_registry tests pass
PASS: hymenium version pin present
PASS: canopy version pin present
PASS: stipe update repair action surfaced on drift
Results: 5 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] doctor reports stale or mismatched installed versions for managed tools
- [x] Hymenium and Canopy are included in the freshness surface
- [x] operator guidance distinguishes installed binary use from source `cargo run`
- [x] tests cover a stale installed binary case
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 CentralCommand dogfood run. This belongs in Stipe because it owns install, update, doctor, and repair guidance.

