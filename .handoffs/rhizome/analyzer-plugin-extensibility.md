# Rhizome: Analyzer Plugin Extensibility

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** rhizome/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `rhizome` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

<!-- Save as: .handoffs/rhizome/analyzer-plugin-extensibility.md -->

## Problem

Rhizome's code analysis uses built-in backends for supported languages (tree-sitter
for 18 languages, LSP for 32). There is no mechanism for adding new language
support, custom analysis passes, or domain-specific intelligence without modifying
rhizome's core. As the ecosystem covers more project types — non-standard languages,
generated code, configuration formats, domain-specific files — the absence of an
extension point forces each new need into the rhizome core or leaves it unserved.

## What exists (state)

- **`BackendSelector`**: picks between tree-sitter and LSP backends per tool call;
  there is also a shipped heuristic fallback tier as the last resort
- **Tree-sitter backend**: built-in, 18 languages, no extension surface
- **LSP backend**: built-in, 32 languages, no extension surface
- **`rhizome-core`**: core analysis traits and data types; the trait boundaries
  that a plugin would implement exist implicitly but are not stabilized as a
  public interface
- **No plugin discovery, no external analyzer loading, no sample plugin**

## What needs doing (intent)

Design and implement an analyzer plugin interface for rhizome. Plugins should be
able to add new language support or custom analysis passes without touching rhizome
core. Start with a trait-based interface using dynamic dispatch; consider WASM for
sandboxed third-party plugins only if the trait approach proves insufficient.
Design the interface before building the loader.

---

### Step 1: Define the analyzer plugin interface

**Project:** `rhizome/`
**Effort:** 2–3 days (design-first)
**Depends on:** nothing

Stabilize a public plugin trait in `rhizome-core` that covers the operations
a backend must support:

```rust
pub trait AnalyzerPlugin: Send + Sync {
    /// Unique identifier for this plugin (e.g., "toml-analyzer")
    fn id(&self) -> &str;

    /// File extensions or MIME types this plugin claims
    fn supported_extensions(&self) -> &[&str];

    /// Return a structural outline for the given file
    fn get_structure(&self, path: &Path) -> Result<StructureOutline>;

    /// Return the content of a specific region by ID
    fn get_region(&self, path: &Path, region_id: &str) -> Result<FileRegion>;

    /// Optional: return symbol definitions (may return empty)
    fn get_symbols(&self, path: &Path) -> Result<Vec<Symbol>> {
        Ok(vec![])
    }
}
```

Key design decisions to make explicit:
- **Priority**: plugins are tried after tree-sitter and LSP but before the
  heuristic fallback; the first plugin claiming the extension wins
- **Error contract**: a plugin that returns `Err` causes fallthrough to the
  next tier, not a hard failure
- **Registration**: plugins are registered at startup, not at runtime; dynamic
  loading comes later (Step 2)

Document the design decisions in `rhizome/docs/plugin-interface.md`.

#### Verification

```bash
cd rhizome && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `AnalyzerPlugin` trait defined in `rhizome-core` with the operations above
- [ ] Trait is `Send + Sync` and object-safe
- [ ] `BackendSelector` has a plugin tier between LSP and heuristic fallback
- [ ] Design decisions documented in `rhizome/docs/plugin-interface.md`
- [ ] Build and tests pass

---

### Step 2: Implement plugin discovery and loading

**Project:** `rhizome/`
**Effort:** 2–3 days
**Depends on:** Step 1

Add a plugin loader that discovers and registers analyzer plugins at startup:

- **Built-in registration**: plugins in `rhizome-plugins/` crate are registered
  via a `register_builtins(registry: &mut PluginRegistry)` call at init
- **External path loading**: if `RHIZOME_PLUGIN_PATH` is set, scan the directory
  for shared libraries (`.so`/`.dylib`/`.dll`) implementing a C ABI entry point
  `rhizome_plugin_init(registry: *mut PluginRegistry)` — this is the extension
  point for third-party plugins
- **Conflict resolution**: if two plugins claim the same extension, the last one
  registered wins; a warning is emitted
- **`rhizome plugin list`**: new CLI command that shows registered plugins, their
  claimed extensions, and their source (built-in or path)

External loading is lower priority than built-in registration; implement built-in
first and stub external path loading.

#### Verification

```bash
cd rhizome && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
rhizome plugin list 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `PluginRegistry` type exists and holds registered plugins
- [ ] Built-in plugins registered at startup via `register_builtins`
- [ ] `RHIZOME_PLUGIN_PATH` stub exists (even if external loading is not yet
      implemented, the env var should be recognized and logged)
