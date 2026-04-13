# Architecture

Use this section when the question is about boundaries, runtime flow, or what
local-first means in practice.

## Guides

- [harness-overview.md](./harness-overview.md)
  The shortest end-to-end explanation of host, harness layer, repo, and operator surface.
- [ecosystem-architecture.md](./ecosystem-architecture.md)
  Ownership boundaries across the ecosystem.
- [harness-composition.md](./harness-composition.md)
  How the repos compose one working harness around the model.
- [platform-layer-model.md](./platform-layer-model.md)
  How the ecosystem maps to a standard six-layer orchestration platform model.
- [integration.md](./integration.md)
  How the projects connect, which protocols they use, and where failures show up.
- [local-first.md](./local-first.md)
  What local-first means in practice and where the trade-offs are.
- [hymenium-design-note.md](./hymenium-design-note.md)
  Active workflow orchestration layer: dispatch, phase gating, dependency resolution, and retry above canopy.
- [annulus-design-note.md](./annulus-design-note.md)
  Cross-ecosystem utilities tool design and scope.
- [resumability-design-note.md](./resumability-design-note.md)
  Deferred crash recovery, checkpoint/restore, and idempotent re-execution.
- [policy-layer-design-note.md](./policy-layer-design-note.md)
  Deferred guardrails, AuthN/AuthZ, and compliance layer.
- [token-optimization-design-note.md](./token-optimization-design-note.md)
  Token reduction strategies: structural parsing, progressive disclosure, and cache-friendly layout.
- [unified-output-aggregation.md](./unified-output-aggregation.md)
  One aggregation path (Annulus), many renderers (statusline, JSON, Cap). Data sources, consumers, and degradation strategy.
