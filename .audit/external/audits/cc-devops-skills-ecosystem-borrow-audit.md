# cc-devops-skills Ecosystem Borrow Audit

Date: 2026-04-23
Repo reviewed: `akin-ozer/cc-devops-skills`
Lens: DevOps skill library with generator/validator pairs, shell scripts, regression tests, and a GitHub Actions drop-in wrapper

## One-paragraph read

`cc-devops-skills` is a mature, production-oriented Claude Code skill pack for DevOps work. It ships 31 skills across five domains — IaC (Terraform, Terragrunt, Ansible), CI/CD (GitHub Actions, GitLab CI, Azure Pipelines, Jenkins), containers and Kubernetes (Docker, Helm, raw YAML, debugging), observability (PromQL, LogQL, Loki, Fluent Bit), and scripting (Bash, Makefile). Every domain except k8s-debug follows the same generator-plus-validator pairing. Each skill uses YAML frontmatter with `name` and `description`, a checklist-driven step table in `SKILL.md`, a `references/` directory of domain knowledge, shell scripts to wrap real CLI tools, and a `tests/` directory with regression tests against those scripts. The most substantive evidence of engineering quality is in the Terraform validator: a Python HCL parser with a cached-virtualenv wrapper, a Checkov wrapper that preserves exit codes reliably, regression tests that cover parse errors, implicit provider detection, argument handling, and stub-based checkov exit-code propagation. The repo also ships a GitHub Actions `action.yml` that wraps `anthropics/claude-code-action@v1` and injects the marketplace automatically, which is a packaging and distribution pattern that stands on its own. The primary fit is `lamella`, which already owns this territory but has meaningful gaps in validation tooling, regression testing, script wrappers, and the generator/validator split that this repo makes concrete.

## What cc-devops-skills is doing that is solid

### 1. Generator/validator skill pairing as a first-class pattern

Every IaC and CI/CD domain is split into a generator skill and a validator skill. The generator invokes the validator at the end of its checklist. This is an explicit, cross-skill composition contract enforced at the authoring level rather than left implicit.

Evidence:
- `terraform-generator/SKILL.md`: Step 7 in the required checklist is `Invoke \`Skill(devops-skills:terraform-validator)\``
- `helm-generator/SKILL.md`: analogous structure
- Every paired domain follows the same pattern

### 2. Checklist-driven SKILL.md with explicit done criteria

SKILL.md files use a step table with REQUIRED/Recommended tags, a Done Criteria section, and a normative vocabulary (MUST, SHOULD, MAY in the k8s generator). The model cannot skip steps without violating a written contract. Done criteria are concrete and enumerable, not vague.

Evidence:
- `terraform-generator/SKILL.md`: 9-step table with ✅ REQUIRED markers and a prose block enforcing fix-and-revalidate loops
- `terraform-validator/SKILL.md`: 13-step checklist with explicit Done Criteria: "Validation instructions are executable end-to-end with one deterministic command path", "Wrapper scripts behave predictably in both success and failure paths"
- `k8s-debug/SKILL.md`: Done criteria include "Root cause is identified and tied to evidence (events/logs/config/state)"

### 3. Shell script wrappers with real contracts

Scripts are not glue code. `extract_tf_info_wrapper.sh` handles a Python dependency (python-hcl2) by auto-creating a cached virtualenv at `~/.cache/terraform-validator/` and reusing it across runs. `run_checkov.sh` is a full CLI wrapper with argument parsing, allowed-format validation, and correct exit-code propagation. Both have documented exit code contracts.

Evidence:
- `extract_tf_info_wrapper.sh`: fast-path check for system python-hcl2, venv creation and reuse, delegates to `extract_tf_info.py`
- `run_checkov.sh`: `ALLOWED_FORMATS` array, `--compact`, `--format`, `--skip`, `--check` argument handling; passes `$?` through cleanly
- `cluster_health.sh`: `WARN_COUNT`, `CHECK_FAIL_COUNT`, `BLOCKED_COUNT` exit code system; `--strict` flag toggles warning sensitivity

### 4. Regression tests covering script contracts

The Terraform validator has a `tests/test_regression.sh` that:
1. Creates synthetic `.tf` fixtures in a temp directory
2. Confirms the parser exits non-zero and reports `parse_error_count >= 1` on malformed HCL
3. Confirms implicit provider detection (random, http) populates `all_provider_names_for_docs`
4. Confirms the wrapper exits non-zero for missing or nonexistent path arguments
5. Stubs out `checkov` with a controllable exit code and verifies the wrapper propagates it

