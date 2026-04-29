# Inter-App Communication

System-to-system communication in the basidiocarp ecosystem must be explicit, typed, and transport-agnostic. This document establishes the hierarchy and rules.

---

## Rule

CLIs are human/operator surfaces. System-to-system calls must use typed local service endpoints, library APIs, or capability-resolved transports. CLI fallbacks are allowed only as compatibility adapters with a visible warning and a documented replacement handoff in `septa/integration-patterns.md`.

---

## Integration Hierarchy

Choose the lowest layer that fits your use case:

### 1. Library/Crate Dependency (Preferred)

- **Transport:** Compile-time link, zero latency, full type safety.
- **Use when:** Both producer and consumer are Rust crates in the same workspace or pinned via `ecosystem-versions.toml`.
- **Example:** A tool uses `spore::discover::find_capability()` instead of shelling out to discovery.

### 2. Local Service Endpoint (Preferred for Cross-Binary)

- **Transport:** Unix socket, loopback TCP, or HTTP, typed via `local-service-endpoint-v1.schema.json`, registered in `septa/integration-patterns.md`.
- **Use when:** Producer and consumer are separate binaries and compile-time linking is not practical.
- **Example:** cap backend queries hyphae via a Unix socket at `~/.basidiocarp/hyphae.sock` instead of spawning the CLI.

### 3. CLI Fallback (Temporary, Documented as Exception)

- **Transport:** CLI invocation; should be the last resort.
- **Use when:** Temporary compatibility bridge or operator-facing human interface (dashboard, shell).
- **Constraints:** Must be documented as an exception in `septa/integration-patterns.md` with a noted replacement handoff.
- **Example:** A hook-time signal captured via `hyphae session start` to avoid recursion in v1; candidates for v2 hook-time endpoint registry.

---

## Contract References

- **Local Service Endpoint Schema:** [`septa/local-service-endpoint-v1.schema.json`](../../septa/local-service-endpoint-v1.schema.json) — static endpoint descriptors for unix-socket, TCP, and HTTP transport.
- **Runtime Lease Schema:** [`septa/capability-runtime-lease-v1.schema.json`](../../septa/capability-runtime-lease-v1.schema.json) — ephemeral PID-bound leases for live service discovery.
- **Integration Patterns:** [`septa/integration-patterns.md`](../../septa/integration-patterns.md) — all cross-tool integrations with wire format, schema references, and CLI coupling classification.
