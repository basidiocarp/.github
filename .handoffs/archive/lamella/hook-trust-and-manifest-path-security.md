# Lamella: Hook Trust And Manifest Path Security

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/scripts/hooks/post-edit-format.js`, `lamella/scripts/hooks/post-edit-typecheck.js`, `lamella/resources/hooks/auto-format/auto-format.js`, `lamella/resources/hooks/hooks.json`, `lamella/resources/hooks/settings.json`, `lamella/scripts/plugins/build-plugin.sh`, `lamella/builders/build-codex-skills.sh`, `lamella/scripts/ci/validate-manifests.js`, `lamella/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no host runtime implementation and no plugin manifest format redesign unless containment cannot be expressed in the current format
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-hook-trust-and-manifest-path-security.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** hook scripts, hook manifests/settings, manifest validator, Claude/Codex builders
- **Reference seams:** existing `make validate`, manifest validation script, hook packaging fixtures
- **Spawn gate:** do not launch an implementer until the parent agent decides whether post-edit hooks should be disabled by default for untrusted repos or run with a scrubbed environment and explicit tool allowlist

## Problem

Lamella post-edit hooks run repo-controlled Node toolchains and executable formatter/typechecker configs with the inherited environment. Editing a JS/TS file in an untrusted repo can trigger local `node_modules/.bin/*`, Prettier plugins, or config code that can read API keys and shell tokens.

Lamella manifest resource paths are joined into copy sources without canonical containment checks. A borrowed or malicious manifest can use `../` entries to package files from outside `resources/` into generated plugin/export output.

Packaged inline hook configs also echo full hook payloads in source and generated manifests. That overlaps with session logger redaction, but the toolchain trust and path traversal concerns need a separate implementation scope.

## What needs doing

1. Add an explicit trust model for post-edit formatter/typecheck hooks before running repo-local Node toolchains or executable configs.
2. Minimize inherited environment for hook-spawned toolchains or require opt-in trust for secret-bearing env propagation.
3. Add regression fixtures where `prettier.config.js` attempts to read a fake API key.
4. Validate manifest resource entries by canonicalizing and checking containment under the intended content root.
5. Make builders reject traversal entries before any copy operation.
6. Ensure source and generated hook configs no longer echo raw hook payloads.

## Verification

```bash
cd lamella && make validate
bash .handoffs/lamella/verify-hook-trust-and-manifest-path-security.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] post-edit hooks do not run untrusted repo toolchains with inherited secrets
- [ ] executable formatter/typechecker configs require trust or run with scrubbed env
- [ ] manifest validation rejects `../` and absolute resource traversal
- [ ] builders reject traversal before copying files
- [ ] source/generated hook configs do not echo raw hook payloads
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 5 security and secrets audit. Severity: high/medium.
