# Cap Config Write Validation

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

<!-- Save as: .handoffs/cap/config-write-validation.md -->
<!-- Create verify script: .handoffs/cap/verify-config-write-validation.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

Cap’s settings write endpoints build TOML with direct string interpolation and only
partial validation. Malformed or hostile input can produce broken config files or
unexpected config content.

## What exists (state)

- **Mycelium settings write:** booleans are interpolated directly
- **Rhizome settings write:** `languages` entries are quoted without escaping
- **Hyphae settings write:** `embedding_model` is inserted directly into a TOML line

## What needs doing (intent)

Centralize request validation and TOML-safe serialization for all settings write
routes so the server only writes known-good values.

---

### Step 1: Validate Input Shapes

**Project:** `cap/`
**Effort:** 45 min
**Depends on:** nothing

Add explicit request-shape validation in `server/routes/settings/writes.ts`:

- `hyphae_enabled` and `rhizome_enabled` must be booleans
- `auto_export` must be a boolean
- `languages` must be an array of non-empty strings
- `embedding_model` must be a non-empty string
- existing numeric threshold checks remain

### Step 2: Centralize Safe TOML Writing

**Project:** `cap/`
**Effort:** 45 min
**Depends on:** Step 1

Create a small helper for TOML-safe scalar and string-array serialization and use it
for all three settings writes instead of raw string interpolation.

#### Files to modify

**`cap/server/routes/settings/writes.ts`** — validate incoming body fields and route all
TOML string emission through a safe helper.

**`cap/server/__tests__/config-write-validation.test.ts`** — add tests for rejected
invalid payloads and escaped string writes.

#### Verification

```bash
cd cap && npm run test:server -- server/__tests__/config-write-validation.test.ts
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All settings write payloads are shape-validated
- [ ] TOML strings and string arrays are escaped through one helper path
- [ ] Server tests cover rejected malformed payloads and valid writes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-config-write-validation.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-config-write-validation.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

## Context

## Implementation Seam

- **Likely repo:** `cap`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cap` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsCreated from the completed Cap deep audit on 2026-04-05. This is the main
input-validation follow-up for the settings write surface.
