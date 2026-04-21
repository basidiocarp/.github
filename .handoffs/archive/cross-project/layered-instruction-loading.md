# Layered Instruction Loading

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Agent instruction loading (CLAUDE.md, AGENTS.md, project rules) follows an implicit precedence order that is not standardized or documented across the ecosystem. Claude Code loads these files natively, but the intended layering — global user rules, workspace root, project level, directory level — is not captured as an explicit contract. ForgeCode implements explicit global-to-local layered loading with caching and clear precedence. The basidiocarp ecosystem has CLAUDE.md files at multiple levels but no documented loading contract, no validation that files exist where expected, and no operator-visible signal when layers conflict or are missing.

## What exists (state)

- **`CLAUDE.md`**: exists at workspace root and in several subprojects (hyphae, cap, etc.). Claude Code loads these natively based on file proximity.
- **`~/.claude/rules/`**: global user rules, loaded by Claude Code from the user home directory.
- **`lamella`**: packages skills and hooks but does not define instruction loading order or validate instruction file presence.
- **`stipe init`**: configures hosts but does not validate instruction file presence or precedence.
- **No explicit loading model**: the intended L0 → L1 → L2 → L3 order is not written down anywhere as a contract.
- **No validation**: nothing checks whether subprojects have CLAUDE.md files or whether layers conflict.

## What needs doing (intent)

Two pieces. First, document the instruction loading contract explicitly — the intended layer order, precedence rules (override vs merge), and which layers are authoritative for which scope. This may land as a septa contract, a docs/foundations document, or both. Second, add validation to `stipe doctor` that checks instruction files exist at expected locations and flags missing or conflicting layers as operator warnings.

---

### Step 1: Document the instruction loading contract

**Project:** workspace root / `septa/` or `docs/foundations/`
**Effort:** 4-8 hours
**Depends on:** nothing

Define the intended loading order as an explicit written contract. The layer model:

- **L0 — Global user rules**: `~/.claude/rules/` — user-level preferences and conventions, applies everywhere
- **L1 — Workspace root**: `CLAUDE.md` and `AGENTS.md` at the basidiocarp root — workspace-wide conventions
- **L2 — Project level**: `<project>/CLAUDE.md` — project-specific guidance, narrows or overrides L1 for that project
- **L3 — Directory level**: `CLAUDE.md` in subdirectories — tight-scope overrides for a specific module or path

Precedence rule: later layers override earlier layers for conflicting guidance. Complementary guidance is additive. L0 sets defaults, L3 wins when it speaks to the same topic.

Decide the artifact format:
- If this is a contract for tooling to enforce, put it in `septa/` as `instruction-loading-v1.schema.json`
- If this is documentation only, put it in `docs/foundations/instruction-loading.md`
- If both, do both

The document must also note what Claude Code does natively (file-proximity loading) and where the explicit ecosystem contract adds value over host-native behavior (validation, conflict detection, stipe doctor integration).

#### Verification

```bash
ls /Users/williamnewton/projects/basidiocarp/docs/foundations/ 2>/dev/null
ls /Users/williamnewton/projects/basidiocarp/septa/*.schema.json 2>/dev/null | grep instruction
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Loading order documented with all four layers (L0–L3) defined
- [ ] Precedence rules explicit: override vs additive for conflicting vs complementary guidance
- [ ] Document addresses relationship to Claude Code native behavior
- [ ] Contract or document exists in septa or docs/foundations (or both)

---

### Step 2: Add instruction file validation to stipe doctor

**Project:** `stipe/`
**Effort:** 4-8 hours
**Depends on:** Step 1

Add a check group to `stipe doctor` that validates instruction files exist at expected locations across the ecosystem. Use the contract from Step 1 as the source of truth for what "expected" means.

Checks:
- Workspace `CLAUDE.md` present (L1)
- Workspace `AGENTS.md` present (L1)
- Each active subproject has a `CLAUDE.md` (L2) — active means the project directory exists and contains source files
- Global rules directory `~/.claude/rules/` exists (L0) — warning only if absent, not an error

Conflict detection: if a subproject CLAUDE.md contains guidance that explicitly contradicts a workspace CLAUDE.md directive on the same topic, flag as a warning. This is best-effort pattern matching, not semantic analysis — look for identical section headers with different content.

Output follows the existing stipe doctor check-group format. All instruction-file findings are warnings, not errors.

#### Verification

```bash
cd stipe && cargo build --release 2>&1 | tail -5 && cargo test 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` reports workspace CLAUDE.md and AGENTS.md presence
- [ ] `stipe doctor` reports L2 instruction file presence for active subprojects
- [ ] Missing instruction files produce warnings, not errors
- [ ] Potential layer conflicts flagged as warnings
- [ ] Build and tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cross-project/verify-layered-instruction-loading.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cross-project/verify-layered-instruction-loading.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete with failures.

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFrom synthesis DN-1. ForgeCode implements explicit global-to-repo-to-cwd layered loading with caching and clear source-of-truth semantics. The basidiocarp ecosystem already has CLAUDE.md files at multiple levels but relies on Claude Code's native file-proximity behavior without documenting or validating the intended layer model. This handoff does not change how Claude Code loads instructions — it makes the intended model explicit and adds validation so operators know when layers are missing or conflicting. Serena and context-keeper audits also point to layered config overrides as an area where explicit contracts reduce drift.
