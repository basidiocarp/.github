# Septa: Contract Governance Enforcement

## ⚠ STOP — READ BEFORE STARTING ANYTHING

This handoff requires a design decision before any implementation begins. Do not write code, modify files, or spawn subagents until the question in the "Decision Required" section has been answered by the human engineer.

Read this entire handoff, then ask the questions in "Decision Required." Implementation starts only after the human has chosen an approach.

---

## Handoff Metadata

- **Dispatch:** `umbrella — do not send to implementer directly`
- **Owning repo:** `septa` (governance tooling); cross-repo impact on CI
- **Allowed write scope:** `septa/scripts/`, `septa/validate-all.sh`, CI configs for producer repos
- **Cross-repo edits:** CI config additions only (no source changes in producer repos)
- **Non-goals:** writing the missing septa schemas (those are separate fix handoffs); changing the septa schema format
- **Verification contract:** `septa/validate-all.sh` catches a known unseamed cross-tool payload; a PR introducing a new cross-tool payload without a schema is rejected
- **Completion update:** update dashboard after decision is made and governance tools are live

## Context

Phase 5 found that septa schema coverage is opt-in. Three seams have no schema backing despite carrying structured cross-tool payloads:
- `hyphae/crates/hyphae-mcp/src/memory_protocol.rs` → `MemoryProtocolSurface` — no schema
- Hyphae session context JSON (consumed by volva) — no schema
- Claude Code hook envelope (consumed by cortina) — no schema

This means any of these shapes can change without `validate-all.sh` detecting it. The Phase 1 Contract Audit found similar drift in `canopy-snapshot-v1` (struct emits 21 fields; schema documents ~10). These are symptoms of the same root problem: septa enforces schemas that exist, but has no mechanism to detect missing schemas for new cross-tool calls.

The current model is: developer writes a cross-tool payload, optionally adds a septa schema. There is no gate preventing "optionally" from becoming "never."

Audit findings:
- Phase 1 P2: `.handoffs/campaigns/ecosystem-health-audit/phase1-contract/findings-p2.md`
- Phase 5 P1: `.handoffs/campaigns/ecosystem-health-audit/phase5-interaction/findings-p1.md` (Seam 3, Seam 6)

---

## Decision Required

Before any implementation, the human engineer must choose a governance model. The core question is: **how much enforcement do you want, and at what cost to developer ergonomics?**

---

### Option A: Documentation and convention (lightest touch)

**What it does:** Adds a `CROSS-TOOL-PAYLOADS.md` registry in `septa/` that lists every known cross-tool payload (schema-backed or not). CI checks that the registry file was updated when a producer or consumer changes. A PR touching a producer without updating the registry fails CI.

**How it works:**
```markdown
# septa/CROSS-TOOL-PAYLOADS.md

| Payload | Producer | Consumer(s) | Schema | Status |
|---------|----------|-------------|--------|--------|
| canopy-snapshot-v1 | canopy/src/api.rs | cap/server/routes/canopy.ts | canopy-snapshot-v1.schema.json | Backed |
| MemoryProtocolSurface | hyphae/crates/hyphae-mcp | volva/crates/volva-runtime | — | UNSEAMED |
| hook envelope | Claude Code | cortina adapters | — | UNSEAMED |
```

CI script:
```bash
# If any producer file changed, check if CROSS-TOOL-PAYLOADS.md was also touched
if git diff --name-only HEAD^ HEAD | grep -qE "^(hyphae|canopy|cortina|volva)/"; then
    if ! git diff --name-only HEAD^ HEAD | grep -q "septa/CROSS-TOOL-PAYLOADS.md"; then
        echo "ERROR: Producer changed without updating septa/CROSS-TOOL-PAYLOADS.md"
        exit 1
    fi
fi
```

**Tradeoffs:**
- ✅ Low implementation cost — registry is a markdown file
- ✅ Makes unseamed payloads visible without blocking existing work
- ✅ Allows developers to explicitly mark payloads as "UNSEAMED — accepted risk" without failing CI
- ❌ Relies on developers updating the registry — does not prevent adding a new unseamed payload without registering it
- ❌ Does not validate that registered payloads actually match their schemas

**When to pick this:** You want visibility without hard gates. Good for a team with strong discipline.

---

### Option B: Unseamed payload scanner (automated detection, no schema required)

**What it does:** Adds a script that scans producer repos for struct types that are serialized to JSON and sent to another tool (via subprocess args, stdout, or HTTP) and flags any that lack a corresponding septa schema. Developers can explicitly mark a payload as `#[septa(accepted_risk)]` or an equivalent annotation to bypass the gate.

**How it works:**
```bash
# septa/scripts/scan-unseamed-payloads.sh
# Greps for struct types that appear in:
# 1. serde_json::to_string() / serde::Serialize in a cross-tool context
# 2. Command::output() / subprocess spawning
# 3. HTTP response bodies in cap server
# Then cross-references against known septa schemas

KNOWN_SCHEMAS=$(ls septa/*.schema.json | sed 's/septa\///' | sed 's/.schema.json//')
# For each serialized struct, check if KNOWN_SCHEMAS contains a matching entry
```

