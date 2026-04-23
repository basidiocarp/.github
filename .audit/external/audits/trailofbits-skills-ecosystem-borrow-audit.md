# Trail of Bits Skills Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `trailofbits/skills` (github.com/trailofbits/skills)
Lens: what to borrow from the repo, how it fits the basidiocarp ecosystem, and what it suggests improving in the ecosystem itself

## One-paragraph read

`trailofbits/skills` is the most production-grade skill authoring reference available in the Claude Code ecosystem. Its strongest material is not the security domain knowledge itself — that is expected from a professional audit firm — but the engineering discipline it applies to skill authoring: mandatory hard gates before destructive actions, explicit "Rationalizations to Reject" sections that pre-empt the specific shortcuts LLMs take when fatigued or under pressure, orchestration diagrams that show exactly how subagents and tasks relate, and a CI validation pipeline that enforces frontmatter, hardcoded-path, and Codex-mapping consistency. The lamella codeql and semgrep skills are already downstream ports of this repo's work, which confirms the primary fit. The next borrowable tier — `fp-check`, `differential-review`, `variant-analysis`, and `workflow-skill-design` — is where the remaining high-value material lives, and none of it has a lamella equivalent yet.

## What Trail of Bits Skills is doing that is solid

### 1. Rationalizations to Reject as a first-class skill section

Every security-facing skill in this repo includes a table of common shortcuts or justifications that the model is likely to invoke during execution, paired with the exact counter-argument. This is not a "When NOT to Use" section. It is a list of mid-execution cognitive traps with refutations baked in.

Evidence:

- `plugins/static-analysis/skills/codeql/SKILL.md` — 12 named rationalizations including "Zero findings means the code is secure", "security-and-quality is the broadest suite", and "just pass the pack names directly"
- `plugins/fp-check/skills/fp-check/SKILL.md` — 6 named rationalizations including "Skipping full verification for efficiency" and "The code looks unsafe, reporting without tracing data flow"
- `plugins/differential-review/skills/differential-review/SKILL.md` — 7 named rationalizations including "Small PR, quick review" (with Heartbleed as the counter-example) and "Blast radius is obvious"

This pattern is not in the Lamella skill-authoring-convention or skills-spec. It is the highest-signal item in this repo.

### 2. Hard gates with forced confirmation before consequential actions

The Semgrep skill enforces user confirmation before spawning any scan tasks. The original request is explicitly not treated as approval. The gate is implemented via `AskUserQuestion` and tracked as a task dependency so the model cannot falsely mark it complete without actual user input.

Evidence:

- `plugins/static-analysis/skills/semgrep/SKILL.md` — "User must approve the scan plan (Step 3 is a hard gate) — The original 'scan this codebase' request is NOT approval"
- The orchestration diagram in that same file shows the gate as a named node in the dependency graph, not a prose instruction

This is structurally different from a simple reminder. It forces a task-dependency bottleneck.

### 3. Hooks-enforced completeness verification for subagent output

The `fp-check` plugin includes a `hooks.json` that intercepts both `Stop` and `SubagentStop` lifecycle events and runs an LLM-based completeness check before allowing the session to close. The hook specifies exactly which phases each agent type must have produced, per agent role.

Evidence:

- `plugins/fp-check/hooks/hooks.json` — the `Stop` hook verifies 7 named phases and a 6-gate review were completed for every bug; the `SubagentStop` hook verifies per-role output completeness for `data-flow-analyzer`, `exploitability-verifier`, and `poc-builder`

This is the most sophisticated hook usage observed across all external audits in this corpus. It uses the `Stop` lifecycle event as a correctness enforcer, not just a cleanup step.

### 4. Progressive disclosure implemented at the reference-chain level, not just as prose advice

Every large skill keeps `SKILL.md` under 500 lines and externalizes depth into `references/` and `workflows/`. The CodeQL skill has 12 distinct reference files covering macOS arm64e workarounds, build failure catalogs, quality assessment metrics, SARIF processing, ruleset catalogs, and performance tuning. The structure is one hop from `SKILL.md` — reference files do not chain to more reference files.

Evidence:

- `plugins/static-analysis/skills/codeql/references/` — 12 reference files
- `plugins/static-analysis/skills/codeql/workflows/` — 3 workflow files: `build-database.md`, `create-data-extensions.md`, `run-analysis.md`
- `plugins/fp-check/skills/fp-check/references/` — 6 files covering bug-class-specific verification, gate reviews, evidence templates, and false-positive pattern libraries

