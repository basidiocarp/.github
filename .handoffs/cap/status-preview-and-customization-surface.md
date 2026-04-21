# Cap Status Preview And Customization Surface

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** cap/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

`cap` already has broader operator-surface work queued, but the audit set points to one narrower missing UI layer: previewing and editing a portable status/customization contract instead of poking at host-specific config. Without that split, `cap` risks becoming another place that bakes in host assumptions instead of helping the operator work against shared contracts.

## What exists (state)

- **`cap` operator views:** already have a broader live-operator handoff
- **`stipe`, `cortina`, and `lamella`:** are the likely backends or packaging layers for status-related state
- **No portable preview surface:** there is no handoff focused on status preview and customization over a shared contract
- **Audit pressure:** `ccstatusline` most directly, with support from `1code` and the broader synthesis

## What needs doing (intent)

Add a focused `cap` surface for:

- previewing resolved status state
- inspecting customization bundles or presets
- editing portable configuration inputs instead of host-specific blobs
- showing capability or validation errors from backend-owned contracts

This should sit on top of the shared contract and backend ownership, not replace them.

---

### Step 1: Define the typed read and edit models

**Project:** `cap/`
**Effort:** 2-3 hours
**Depends on:** resolved status and customization contract direction is stable

Define the typed client models for status preview, customization inputs, capability state, and validation errors.

#### Files to modify

**`cap/src/lib/types/`** — add read and edit models for status customization.

**`cap/src/lib/api/`** or server wrappers — add typed client access to the portable contract shape.

#### Verification

```bash
rg -n 'status preview|customization|capability|resolved status' cap/src
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cap` has typed models for status preview and customization
- [ ] the models reference portable contract fields rather than host-local config blobs
- [ ] validation and capability state are part of the read model

---

### Step 2: Add one usable preview and edit surface

**Project:** `cap/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Add one real surface where an operator can inspect a resolved status preview and change portable customization inputs. The first version can be narrow, but it should make the contract visible and inspectable.

#### Files to modify

**`cap/src/pages/`** — add or extend the view for status preview and editing.

**`cap/src/lib/queries/`** — add query or mutation wiring for the new surface.

#### Verification

```bash
cd cap && npm run build 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cap` exposes at least one status preview surface
- [ ] the UI edits portable customization inputs, not host-specific blobs
- [ ] the build passes

---

### Step 3: Keep ownership aligned with the backend contracts

**Project:** `cap/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Make the ownership split explicit in the route layer and UI copy:

- `septa` owns the contract
- `stipe` and `cortina` own resolution or host facts
- `lamella` owns packaged presets where relevant
- `cap` previews and edits against those backend-owned shapes

#### Files to modify

**`cap/server/routes/`** — keep backend ownership visible.

**`cap/src/pages/`** — keep labels and interactions aligned with backend ownership.

#### Verification

```bash
bash .handoffs/cap/verify-status-preview-and-customization-surface.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `cap` is clearly a consumer of the portable contract
- [ ] backend ownership is explicit in route or model naming
- [ ] the verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cap/verify-status-preview-and-customization-surface.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/cap/verify-status-preview-and-customization-surface.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- `.audit/external/audits/ccstatusline-ecosystem-borrow-audit.md`
- `.audit/external/audits/1code-ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/ecosystem-synthesis-and-adoption-guide.md`
- `.handoffs/campaigns/external-audit-gap-map/README.md`