**Tradeoffs:**
- ✅ Automated detection — no manual registry needed
- ✅ Catches new unseamed payloads without requiring developers to remember to update anything
- ❌ High false positive rate — many structs are serialized locally and never cross tool boundaries
- ❌ Heuristic-based — a scanner cannot definitively know if a serialized struct is cross-tool without reading the full call graph
- ❌ Significant implementation effort (the scanner itself is a non-trivial static analysis tool)

**When to pick this:** You are willing to invest in tooling and can tolerate false positives during initial tuning. Better long-term automation than Option A.

---

### Option C: Schema-first enforcement with explicit exemption registry (recommended)

**What it does:** Inverts the current model. The rule becomes: any new cross-tool payload type **must** be registered in septa before it can be merged. Existing unseamed payloads are added to an explicit exemption file (`septa/exemptions.json`) with a severity and rationale. CI fails if a new producer/consumer pair is added without either a schema or an exemption entry.

**How it works:**

```json
// septa/exemptions.json
{
  "exemptions": [
    {
      "payload": "MemoryProtocolSurface",
      "producer": "hyphae/crates/hyphae-mcp/src/memory_protocol.rs",
      "consumers": ["volva/crates/volva-runtime/src/context.rs"],
      "severity": "medium",
      "rationale": "Co-versioned in same workspace; low drift risk until repos separate",
      "tracked_in": "septa/contract-governance-enforcement.md"
    }
  ]
}
```

CI check:
```bash
# septa/scripts/check-cross-tool-payloads.sh
# 1. Parse exemptions.json to get known exempted payloads
# 2. For each known payload type in the registry (schemas + exemptions), verify it still exists
# 3. Flag any payload type that appears in cross-tool call sites but is not in schemas OR exemptions
```

**Tradeoffs:**
- ✅ Makes the governance model explicit and reviewable — exemptions require a rationale
- ✅ Existing unseamed payloads are acknowledged rather than ignored
- ✅ New payloads cannot be added without a deliberate decision (schema or exemption)
- ✅ Exemptions can be promoted to full schemas over time
- ❌ Still requires manual identification of cross-tool call sites for the initial exemption population
- ❌ The CI script needs to know which call sites are cross-tool (same heuristic problem as Option B)
- ❌ Medium implementation effort

**When to pick this:** You want a durable governance model that scales as the ecosystem grows and repos potentially separate. The exemption registry makes the current debt visible without blocking all existing work.

---

### Option D: Full schema-first with no exemptions (strictest)

**What it does:** Every cross-tool serialized payload must have a septa schema. No exemptions. CI blocks any PR that introduces a new cross-tool call without a schema. Existing unseamed payloads must be schema-backed before their next change.

**Tradeoffs:**
- ✅ Strictest enforcement — no way to accidentally add an unseamed payload
- ✅ Septa becomes authoritative for every cross-tool contract
- ❌ High short-term cost — the three existing unseamed payloads (MemoryProtocolSurface, session context, hook envelope) must be fully schema-backed before any other changes land in those files
- ❌ The Claude Code hook envelope may not be possible to fully schema-back if Claude Code doesn't expose its envelope definition
- ❌ Creates friction for rapid iteration — every new cross-tool data shape requires a septa PR

**When to pick this:** Long-term correctness matters more than iteration speed. Commit to writing schemas as the first step of every new cross-tool feature.

---

## Questions for the Human Engineer

Before implementation starts, answer:

1. **Which option?** (A, B, C, or D)
2. **How much do you trust the "co-versioned in same workspace" argument for the three unseamed payloads?** If the answer is "not much," that pushes toward Option C or D.
3. **Is the Claude Code hook envelope schematizable?** Claude Code's hook envelope is not defined by this codebase — it comes from the Claude Code runtime. Can we define a schema for it? Or does it need to be an accepted risk?
4. **What is the enforcement boundary?** Should the check run only on changes to septa/ (catching schema drift), or also on changes to any producer/consumer repo (catching new unseamed payloads)?
5. **How do you want to handle the backlog of 3 known-unseamed payloads?** Schema them all before enabling enforcement? Or enable enforcement with exemptions first?

---

## Implementation Seam (after decision)

- **Likely repo:** `septa`
- **Likely files:** `septa/scripts/` (new governance script), `septa/exemptions.json` (if Option C), CI configs in producer repos
- **Reference seams:** read `septa/validate-all.sh` structure before writing new scripts — match the pattern
- **Spawn gate:** do not spawn an implementer until the human has answered the decision questions above

---

## Verification (after implementation)

```bash
# Governance script should flag known unseamed payloads
bash septa/scripts/check-cross-tool-payloads.sh

# After exemptions or schemas are added, script should pass
bash septa/validate-all.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Governance script detects at least one known unseamed payload
- [ ] Existing schemas all pass `validate-all.sh`
- [ ] New payload added without schema (or exemption) fails CI
- [ ] Backlog of 3 unseamed payloads addressed per chosen option

## Completion Protocol

1. Decision questions answered by human
2. Governance tooling implemented per chosen option
3. Existing 3 unseamed payloads handled (schemed or exempted)
4. CI wired to reject new unseamed payloads
5. Dashboard updated
