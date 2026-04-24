# ForgeCode Audit Notes

Date: 2026-04-07
Re-assessed: 2026-04-23 (Wave 1 re-audit — verdict: Update; spawned canopy/permission-memory-policy.md handoff)
Repo: `antinomyhq/forgecode`
Local clone: `.examples/forgecode`
Local commit audited from clone start point: `3b96b0918`

These notes capture the first pass of the audit before the deeper local review. The initial pass was based on the public `main` branch structure, README, workflows, config surface, and package layout.

## Current assessment

The repo looks like a serious product with real engineering investment. I would currently rate it as:

- Product maturity: strong
- Code structure: moderate to strong
- Engineering quality: moderate

The strongest parts are the product surface, workspace modularity, config and provider design, shell integration, and release packaging. The weaker parts are boundary purity, maintainer-facing docs, and uneven quality gates.

## What looks good

- The Rust workspace is split into focused crates rather than one oversized CLI crate. That gives them useful seams around config, repo access, services, infra, UI helpers, testing, and workflow generation.
- Config is treated as a real product API. The checked-in defaults and JSON schema suggest they expect users and teams to customize behavior in a structured way rather than rely on scattered flags.
- The shell workflow is first-class. The shell plugin, command surfaces, and conversation features look like deliberate product design rather than a thin wrapper over a CLI.
- MCP support is core to the design, not bolted on later.
- The repo contains explicit operational guidance in `AGENTS.md` and tool docs, which is a good signal for long-term maintainability.
- They have release automation for a wide target matrix and they appear to take packaging seriously.

## Main risks

- Some crate boundaries look cleaner in name than in practice. The layout is good, but there are signs of layering drift in how responsibilities are distributed.
- CI quality gates are split across workflows. That can work, but it weakens the idea of one authoritative pipeline.
- Release targets are broader than the visible test surface. They build for many platforms, but the public testing story looks more Linux-heavy.
- Maintainer docs are thin relative to repo complexity. User docs are much stronger than contributor docs.
- The workflow and dependency surface is large enough that maintenance cost is becoming a design concern of its own.

## Features worth borrowing

- Layered instruction loading from global, repo, and local scope.
- Schema-driven config with provider overrides and task-specific model slots.
- First-class MCP management.
- Approval memory that turns one-off approvals into reusable policy.
- A separate shell UX layer instead of stuffing shell behavior into the core runtime.
- Clear role separation between planning, research, and implementation agents.

## Features to borrow carefully

- The crate split is worth studying, but not copying blindly. Some boundaries appear porous.
- Generated CI and release workflows reduce hand-maintenance in one place while increasing complexity in another.
- Aggressive dependency automation is only safe if the test matrix is stronger than the release surface.

## Next pass

The deeper local audit should answer four things:

1. Whether the crate dependency graph matches the intended architecture.
2. Where the biggest complexity hotspots live in `forge_app`, `forge_repo`, and `forge_services`.
3. How much real test coverage exists by crate and by behavior, not just by workflow presence.
4. Which features are strong enough to adopt directly versus just use as reference material.

## Local audit update

I ran a second pass against the local clone and the high-level picture mostly held up, but the evidence is sharper now.

The good news is that the repo does build locally. `cargo check -q` passed from the workspace root. The repo also has a real amount of test code distributed across core crates, with particularly heavy concentration in `forge_domain`, `forge_app`, `forge_repo`, `forge_main`, and `forge_services`.

The more important news is that the modular story is only partly true. The crate names suggest a clean architecture, but there is visible boundary drift:

- `forge_repo` depends directly on `forge_app`, which weakens the idea that `repo` sits neatly below application orchestration.
- `forge_domain` is functioning as a very broad export surface rather than a narrow domain model crate.
- Several hotspot files are large enough to be maintenance risks on their own.

### Concrete local findings

- `forge_repo/Cargo.toml` pulls in `forge_app` directly. That is the clearest architecture smell I found in the local clone.
- `forge_services/src/instructions.rs` confirms the layered `AGENTS.md` loading pattern is real and implemented cleanly.
- `forge_services/src/policy.rs` confirms permission memory is a core implementation feature, not just a README claim.
- `forge_ci/src/workflows/ci.rs` and `forge_ci/src/workflows/autofix.rs` show that workflow generation is deliberate and tested, but also confirm that quality gates are split across “coverage/build” and “autofix/lint”.
- `forge_ci/tests/ci.rs` verifies workflow generation itself, which is useful, but it does not replace stronger behavioral checks for the runtime.

### Complexity hotspots

The largest files in the local pass were not random. They cluster around orchestration, tool catalogs, provider integration, and request or response transformation:

- `crates/forge_app/src/operation.rs`
- `crates/forge_domain/src/tools/catalog.rs`
- `crates/forge_domain/src/context.rs`
- `crates/forge_repo/src/provider/bedrock.rs`
- `crates/forge_repo/src/provider/openai_responses/{request,response,repository}.rs`
- `crates/forge_services/src/attachment.rs`
- `crates/forge_services/src/tool_services/fs_{patch,search}.rs`

That pattern tells a pretty simple story: the architecture is trying to stay modular, but the product complexity is accumulating in a handful of central files anyway.

### Test and quality signals

- `cargo check -q`: passed
- `cargo test -q -p forge_ci`: passed
- `cargo test -q -p forge_config`: failed

The `forge_config` failure is a useful signal. A test in `crates/forge_config/src/reader.rs` expects the default config base path to end in `forge`, but on this machine it resolved to `dir`. That suggests the test is more environment-sensitive than it should be, or the fallback behavior is under-specified.

### Revised view

The repo still looks worth studying and selectively borrowing from. The most defensible pieces are the shell workflow design, the provider and config model, layered instructions, MCP support, and permission memory.

The main caution is architectural honesty. ForgeCode has good modular instincts, but some crates are acting as catch-alls and some dependency directions undercut the clean story implied by the names.
