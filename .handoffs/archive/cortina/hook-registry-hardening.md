# Hook Registry Hardening

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/...`
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** hook content authoring (lamella), hook path validation (annulus), or MCP server registration (stipe)
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cortina/verify-hook-registry-hardening.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** `src/hooks/` or `src/runner.rs` — wherever hook dispatch and execution lives
- **Reference seams:** caveman `hooks/caveman-activate.js:20-25` for silent-fail pattern; oh-my-openagent `src/plugin/hooks/create-session-hooks.ts` for named-disable and `safeCreateHook()` guarded init
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Cortina captures lifecycle signals and runs hooks, but two properties are missing: (1) a documented and enforced silent-fail standard so that hook errors never interrupt agent sessions, and (2) per-hook named disable controls so operators can disable individual hooks by name without removing them. Both caveman and oh-my-openagent demonstrate these as essential production properties. Without silent-fail, a broken hook can interrupt an agent session. Without named disable, debugging a misbehaving hook requires removing it entirely.

## What exists (state)

- **`cortina`:** runs hooks for lifecycle events; error handling behavior varies
- **caveman reference:** explicit policy that all filesystem errors in hooks are swallowed; hooks must not surface errors to the user
- **oh-my-openagent reference:** 25+ named hooks, each disable-able via config by name; `safeCreateHook()` catches init failures instead of propagating them

## What needs doing (intent)

1. Document and enforce a silent-fail standard: hook execution failures are logged (at debug/trace level) but never propagated to the agent session or user. The hook runner guarantees that a failing hook cannot break the session.
2. Add named hook identity: each hook has a string name that is stable across sessions.
3. Add per-hook disable via config: operators can disable specific hooks by name in cortina's config without removing hook files.
4. Add guarded init: hook initialization failures are caught and logged, not propagated. A hook that fails to initialize is skipped for the session with a warning, not a crash.

## Scope

- **Primary seam:** hook runner dispatch and initialization
- **Allowed files:** `cortina/src/` hook runner and config modules
- **Explicit non-goals:**
  - Do not change hook content or authoring patterns (lamella concern)
  - Do not add new hook event types in this handoff
  - Do not change the hook discovery mechanism (file layout stays the same)

---

### Step 1: Enforce silent-fail in hook runner

**Project:** `cortina/`
**Effort:** 0.5 day
**Depends on:** nothing

Wrap all hook execution in a catch-all that logs the error at debug level and continues. No hook execution failure should propagate beyond the hook runner. Add tests that verify a panicking or erroring hook does not affect the session.

#### Verification

```bash
cd cortina && cargo test hook 2>&1
```

**Checklist:**
- [ ] Hook execution errors are caught and logged, not propagated
- [ ] A test verifies that a failing hook does not interrupt the runner
- [ ] No existing tests regress

---

### Step 2: Add named hook identity and per-hook disable

**Project:** `cortina/`
**Effort:** 0.5 day
**Depends on:** Step 1

Give each hook a stable string name derived from its file or registration. Add a `disabled_hooks` list to cortina's config. During dispatch, skip hooks whose names appear in the disabled list with a trace-level log.

#### Verification

```bash
cd cortina && cargo test hook 2>&1
cd cortina && cargo test config 2>&1
```

**Checklist:**
- [ ] Each hook has a stable string name
- [ ] `disabled_hooks` config field is recognized
- [ ] Disabled hooks are skipped with a log message
- [ ] Enabling/disabling does not require removing hook files

---

### Step 3: Add guarded init

**Project:** `cortina/`
**Effort:** 0.5 day
**Depends on:** Step 2

Wrap hook initialization in a guard that catches failures. A hook that fails to initialize is marked as unavailable for the session with a warning log. The rest of the hooks still initialize and run normally.

#### Verification

```bash
cd cortina && cargo test 2>&1
cd cortina && cargo clippy -- -D warnings 2>&1
```

**Checklist:**
- [ ] Hook init failures are caught and do not crash cortina
- [ ] Failed-to-init hooks are skipped for the session
- [ ] Warning is logged for failed init
- [ ] No new clippy warnings

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cortina/verify-hook-registry-hardening.sh`
3. All checklist items are checked
4. The active handoff dashboard is updated to reflect completion
5. If `.handoffs/HANDOFFS.md` tracks active work only, this handoff is archived or removed from the active queue in the same close-out flow

### Final Verification

```bash
bash .handoffs/cortina/verify-hook-registry-hardening.sh
```

## Context

Sources: caveman ecosystem borrow audit (2026-04-14) section "Cortina should have a documented silent-fail standard for hooks"; oh-my-openagent ecosystem borrow audit (2026-04-14) section "Hook system: named, individually disable-able, guarded init." See `.audit/external/audits/caveman-ecosystem-borrow-audit.md` and `.audit/external/audits/oh-my-openagent-ecosystem-borrow-audit.md`.

Related handoffs: #65a Cortina Rhizome Read/Grep Advisories, #66 Cortina PreCompact/UserPromptSubmit Capture. This handoff is independent but improves the reliability of all hook-based cortina features.
