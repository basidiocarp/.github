# Cross-Project Ecosystem Logging Rollout Phase 2

## Status

Complete. The targeted hardening work identified by the ecosystem logging audit
has been implemented across the named repos, and this document now records the
outcome rather than pending intent.

## Problem

The shared `spore` logging contract is now adopted across the ecosystem, but the
review handoff found repeated gaps in boundary coverage, stable context
propagation, subprocess diagnostics, and doc/runtime alignment. The rollout is
present, but not yet strong enough for reliable operator debugging in the most
failure-prone paths.

## What existed (state)

- All audited repos initialize through the shared `spore` logging path.
- `ecosystem-logging-audit-review.md` produced per-repo audit reports plus a
  synthesis summary.
- The remaining work was no longer rollout plumbing; it was targeted hardening.

## What needed doing (intent)

Implement the highest-value phase-two fixes called out by the audit:

- `mycelium`: correct plugin fallback behavior and preserve child stderr
- `cortina`: make Canopy evidence attachment durable and deepen adapter tracing
- `stipe`: make `init --json` stdout-pure and extend tracing beyond release
  verification
- `hyphae`: propagate `session_id` and `workspace_root` through deeper workflow
  and write paths
- `rhizome`: align docs with `RHIZOME_LOG` and add missing subprocess
  boundaries
- `canopy`: make boundary spans visible under normal operator settings and add
  verification/polling coverage
- `volva`: add auth-local tracing and move retry/backoff notices onto shared
  tracing

The intended outcome for this phase was not “more tracing everywhere.” The
outcome was
better failure-locality, stable shared context, stdout/stderr-safe diagnostics,
and docs that match the shipped behavior.

## Scope

- repo-local hardening in `mycelium/`, `cortina/`, `stipe/`, `hyphae/`,
  `rhizome/`, `canopy/`, and `volva/`
- shared contract checks against `spore/src/logging.rs`
- test and doc updates where behavior changes

## Out of scope

- changing the base `spore` contract unless multiple repos prove the contract is
  the blocker
- unrelated feature work
- retrospective summary rewrites without implementation

## Verification targets

- each touched repo keeps its own build and test surface green
- any JSON, MCP, hook, or subprocess surface remains stdout-safe
- new tracing boundaries use stable fields such as `tool`, `request_id`,
  `session_id`, and `workspace_root` only when semantically correct
- docs and READMEs reflect the real repo-specific log knob and stderr behavior

## Outcome

The highest-value fixes from the audit landed as follows:

- `mycelium`: safe single-execution plugin fallback, better tracing coverage,
  and stderr preservation shipped in `v0.8.9`
- `cortina`: durable Canopy evidence attachment, broader adapter tracing, and
  stderr preservation shipped in `v0.2.8`
- `rhizome`: doc/runtime alignment and additional subprocess boundaries shipped
  in `v0.7.6`
- `hyphae`: deeper `session_id` and `workspace_root` propagation shipped in
  `v0.10.5`
- `canopy`: lifecycle-enabled default spans, verification/polling coverage, and
  logging-surface alignment landed on `main` at `a01dc03`
- `stipe`: stdout-pure `init --json`, stronger setup diagnostics, and broader
  tracing landed on `main` at `44150d2`
- `volva`: auth-local tracing, retry/backoff tracing, and local correlation
  context shipped in `v0.1.1`

## Verification result

Repo-local verification was run in each touched repo during implementation:

- `mycelium`: `cargo fmt`, `cargo build --workspace`, `cargo test --workspace`
- `cortina`: `cargo fmt`, `cargo build --workspace`, `cargo test --workspace`
- `rhizome`: `cargo fmt`, `cargo build --workspace`, `cargo test --workspace`
- `hyphae`: `cargo fmt`, `cargo build --workspace`, `cargo test --workspace`
- `canopy`: `cargo fmt`, `cargo build --workspace`, `cargo test --workspace`
- `stipe`: `cargo fmt`, `cargo build --workspace`, `cargo test --workspace`
- `volva`: `cargo fmt`, `cargo build --workspace`, `cargo test --workspace`

## Closeout

This handoff is complete. Future work in this area should be tracked as a new
handoff only if fresh audit findings appear or the shared `spore` contract
changes materially.
