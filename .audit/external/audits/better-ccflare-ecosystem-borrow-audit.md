# Better-CCFlare Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `better-ccflare`
Lens: what to borrow from better-ccflare, how it fits the basidiocarp ecosystem, and what it suggests improving

## One-paragraph read

better-ccflare is a multi-account load balancer and proxy for Claude and other LLMs, distributing requests across accounts to avoid rate limits. Its strongest portable ideas are: pluggable load-balancing strategy system with composable "combos" (fallback chains), unified multi-provider adapter layer across 10+ LLM providers with automatic format conversion, OAuth token health state machine with auto-refresh and rate-limit detection, and SQLite/PostgreSQL persistence with optional AES-256-GCM request encryption. Basidiocarp benefits most in `spore` (multi-provider abstraction, credential management), `canopy` (routing strategies and dispatch logic), and `septa` (provider contracts, streaming format definitions). The load-balancing rate-limit algorithms are too domain-specific to copy wholesale.

## What better-ccflare is doing that is solid

### 1. Pluggable strategy system with composable fallback chains

Strategies (session-based OAuth routing, pay-as-you-go for API keys, supervisor model) are registered in a registry. "Combos" compose strategies into fallback chains managed from a dashboard. State machine handles auto-refresh and smart timeout handling cleanly separated from account management.

Evidence:
- Strategy registry and strategy state machine in `packages/core/src/strategy.ts`
- "Combos" dashboard-managed fallback chain composition
- Strategy pause/resume on rate limit detection with configurable cooldown

Why that matters here:
- `canopy` multi-agent runtime needs pluggable routing/dispatch strategies — this pattern is directly applicable.
- Strategy composition as config (not code) is a strong operator affordance.

### 2. Unified multi-provider adapter layer

Unified interface across 10+ LLM providers (Claude OAuth, console API, Bedrock, Vertex AI, OpenRouter, OpenAI-compatible) with automatic request/response format conversion and streaming support. Providers are registered; new ones are added by implementing the adapter interface.

Evidence:
- Provider adapter classes in `packages/core/src/providers/`
- Automatic conversion between provider-specific streaming formats (Qwen/DashScope incremental tool call handling)
- OpenAI-compatible fallback mode for providers without native SDK support

Why that matters here:
- `spore` (shared infrastructure) should have a unified provider abstraction layer for all cloud services.
- The adapter pattern (one interface, multiple backends) belongs in `septa` as a contract.

### 3. OAuth token health state machine with auto-refresh

Health monitoring with automatic refresh, 30-minute buffer before expiration, pause/resume on rate limit detection, and per-provider credential rotation. Token state is persisted and queryable.

Evidence:
- OAuth token lifecycle manager with state: healthy → refreshing → rate-limited → paused
- Per-provider credentials with rotation policy
- Database-backed health monitoring with repair tools

Why that matters here:
- This is a missing capability across basidiocarp — there is no unified auth token lifecycle manager.
- `spore` or a dedicated auth layer should own this for all tools that touch external APIs.

### 4. Request encryption-at-rest with AES-256-GCM

Request logs are optionally encrypted at rest. Encryption keys are user-configured. Supports both SQLite (local) and PostgreSQL (Kubernetes) backends with the same encryption model.

Evidence:
- Optional AES-256-GCM encryption of stored request payloads
- Key management via environment variable or config file
- Encrypted fields transparent to query layer

Why that matters here:
- `septa` cross-tool contracts should define credential/payload safety requirements.
- `hyphae` persistent memory should support optional encryption at rest using a similar model.

## What to borrow directly

### Borrow now

- Multi-provider adapter pattern.
  Best fit: `spore` (shared infrastructure should have unified provider abstraction layer for all cloud services).

- Strategy registry and composition.
  Best fit: `canopy` (multi-agent runtime needs pluggable routing/dispatch strategies).

- OAuth token health state machine.
  Best fit: shared authentication layer (currently missing; blocks secure multi-provider support).

- Request encryption-at-rest pattern.
  Best fit: `septa` (cross-tool contracts should define credential/payload safety); `hyphae` (memory encryption).

## What to adapt, not copy

### Adapt

- Strategy "combos" (fallback chains as dashboard config).
  Adaptation: Make strategies declarative in project config (TOML or JSON), not dashboard-managed; adapt for `canopy` task routing.

- Database schema and migration system.
  Adaptation: Adapt SQLite/PostgreSQL migration strategy for `hyphae` persistent memory; different data model but same migration discipline.

- Real-time analytics dashboard.
  Adaptation: Decouple from the load balancer; insights belong in `cap` (dashboard); reuse the web UI architecture pattern.

## What not to borrow

### Skip

- Load balancing algorithms specific to LLM rate limit windows.
  Too domain-specific; strategies should be pluggable in `canopy`, not hardcoded for rate windows.

- OAuth/credential storage implementation.
  Credential management is a security-critical cross-cutting concern; deserves a dedicated service, not ad-hoc SQLite fields.

- Full multi-account session routing (OAuth 5hr window management).
  This is a product feature specific to Claude OAuth; `canopy` needs the routing pattern, not the OAuth mechanics.

## How better-ccflare fits the ecosystem

### Best fit by repo

- `spore`: Multi-provider abstraction, credential management, service discovery.
- `canopy`: Request routing strategies and dispatch logic.
- `septa`: Provider contracts, streaming format definitions, encryption contracts.
- `volva`: Runtime selection of provider (which account/model to use for a given task).
- `cap`: Analytics dashboard and rate-limit visualization.

## What better-ccflare suggests improving in your ecosystem

### 1. No credential abstraction

Basidiocarp lacks a unified secret store. Define a `septa` contract for how tools share credentials safely, with lifecycle management (refresh, rotation, expiry).

### 2. Strategy composition should be declarative

"Combos" (fallback chains) are dashboard-managed in better-ccflare. Should be declarative in project config (like lamella patterns) for canopy routing.

### 3. No provider-specific hooks

better-ccflare handles 10+ providers in branching logic. Should be extracted into `spore` provider SPI (Service Provider Interface) or plugin system so new providers are addable without touching core logic.

## Final read

**Borrow:** multi-provider abstraction, OAuth token lifecycle state machine, strategy registry, encryption patterns.

**Adapt:** analytics dashboard, database migration patterns, strategy composition (make declarative).

**Skip:** load balancing algorithms specific to rate limits; credential storage (needs dedicated security-first service).
