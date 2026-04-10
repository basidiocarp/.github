# Rust Repo Audit Checklist

Date: 2026-04-07
Scope: any current or future Rust repo in the `basidiocarp` ecosystem
Companion docs:

- [docs/foundations/rust-workspace-architecture-standards.md](./rust-workspace-architecture-standards.md)
- [docs/foundations/rust-workspace-standards-applied.md](./rust-workspace-standards-applied.md)

This is the checklist version. Use it when you want to audit a Rust repo quickly without rewriting the standards from
scratch.

## How to use it

Start at the top and answer each section honestly. If a repo fails one or two items, that is normal. If it keeps failing
the same kind of item across sections, that is architecture drift, not just rough edges.

## 1. Repo purpose and boundary

- [ ] Can I explain what this repo owns in two or three sentences?
- [ ] Can I explain what it explicitly does not own?
- [ ] If this repo talks to sibling tools, are those boundaries named and documented?
- [ ] If this repo emits or consumes cross-project payloads, are those contracts explicit?
- [ ] Does the repo avoid “just import the sibling” shortcuts that blur ownership?

If this section is weak, stop there first. A repo without a clear boundary will fail the rest of the checklist in noisy
ways.

## 2. Crate and module shape

- [ ] Do the crate names match the real dependency direction?
- [ ] Is there an obvious composition root if the repo has multiple crates?
- [ ] Do lower layers avoid depending on orchestration or app crates?
- [ ] Is there a clear place for ports or service contracts if multiple adapters need them?
- [ ] Does the repo avoid a “mega domain” crate that quietly exports everything?
- [ ] In a single-package repo, are internal modules still separated by responsibility?

Red flags:

- a `repo` crate depends on `app`
- an `infra` crate depends on orchestration code
- a `domain` crate is really just “shared stuff”

## 3. Core abstractions

- [ ] Can I name the one or two core traits or abstractions that organize the repo?
- [ ] Do adapters implement those abstractions instead of bypassing them?
- [ ] Are transport surfaces like CLI or MCP using shared logic instead of duplicating behavior?
- [ ] Are cross-cutting concerns like retries, timeouts, or policies attached at the right layer?

If the repo cannot name its own center, it probably does not have one.

## 4. Hotspot files

- [ ] Are the biggest files still coherent?
- [ ] Does any one file combine dispatch, policy, provider selection, config, formatting, and retries?
- [ ] Does any one file act like a second composition root by accident?
- [ ] Are growth areas being split into modules before they become permanent tangles?

This is where fake modularity shows up. A clean crate graph can still hide giant orchestration hubs.

## 5. Config and operator surfaces

- [ ] Is there one clear config entry point?
- [ ] Are defaults explicit?
- [ ] Is config validation early and readable?
- [ ] If the repo is host-facing, is operator UX treated like a product surface rather than a bag of flags?
- [ ] If the repo manages providers, MCP servers, hosts, or sessions, are those flows coherent?

Config is architecture. If the config story is muddled, the repo usually is too.

## 6. Permissions, policy, and runtime safety

- [ ] If the repo executes commands, reads files, writes files, or touches remote services, is permission behavior
  modeled explicitly?
- [ ] Are approval or policy decisions enforced in the execution path?
- [ ] Are defaults readable and reviewable?
- [ ] Is policy treated as runtime state instead of prompt folklore?

This matters most for host tools, CLI agents, and anything near execution boundaries.

## 7. Contracts and shared dependencies

- [ ] If another repo consumes this repo’s output, is that output versioned or at least treated as a contract?
- [ ] Are shared dependencies like `spore` or schema surfaces upgraded deliberately?
- [ ] Does the repo know which other tools break if its payloads change?
- [ ] Are generated files clearly separated from the source of truth?

This is where ecosystem discipline shows up.

## 8. CI and verification

- [ ] Is there one obvious answer to “what does green mean” for this repo?
- [ ] Are lint, test, and build checks authoritative rather than scattered across helper workflows?
- [ ] If workflow files are generated, are the generators tested?
- [ ] Does the narrowest meaningful verification command exist and is it documented?
- [ ] Can the repo pass its own basic checks in a normal local environment?

Warning sign:

- the repo looks polished, but a basic crate-local test run still fails on a normal machine

## 9. Tests

- [ ] Do tests match the product surface?
- [ ] If output is the product, are snapshots treated seriously?
- [ ] If contracts matter, are contract or payload-shape tests present?
- [ ] If the repo exposes CLI and MCP surfaces, are both covered where it matters?
- [ ] Are tests concentrated only in helpers, or do they exercise the important flows?

Large test counts are nice. Relevant test counts matter more.

## 10. Docs for maintainers

- [ ] Is there a short architecture note?
- [ ] Does the repo explain its build and test commands?
- [ ] Does it identify key files or key crates?
- [ ] Does it explain generated output and sources of truth?
- [ ] Does it document the contracts that matter to sibling tools?

User docs are not maintainer docs. Do not confuse them.

## 11. Ecosystem fit

- [ ] Does the repo stay inside its lane?
- [ ] Is work that belongs in `stipe`, `hyphae`, `rhizome`, `mycelium`, `cortina`, `canopy`, or `spore` actually landing
  there?
- [ ] Is the repo adding value that justifies existing as its own unit?
- [ ] If it is growing, is it growing deeper into its own responsibility rather than sideways into a sibling’s?

If the repo keeps solving sibling problems, it is either misplaced or missing a boundary.

## 12. Final read

After the checklist, write three lines:

1. Keep:
   What is already structurally right and should be protected?

2. Tighten:
   What is directionally right but needs better discipline?

3. Watch:
   Where is the next likely failure mode if the repo keeps growing?

That is usually enough to turn the checklist into real action.

## Short version

When in doubt, ask six questions:

- What does this repo own?
- Where is the core?
- Which direction do dependencies flow?
- Where is the composition root?
- What does green mean?
- What breaks outside this repo if I change this?

If a Rust repo can answer those clearly, it is probably in good shape. If it cannot, the checklist has already found the
work.
