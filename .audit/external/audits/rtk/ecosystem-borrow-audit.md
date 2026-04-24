# RTK Ecosystem Borrow Audit

Date: 2026-04-07
Re-assessed: 2026-04-23 (Wave 1 re-audit — verdict: Update; spawned mycelium/declarative-filter-extensions.md handoff)
Repo reviewed: `rtk`
Lens: what to borrow from the tool, how it fits the `basidiocarp` ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

`rtk` is not mainly interesting as a Rust architecture template. It is interesting as a productized operator tool that turns shell filtering, hook installation, command rewriting, measurement, and contributor process into one coherent system. The best lessons for this ecosystem are around product surfaces and operating discipline: declarative extension points, project-scoped telemetry, explicit permission/integrity modeling, strong repo-local guidance, and policy enforced by scripts instead of prose alone. The main thing not to copy is its large single-binary concentration pattern.

## What RTK is doing that is solid

### 1. It treats product boundaries seriously

RTK is not “just a filter.” It clearly owns filtering, hook integration, discovery, analytics, and operator configuration, and it documents those ownership lines in repo-local docs and module-level READMEs.

Evidence:

- [docs/contributing/ARCHITECTURE.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/docs/contributing/ARCHITECTURE.md#L31)
- [src/cmds/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/cmds/README.md#L3)
- [src/core/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/core/README.md#L5)
- [src/hooks/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/hooks/README.md#L5)

Why that matters here:

- `mycelium`, `stipe`, and `cortina` are all vulnerable to “useful tool drift,” where a repo slowly becomes a bag of adjacent behaviors.
- RTK is better than average at saying what belongs where.

### 2. It treats config and permissions as architecture

RTK models permissions, patch modes, integrity state, host-specific install behavior, and config defaults as first-class runtime surfaces rather than scattered conditionals.

Evidence:

- [src/core/config.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/core/config.rs#L8)
- [src/hooks/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/hooks/README.md#L35)
- [src/hooks/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/hooks/README.md#L64)
- [src/hooks/permissions.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/hooks/permissions.rs#L18)

Why that matters here:

- `stipe` should absorb more explicit permission and integrity modeling.
- `cortina` should keep host-capture policy explicit rather than implicit.
- `mycelium` can borrow the idea of treating user-facing config as a stable API surface.

### 3. It uses a strong extension model

The hybrid of compiled Rust filters and declarative TOML filters is one of RTK’s best ideas. It keeps the core strict while letting the long tail stay cheap.

Evidence:

- [src/filters/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/filters/README.md#L5)
- [build.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/build.rs#L15)
- [src/filters/turbo.toml](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/filters/turbo.toml#L1)

Why that matters here:

- `mycelium` is the most direct fit. It already has rich filtering/output concerns.
- `lamella` could borrow the pattern conceptually for structured rule or command payload validation.
- `stipe` could use a similar “compiled core, declarative host adapters” split for some setup policy surfaces.

### 4. It closes the loop with measurement

RTK does not stop at filtering output. It measures savings, missed opportunities, and learning signals in a project-scoped way.

Evidence:

- [src/core/tracking.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/core/tracking.rs#L42)
- [src/analytics/gain.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/analytics/gain.rs#L15)
- [src/discover/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/discover/README.md#L42)
- [src/learn/README.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/learn/README.md#L7)

Why that matters here:

- The ecosystem has good tool depth but is weaker on unified operator-facing feedback loops.
- `mycelium`, `stipe`, and `canopy` would all benefit from more visible “what value did this tool create?” reporting.

### 5. It turns process into guardrails

RTK is strong at making process expectations executable: required docs, test-presence checks, clearly documented green path, and subsystem-level contributor guidance.

Evidence:

- [CLAUDE.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/CLAUDE.md#L25)
- [CLAUDE.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/CLAUDE.md#L113)
- [scripts/check-test-presence.sh](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/scripts/check-test-presence.sh#L31)
- [CONTRIBUTING.md](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/CONTRIBUTING.md#L202)
- [.github/workflows/ci.yml](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/.github/workflows/ci.yml#L14)

Why that matters here:

- Your ecosystem standards docs are good, but several repos still rely too much on human discipline.
- RTK is a useful model for moving from “good guidance” to “enforced expectations.”

## What to borrow directly

### Borrow now

- Project-scoped savings and effectiveness analytics.
  Best fit: `hyphae`, `canopy`, then `mycelium`.
  Reason: RTK’s product idea is good, but the ecosystem already has better homes for scoped evidence and command-output storage than a global standalone dashboard.

- Explicit permission and integrity state for host-facing behavior.
  Best fit: `stipe`, `cortina`.
  Reason: both repos touch host state and would benefit from RTK-style explicit trust modeling.

- Component-level ownership docs inside the repo, not just top-level guidance.
  Best fit: `mycelium`, `stipe`, `cortina`, `canopy`.
  Reason: this is a cheap way to slow drift in single-package or policy-heavy repos.

- Policy-enforcing scripts for tests and docs.
  Best fit: `mycelium`, `hyphae`, `rhizome`.
  Reason: output- and contract-heavy repos benefit from checks that enforce repo-specific expectations.

- Fail-open hook contracts as an ecosystem invariant.
  Best fit: `cortina`, enforced or checked by `stipe`.
  Reason: RTK is explicit that hook failures must not block the user command. That should remain true across supported hosts here too.

## What to adapt, not copy

### Adapt

- Compiled core plus declarative extension layer.
  Adaptation: use where the domain has a predictable “long tail,” not everywhere.
  Best fit: `mycelium`; possible fit in `stipe`.

- Checked-in assistant guidance as a policy surface.
  Adaptation: keep it versioned and validated, not just copied into every repo.
  Best fit: `lamella`, `mycelium`, `stipe`.

- Missed-opportunity discovery loops.
  Adaptation: use only where the tool can actually recommend a better future action.
  Best fit: `mycelium` and maybe `stipe`; weaker fit for `hyphae` or `rhizome`.

- Thin host adapters over one rewrite or classification core.
  Adaptation: keep runtime logic in `cortina` and `mycelium`, packaging in `lamella`, and setup or repair in `stipe`.
  Best fit: the existing `mycelium` plus `cortina` seam.

- Closed-loop correction detection.
  Adaptation: capture corrections at the edge, store durable lessons in `hyphae`, and keep machine-readable rewrites in `mycelium`.
  Best fit: `cortina` + `hyphae` + `mycelium`, not one repo.

## What not to borrow

### Skip

- The hidden-monolith file concentration pattern.
  [src/main.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/main.rs), [src/hooks/init.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/hooks/init.rs), and [src/discover/registry.rs](/Users/williamnewton/projects/basidiocarp/.audit/external/sources/rtk/src/discover/registry.rs) carry too much central orchestration.

- Broad host support as a goal by itself.
  RTK supports many hosts, but that breadth drives hotspot growth. The ecosystem should keep host support focused where it belongs, mainly `stipe` and `cortina`.

- Advisory security gates presented as stronger than they are.
  The earlier RTK audit already showed that some “security” and benchmark checks are softer than the docs imply.

## How RTK fits the ecosystem

### Best fit by repo

- `mycelium`
  Strongest direct fit for the declarative extension model, rewrite/classification control plane, and stricter subsystem ownership docs.

- `stipe`
  Strong fit for explicit host policy, integrity state, install/repair discipline, and more operator-visible trust modeling.

- `cortina`
  Strong fit for fail-open host behavior, explicit boundary docs, and thin adapter design, but not for owning the whole filtering/rewrite product loop itself.

- `canopy`
  Strong fit for scoped evidence and effectiveness reporting, not for hook or shell-specific architecture.

- `hyphae`
  Moderate direct fit through lessons, scoped command-output memory, and durable correction storage, plus strong process fit.

- `rhizome`
  Limited direct fit for RTK’s shell product ideas, but useful as the better home for smart code reads and capability-routed inspection.

- `lamella`
  Good fit for validated checked-in guidance and structured extension surfaces, but not as the main runtime home for host behavior.

## What RTK suggests improving in your ecosystem

### 1. Push repo-local guidance down into subsystem docs

Your root and repo-level docs are useful, but several repos would benefit from RTK-style internal boundary docs for major modules or command families.

Best targets:

- `mycelium`
- `stipe`
- `cortina`

### 2. Convert standards into repo-specific guards

The ecosystem already has architecture standards. What it lacks in some places is RTK’s habit of turning those expectations into scripts and CI gates.

Best targets:

- test-presence or contract-presence checks in `mycelium`
- payload/contract validation around `septa` consumers
- host integration validation in `stipe` and `cortina`

### 3. Make operator value more visible

RTK is better than the ecosystem at surfacing measured benefit. Several of your tools are powerful but still rely on users inferring the value.

Best targets:

- `hyphae`: scoped command-output and lesson value reporting
- `canopy`: evidence and coordination effectiveness reporting
- `mycelium`: token/time savings reporting
- `stipe`: install/repair outcome reporting

### 4. Treat permissions and trust as explicit state

Your standards already say this. RTK shows a more concrete implementation shape.

Best targets:

- `stipe`
- `cortina`
- any future repo that edits host config, writes hooks, or runs commands on the user’s behalf

### 5. Clarify stewardship below the repo level

RTK’s maintainer approach is more explicit about subsystem ownership than most ecosystem repos currently are.

Best targets:

- `mycelium`
- `hyphae`
- `rhizome`

## Recommended ecosystem actions

### Do now

- Add subsystem ownership docs to `mycelium`, `stipe`, and `cortina`.
- Identify one repo-specific policy check to automate in each of `mycelium`, `hyphae`, and `rhizome`.
- Define explicit permission/integrity state language for `stipe` and `cortina`.
- Preserve fail-open host behavior as an explicit invariant and make `stipe doctor` validate it where practical.

### Do next

- Prototype project-scoped effectiveness reporting in `mycelium`.
- Extend scoped command-output and lesson reporting in `hyphae` or `canopy` rather than building a global RTK-style dashboard.
- Explore a declarative extension surface for `mycelium` or `stipe` where the long tail is real.
- Add clearer subsystem stewardship notes in the repos with the broadest surfaces.

### Revisit later

- Only consider broader host-surface borrowing if it preserves repo boundaries.
- Do not copy RTK’s single-binary concentration pattern into growing ecosystem tools.

## Verification context

This document reuses the local verification from the RTK audit already completed on 2026-04-07:

- `cargo check -q`
- `cargo test -q`
- `cargo clippy --all-targets -q`
- `cargo fmt --all -- --check`
- `bash scripts/validate-docs.sh`
- `bash scripts/check-test-presence.sh --self-test`

That audit also established the main caution: RTK is stronger as a product and process reference than as a direct crate-structure template.

## Final read

Borrow: explicit product surfaces, declarative extensions, permission modeling, measured operator value, and executable repo policy.

Adapt: checked-in assistant guidance and discovery loops, but only where the repo really owns that behavior.

Skip: the giant-file concentration pattern and broad host support as a goal in itself.