The Lamella skills-spec mentions progressive disclosure but the existing lamella security skills (codeql, semgrep) do carry forward this pattern. The gap is that the `references/` content in this repo is richer and more systematically organized.

### 5. The `workflow-skill-design` meta-skill as an authoring canon

This skill teaches how to design workflow skills using structural patterns (routing, sequential pipeline, linear progression, safety gate, task-driven). It includes an anti-pattern catalog with 20 named anti-patterns, each with a one-line fix and a before/after example. It also includes a tool-assignment guide that maps component type to minimum tool set, and an explicit principle that the `description` field is the trigger, not the body.

Evidence:

- `plugins/workflow-skill-design/skills/designing-workflow-skills/SKILL.md` — the full pattern selection tree, anti-pattern quick reference (AP-1 through AP-20), and the component type to tool set table
- `plugins/workflow-skill-design/skills/designing-workflow-skills/references/anti-patterns.md` — full catalog
- `plugins/workflow-skill-design/skills/designing-workflow-skills/references/workflow-patterns.md` — 5 patterns with structural skeletons

This is a codified authoring canon, not just guidance prose.

### 6. CI validation that enforces structural invariants across all skills

The validate workflow checks YAML frontmatter presence and required fields, hardcoded user paths (not just example paths), personal email policies, plugin metadata consistency across `plugin.json`, `marketplace.json`, `README.md`, and `CODEOWNERS`, and Codex skill mapping completeness.

Evidence:

- `.github/workflows/validate.yml` — inline Python checking frontmatter and hardcoded paths; delegates to `validate_plugin_metadata.py` and `validate_codex_skills.py`
- `.github/scripts/validate_plugin_metadata.py` — parses marketplace JSON, CODEOWNERS, README, and plugin JSON in a single pass and reports all discrepancies together

The `pre-commit-config.yaml` adds ruff, shellcheck, shfmt, YAML check, JSON check, and trailing whitespace enforcement as a pre-commit gate.

### 7. Separation of scan-and-fix from verdict

The `fp-check` skill enforces a clean separation between phases that gather evidence (data flow analysis, exploitability verification, PoC creation) and the gate review that issues a final verdict. The model cannot issue a verdict until all 6 gates have been evaluated with evidence. Devil's advocate review is a mandatory phase, not an optional note.

Evidence:

- `plugins/fp-check/skills/fp-check/references/gate-reviews.md` — 6-gate table with explicit Pass/Fail criteria per gate; verdict only after all gates
- `plugins/fp-check/skills/fp-check/references/evidence-templates.md` — templates for data flow, mathematical proofs, attacker control, and devil's advocate

### 8. Variant analysis as a systematic skill, not an ad hoc search

The `variant-analysis` skill formalizes the process of generalizing from a known bug to a class search: start with an exact match, verify it matches only the known instance, then abstract one element at a time with false-positive rate tracking. It stops generalization when false-positive rate exceeds 50%.

Evidence:

- `plugins/variant-analysis/skills/variant-analysis/SKILL.md` — the 5-step process with explicit FP rate threshold and pitfall catalog (4 named pitfalls with examples)
- Tool selection table maps scenario to tool (ripgrep → Semgrep → CodeQL) based on depth needed

## What to borrow directly

### Borrow now — lamella

**Rationalizations to Reject as a required section for security skills.** The existing lamella `skill-authoring-convention.md` has no equivalent. Every security skill in lamella should gain this section. The convention doc should name it as required for audit or security skills, the same way Trail of Bits names it in their `CLAUDE.md` quality standards.

**The `workflow-skill-design` skill content as a lamella authoring reference.** The anti-pattern catalog (AP-1 through AP-20), the pattern-selection tree, and the tool-assignment guide are the best structured authoring canon observed in any external audit. These ideas should be absorbed into lamella's `docs/authoring/` as concrete references, not just as inspiration for prose edits to existing docs.

**Output directory discipline from the CodeQL and Semgrep skills.** The pattern of resolving `$OUTPUT_DIR` once at the start, auto-incrementing when the default exists, storing all generated artifacts inside it, and never scattering files in the working directory is already in the lamella CodeQL and Semgrep ports. Confirm this pattern is codified in `docs/authoring/best-practices.md` so it applies to all future skills that generate files.