This is behavioral regression testing of the scripts-as-contract layer. Lamella has nothing comparable.

Evidence:
- `terraform-validator/tests/test_regression.sh`: full bash regression test with Python inline assertions

### 5. References as structured domain knowledge

Each skill ships a `references/` directory with domain-specific documents the skill is instructed to read at specific steps. The Terraform validator has `security_checklist.md`, `best_practices.md`, `common_errors.md`, and `advanced_features.md`. The validator's step table specifies which document to read at which step (e.g., read `security_checklist.md` before the security scan, consult `common_errors.md` only when errors occur). This is progressive disclosure applied to reference loading.

Evidence:
- `terraform-validator/SKILL.md`: "Required Reference File Reading" table mapping step → reference file with explicit When column
- `k8s-debug/SKILL.md`: "Reference Navigation Map" routing by observed symptom to specific section

### 6. Reference navigation maps (symptom routing)

`k8s-debug` introduces a symptom-to-reference routing table: given a symptom (CrashLoopBackOff, DNS failure, PVC pending), the table tells the model which file to open and which section to start at. This avoids dumping all reference material at once.

Evidence:
- `k8s-debug/SKILL.md`: "Reference Navigation Map" table with Symptom/Need, Open, Start Section columns

### 7. Tool-fallback language and graceful degradation

Both the SKILL.md files and the scripts have explicit fallback language: if a tool is missing, ask the user, provide the install command, re-run if the user accepts. Scripts continue with reduced output when optional tools (`jq`, `kubectl top`) are unavailable.

Evidence:
- `terraform-validator/SKILL.md`: "Handling Missing Tools" section with per-tool recovery workflows
- `cluster_health.sh`: continues on individual check failures, accumulates into exit code summary

### 8. GitHub Actions drop-in wrapper

The `action.yml` is a full drop-in replacement for `anthropics/claude-code-action@v1` that merges the marketplace URL and plugin name into the caller's inputs and delegates the rest. The merge logic is explicit, minimal, and respects the upstream surface completely. This is a distribution pattern for skill injection that is independent of the skill content.

Evidence:
- `action.yml`: composite action with `merge_multiline` shell function, `emit_output` using `GITHUB_OUTPUT` heredoc, upstream inputs mirrored completely
- `docs/drop-in-wrapper.md`: documents passthrough mode and extension inputs

## What to borrow directly

### Borrow: generator/validator skill split as an explicit authoring pattern

Lamella already has `terraform-patterns` and `github-actions-validator` as separate skills, but there is no authoring rule that mandates the pairing or makes the generator explicitly invoke the validator. The generator-invokes-validator pattern should become a named lamella authoring convention: any generator skill for a domain that has a validator must name that validator in its final required step.

Best fit: `lamella` authoring docs (`docs/authoring/skills-spec.md`, `docs/authoring/best-practices.md`).
Septa contract: no — this is an authoring convention, not a wire format.
Borrow now.

### Borrow: Done Criteria section as a required SKILL.md section

`cc-devops-skills` makes done criteria explicit, concrete, and enumerable at the bottom of every complex skill. Lamella's skills-spec.md does not require a Done Criteria section. Adding it as a required section for skills with multi-step workflows would improve skill authoring quality.

Best fit: `lamella` skills-spec and skill template.
Septa contract: no.
Borrow now.

### Borrow: Reference Navigation Map for troubleshooting/debugging skills

The symptom-to-reference table from `k8s-debug` is directly applicable to lamella debugging and troubleshooting skills (e.g., `docker-troubleshoot`, any future incident-commander variant). Rather than front-loading all references, route the model to the specific section it needs based on observed symptoms.

Best fit: `lamella` skill authoring pattern, immediately applicable to `docker-troubleshoot`, `incident-commander`, and similar skills.
Septa contract: no.
Borrow now.

### Borrow: checklist-driven step table with REQUIRED markers

The tabular step checklist with explicit REQUIRED/Recommended tags and a prose enforcement block is a concrete improvement over lamella's current MUST DO/MUST NOT DO constraint lists. The table format gives the model a numbered, trackable workflow rather than a prose constraint block.

Best fit: `lamella` skill authoring pattern.
Septa contract: no.
Borrow now.

## What to adapt, not copy

### Adapt: shell script wrappers with exit code contracts

