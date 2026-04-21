# Stipe Permission Memory And Runtime Policy

## Problem

The recent audit wave sharpened a gap that `stipe` only covers indirectly today: host install and doctor flows can inspect state, but they do not yet treat approval memory and runtime policy as a first-class operator surface. Without that, one-off approvals stay implicit, repeated host setup gets harder to reason about, and policy drift ends up hidden in scattered config or local machine state.

## What exists (state)

- **`stipe` doctor and install flows:** already cover provider, MCP, plugin, and repair-adjacent behavior
- **`cortina` lifecycle work:** is pushing toward cleaner normalized runtime state around host execution
- **No approval-memory model:** there is no durable, explicit model for remembered approvals, policy scope, or runtime exceptions
- **Audit pressure:** `forgecode` and `rtk` both pointed toward remembered policy, operator-visible trust state, and safer repeated setup

## What needs doing (intent)

Add a small, explicit policy layer in `stipe` for:

- remembered approvals and deny decisions
- scope and precedence for runtime policy
- doctor and install visibility into current policy state
- a repair path that can explain what policy is active and why

This should stay host-respecting. `stipe` should surface and manage policy; it should not silently invent approvals on the user's behalf.

---

### Step 1: Define the policy model and storage boundary

**Project:** `stipe/`
**Effort:** 2-3 hours
**Depends on:** provider and doctor groundwork already in the queue

Add a small policy model that names:

- approval record
- policy scope
- decision source
- last-updated metadata where useful

Keep the first cut narrow. Focus on explicit state that repeated host flows can reuse.

#### Files to modify

**`stipe/src/`** — add the runtime-policy and approval-memory model where it fits the current command structure.

**`stipe/README.md`** or adjacent docs — explain what `stipe` means by approval memory and runtime policy.

#### Verification

```bash
rg -n 'approval memory|runtime policy|policy scope|remembered approval' stipe
```

**Output:**
<!-- PASTE START -->
```text
stipe/src/commands/runtime_policy.rs:163:            "  policy scope precedence: {}",
stipe/src/commands/runtime_policy.rs:179:            "  active decision for {}: no remembered approval or deny decision recorded",
stipe/src/commands/runtime_policy.rs:189:        lines.push("  approval memory: none recorded".to_string());
stipe/src/commands/runtime_policy.rs:202:            "  approval memory: {allow_count} allow, {deny_count} deny"
stipe/src/commands/runtime_policy.rs:219:        "No remembered approvals or deny decisions are currently stored.".to_string()
stipe/src/commands/runtime_policy.rs:222:            "{} remembered approval-memory decision(s) recorded with {} precedence.",
stipe/src/commands/runtime_policy.rs:326:        .context("runtime policy path should have a parent directory")?;
stipe/src/commands/runtime_policy.rs:329:    let content = toml::to_string_pretty(policy).context("serializing runtime policy")?;
stipe/src/commands/runtime_policy.rs:439:        assert!(lines.iter().any(|line| line.contains("approval memory")));
stipe/README.md:102:- Approval memory and runtime policy for repeated host setup decisions
stipe/README.md:109:doctor, repair, provider health, registration policy, and the approval memory
stipe/README.md:110:or runtime policy state that explains why repeated setup actions are allowed or
stipe/README.md:122:- remembered approvals or deny decisions are explicit records, not hidden booleans
stipe/README.md:123:- policy scope is ordered `project -> user`
stipe/src/commands/doctor.rs:430:        "  policy scope precedence: {}",
stipe/src/commands/doctor.rs:455:        lines.push("  approval memory: none recorded".to_string());
stipe/src/commands/doctor.rs:457:        lines.push("  approval memory:".to_string());
stipe/src/commands/doctor.rs:662:        name: "runtime policy".to_string(),
stipe/src/commands/install/runner.rs:365:                "Updated approval memory and runtime policy",
stipe/src/commands/doctor/tests.rs:124:    assert!(names.iter().any(|name| name.contains("runtime policy")));
stipe/src/commands/doctor/tests.rs:427:            name: "runtime policy".to_string(),
stipe/src/commands/doctor/tests.rs:429:            message: "No remembered approvals or deny decisions are currently stored.".to_string(),
stipe/src/commands/doctor/tests.rs:470:            .any(|line| line.contains("policy scope precedence: project -> user"))
stipe/src/commands/doctor/tests.rs:472:    assert!(lines.iter().any(|line| line.contains("approval memory")));
```

