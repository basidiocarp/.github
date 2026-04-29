# Phase 3 Summary: Verification Quality Audit

**Status:** consolidated into active handoffs

## New Handoffs

- `cross-project/verification-command-and-script-hardening.md`: weak scripts, cwd-unsafe command blocks, dashboard hygiene, missing paired scripts, and CI parity docs.
- `cross-project/producer-contract-validation-harness.md`: real producer output should validate against Septa and then parse through real consumers.
- `cap/server-and-ui-verification-hardening.md`: malformed write payloads, Septa-backed Cap consumer tests, and UI tests focused on observable behavior.
- `hymenium/workflow-gate-integration-verification.md`: implementer-to-auditor gate needs evidence-backed integration tests rather than only mock gate success.
- `rhizome/lsp-and-export-verification.md`: default validation skips live/fake LSP semantics and Hyphae export behavior.
- `cortina/hook-executor-verification.md`: executor docs/tests need to agree on whether execution is real or stubbed.
- `mycelium/git-branch-regression-verification.md`: branch write-regression coverage should not live only in ignored tests.

## Folded Into Existing Handoffs

- A2 Canopy read-model verification must run the required Septa schema validations.
- A21 Cap auth/webhook verification must include malformed write/action body tests and adapter non-invocation assertions.
- A16 Septa validation tooling already covers stale registry, variant fixture validation, and raw `$ref` command guidance.

## Validation Notes

One lane ran `bash -n` over active verify scripts and found no syntax errors. It also ran the Cap live-operator verify script and found it passes despite the handoff saying the feature is missing, which is tracked in the cross-project verification hardening handoff.
