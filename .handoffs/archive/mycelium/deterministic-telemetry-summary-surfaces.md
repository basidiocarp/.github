# Mycelium Deterministic Telemetry Summary Surfaces

## Problem

The audit set keeps pushing toward one missing `mycelium` layer: deterministic, local-first telemetry summaries that other tools can trust. Right now the ecosystem has pressure for better usage, cost, and value reporting, but without a named summary surface `mycelium` risks staying too implicit while `cap` or host adapters do more retrospective interpretation than they should.

## What exists (state)

- **`mycelium`:** already owns analysis and tracking-adjacent code paths
- **`cap`:** already has operator-facing cost and usage surfaces
- **`cortina`:** is moving toward normalized edge capture
- **No named deterministic summary surface:** the queue does not yet describe a stable summary layer that other tools can consume
- **Audit pressure:** `ccusage`, `rtk`, and `context-keeper` all pointed to clearer, local-first reporting surfaces

## What needs doing (intent)

Add stable summary surfaces in `mycelium` for normalized telemetry. The first pass should focus on:

- deterministic aggregation rules
- stable machine-readable outputs
- local-first summaries that do not depend on remote services
- a narrow consumer path for `cap` or other operator tooling

This should build on a normalized usage-event contract, not bypass it.

---

### Step 1: Define the summary model and output shape

**Project:** `mycelium/`
**Effort:** 2-3 hours
**Depends on:** usage-event contract direction is clear

Define the first summary model for usage and telemetry reporting. Keep it explicit about what is aggregated, what time or scope dimensions exist, and what fields are stable enough for downstream consumers.

#### Files to modify

**`mycelium/src/`** — add the summary model and aggregation boundary where it fits the existing architecture.

**`mycelium/README.md`** or adjacent docs — document what the deterministic telemetry summary surface means.

#### Verification

```bash
rg -n 'deterministic telemetry|telemetry summary|usage summary|summary surface' mycelium
```

**Output:**
<!-- PASTE START -->
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/telemetry.rs:1://! Deterministic telemetry summary surfaces built from local tracking aggregates.
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/telemetry.rs:15:/// Stable machine-readable telemetry summary surface for operator tooling.
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/telemetry.rs:109:    /// Build the named deterministic telemetry summary surface from local tracking aggregates.
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/tests.rs:176:                .expect("telemetry summary");
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/tests.rs:207:                .expect("telemetry summary");
/Users/williamnewton/projects/basidiocarp/mycelium/README.md:106:- Deterministic telemetry summary surfaces built from local tracking aggregates
/Users/williamnewton/projects/basidiocarp/mycelium/README.md:151:the deterministic telemetry summary surface. It is local-first, machine-readable,
/Users/williamnewton/projects/basidiocarp/mycelium/README.md:158:- `mycelium` summarizes them into deterministic telemetry and usage summaries
/Users/williamnewton/projects/basidiocarp/mycelium/README.md:162:named telemetry summary block derived from the tracking database. Downstream
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:78:        .context("Failed to build deterministic telemetry summary surface")?;

<!-- PASTE END -->

**Checklist:**
- [x] `mycelium` defines a named telemetry summary surface
- [x] the first model is machine-readable and explicit
- [x] docs name the summary boundary clearly

---

### Step 2: Add one stable output path and one consumer-facing seam

**Project:** `mycelium/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Add one stable output path that another tool can consume without guessing. Good first options:

- a JSON summary export
- an MCP resource or command output
- a typed internal API that `cap` can read through an existing server layer

#### Files to modify

**`mycelium/src/`** — add the output path and deterministic aggregation implementation.

**`mycelium/tests/`** or adjacent test modules — add coverage for summary determinism.

#### Verification

```bash
rg -n 'json|resource|summary' mycelium/src mycelium/tests
```

**Output:**
<!-- PASTE START -->
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/mod.rs:152:/// Serializable to JSON for export via `mycelium gain --daily --format json`.
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:12:    pub(crate) summary: ExportSummary,
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:13:    pub(crate) telemetry_summary: TelemetrySummarySurface,
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:76:    let telemetry_summary = tracker
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:77:        .get_telemetry_summary_filtered(project_scope)
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:78:        .context("Failed to build deterministic telemetry summary surface")?;
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:97:        telemetry_summary,
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:130:pub(crate) fn export_json(
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:151:    let json = serde_json::to_string_pretty(&export)?;
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:164:    fn gain_json_export_includes_deterministic_telemetry_summary_surface() {
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:181:            export.telemetry_summary.summary_surface,
/Users/williamnewton/projects/basidiocarp/mycelium/src/gain/export.rs:182:            "deterministic-telemetry-summary"
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/tests.rs:154:fn test_telemetry_summary_surface_orders_command_breakdown_deterministically() {
/Users/williamnewton/projects/basidiocarp/mycelium/src/tracking/tests.rs:185:fn test_telemetry_summary_surface_orders_parse_failures_deterministically() {

<!-- PASTE END -->

**Checklist:**
- [x] at least one stable output path exists
- [x] there is a clear consumer seam for operator tooling
- [x] determinism is covered by a test or repeatable validation path

---

### Step 3: Keep reporting ownership out of the UI layer

**Project:** `mycelium/`, supporting `cap/` docs if needed
**Effort:** 2-3 hours
**Depends on:** Step 2

Document and enforce the ownership split:

- `cortina` captures normalized edge events
- `mycelium` summarizes them
- `cap` renders or explores summaries

Do not let the first useful UI drive `mycelium` into ad hoc, presentation-specific output.

#### Files to modify

**`mycelium/README.md`** or architecture docs — describe the ownership split.

**Consumer docs** where needed — note that UI surfaces consume `mycelium` summaries rather than recomputing them.

#### Verification

```bash
bash .handoffs/mycelium/verify-deterministic-telemetry-summary-surfaces.sh
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
PASS: Mycelium mentions deterministic telemetry summaries
PASS: Mycelium source mentions a stable summary output
PASS: Mycelium tests or docs mention deterministic aggregation
Results: 3 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] `mycelium` owns summary generation explicitly
- [x] the verify script passes
- [x] the summary surface is documented as a reusable backend boundary

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/mycelium/verify-deterministic-telemetry-summary-surfaces.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/mycelium/verify-deterministic-telemetry-summary-surfaces.sh
```

**Output:**
<!-- PASTE START -->
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
PASS: Mycelium mentions deterministic telemetry summaries
PASS: Mycelium source mentions a stable summary output
PASS: Mycelium tests or docs mention deterministic aggregation
Results: 3 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/ccusage-ecosystem-borrow-audit.md`
- `.audit/external/audits/rtk/ecosystem-borrow-audit.md`
- `.audit/external/audits/context-keeper-ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/ecosystem-synthesis-and-adoption-guide.md`
- `.handoffs/campaigns/external-audit-gap-map/README.md`