<!-- PASTE END -->

**Checklist:**
- [x] `stipe` defines approval memory and runtime policy explicitly
- [x] the first model includes scope or decision provenance
- [x] docs name the boundary as a `stipe` concern

---

### Step 2: Connect doctor and install flows to policy visibility

**Project:** `stipe/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Wire at least one doctor or install path to surface the new policy state. The first iteration does not need to cover every command, but it should let an operator see remembered approvals, denied states, or active policy rules without digging through raw config.

#### Files to modify

**`stipe/src/commands/doctor/`** — surface current policy state or policy-health checks.

**`stipe/src/commands/install/`** or related command modules — reuse remembered policy state during setup or repair flows.

#### Verification

```bash
rg -n 'policy|approval|remembered|deny|allow' stipe/src/commands/doctor stipe/src/commands/install stipe/src/ecosystem
```

**Output:**
<!-- PASTE START -->
```text
stipe/src/ecosystem/mcp.rs:8:use crate::commands::host_policy::{self, HostConfigScope};
stipe/src/ecosystem/mcp.rs:11:    host_policy::project_root()
stipe/src/ecosystem/mcp.rs:39:        HostConfigScope::User => host_policy::host_config_path(host_policy::HostMode::ClaudeCode)
stipe/src/ecosystem/mcp.rs:49:        HostConfigScope::Local => host_policy::host_config_path(host_policy::HostMode::ClaudeCode)
stipe/src/ecosystem/mcp.rs:69:    let scope_name = host_policy::scope_name(scope);
stipe/src/ecosystem/status/tests.rs:2:use crate::commands::host_policy::HostMode;
stipe/src/ecosystem/workflow.rs:5:use crate::commands::host_policy::{HostConfigScope, HostMode};
stipe/src/ecosystem/workflow.rs:347:    match crate::commands::host_policy::project_root().or_else(|| std::env::current_dir().ok()) {
stipe/src/ecosystem/mod.rs:13:use crate::commands::host_policy::HostConfigScope;
stipe/src/ecosystem/mod.rs:42:#[allow(
stipe/src/ecosystem/mod.rs:73:    match crate::commands::host_policy::project_root().or_else(|| std::env::current_dir().ok()) {
stipe/src/ecosystem/configure.rs:7:use crate::commands::host_policy::{self, HostConfigScope};
stipe/src/ecosystem/configure.rs:63:    if !host_policy::host_scope_supported(host_policy::HostMode::Codex, scope) {
stipe/src/ecosystem/configure.rs:67:            host_policy::scope_name(scope)
stipe/src/ecosystem/configure.rs:150:#[allow(clippy::ref_option)]
stipe/src/ecosystem/configure.rs:224:    match host_policy::project_root().or_else(|| std::env::current_dir().ok()) {
stipe/src/commands/doctor/model.rs:5:use crate::commands::host_policy::HostMode;
stipe/src/commands/doctor/model.rs:7:use crate::commands::runtime_policy::RuntimePolicyReport;
stipe/src/commands/doctor/model.rs:41:    pub(super) runtime_policy: Option<RuntimePolicyReport>,
stipe/src/commands/doctor/model.rs:60:    #[allow(dead_code)]
stipe/src/commands/install/runner.rs:22:use crate::commands::runtime_policy;
stipe/src/commands/install/runner.rs:206:#[allow(clippy::too_many_lines)]
stipe/src/commands/install/runner.rs:226:        let runtime_policy = runtime_policy::collect_runtime_policy(Some(profile));
stipe/src/commands/install/runner.rs:227:        for line in runtime_policy::render_install_policy_lines(profile, &runtime_policy) {
stipe/src/commands/install/runner.rs:353:        let policy_path = runtime_policy::remember_install_profile_approval(profile)?;
stipe/src/commands/install/runner.rs:361:        if let Some(policy_path) = policy_path {
stipe/src/commands/install/runner.rs:365:                "Updated approval memory and runtime policy",
stipe/src/commands/install/runner.rs:366:                policy_path.display()
stipe/src/commands/install/runner.rs:399:    match crate::commands::host_policy::project_root().or_else(|| std::env::current_dir().ok()) {
stipe/src/commands/doctor/tests.rs:5:use crate::commands::runtime_policy::{
stipe/src/commands/doctor/tests.rs:15:use super::{host_policy, tool_registry};
stipe/src/commands/doctor/tests.rs:124:    assert!(names.iter().any(|name| name.contains("runtime policy")));
stipe/src/commands/doctor/tests.rs:197:    assert!(host_policy::codex_target_requested(Some("codex")));
stipe/src/commands/doctor/tests.rs:258:        runtime_policy: None,
stipe/src/commands/doctor/tests.rs:294:        runtime_policy: None,
stipe/src/commands/doctor/tests.rs:341:        runtime_policy: None,
stipe/src/commands/doctor/tests.rs:395:        runtime_policy: None,
stipe/src/commands/doctor/tests.rs:420:fn test_render_report_includes_runtime_policy_section() {
stipe/src/commands/doctor/tests.rs:427:            name: "runtime policy".to_string(),
stipe/src/commands/doctor/tests.rs:429:            message: "No remembered approvals or deny decisions are currently stored.".to_string(),
stipe/src/commands/doctor/tests.rs:438:        runtime_policy: Some(RuntimePolicyReport {
stipe/src/commands/doctor/tests.rs:440:            config_paths: vec![std::path::PathBuf::from("/tmp/runtime-policy.toml")],
stipe/src/commands/doctor/tests.rs:443:            remembered_decisions: vec![RememberedDecision {
stipe/src/commands/doctor/tests.rs:449:                note: Some("Remembered approval".to_string()),
stipe/src/commands/doctor/tests.rs:457:                note: Some("Remembered approval".to_string()),
stipe/src/commands/doctor/tests.rs:466:    assert!(lines.iter().any(|line| line == "Runtime policy:"));
stipe/src/commands/doctor/tests.rs:470:            .any(|line| line.contains("policy scope precedence: project -> user"))
stipe/src/commands/doctor/tests.rs:472:    assert!(lines.iter().any(|line| line.contains("approval memory")));
stipe/src/commands/doctor/tests.rs:476:            .any(|line| line.contains("active install profile decision: allow"))
```

<!-- PASTE END -->

**Checklist:**
- [x] at least one operator-facing command exposes policy state
- [x] install or repair logic can reuse remembered approvals
- [x] policy is visible as state, not only as scattered booleans

---

### Step 3: Add one durable validation seam

**Project:** `stipe/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Add one durable verification seam so the work is not just a doc or struct pass. Good first options:

- a policy serialization test
- a doctor snapshot or output test
- a command-level test for approval reuse

#### Files to modify

**`stipe/tests/`** or targeted command test modules — add one narrow validation path.

**`stipe/`** — update any docs or config examples needed for the validation seam.

#### Verification

```bash
bash .handoffs/archive/stipe/verify-permission-memory-and-runtime-policy.sh
```

**Output:**
<!-- PASTE START -->
```text
PASS: Stipe mentions approval memory or remembered approvals
PASS: Stipe mentions runtime policy or policy scope
PASS: Doctor or install surfaces mention policy state
PASS: Stipe docs mention the approval-memory boundary
Results: 4 passed, 0 failed
```

<!-- PASTE END -->

**Checklist:**
- [x] at least one test or validation path covers policy state
- [x] the verify script passes
- [x] approval memory is no longer only an implied future concern

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/stipe/verify-permission-memory-and-runtime-policy.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/stipe/verify-permission-memory-and-runtime-policy.sh
```

**Output:**
<!-- PASTE START -->
```text
PASS: Stipe mentions approval memory or remembered approvals
PASS: Stipe mentions runtime policy or policy scope
PASS: Doctor or install surfaces mention policy state
PASS: Stipe docs mention the approval-memory boundary
Results: 4 passed, 0 failed
```

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/forgecode/borrow-matrix.md`
- `.audit/external/audits/forgecode/feature-comparison.md`
- `.audit/external/audits/rtk/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/ecosystem-synthesis-and-adoption-guide.md`
- `.handoffs/campaigns/external-audit-gap-map/README.md`
