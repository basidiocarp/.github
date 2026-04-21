# Septa: Fail-Open Hook Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** septa/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


<!-- Save as: .handoffs/septa/fail-open-hook-contracts.md -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

The ecosystem has no formal contract enforcing that hooks must never block user
commands. Fail-open is the most critical invariant in the hook execution model:
if a hook crashes, times out, or is misconfigured, the host command must proceed.
Today this is an informal convention scattered across cortina and stipe docs —
not a tested contract, not a versioned schema, and not something stipe doctor
can verify at install time.

A single misconfigured hook timeout can cause every Claude Code command to hang.
There is no septa schema that states what timeout defaults are acceptable, what
the error handling shape must look like, or what exit codes are semantically
meaningful. Each tool interprets this independently.

## What exists (state)

- **Cortina**: implements fail-open informally — hook failures log a warning but
  do not interrupt the captured signal flow
- **Stipe doctor**: checks that hook paths exist and are executable; does not
  check timeout configuration or validate fail-open behavior
- **`septa/`**: has contracts for session events, evidence refs, usage events,
  and volva hook events — no contract for hook execution semantics
- **`docs/`**: no formal invariant document for the fail-open rule
- **Lamella**: ships default hook templates with no documented timeout bounds

## What needs doing (intent)

Define the fail-open contract formally in septa, enforce it in cortina tests,
and surface it in stipe doctor so operators discover misconfiguration before
it becomes a problem in practice.

---

### Step 1: Define `hook-execution-v1.schema.json` in septa

**Project:** `septa/`
**Effort:** 2–3 hours
**Depends on:** nothing

Add a septa schema that codifies the fail-open invariant and the execution
contract that all hook runners in the ecosystem must implement.

The schema should cover:
- `timeout_ms`: maximum allowed hook execution time (default 10000, max 30000)
- `on_timeout`: required value `"proceed"` — host must not block
- `on_error`: required value `"proceed"` — host must not block on non-zero exit
- `exit_code_semantics`: document which exit codes are meaningful (0 = ok,
  non-zero = advisory failure, no blocking meaning)
- `stderr_disposition`: `"log"` or `"suppress"` — never propagated to user as an error

Add a matching example fixture `septa/fixtures/hook-execution-v1-example.json`.

Update `septa/README.md` to list the new contract family and its version.

Update `ecosystem-versions.toml` `[contracts]` block:

```toml
hook-execution = "1.0"
```

#### Verification