The Terraform validator's script architecture (a shell wrapper that handles dependencies, delegates to a core tool, and propagates exit codes reliably) is a strong pattern. Lamella's `github-actions-validator` skill already has a `scripts/` directory. The pattern to adopt is not the Terraform-specific scripts but the structural conventions: wrapper scripts handle their own dependencies, document their exit code contract, and the SKILL.md names the exact command to run (not just "run the tool").

Adaptation needed: lamella skills that invoke CLI tools should wrap those calls in scripts that follow this contract. The existing `github-actions-validator` scripts directory is the right place to start.
Best fit: `lamella`, applied skill by skill as validators are written or revised.

### Adapt: regression tests for skill scripts

The behavioral regression test in `terraform-validator/tests/test_regression.sh` covers the script-as-contract layer with synthetic fixtures. Lamella has no equivalent. The pattern to adopt is: any lamella skill with shell scripts should have a `tests/` directory containing a regression test that verifies the script's core contract (argument handling, exit codes on error, and at least one happy-path smoke check).

Adaptation needed: the specific test assertions are Terraform-specific. The structure (temp dir, synthetic fixture, inline Python or bash assertion, EXIT CODE propagation stub) is portable.
Best fit: `lamella`. This should be added to the lamella AGENTS.md or authoring docs as a recommended authoring standard for validator skills.

### Adapt: progressive reference loading by step

The Terraform validator's Required Reference File Reading table (which document, when, why) is more precise than lamella's current reference loading: lamella skills typically say "load based on context" without specifying which step triggers which reference. Adapt this into a column in the Reference Guide table already used by lamella skills: add a "Load When" column that specifies the triggering condition.

Lamella already has the Reference Guide table pattern in `terraform-patterns/SKILL.md`. Adding a "Load When" column is a small, concrete improvement.
Best fit: `lamella` skill authoring pattern. Already partially present.

### Adapt: tool-fallback language as an authoring requirement

Lamella's skills-spec.md does not require skills to document what happens when a required tool is absent. `cc-devops-skills` treats this as mandatory: every tool dependency has a recovery workflow. This should be added as an authoring requirement in lamella's best-practices doc.

Best fit: `lamella` authoring docs.

### Adapt: GitHub Actions wrapper pattern for lamella marketplace distribution

The `action.yml` drop-in wrapper — a composite action that merges a marketplace URL and plugin name into the upstream inputs — is a distribution pattern for making the lamella marketplace easy to adopt in CI. Lamella does not currently ship a GitHub Actions wrapper. The wrapper design is clean and simple enough to port. The adaptation needed is: replace the hardcoded `akin-ozer/cc-devops-skills` defaults with `basidiocarp/lamella` equivalents.

Best fit: `lamella` (distribution). This is low priority but a real distribution gap.
Septa contract: no.

## What not to borrow

### Skip: the IaC content itself

Lamella already has `terraform-patterns`, `github-actions-validator`, `helm-charts`, `kubernetes-manifest-generator`, `kubernetes-security-policies`, `promql`, `prometheus-configuration`, `grafana-dashboards`, `ansible`, `docker-patterns`, `docker-troubleshoot`, and others. The domain coverage is largely overlapping. The content in `cc-devops-skills` references (security checklists, best practices, provider examples) is domain-specific and would need to be evaluated individually against lamella's existing references before any import. The risk of redundancy and drift is high.

### Skip: Context7 integration

The Terraform validator is tightly coupled to `mcp__context7__resolve-library-id` and `mcp__context7__query-docs` for provider documentation lookup. This is a product-specific MCP dependency that basidiocarp does not use and should not import as a lamella dependency.

### Skip: the observability generator skills (promql-generator, logql-generator, loki-config-generator)

Lamella has `promql`, `prometheus-configuration`, and `otel-collector` already. The observability generators in `cc-devops-skills` use an interactive planning workflow (multi-stage question/answer) that is better suited for a conversational UI than for lamella's structured skill format. The promql-generator in particular front-loads several stages of interactive clarification before generating anything, which conflicts with lamella's preference for deterministic, bounded workflows.

### Skip: the Codex plugin manifest

The `.codex-plugin/plugin.json` is a Codex Desktop integration that maps to a different packaging path than lamella's build system. Lamella already manages its own Codex packaging. Do not import this manifest format.

### Skip: the `.claude-plugin/marketplace.json` format

