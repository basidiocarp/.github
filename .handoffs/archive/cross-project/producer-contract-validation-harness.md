# Cross-Project: Producer Contract Validation Harness

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `septa/scripts/`, `septa/README.md`, `cap/server/__tests__/`, repo-local contract tests in producer repos, `.handoffs/`
- **Cross-repo edits:** producer test files only for contract harness adoption
- **Non-goals:** no schema redesign and no producer payload behavior changes except test adapters/fixtures
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-producer-contract-validation-harness.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `septa` plus producer repos
- **Likely files/modules:** local `$ref` schema validator helper, Cap contract E2E tests, producer serializer tests
- **Reference seams:** `septa/validate-all.sh`, Cap Hyphae/Mycelium contract E2E tests, Phase 1 contract drift handoffs
- **Spawn gate:** do not launch an implementer until the parent agent chooses the first producer surfaces to onboard

## Problem

Septa currently proves fixture/schema agreement, but most tests do not prove real producer output validates against Septa and then parses through the real consumer. Some Cap contract E2E tests run real binaries, but they assert adapter behavior rather than JSON Schema validation against the shared local registry.

## What needs doing

1. Extract a reusable validator that can validate arbitrary JSON files or captured stdout with Septa's local `$ref` registry.
2. Add a small harness pattern: produce real JSON, validate against Septa, then pass the same JSON through the consumer parser.
3. Onboard the highest-risk Phase 1 surfaces first: Canopy task/snapshot/status, Hyphae read/archive, Mycelium gain/summary, Cortina session/usage, Volva hook event.
4. Document how producer repos add contract tests without raw network-sensitive `check-jsonschema` calls.

## Verification

```bash
cd septa && bash validate-all.sh
cd septa && bash scripts/check-cross-tool-payloads.sh
bash .handoffs/cross-project/verify-producer-contract-validation-harness.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] a reusable local-registry validator exists for captured producer output
- [ ] at least one real producer output per initial surface validates against Septa
- [ ] consumers parse the same validated payloads
- [ ] docs tell developers not to use raw network-sensitive schema validation for `$ref` schemas
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 3 verification quality audit. This complements A16 by proving real producer behavior, not only fixture inventory.