**Variant analysis skill.** Lamella has no equivalent. The 5-step process is portable and does not require Trail of Bits domain context. It fits `lamella/resources/skills/security/` directly alongside the existing analysis skills.

### Borrow now — cortina

**The `hooks.json` completeness-enforcement pattern from `fp-check`.** Using `Stop` and `SubagentStop` hooks to verify phase-by-phase completeness before a session closes is the right model for cortina to study when designing completeness enforcement hooks. The implementation pattern — an LLM-based prompt that scans the conversation for evidence of named phases — is directly applicable. The domain-specific content (fp-check phases) would differ, but the hook shape is portable.

## What to adapt, not copy

### Hard gate pattern — lamella

The Semgrep hard gate (`AskUserQuestion` + task dependency + explicit "original request is not approval") should be the model for any lamella skill that triggers an expensive or side-effecting action. The adaptation needed is making this a named pattern in the lamella authoring docs with a skeleton, rather than copying the Semgrep-specific prompt text. The safety gate pattern already exists in the `workflow-skill-design` skill's pattern catalog; lamella authoring docs should reference this pattern by name.

### `differential-review` — lamella or canopy

The differential-review skill's codebase-size strategy (SMALL/MEDIUM/LARGE with different analysis depth) and blast-radius quantification step are strong ideas. The six-phase structure (triage → code analysis → test coverage → blast radius → adversarial → report) is coherent and the supporting files (methodology, adversarial, reporting, patterns) implement clean progressive disclosure. The adaptation needed is decoupling the git-specific implementation details from the review methodology, since the ecosystem's canopy tool handles task coordination and the review methodology belongs in lamella. If differential review is added to lamella, the `adversarial.md` structure (attacker model, attack vectors, exploitability rating, exploit scenario template) should be a separate reference file, not merged into the main skill body.

### `fp-check` agent model — lamella plus canopy

The `fp-check` plugin spawns three specialized subagents (`data-flow-analyzer`, `exploitability-verifier`, `poc-builder`) with a gate-review agent that blocks on all three. This maps well to the canopy coordination model for task ownership and handoff. The adaptation is that in the basidiocarp model, canopy owns the coordination plane and lamella packages the skill content. A direct port would mix those concerns. The right shape is: lamella provides the skill content and subagent prompts; canopy handles the task dependency graph. The gate review logic could be a cortina Stop hook.

### `semgrep-rule-creator` — lamella

The rule authoring checklist (7-step, test-first, AST analysis, iterate, optimize), the distinction between taint mode and pattern matching with clear preference ordering, and the strict prohibition on `todook`/`todoruleid` annotations are all worth absorbing into the lamella Semgrep skill as authoring guidance. The `WebFetch` step that pulls live Semgrep docs before writing rules is clever; the adaptation is verifying that `{baseDir}` path handling works correctly in lamella's build context.

## What not to borrow

### The plugin system as a template

Trail of Bits builds for the Claude Code plugin marketplace with `plugin.json`, `marketplace.json`, `CODEOWNERS`, and a Codex `.codex/skills/` sidecar tree. Lamella has its own manifest-driven build pipeline that serves a different deployment model. The Trail of Bits plugin wiring is product-specific to their release and distribution setup, not a general pattern.

### Smart contract and blockchain security skills

`building-secure-contracts`, `entry-point-analyzer`, `spec-to-code-compliance`, and `zeroize-audit` are domain-specific to the Trail of Bits client base. The ecosystem has no blockchain or smart contract workload. Skip.

### Mobile, malware, and infrastructure skills

`firebase-apk-scanner`, `yara-authoring`, `dwarf-expert`, `debug-buttercup`, `constant-time-analysis` — these are valuable within Trail of Bits' practice but have no general-purpose fit in basidiocarp.

### The `audit-context-building` skill as-is

The ultra-granular line-by-line analysis mode (First Principles, 5 Whys, 5 Hows applied at micro scale) is a specialist audit posture designed for pre-engagement context building. Lamella's `security-audit-methodology` skill already covers the general methodology surface. Borrowing the ultra-granular philosophy would require a separate lamella skill targeting pre-engagement deep-dive scenarios, and the demand for that in the ecosystem is unclear. Worth revisiting if a client-engagement workflow ever materializes.

### `let-fate-decide` and `culture-index`

These are not security infrastructure. Skip.

## How Trail of Bits Skills fits the ecosystem

### Best fit by repo

