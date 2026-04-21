# Cross-Project: Authoritative Orchestration ADR

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cross-project`
- **Allowed write scope:** `docs/research/orchestration/...`, `hymenium/docs/...`, `canopy/docs/...`
- **Cross-repo edits:** docs-only updates in the named paths above
- **Non-goals:** implementing runtime behavior, changing Septa schemas, or editing Canopy or Hymenium code
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-authoritative-orchestration-adr.sh`
- **Completion update:** once review is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `docs/research/orchestration/` with alignment notes in `hymenium/docs/` and `canopy/docs/`
- **Likely files/modules:** `docs/research/orchestration/README.md`; new ADR or reset note under `docs/research/orchestration/`; `hymenium/docs/architecture.md`; `canopy/docs/architecture.md`
- **Reference seams:** the current orchestration research docs and the repo-local architecture docs
- **Spawn gate:** do not launch an implementer until the parent agent can name the exact doc files to update

## Problem

The orchestration ideas are richer than the live implementation, but there is no single canonical document that states what owns what, which workflow states are real, or which role names should be used outside the research shorthand. That invites drift before code changes even start.

## What exists (state)

- **Research docs:** describe the richer baseline and research-role vocabulary
- **Hymenium docs:** describe current ownership but not the reset target clearly enough
- **Canopy docs:** still describe workflow context in a way that can be read as workflow ownership

## What needs doing (intent)

Publish one authoritative orchestration design note that locks in:

- Hymenium as the single orchestration authority
- Canopy as the coordination ledger and operator surface
- Septa as the concrete orchestration contract layer
- `.handoffs/` as the authored specification layer
- the cleaner runtime role names to use in active work

## Scope

- **Primary seam:** authoritative orchestration ownership and vocabulary
- **Allowed files:** `docs/research/orchestration/...`, `hymenium/docs/...`, `canopy/docs/...`
- **Explicit non-goals:**
  - Do not change runtime code
  - Do not change schemas
  - Do not redesign Cap

---

### Step 1: Publish the reset note

**Project:** `docs/research/orchestration/`
**Effort:** 2-4 hours
**Depends on:** nothing

Add a short reset note or ADR that states the authority model, the runtime role language, and the rule that backward compatibility is not a design constraint for this internal reset.

#### Verification

```bash
rg -n "single orchestration authority|coordination ledger|Spec Author|Workflow Planner|Packet Compiler" docs/research/orchestration hymenium/docs canopy/docs
```

**Checklist:**
- [ ] One document names Hymenium as the single orchestration authority
- [ ] One document names Canopy as the coordination ledger and operator surface
- [ ] Cleaner role names are documented in one stable place

---

### Step 2: Align repo-local architecture docs

**Project:** `hymenium/`, `canopy/`
**Effort:** 2-4 hours
**Depends on:** Step 1

Refresh the repo-local architecture docs so their boundary language matches the reset note instead of the pre-reset mixed model.

#### Verification

```bash
rg -n "single orchestration authority|coordination ledger|workflow authority|operator surface" hymenium/docs canopy/docs
```

**Checklist:**
- [ ] Hymenium docs describe workflow authority unambiguously
- [ ] Canopy docs describe ledger and read-model ownership unambiguously
- [ ] No repo-local doc still implies that Canopy is a second workflow engine

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. The authoritative reset note exists and is linked from the research area
2. `bash .handoffs/cross-project/verify-authoritative-orchestration-adr.sh` passes
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion

### Final Verification

```bash
bash .handoffs/cross-project/verify-authoritative-orchestration-adr.sh
```

## Context

This is the first child handoff in the orchestration reset. It turns the architectural direction into a stable written baseline so the schema and runtime work do not drift apart while the reset is in progress.