```bash
ls /Users/williamnewton/projects/basidiocarp/septa/hook-execution-v1.schema.json
ls /Users/williamnewton/projects/basidiocarp/septa/fixtures/hook-execution-v1-example.json
grep "hook-execution" /Users/williamnewton/projects/basidiocarp/ecosystem-versions.toml
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `septa/hook-execution-v1.schema.json` exists and is valid JSON Schema
- [ ] Schema defines `timeout_ms`, `on_timeout`, `on_error`, `exit_code_semantics`,
  `stderr_disposition`
- [ ] `on_timeout` and `on_error` require `"proceed"` as the only valid value
- [ ] Example fixture exists and validates against the schema
- [ ] `ecosystem-versions.toml` has `hook-execution = "1.0"` under `[contracts]`
- [ ] `septa/README.md` lists the new contract

---

### Step 2: Add fail-open enforcement tests in cortina

**Project:** `cortina/`
**Effort:** 2–3 hours
**Depends on:** Step 1

Add tests that prove cortina's hook runner is actually fail-open. These tests
should exercise the observable behavior, not just the code path:

1. A hook that exits non-zero must not cause the calling command to fail
2. A hook that exceeds the timeout must be killed and the command must proceed
3. A hook that panics or crashes (killed by signal) must not block execution
4. All three failure modes must produce a warning log entry, not an error

If cortina's hook runner does not already implement timeout enforcement, add it
here. The timeout value should be read from config and default to 10000ms.

#### Files to modify

**`cortina/src/hooks/`** or equivalent — add or verify timeout enforcement:

```rust
// Hook execution must always be fail-open
pub async fn run_hook(path: &Path, timeout: Duration) -> HookOutcome {
    // ... spawn hook process ...
    // On timeout: kill, log warning, return HookOutcome::TimedOut
    // On non-zero exit: log warning, return HookOutcome::Failed
    // On crash: log warning, return HookOutcome::Crashed
    // Caller must treat all non-Ok variants as advisory, never blocking
}
```

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test hook 2>&1 | tail -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Test: hook exits non-zero → command proceeds, warning logged
- [ ] Test: hook exceeds timeout → process killed, command proceeds, warning logged
- [ ] Test: hook process killed by signal → command proceeds, warning logged
- [ ] Timeout value is configurable with a 10000ms default
- [ ] All three failure paths produce a structured warning (not a panic)
- [ ] `cargo test --workspace` passes

---

### Step 3: Add stipe doctor check for hook timeout configuration

**Project:** `stipe/`
**Effort:** 1–2 hours
**Depends on:** Step 1

Extend `stipe doctor` to verify that hook timeout configuration falls within the
bounds defined by the septa schema. A missing timeout config is not an error —
the default (10000ms) is safe. A timeout configured above 30000ms is an error
because it risks hanging user commands. A timeout of 0 or negative is an error.

Add a new doctor check named `hook-execution-contract` alongside the existing
hook path existence checks.

#### Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/stipe && cargo test doctor 2>&1 | tail -20
./target/debug/stipe doctor 2>&1 | grep -i hook
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `stipe doctor` reports `hook-execution-contract: ok` when timeout is at default
- [ ] `stipe doctor` reports an error when hook timeout exceeds 30000ms
- [ ] `stipe doctor` reports an error when hook timeout is 0 or negative
- [ ] Doctor output includes the septa contract version being checked against
- [ ] `cargo test --workspace` passes

---

### Step 4: Document the fail-open invariant in ecosystem docs

**Project:** workspace root
**Effort:** 1 hour
**Depends on:** Steps 1–3

Add a short document in `docs/foundations/` that states the fail-open invariant
as a first-class ecosystem constraint, references the septa schema, and links to
the cortina enforcement tests and stipe doctor check.

The document should cover:
- Why fail-open is non-negotiable (hooks must never block agent work)
- What the septa contract guarantees (timeout bounds, error semantics)
- How to verify compliance (stipe doctor, cortina tests)
- What to do when a hook genuinely needs to block (it can't — redesign it)

#### Verification

```bash
ls /Users/williamnewton/projects/basidiocarp/docs/foundations/fail-open-hook-invariant.md
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `docs/foundations/fail-open-hook-invariant.md` exists
- [ ] Document references `septa/hook-execution-v1.schema.json`
- [ ] Document links to cortina enforcement tests and stipe doctor check
- [ ] Document is linked from `docs/foundations/README.md`

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `septa/hook-execution-v1.schema.json` exists and validates its own example fixture
3. `cargo test --workspace` passes in both `cortina/` and `stipe/`
4. `stipe doctor` surfaces the hook-execution-contract check
5. All checklist items are checked

### Final Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/cortina && cargo test --workspace 2>&1 | tail -5
cd /Users/williamnewton/projects/basidiocarp/stipe && cargo test --workspace 2>&1 | tail -5
/Users/williamnewton/projects/basidiocarp/stipe/target/debug/stipe doctor 2>&1 | grep hook-execution
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** all tests pass; `stipe doctor` reports `hook-execution-contract: ok`.

## Context

Source: RTK audit. The fail-open rule is referenced informally in cortina and
lamella documentation, but no test currently proves the runtime enforces it.
The closest existing contract in septa is `volva-hook-event-v1.schema.json`,
which covers the event payload shape — not the execution semantics.

Companion handoffs:
- `septa/foundation-alignment.md` (#91) — septa contract governance baseline
- `stipe/doctor-expansion.md` (#92) — broader doctor check expansion
- `annulus/stale-hook-path-validation.md` (#70) — hook path existence checks
