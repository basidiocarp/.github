# Septa: Validation Tooling And Inventory

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** `septa/README.md`, `septa/CROSS-TOOL-PAYLOADS.md`, `septa/validate-all.sh`, `septa/scripts/`, `septa/fixtures/`, `ecosystem-versions.toml`
- **Cross-repo edits:** none
- **Non-goals:** no producer schema redesign and no governance model decision from `contract-governance-enforcement.md`
- **Verification contract:** run the repo-local commands below and `bash .handoffs/septa/verify-validation-tooling-and-inventory.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** `validate-all.sh`, `scripts/check-cross-tool-payloads.sh`, `README.md`, `CROSS-TOOL-PAYLOADS.md`, `ecosystem-versions.toml`
- **Reference seams:** local `$ref` registry in `validate-all.sh`, all `septa/*-v1.schema.json`, `septa/fixtures/*`
- **Spawn gate:** do not launch an implementer until the parent agent decides whether direct `check-jsonschema --schemafile ...` commands should be documented as unsupported for schemas with local `$ref`

## Spawn Gate Decision

- **Canonical validation command:** `bash validate-all.sh` — this is the only supported command for validating schemas that use local `$ref`. Document it as the primary workflow everywhere.
- **Raw `check-jsonschema` status:** explicitly unsupported for cross-ref schemas. Add a note in README that `check-jsonschema --schemafile <schema> <fixture>` will fail for schemas with `$id`-rebased local references and must not be used directly for those.
- **Single-schema debug path:** document the correct invocation with `--base-uri file:///path/to/septa/` as a debug-only option with explicit caveats about path sensitivity — not as a primary workflow.
- **Rationale:** `$ref` resolution through `https://basidiocarp.dev` is a tooling quirk; one canonical command reduces agent errors and avoids fragile path-dependent invocations.

## Problem

Septa's canonical validator passes, but the documented raw `check-jsonschema` command can fail for schemas with `$id`-rebased local references because it tries to resolve refs through `https://basidiocarp.dev`. The payload registry and README inventories also lag actual schema files, and variant fixtures are not validated by the default script. The data integrity audit also found a concrete contract ledger value drift: `workflow-template` is pinned as `1.0` in `ecosystem-versions.toml` while the actual schema/fixture/Hymenium producer use `1.1`.

The docs drift audit confirmed the inventory gap with current missing registry entries including `context-envelope-v1`, `credential-v1`, `dependency-types-v1`, and `task-output-v1`, plus README omissions such as `annulus-statusline-v1`, `cortina-audit-handoff-v1`, and `host-identifier-v1`.

## What needs doing

1. Update README validation instructions so developers use the local registry path for cross-file `$ref` schemas.
2. Fix `CROSS-TOOL-PAYLOADS.md` or its checker so registered contracts match the actual schema inventory.
3. Update README and `ecosystem-versions.toml` contract inventories to include all current schemas.
4. Extend `validate-all.sh` to validate variant fixtures such as `.full.json`, `.degraded.json`, and `.flagged.json`.
5. Add a check that contract ledger values match schema/fixture `schema_version` values where those values are literal version strings.
6. Keep this handoff separate from the broader governance decision about detecting unseamed payloads.

## Scope

- **Primary seam:** Septa validation and inventory tooling
- **Allowed files:** Septa docs/scripts/fixtures and root version ledger
- **Explicit non-goals:** no producer payload redesign, no schema-first enforcement model

## Verification

```bash
cd septa && bash validate-all.sh
cd septa && bash scripts/check-cross-tool-payloads.sh
bash .handoffs/septa/verify-validation-tooling-and-inventory.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] README validation commands work offline for cross-file `$ref` schemas
- [ ] `CROSS-TOOL-PAYLOADS.md` checker passes
- [ ] README inventory matches schema files
- [ ] known missing contracts from the docs drift audit are listed or intentionally excluded with rationale
- [ ] `ecosystem-versions.toml` contract ledger matches schema files
- [ ] `workflow-template` and similar literal contract versions match schema/fixture versions
- [ ] variant fixtures are included in default validation
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the Phase 1 contract round-trip audit in the sequential audit hardening campaign and expanded by Phase 7 docs drift audit. Severity: high/medium for tooling reliability.