The marketplace manifest is a simple owner/plugin registration that maps to the Claude Code marketplace. Lamella has its own manifest format. The cc-devops-skills format is not richer or more expressive; adopting it would just add a second manifest format.

## How cc-devops-skills fits the ecosystem

### Best fit by repo

- **lamella**: Strong fit. Generator/validator split, checklist step tables, Done Criteria, progressive reference loading, reference navigation maps, script wrapper conventions, regression test structure, and GitHub Actions distribution wrapper are all lamella-owned concerns.
- **septa**: No fit. No cross-tool wire contracts are involved. Skill authoring conventions do not need septa coordination.
- **mycelium**: No fit. The output filtering concern does not arise here.
- **canopy**: No fit. Skills are not task coordination artifacts.

### Septa contract needed?

No. The improvements are all authoring conventions and build-time standards. They do not cross tool boundaries at runtime.

### New tool candidate?

No. Every borrowable idea lands in lamella.

## What cc-devops-skills suggests improving in your ecosystem

### Lamella skills lack a validation scripting standard

Lamella has multiple `scripts/` directories in skills (e.g., `github-actions-validator/scripts/`) but no authoring rule that defines what scripts must do, how they handle exit codes, or what argument contracts they must expose. `cc-devops-skills` treats the scripts layer as a first-class contract. Lamella's skills-spec.md should add a Scripts section that covers: exit code contract, dependency handling (install or fail clearly), argument validation, and required wrapper structure.

### Lamella has no regression tests for skill scripts

Every lamella skill script that wraps a CLI tool has zero behavioral tests. `cc-devops-skills` demonstrates that a minimal regression test (synthetic fixture, argument contract, exit code propagation stub) is achievable in a single bash file and catches real failure modes. Lamella's AGENTS.md or authoring docs should require a `tests/` directory for any skill that ships scripts.

### Lamella's generator skills do not explicitly invoke validators

Lamella has both generator and validator skills for overlapping domains (Terraform, GitHub Actions, Kubernetes) but does not enforce the cross-skill invocation. The generator should name the validator in its final step. This is an authoring gap, not a build-system gap.

### Lamella's Done Criteria are implicit

Lamella skills end with a Constraints section. There is no Done Criteria block. For multi-step workflows with scripts, adding an explicit Done Criteria section makes it unambiguous when the skill's work is complete.

### Lamella has no distribution wrapper for GitHub Actions

Any team using lamella skills in a GitHub Actions workflow must know to configure the marketplace and plugin name manually. A drop-in action.yml that injects the marketplace automatically removes that friction. `cc-devops-skills` ships this; lamella does not.

## Verification context

- Repository read via GitHub API (`gh api repos/akin-ozer/cc-devops-skills/contents/...`)
- SKILL.md files read in full for: `terraform-generator`, `terraform-validator`, `k8s-debug`, `helm-generator` (header), `github-actions-generator` (header), `bash-script-generator` (header), `promql-generator` (header), `k8s-yaml-generator` (header)
- Scripts read in full: `extract_tf_info_wrapper.sh`, `run_checkov.sh` (header), `cluster_health.sh` (header)
- Regression test read in full: `terraform-validator/tests/test_regression.sh`
- Manifests read: `action.yml`, `.claude-plugin/marketplace.json`
- Reference file list confirmed for: terraform-generator, terraform-validator, k8s-debug, github-actions-generator
- Lamella cross-checked: `resources/skills/devops/` directory (29 existing devops skills), `lamella/docs/authoring/skills-spec.md`, `resources/skills/devops/terraform-patterns/SKILL.md`
- README and docs/drop-in-wrapper.md read via WebFetch and GitHub API

## Final read

`cc-devops-skills` is the most operationally complete DevOps skill pack in the Claude Code ecosystem to date. The generator/validator split, the checklist step tables with REQUIRED markers, the explicit Done Criteria, the regression tests for script contracts, the progressive reference loading by step, and the symptom-routing navigation map are all concrete authoring improvements that lamella can absorb directly into its spec and template. None of these require a new tool or a septa contract. The domain content itself largely duplicates what lamella already has and should not be imported wholesale. The GitHub Actions distribution wrapper is a low-priority but real gap: lamella has no equivalent, and this repo's implementation is clean enough to port with minimal adaptation. The most urgent borrowable insight is that lamella's validator skills ship scripts with no behavioral tests and no documented exit code contracts — `cc-devops-skills` demonstrates that both are achievable and matter.
