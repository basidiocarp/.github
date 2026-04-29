# Cross-Project: CLI Coupling Exemption Audit

<!-- Save as: .handoffs/cross-project/cli-coupling-exemption-audit.md -->
<!-- Create verify script: .handoffs/cross-project/verify-cli-coupling-exemption-audit.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `docs/foundations/`, `septa/integration-patterns.md`, `.handoffs/`, repo-local docs and tests that inventory or replace Basidiocarp-to-Basidiocarp CLI calls
- **Cross-repo edits:** documentation, tests, and narrow adapter annotations only; implementation replacements belong in repo-owned handoffs
- **Non-goals:** no bulk removal of all CLI integrations in one pass
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-cli-coupling-exemption-audit.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** cross-project docs plus targeted repo-local adapter annotations
- **Likely files/modules:** `septa/integration-patterns.md`, `docs/foundations/inter-app-communication.md`, source files containing `Command::new` calls to sibling tools, active replacement handoffs
- **Reference seams:** `system-to-system-communication-boundary.md`, capability control plane handoffs, existing trust-boundary handoffs
- **Spawn gate:** do not launch an implementer until the parent agent defines the initial scan pattern and exemption format

## Problem

The workspace now has a rule against new system-to-system CLI coupling, but existing integrations still shell out between Basidiocarp tools. Without an inventory and exemption gate, those existing calls become invisible precedent and new ones can slip in during feature work.

## What exists (state)

- **Foundation standard:** states CLI fallback rules.
- **Integration inventory:** lists several CLI-based integrations but does not classify them as operator calls, temporary exceptions, or replacement work.
- **Handoffs:** capability endpoint/client handoffs cover the Hymenium to Canopy dispatch case.

## What needs doing (intent)

Create an auditable inventory of Basidiocarp-to-Basidiocarp CLI calls and require each one to be classified:

- human/operator CLI surface
- temporary compatibility fallback with replacement handoff
- hook-time exception with circular-dependency rationale
- bug requiring immediate replacement

The verification should detect likely new sibling-tool CLI calls and fail unless they are documented or exempted.

## Scope

- **Primary seam:** cross-project CLI coupling inventory and enforcement
- **Allowed files:** listed in metadata
- **Explicit non-goals:** no full migration of all existing CLI calls, no generated code churn, no private DB integration

## Verification

```bash
rg 'Command::new|std::process::Command|tokio::process::Command' */src */tests
bash .handoffs/cross-project/verify-cli-coupling-exemption-audit.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] integration-patterns classifies existing CLI integrations
- [ ] every system-to-system CLI fallback has a replacement handoff or documented exception
- [ ] scan covers Rust process-spawn calls that target sibling Basidiocarp tools
- [ ] new CLI couplings fail verification until documented or replaced
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 inter-app communication architecture decision. This is the enforcement companion to the policy and endpoint implementation handoffs.