**lamella** — primary and dominant fit. Skill authoring patterns, the Rationalizations to Reject convention, the hard gate pattern, progressive disclosure structure, anti-pattern catalog, variant analysis skill, and SARIF skill all land here. The existing codeql and semgrep skills in lamella are already downstream of this repo; the next tier is fp-check methodology and variant analysis.

**cortina** — secondary fit for the `Stop` and `SubagentStop` completeness enforcement hook pattern. This is the most novel hook design observed across all external audits.

**canopy** — tertiary fit for the fp-check multi-agent coordination model. The task dependency graph with phased verification maps to canopy's task ownership model.

**mycelium** — indirect fit only. Static analysis tools produce verbose output (SARIF, CodeQL build logs, Semgrep JSON) that mycelium's output filtering should be aware of, but this is a configuration concern, not a structural borrowing.

**septa** — no contract needed. The ideas here are skill content and authoring patterns, not cross-tool wire protocols. No septa contract needed.

**canopy, hyphae, stipe** — not a fit for direct borrowing. The features here are authoring conventions and security methodology, not coordination, memory, or install infrastructure.

## What Trail of Bits Skills suggests improving in your ecosystem

### 1. Lamella should make Rationalizations to Reject a required section for security and audit skills

The existing `skill-authoring-convention.md` defines required sections but does not name this one. Given that the most common failure mode in LLM-assisted security work is premature shortcutting, this is a high-impact addition to the authoring standard. It should be named as required for any skill that involves multi-phase analysis or could produce consequential output.

### 2. Lamella authoring docs should name the safety gate as a first-class pattern

The current `best-practices.md` and `skills-spec.md` do not describe the confirmation gate pattern. It should be named, given a skeleton, and linked from the pattern-selection guidance, the same way Trail of Bits names it in `workflow-skill-design`.

### 3. Cortina should study the fp-check hook model before its next hook design cycle

The `Stop` and `SubagentStop` completeness enforcement pattern is the most sophisticated external use of hooks observed across the audit corpus. Cortina should absorb it as a reference design before finalizing its own completeness or lifecycle enforcement strategy.

### 4. Lamella should audit its existing security skills against the anti-pattern catalog

The 20 anti-patterns in `workflow-skill-design` (AP-1 through AP-20) provide a concrete checklist. The existing lamella codeql and semgrep skills should be reviewed against this catalog, particularly AP-2 (monolithic SKILL.md over 500 lines), AP-6 (unnumbered phases), AP-16 (missing rationalizations), and AP-18 (Cartesian product tool calls). Some of these were already fixed in the codeql and semgrep ports but the check is worth running explicitly.

### 5. The `variant-analysis` skill is a gap in lamella's security coverage

Lamella has static analysis skills but no formalized vulnerability variant hunting skill. This is a clean borrow — the methodology is tool-agnostic and the existing tools (ripgrep, Semgrep, CodeQL) are already represented in lamella.

## Verification context

No local build or test run was performed. The audit is based on direct GitHub API access to the repository content at the time of the audit. The repository is public. The validation tooling (`validate_plugin_metadata.py`, `validate_codex_skills.py`, `validate.yml`) was read directly. The skills analyzed are the canonical versions in the `main` branch as of the audit date.

The lamella codeql and semgrep skills confirm that prior synchronization between this repo and basidiocarp has already occurred. The SKILL.md content in `lamella/resources/skills/security/codeql/` and `lamella/resources/skills/security/semgrep/` matches the Trail of Bits originals closely with lamella-format adaptations (`origin: lamella`, modified description field, adjusted section headers).

## Final read

Borrow: the Rationalizations to Reject convention as a required lamella authoring section; the safety gate pattern as a named lamella authoring pattern; the `workflow-skill-design` anti-pattern catalog as a lamella authoring reference; the variant analysis skill as a new lamella security skill; the fp-check Stop hook completeness model as a cortina reference design.

Adapt: the differential-review methodology (strip the git implementation details, keep the codebase-size strategy and blast-radius step); the fp-check multi-agent model (canopy coordinates, lamella packages); the rule-creator checklist for the lamella Semgrep skill.

Skip: the plugin distribution wiring, smart contract domain skills, mobile and malware skills, the audit-context ultra-granular mode unless an engagement workflow materializes.

The clearest actionable gap is the missing Rationalizations to Reject convention in lamella's authoring standard. It costs nothing to add to `docs/authoring/skill-authoring-convention.md` and is the highest-signal pattern in the entire repo.
