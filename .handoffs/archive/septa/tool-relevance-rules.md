# Septa: Tool Relevance Rules Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** septa/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `septa` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

The ecosystem has no formal definition of which tools are relevant for which operations. "If you're editing code, you should check rhizome first" is implicit knowledge in CLAUDE.md files. Without a machine-readable rule set, cortina hooks can't detect when an agent skips a relevant tool, and canopy can't score adoption accurately.

## What exists (state)

- **CLAUDE.md/AGENTS.md files**: Human-readable guidance like "use rhizome for code changes" — not machine-parseable
- **Host identifier schema**: `host-identifier-v1.schema.json` standardizes host names
- **Tool annotation metadata**: #103 proposes metadata on tools — complementary but different scope

## What needs doing (intent)

Define a `tool-relevance-rules-v1.schema.json` in septa that maps operation types (Write, Edit, Read, etc.) to recommended ecosystem tools. This is a static configuration contract consumed by cortina hooks and canopy scoring.

---

### Step 1: Define the schema

**Project:** `septa/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create `septa/tool-relevance-rules-v1.schema.json`:

- `schema_version`: const "1.0"
- `rules`: array of objects, each with:
  - `operation`: enum of tool/action names ["Write", "Edit", "Bash", "Read", "git_commit", "git_push", "file_create", "file_delete"]
  - `file_pattern`: optional glob pattern (e.g., "*.rs", "src/**") — narrows when the rule applies
  - `recommended_tools`: array of objects with { tool_name: string, source: enum ["hyphae", "rhizome", "cortina", "mycelium", "canopy", "volva", "spore"], reason: string }
  - `severity`: enum ["required", "recommended", "optional"] — how strongly to nudge
  - `check_window`: enum ["session", "recent_10", "recent_5"] — how far back to look for prior calls

Use `additionalProperties: false` at all levels.

#### Files to modify

**`septa/tool-relevance-rules-v1.schema.json`** — create new schema

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && bash validate-all.sh
```

**Checklist:**
- [ ] Schema created with rules array
- [ ] Operation enum covers common tool actions
- [ ] Severity levels defined (required, recommended, optional)
- [ ] Check window configurable per rule
- [ ] additionalProperties: false at all levels

---

### Step 2: Create the example fixture

**Project:** `septa/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Create `septa/fixtures/tool-relevance-rules-v1.example.json` with realistic rules:

1. Edit/Write on `*.rs` files → recommend rhizome get_structure, find_references (severity: recommended, window: session)
2. Edit/Write on any file → recommend hyphae_memory_recall for related context (severity: optional, window: session)
3. git_commit → recommend hyphae_memory_store for decisions made (severity: recommended, window: recent_10)
4. Bash with test commands → recommend hyphae_memory_store if errors found (severity: optional, window: recent_5)

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/septa && bash validate-all.sh
```

**Checklist:**
- [ ] Fixture validates against schema
- [ ] At least 4 realistic rules included
- [ ] Mix of severity levels shown
- [ ] validate-all.sh passes with 0 failures

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `bash validate-all.sh` passes in `septa/`
3. All checklist items are checked

## Context

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `septa` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsPart of the behavioral guardrails chain (#115a-c). This contract is consumed by cortina hooks (#115b) for pre-write checks and session-end advisories (#115c). Related to #103 (Tool Annotation Metadata) which annotates tools themselves — this annotates when tools should be used.
