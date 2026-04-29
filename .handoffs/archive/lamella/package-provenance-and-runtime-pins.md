# Lamella: Package Provenance And Runtime Pins

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/resources/`, `lamella/manifests/`, `lamella/.claude-plugin/marketplace.json`, `lamella/lamella`, `lamella/scripts/ci/`, `lamella/scripts/plugins/build-plugin.sh`, `lamella/builders/build-codex-skills.sh`, `lamella/scripts/maintenance/zip-skills.sh`, `lamella/.github/workflows/`, `lamella/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no content rewrite except attribution/provenance metadata and no host installer implementation
- **Verification contract:** run the commands below and `bash .handoffs/lamella/verify-package-provenance-and-runtime-pins.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** manifest validators, marketplace catalog builder/validator, packaged MCP configs/hooks, vendored examples, release workflows
- **Reference seams:** `validate-marketplace-catalog.js`, `validate-manifests.js`, `validate-skill-packages.js`, plugin builders
- **Spawn gate:** do not launch an implementer until the parent agent decides whether marketplace entries should use immutable release tags, commit SHAs, or branch refs plus artifact digests

## Problem

Lamella packages third-party or adapted content without enforceable provenance and license carry-through. Examples include YARA rules adapted from external sources and copied Ansible role content packaged under plugin-level license claims. Validators currently check shape but do not validate bundled asset licenses, notices, or provenance metadata.

Lamella also ships runtime configs that execute unpinned package-manager specs such as `npx -y`, `@latest`, and mutable MCP/statusline packages, while its own integrity hook warns against that pattern. Marketplace catalog entries point at the mutable `gh-pages` branch and plugin metadata lacks content digest/source commit fields. Some packaged templates use mutable third-party container tags such as `:latest`, and the skill zip helper appears to target the wrong source directory while emitting unsigned zips.

## What needs doing

1. Add per-skill or per-asset provenance metadata for copied/adapted third-party content.
2. Require NOTICE/license carry-through for vendored examples and validate plugin license claims against bundled assets.
3. Pin packaged MCP/statusline package specs or mark them as example-only and non-installable.
4. Make validation fail on installable `@latest`, unpinned `npx -y`, `bunx`, `pnpm dlx`, or equivalent mutable runtime package execution.
5. Add immutable marketplace/package provenance: source commit, release tag, artifact digest, or signed/attested catalog metadata.
6. Pin or placeholder mutable container tags in shipped templates.
7. Fix or retire `scripts/maintenance/zip-skills.sh`; if kept, emit manifests and SHA-256 files for generated zips.

## Verification

```bash
cd lamella && node scripts/ci/validate-marketplace-catalog.js
cd lamella && node scripts/ci/validate-manifests.js
cd lamella && node scripts/ci/validate-skill-packages.js
cd lamella && make validate
bash .handoffs/lamella/verify-package-provenance-and-runtime-pins.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] vendored/adapted assets have provenance and license metadata
- [ ] plugin license claims do not mask bundled third-party license obligations
- [ ] installable runtime configs do not use unpinned `@latest` or `npx -y`
- [ ] marketplace/plugin metadata includes immutable source or digest provenance
- [ ] shipped templates do not use mutable third-party execution tags by default
- [ ] zip helper is corrected, retired, or emits signed/digested artifacts
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 6 dependency and supply-chain audit. Severity: high/medium.
