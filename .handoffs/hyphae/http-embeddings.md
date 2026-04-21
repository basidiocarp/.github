# HTTP Embeddings (Ollama / OpenAI-Compatible)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Hyphae's vector search requires fastembed, which is a heavy Rust compile dependency with a large binary. Users with Ollama or any OpenAI-compatible embedding API have no way to use their existing setup. The embedding provider is not configurable at runtime.

## What exists (state)

- **`hyphae-core/src/http_embedder.rs`**: stub or not present
- **`fastembed` feature flag**: currently the only embedding path
- **`HYPHAE_EMBEDDING_URL` / `HYPHAE_EMBEDDING_MODEL`**: env vars not yet consumed

## What needs doing (intent)

Add an `HttpEmbedder` implementing the `Embedder` trait, always compiled (no feature flag), configured via env vars. Supports Ollama, OpenAI, and any compatible API.

---

### Step 1: Implement HttpEmbedder

**Project:** `hyphae/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create or expand `hyphae-core/src/http_embedder.rs`:
- Implements `Embedder` trait
- Calls `POST {HYPHAE_EMBEDDING_URL}/v1/embeddings` with `{"model": HYPHAE_EMBEDDING_MODEL, "input": [text]}`
- Returns `Vec<f32>` embedding
- Always compiled — no feature flag
- Cache the embedding dimensions after first probe (use `OnceLock<usize>`)

Wire into backend selection: if `HYPHAE_EMBEDDING_URL` is set, use `HttpEmbedder`; otherwise fall back to fastembed (if available) or disable vector search.

#### Verification

```bash
cd hyphae && cargo build --workspace --no-default-features 2>&1 | tail -5
cargo test --workspace --no-default-features 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `HttpEmbedder` implements `Embedder` trait
- [ ] Compiles without feature flags
- [ ] `HYPHAE_EMBEDDING_URL` env var activates it
- [ ] Dimensions cached with `OnceLock`
- [ ] Build and tests pass

---

### Step 2: Document and expose in stipe doctor

**Project:** `stipe/`
**Effort:** 30 min
**Depends on:** Step 1

Add a check to `stipe doctor` output: if no embedding provider is configured, suggest setting `HYPHAE_EMBEDDING_URL` for Ollama or mention the fastembed default. Update `~/.config/hyphae/config.toml` example to show `embedding_url` option.

**Checklist:**
- [ ] Stipe doctor mentions HTTP embedding option
- [ ] Config example updated

---

## Completion Protocol

1. Step 1 verification output pasted
2. `cargo build --no-default-features` and `cargo test --no-default-features` pass
3. `HYPHAE_EMBEDDING_URL=http://localhost:11434 cargo test` works (or integration note)

## Context

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `hyphae` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom `.plans/priority-phase-5.md`. Unblocks users who already run Ollama locally from getting vector search without recompiling with fastembed.
