# Ecosystem Logging Audit Summary

## Status

Audit collection is complete. Every target repo now has a bounded per-repo audit
report. The targeted phase-two hardening work is also complete, so this summary
now serves as a historical record of the audit plus the implementation outcome.

## Queue

- Round 1: `rhizome`, `hyphae`
- Round 2: `mycelium`, `cortina`
- Round 3: `canopy`, `stipe`
- Round 4: `volva`

## Audit Method

- The lead reviewer stayed read-only and owned synthesis.
- Each round used exactly two fresh subagents.
- Each subagent audited only `spore/` plus one target repo at a time.
- Finished subagents were closed and not reused for later rounds.

## Original Audit Health

- `rhizome`: `partial`
- `hyphae`: `partial`
- `mycelium`: `partial`
- `cortina`: `partial`
- `canopy`: `partial`
- `stipe`: `partial`
- `volva`: `partial`
At collection time, the shared `spore` logging rollout was present across the
ecosystem, but every audited repo still had at least one meaningful hardening
gap around failure-locality, request context, child-process diagnostics, or
doc/runtime alignment.

## Round Results

- Round 1 used two fresh subagents:
  - `spore/` + `rhizome/` -> `partial`
  - `spore/` + `hyphae/` -> `partial`
- Round 2 used two fresh subagents:
  - `spore/` + `mycelium/` -> `partial`
  - `spore/` + `cortina/` -> `partial`
- Round 3 used two fresh subagents:
  - `spore/` + `canopy/` -> `partial`
  - `spore/` + `stipe/` -> `partial`
- Round 4 used one fresh subagent:
  - `spore/` + `volva/` -> `partial`

## Cross-Repo Findings

- Boundary coverage is the biggest repeated gap. Most repos call `init_app` correctly, but `tool_span`, `workflow_span`, `subprocess_span`, or even a visible `root_span` are missing or too quiet at failure-prone boundaries.
- Several repos still lose child-process diagnostics. `mycelium`, `cortina`, and `stipe` all have paths where subprocess stderr is discarded or reduced to a boolean result, which weakens operator debugging.
- Stable context propagation is inconsistent. `session_id`, `request_id`, `tool`, and `workspace_root` are not threaded or normalized consistently enough in `hyphae`, `canopy`, `stipe`, and `volva`.
- Doc/runtime drift remains common. `rhizome`, `cortina`, and `canopy` all overstate or misdescribe the real behavior of repo-specific log knobs or stderr-controlled diagnostics.
- Some of the highest-risk issues are correctness issues that happen to intersect logging, not just missing trace calls. The clearest examples are `mycelium` plugin fallback double-execution risk, `cortina` evidence bridge durability, and `stipe init --json` not being stdout-pure.
- `volva` is now clearly in the phase-two bucket rather than the initial rollout bucket. Its remaining issues are not startup adoption problems; they are missing failure-local tracing in auth and callback flows, raw retry/backoff `eprintln!` calls that bypass `VOLVA_LOG`, and only partial per-run correlation context.

## Synthesis

The audit passed the “did the repo adopt Spore at all?” question. The useful
next step was targeted hardening:

- keep the repo-local startup contract as-is where it already works
- deepen tracing only at fragile workflow, subprocess, polling, retry, and
  callback boundaries
- preserve child stderr and other failure diagnostics instead of collapsing
  failures to booleans or generic text
- normalize shared context fields only where they are semantically real, not as
  blanket decoration
- align docs with the actual runtime knobs and stderr behavior

## Phase-2 Outcome

The phase-two hardening work was carried through the repos named in the audit:

- `rhizome`: docs/runtime alignment and missing subprocess boundaries shipped in `v0.7.6`
- `hyphae`: deeper request/session/workspace propagation shipped in `v0.10.5`
- `mycelium`: plugin fallback correctness and stderr preservation shipped in `v0.8.9`
- `cortina`: durable evidence attachment and deeper adapter tracing shipped in `v0.2.8`
- `canopy`: default-visible boundary spans, verification/polling coverage, and stderr alignment landed on `main` at `a01dc03`
- `stipe`: stdout-pure `init --json`, stronger setup diagnostics, and deeper tracing landed on `main` at `44150d2`
- `volva`: auth-local tracing, retry/backoff tracing, and local correlation context shipped in `v0.1.1`

This means the audit collection phase and the named phase-two remediation pass
are both complete. Any future logging work should be treated as new follow-up
work, not as unfinished rollout debt from this audit.

## Follow-Up Work

- The original follow-up handoff, `cross-project/ecosystem-logging-rollout-phase2.md`, is now complete.
- There is no remaining open repo from this audit collection pass.
