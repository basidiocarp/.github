# Rhizome Foundation Alignment

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `volva`
- **Allowed write scope:** volva/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`rhizome` already has a strong backend-separated structure, but it is vulnerable to capability accretion. As richer analyzer plugins, export surfaces, and edit tools grow, the repo needs a foundation-alignment pass so backend selection, graph export, and tool behavior do not start bypassing the clean core.

## What exists (state)

- **`rhizome`** already has a good workspace split
- **backend separation** is one of its strongest design traits
- **Future handoffs** will expand analyzer/plugin and understanding surfaces

## What needs doing (intent)

Reinforce:

- backend-specific logic stays behind the shared backend selection layer
- core remains focused on stable primitives and export logic
- edit/export/tool tests move out of hotspot files where needed

---

### Step 1: Align docs and backend-boundary guidance

**Project:** `rhizome/`
**Effort:** 1-2 hours
**Depends on:** nothing

Clarify the allowed dependency direction and reinforce backend-selection rules for MCP, CLI, and edit surfaces.

#### Verification

```bash
cd rhizome && cargo build --workspace 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] docs reinforce backend selection and boundary direction
- [ ] docs state what should not leak into core
- [ ] build passes

---

### Step 2: Add a lightweight boundary guard

**Project:** `rhizome/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Add a lightweight guard or convention so future feature work does not bypass shared backend selection or overload the core.

#### Verification

```bash
cd rhizome && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] boundary guard exists for future analyzer/export/edit work
- [ ] tests still pass

---

### Step 3: Split larger edit/export/tool tests from hotspots

**Project:** `rhizome/`
**Effort:** 2-3 hours
**Depends on:** Steps 1-2

Move larger behavior tests out of edit/export/tool hotspots into separate files or `tests/` where needed.

#### Verification

```bash
cd rhizome && cargo test --workspace 2>&1 | tail -40
bash .handoffs/rhizome/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] larger edit/export/tool tests are split where needed
- [ ] inline tests remain only for small invariants
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/rhizome/verify-foundation-alignment.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/rhizome/verify-foundation-alignment.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Companion standards:

## Implementation Seam

- **Likely repo:** `volva`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `volva` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- `docs/foundations/rust-workspace-architecture-standards.md`
- `docs/foundations/rust-workspace-standards-applied.md`
