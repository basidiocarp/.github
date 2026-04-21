# Cross-Agent Install Adapters

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `lamella`
- **Allowed write scope:** `lamella/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** selective-install manifest system (stipe concern), runtime install logic, or skill content authoring
- **Verification contract:** run the repo-local commands below and `bash .handoffs/lamella/verify-cross-agent-install-adapters.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `lamella`
- **Likely files/modules:** `lamella/scripts/adapters/` for the adapter registry and implementations, `lamella/Makefile` for build integration
- **Reference seams:** ECC `scripts/lib/install-targets/helpers.js`, `scripts/lib/install-targets/cursor-project.js`, `scripts/gemini-adapt-agents.js`, `scripts/sync-ecc-to-codex.sh`; ECC PLATFORM_SOURCE_PATH_OWNERS guard for cross-contamination prevention
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Lamella packages skills primarily for Claude Code. ECC demonstrates that the same canonical skill content can be structurally adapted for 7 agent targets at install time: Cursor gets `.md` to `.mdc` renames with namespace flattening; Gemini gets tool name rewriting (`Read` to `read_file`, `Bash` to `run_shell_command`); Codex gets prompt wrapper generation with YAML frontmatter stripping. Without per-target adapters, lamella skills are not portable across the agents the ecosystem supports. Every new agent target requires manual transformation work rather than a registered, testable adapter.

## What exists (state)

- **`lamella`:** builds distribution artifacts with `make build-marketplace`; no per-target structural adaptation logic exists
- **ECC reference:** a working adapter registry with per-target implementations for Claude Code, Codex, Cursor, and Gemini; a PLATFORM_SOURCE_PATH_OWNERS guard that prevents cross-contamination between target outputs; integration into the main build pipeline

## What needs doing (intent)

1. Define an adapter interface that each target implements: accepts canonical skill content and returns transformed content for that target.
2. Implement adapters for Claude Code (passthrough), Codex (frontmatter stripping + prompt wrapper), Cursor (`.md` to `.mdc` rename + namespace flattening), and Gemini (tool name rewriting).
3. Add a platform ownership guard equivalent to ECC's PLATFORM_SOURCE_PATH_OWNERS to prevent one adapter's output from contaminating another target's output directory.
4. Integrate the adapter registry into `make build-marketplace` so every build produces correct per-target outputs.

## Scope

- **Primary seam:** per-target structural adaptation of canonical skill content at build time
- **Allowed files:** `lamella/scripts/adapters/`, `lamella/Makefile`, and any adapter configuration files
- **Explicit non-goals:**
  - Do not build the selective-install manifest system (stipe concern)
  - Do not implement runtime install logic or agent-side install hooks
  - Do not create skill content in this handoff

---

### Step 1: Define the adapter interface and registry

**Project:** `lamella/`
**Effort:** 0.5 day
**Depends on:** #130 Skill Authoring Convention (need the canonical format before adapting it)

Define the adapter interface: what inputs an adapter receives (canonical skill path, frontmatter, body), what it must produce (transformed content, target filename), and how adapters are registered. Write the registry that maps target names to adapter implementations. Document the interface in `lamella/scripts/adapters/README.md`.

#### Verification

```bash
cd lamella && test -d scripts/adapters && echo "adapter dir exists"
cd lamella && test -f scripts/adapters/README.md && echo "interface doc exists"
```

**Checklist:**
- [ ] Adapter interface is defined and documented
- [ ] Registry maps target names to adapter implementations
- [ ] Interface document exists at `lamella/scripts/adapters/README.md`

---

### Step 2: Implement Claude Code, Codex, Cursor, and Gemini adapters

**Project:** `lamella/`
**Effort:** 1 day
**Depends on:** Step 1

Implement four adapters:
- **Claude Code:** passthrough with no structural transformation
- **Codex:** strip YAML frontmatter, wrap content in Codex prompt template
- **Cursor:** rename `.md` to `.mdc`, flatten namespace in filenames
- **Gemini:** rewrite tool names (`Read` to `read_file`, `Bash` to `run_shell_command`, `Write` to `write_file`)

Each adapter is a separate file under `lamella/scripts/adapters/`.

#### Verification

```bash
cd lamella && ls scripts/adapters/ 2>&1
```

**Checklist:**
- [ ] Claude Code adapter implemented (passthrough)
- [ ] Codex adapter implemented (frontmatter stripping + prompt wrapper)
- [ ] Cursor adapter implemented (`.md` to `.mdc` rename + namespace flattening)
- [ ] Gemini adapter implemented (tool name rewriting)
- [ ] Each adapter is in a separate file under `lamella/scripts/adapters/`

---

### Step 3: Add platform ownership guard

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Step 2

Add a guard equivalent to ECC's PLATFORM_SOURCE_PATH_OWNERS that prevents one adapter's output directory from being written by another adapter. The guard should fail the build if an adapter attempts to write outside its designated output path.

#### Verification

```bash
cd lamella && grep -r "PLATFORM\|ownership\|guard" scripts/adapters/ 2>&1
```

**Checklist:**
- [ ] Ownership guard is defined and enforced
- [ ] Adapters cannot write outside their designated output paths
- [ ] Build fails if a cross-contamination attempt is detected

---

### Step 4: Integrate into make build-marketplace

**Project:** `lamella/`
**Effort:** 0.25 day
**Depends on:** Steps 2 and 3

Update `make build-marketplace` to invoke the adapter registry for each registered target. Every build should produce per-target output directories with correctly adapted skill content. Add a dry-run mode that reports which adapters would run and what they would produce.

#### Verification

```bash
cd lamella && make build-marketplace 2>&1 | tail -20
```

**Checklist:**
- [ ] `make build-marketplace` runs all registered adapters
- [ ] Per-target output directories are produced
- [ ] Dry-run mode is available
- [ ] Build fails if any adapter fails

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/lamella/verify-cross-agent-install-adapters.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/lamella/verify-cross-agent-install-adapters.sh
```

## Context

Source: ECC ecosystem borrow audit (2026-04-14) section "Cross-agent install targets with structural adaptation." Reference files from ECC: `scripts/lib/install-targets/helpers.js`, `scripts/lib/install-targets/cursor-project.js`, `scripts/gemini-adapt-agents.js`, `scripts/sync-ecc-to-codex.sh`. See `.audit/external/audits/` for full context.

Related handoffs: #130 Skill Authoring Convention (prerequisite — canonical format must be defined before adapting it). The adapter infrastructure established here is the foundation for any future agent target additions without manual transformation work.
