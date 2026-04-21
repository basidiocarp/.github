# Mycelium: Structural Parser Hardening

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** mycelium/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

<!-- Save as: .handoffs/mycelium/structural-parser-hardening.md -->

## Problem

Mycelium currently uses regex-based filters to strip command output before it reaches the AI model. This is fragile — regex patterns break silently when output formats change, and they can accidentally strip important context that the model needs to understand what actually happened. The fix: use each command's native structured output mode (JSON flags, format strings) instead of regex-parsing human-readable text.

## What exists (state)

- **Mycelium filters**: Regex-based text stripping in the output filtering pipeline that attempts to parse human-readable command output
- **Native structured output**: Most CLI tools support JSON or structured output flags (git `--format`, cargo `--message-format=json`, npm JSON output) that Mycelium doesn't currently leverage

## What needs doing (intent)

Migrate Mycelium's filter pipeline from regex-based text stripping to structural parsing using each tool's native output modes.

---

### Step 1: Audit current filters for structural alternatives

**Project:** `mycelium/`
**Effort:** 2-3 hours
**Depends on:** nothing

Inventory every filter in mycelium and check whether the underlying command supports JSON or structured output. For each filter, document: current approach (regex vs structural), whether a native structured alternative exists, and estimated savings improvement.

#### Verification
```bash
cd mycelium && grep -r "fn filter_" src/ | head -20
```

**Checklist:**
- [ ] Every filter catalogued with current approach
- [ ] Native JSON/structured alternatives identified where available
- [ ] Priority list created (most fragile filters first)

---

### Step 2: Migrate git filters to structured output

**Project:** `mycelium/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Git supports `--format` strings and `--json` on some subcommands. Migrate git log, git status, and git diff filters to use structured git output rather than regex parsing.

#### Verification
```bash
cd mycelium && cargo test
```

**Checklist:**
- [ ] git log filter uses `--format` for field extraction
- [ ] git status filter uses porcelain format
- [ ] Token savings maintained or improved vs regex approach
- [ ] Snapshot tests updated

---

### Step 3: Migrate build tool filters to structured output

**Project:** `mycelium/`
**Effort:** 3-4 hours  
**Depends on:** Step 1

Cargo test supports `--message-format=json`. npm/pnpm support JSON output modes. Migrate build and test output filters to use these.

#### Verification
```bash
cd mycelium && cargo test
```

**Checklist:**
- [ ] cargo test filter uses `--message-format=json` or equivalent
- [ ] npm/pnpm filters use JSON output where available
- [ ] Fallback to regex when structured output unavailable
- [ ] Snapshot tests updated

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked

## Context

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsToken optimization strategy documented in docs/architecture/token-optimization-design-note.md. This is the highest-impact reliability improvement for Mycelium's filtering pipeline. Structural parsing produces consistent, predictable savings without the risk of accidentally stripping important context.