- [ ] `rhizome plugin list` shows registered plugins and claimed extensions
- [ ] Build and tests pass

---

### Step 3: Create a sample built-in plugin

**Project:** `rhizome/`
**Effort:** 1–2 days
**Depends on:** Steps 1–2

Implement a concrete plugin in `rhizome-plugins/` to validate that the interface
is usable and complete. Good candidates:

- **TOML analyzer**: structural outline using table headers as regions; useful
  for `Cargo.toml`, `pyproject.toml`, config files
- **Markdown section analyzer**: headings as regions, code blocks as symbols
- **Custom analysis pass**: a cross-language pass that identifies TODO/FIXME
  markers and surfaces them as a `get_symbols` result regardless of language

Pick whichever fits the current most common unhandled file type in the ecosystem.
The sample plugin's primary purpose is exercising the interface — coverage is more
important than sophistication.

#### Verification

```bash
cd rhizome && cargo test --workspace 2>&1 | tail -10
# Test the sample plugin on a real file in the workspace
rhizome get-structure Cargo.toml 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Sample plugin implements `AnalyzerPlugin` fully (structure, region, optional symbols)
- [ ] Plugin is registered via `register_builtins`
- [ ] `rhizome get-structure <sample-file>` routes to the plugin and returns output
- [ ] Plugin unit tests cover structure and region operations
- [ ] Build and tests pass

---

### Step 4: Document plugin authoring

**Project:** `rhizome/`
**Effort:** 1 day
**Depends on:** Steps 1–3

Write `rhizome/docs/plugin-authoring.md` covering:

- The `AnalyzerPlugin` trait contract and what each method must return
- How to register a built-in plugin via `register_builtins`
- How to package an external plugin (shared library ABI) for `RHIZOME_PLUGIN_PATH`
- Stability guarantees: the trait is versioned; breaking changes increment the
  plugin API major version and old plugins are rejected at load time with a clear
  error
- Walk through the sample plugin from Step 3 as a worked example

The doc goes in `rhizome/docs/` not the workspace docs — it is rhizome's own
developer-facing reference.

#### Verification

- [ ] `rhizome/docs/plugin-authoring.md` written and covers all four points above
- [ ] The worked example matches the actual sample plugin code from Step 3
- [ ] Plugin API versioning policy stated explicitly

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. The plugin trait design document from Step 1 is written
2. Every subsequent step has verification output pasted between the markers
3. `cargo build --workspace` and `cargo test --workspace` pass in `rhizome/`
4. `rhizome plugin list` shows the sample plugin
5. `rhizome get-structure <sample-file>` routes through the plugin for a file
   type the sample plugin claims
6. Plugin authoring documentation is written
7. All checklist items are checked

### Final Verification

```bash
cd rhizome && cargo test --workspace 2>&1 | tail -5
rhizome plugin list 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass, plugin list shows at least one built-in plugin.

## Context

Source: Understand-Anything audit. Priority: **Lower** — rhizome's current
language coverage (18 tree-sitter + 32 LSP + shipped heuristic fallback) is
sufficient for the active ecosystem. Extensibility becomes important as the
ecosystem covers more project types and as third parties want to add domain-specific
analysis without forking rhizome.

The trait-based approach is the right starting point. WASM sandboxing for
untrusted third-party plugins is a valid future direction, but adds significant
complexity and should not be part of this handoff — the interface should be
designed so WASM could be added as a loader variant later without changing the
trait itself.

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `rhizome` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsStart with Step 1 only. The interface design shapes everything downstream, and
a poorly designed plugin boundary is expensive to change once external consumers
exist.
