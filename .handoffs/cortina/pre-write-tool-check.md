# Cortina: Pre-Write Tool Verification Hook

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Agents can Write or Edit files without ever checking rhizome for code structure or hyphae for relevant context. The tools are available but adoption is optional. A PreToolUse hook can detect when an agent is about to write to a file without having called recommended tools first, and inject an advisory message to nudge the agent.

## What exists (state)

- **Cortina PreToolUse handler**: Handles pre-tool-use events — can inspect and advise before tool execution
- **Tool usage accumulator**: #114b adds per-session tracking of which tools have been called
- **Tool relevance rules**: #115a defines which tools are recommended for which operations
- **Smart Tool Redirection**: #65 covers PreToolUse advisories for tool substitution — different concern but same hook point

## What needs doing (intent)

Add a pre-write check to cortina's PreToolUse handler that compares the current tool call against tool-relevance-rules, checks the session's tool usage accumulator, and injects an advisory if recommended tools haven't been called.

---

### Step 1: Load tool relevance rules at session start

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** #115a (Tool Relevance Rules Contract)

Load `tool-relevance-rules-v1.json` from the project's septa directory (or a bundled default) at session start. Parse into a lookup structure keyed by operation type.

```rust
pub struct RelevanceRuleSet {
    rules: Vec<RelevanceRule>,
}

pub struct RelevanceRule {
    operation: String,
    file_pattern: Option<String>,
    recommended_tools: Vec<RecommendedTool>,
    severity: Severity,
    check_window: CheckWindow,
}

impl RelevanceRuleSet {
    pub fn load(path: &Path) -> Result<Self>;
    pub fn matching_rules(&self, operation: &str, file_path: Option<&str>) -> Vec<&RelevanceRule>;
}
```

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo build --workspace 2>&1 | tail -5
cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Rules loaded from septa contract or bundled default
- [ ] Rules parsed into lookup structure
- [ ] File pattern matching works for glob patterns
- [ ] Graceful fallback if rules file not found (no rules = no checks)
- [ ] Build and tests pass

---

### Step 2: Add pre-write advisory check

**Project:** `cortina/`
**Effort:** 3-4 hours
**Depends on:** Step 1, #114b (Tool Usage Accumulator)

In the PreToolUse handler, when the operation is Write or Edit:

1. Find matching rules from the rule set (by operation and file pattern)
2. Check the tool usage accumulator for whether recommended tools were called in the check window
3. If severity is "required" or "recommended" and the tool wasn't called, emit an advisory
4. The advisory is a structured message (not a block) that the agent receives as context

Advisory format:
```json
{
  "type": "tool_usage_advisory",
  "severity": "recommended",
  "message": "Consider calling rhizome.find_references before editing src/auth.rs — 3 other modules reference symbols in this file",
  "recommended_tools": ["rhizome.find_references", "rhizome.get_structure"],
  "skippable": true
}
```

Important: advisories must NOT block the Write/Edit. They inject context, not gates. The agent can proceed.

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] PreToolUse checks Write/Edit against relevance rules
- [ ] Advisory emitted when recommended tools not called
- [ ] Advisory is non-blocking (agent can always proceed)
- [ ] Severity levels respected (required = stronger wording, optional = gentle suggestion)
- [ ] No advisory when rules file absent or tools already called
- [ ] Tests pass

---

### Step 3: Add unit tests for advisory logic

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Step 2

Test cases:
1. Write to .rs file with no prior rhizome calls → advisory emitted
2. Write to .rs file after rhizome.get_structure called → no advisory
3. Write to .md file with no rules matching → no advisory
4. Rules file missing → no advisories, no error
5. All recommended tools called → no advisory

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test --workspace 2>&1 | tail -10
```

**Checklist:**
- [ ] Happy path tested (tools called → no advisory)
- [ ] Gap path tested (tools not called → advisory)
- [ ] No-rules path tested (missing file → no advisory)
- [ ] File pattern matching tested
- [ ] All tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `cargo build --workspace` and `cargo test --workspace` pass in `cortina/`
3. All checklist items are checked

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsPart of the behavioral guardrails chain (#115a-c). Depends on #115a (rules contract) and #114b (tool usage accumulator). This is the proactive nudge — it fires before the agent writes. #115c adds a retrospective summary at session end. Related to #65 (Smart Tool Redirection) which occupies the same PreToolUse hook point but for tool substitution, not adoption nudging.
