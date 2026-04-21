# Hymenium: Handoff Document Parser

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** hymenium/src/parser/...
- **Cross-repo edits:** none
- **Non-goals:** decomposition logic, workflow engine, canopy integration
- **Verification contract:** cargo test -p hymenium
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when complete

## Problem

Hymenium needs to read the structured handoff markdown documents in `.handoffs/` and extract their rich metadata: handoff metadata blocks, steps with dependencies and effort estimates, verification commands, file scope, and checklist items. Canopy's existing `import_handoff` parser only extracts step titles and body text — it misses the metadata block, step dependencies, effort, project directory, and verification commands that the templates now include.

## What exists (state)

- **Canopy import_handoff**: Parses `### Step N:` sections into subtasks. Does not extract metadata block, `Depends on:`, `Effort:`, `Project:`, `#### Verification`, or `#### Files to modify`
- **Handoff template**: `.handoffs/` documents follow WORK-ITEM-TEMPLATE.md with structured metadata, steps, and verification
- **Handoff metadata block**: New addition — dispatchability, owning repo, write scope, verification contract, completion update rule

## What needs doing (intent)

Build a comprehensive handoff document parser in hymenium that extracts the full structure into typed Rust data.

---

### Step 1: Define parsed handoff data model

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** #118a (Crate Scaffold)

Define types in `src/parser/mod.rs`:

```rust
pub struct ParsedHandoff {
    pub title: String,
    pub metadata: HandoffMetadata,
    pub problem: String,
    pub state: Vec<String>,
    pub intent: String,
    pub steps: Vec<ParsedStep>,
    pub completion_protocol: Option<String>,
    pub context: Option<String>,
}

pub struct HandoffMetadata {
    pub dispatchability: Dispatchability,
    pub owning_repo: String,
    pub allowed_write_scope: Vec<String>,
    pub cross_repo_rule: Option<String>,
    pub non_goals: Vec<String>,
    pub verification_contract: String,
    pub completion_update: String,
}

pub enum Dispatchability {
    Direct,
    Umbrella,
}

pub struct ParsedStep {
    pub number: u32,
    pub title: String,
    pub project: Option<String>,
    pub effort: Option<String>,
    pub depends_on: Vec<String>,
    pub description: String,
    pub files_to_modify: Vec<FileModification>,
    pub verification: Option<VerificationBlock>,
    pub checklist: Vec<ChecklistItem>,
}

pub struct FileModification {
    pub path: String,
    pub description: String,
}

pub struct VerificationBlock {
    pub commands: Vec<String>,
    pub paste_markers: Vec<PasteMarker>,
}

pub struct ChecklistItem {
    pub text: String,
    pub checked: bool,
}

pub struct PasteMarker {
    pub line_number: usize,
    pub has_content: bool,
}
```

#### Verification

```bash
cd hymenium && cargo build 2>&1 | tail -5
cargo test 2>&1 | tail -5
```

**Checklist:**
- [ ] All types defined with doc comments
- [ ] Types are serializable (derive Serialize, Deserialize)
- [ ] Build passes

---

### Step 2: Implement markdown parser

**Project:** `hymenium/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Implement the parser in `src/parser/markdown.rs`:

1. Extract title from first `# ` heading
2. Parse the metadata block (between `## Handoff Metadata` and next `##`)
3. Parse `## Problem`, `## What exists`, `## What needs doing` sections
4. Parse `### Step N:` sections with all subfields
5. Extract `#### Verification` blocks with commands
6. Extract `#### Files to modify` blocks
7. Count checkboxes and paste markers

Handle edge cases:
- Missing metadata block (older handoffs) → return None for metadata
- Missing step subfields → return None for optional fields
- Malformed markdown → return best-effort parse with warnings

#### Verification

```bash
cd hymenium && cargo test parser 2>&1 | tail -10
```

**Checklist:**
- [ ] Parses title, metadata, problem, state, intent sections
- [ ] Parses steps with dependencies, effort, project
- [ ] Extracts verification commands
- [ ] Extracts files to modify
- [ ] Counts checkboxes and paste markers
- [ ] Handles missing metadata gracefully
- [ ] Tests pass

---

### Step 3: Add tests with real handoff fixtures

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Copy 2-3 real handoff documents from `.handoffs/` into `hymenium/tests/fixtures/` and write tests that:
1. Parse each fixture successfully
2. Verify extracted metadata matches expected values
3. Verify step count, dependencies, and effort estimates
4. Verify checklist counts
5. Test an older handoff without metadata block

#### Verification

```bash
cd hymenium && cargo test parser 2>&1 | tail -10
```

**Checklist:**
- [ ] At least 2 real handoff fixtures used
- [ ] Metadata extraction verified
- [ ] Step parsing verified with dependencies and effort
- [ ] Old-format handoff handled gracefully
- [ ] All tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output pasted
2. `cargo test` passes in `hymenium/`
3. All checklist items checked

## Context

Part of hymenium chain (#118c). Depends on #118a (crate scaffold). The parser is the input layer — everything else (decomposition, dispatch, monitoring) consumes its output.
