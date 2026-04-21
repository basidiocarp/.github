# Stipe Approval Persistence Success Path

## Priority

Low. The denial and load-error safety path is already covered. This handoff is for deeper confidence in the successful profile-install path.

## Problem

`stipe install --profile ...` now records approval memory and runtime policy after a successful profile install, and refusal behavior is covered for remembered deny decisions and policy load errors. What is still missing is an end-to-end test that proves successful installs persist approval memory correctly through the real command path.

Without that, the success-path write is still mostly trusted by helper-level coverage and indirect verification.

## What exists (state)

- **Runtime policy model:** explicit remembered decisions, scope, provenance, and doctor visibility already exist
- **Command-level refusal tests:** `install::run(..., Some(InstallProfile::Codex), true, ...)` is covered for project-scoped deny and load-error refusal
- **Persistence helper coverage:** helper seams cover serialization and persistence conditions

## What needs doing (intent)

Add one narrow end-to-end validation path for successful approval persistence after a real profile install.

The goal is not to expand policy features. The goal is to prove that a successful profile install updates:

- saved install profile state
- approval memory / runtime policy state
- operator-visible success-path expectations

Keep it deterministic and local-only.

Explicitly out of scope:

- new policy scopes or precedence rules
- redesigning install flow
- broader networked install harnesses

---

### Step 1: Add a success-path test seam

**Project:** `stipe/`
**Effort:** 1-2 hours
**Depends on:** current runtime-policy work

Add a test seam that can exercise the successful profile-install persistence path without depending on live downloads or external binaries.

Prefer a narrow seam over a broad mock framework. If a minimal internal helper is needed to make the success path deterministic, keep it local to install tests.

#### Files to modify

**`stipe/src/commands/install/tests.rs`** — add the end-to-end success-path test.

**`stipe/src/commands/install/runner.rs`** or nearby install helpers — only if a minimal deterministic seam is required.

#### Verification

```bash
cd stipe && cargo test install 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->
```text
    Finished `test` profile [unoptimized + debuginfo] target(s) in 2.49s
     Running unittests src/main.rs (target/debug/deps/stipe-fff34bb61a74d7a3)

running 48 tests
test commands::install::release::tests::parse_initialize_response_requires_protocol_version ... ok
test commands::install::tests::test_find_matching_asset_requires_tar_gz ... ok
test commands::install::tests::test_find_matching_asset_missing_platform ... ok
test commands::host_policy::tests::test_install_profile_repair_action_keeps_cursor_distinct ... ok
test commands::install::tests::test_find_matching_asset_success ... ok
test commands::developer_tools::tests::install_advice_mentions_advisory_boundary ... ok
test commands::claude_hooks::tests::test_install_claude_hooks_at_path_is_idempotent ... ok
test commands::install::tests::test_extract_tarball_with_binary ... ok
test commands::install::tests::test_format_install_preview_reports_existing_and_missing_tools ... ok
test commands::install::tests::test_install_run_fails_when_project_runtime_policy_cannot_load ... ok
test commands::install::tests::test_install_run_honors_project_runtime_policy_deny ... ok
test commands::install::tests::test_platform_key_known ... ok
test commands::install::tests::test_install_run_honors_user_runtime_policy_deny_without_project_override ... ok
test commands::install::tests::test_profile_mode_labels_make_codex_explicit ... ok
test commands::install::tests::test_extract_tarball_missing_binary ... ok
test commands::install::tests::test_install_run_persists_profile_and_approval_memory_on_success ... ok
test commands::install::tests::test_profile_tools_cover_expected_sets ... ok
test commands::install::tests::test_render_install_preview_snapshot_for_interactive_mode ... ok
test commands::install::tests::test_resolve_requested_tools_handles_all_mode ... ok
test commands::install::tests::test_render_profile_install_preview_snapshot ... ok
test commands::install::tests::test_resolve_requested_tools_includes_manual_profile_members ... ok
test commands::install::tests::test_resolve_requested_tools_uses_profile_and_dedupes_extras ... ok
test commands::install::tests::test_selected_profile_for_persistence_keeps_successful_non_developer_profile ... ok
test commands::install::tests::test_selected_profile_for_persistence_skips_failed_installs ... ok
test commands::install::tests::test_render_install_preview_snapshot_for_explicit_tools ... ok
test commands::install::tests::test_profile_config_round_trips ... ok
test commands::install::tests::test_split_requested_tools_keeps_manual_members_out_of_managed_installs ... ok
test commands::codex_notify::tests::test_install_codex_notify_preserves_existing_notify_entries ... ok
test commands::runtime_policy::tests::test_enforce_install_profile_policy_blocks_load_errors ... ok
test commands::runtime_policy::tests::test_enforce_install_profile_policy_blocks_remembered_deny ... ok
test commands::runtime_policy::tests::test_render_install_policy_lines_mentions_approval_memory ... ok
test commands::tool_registry::tests::test_install_all_and_update_all_cover_same_managed_release_tools ... ok
test commands::tool_registry::tests::test_install_profiles_only_reference_installable_tools ... ok
test commands::tool_registry::tests::test_optional_doctor_tools_have_install_hints ... ok
test commands::uninstall::tests::test_render_preview_output_snapshot ... ok
test commands::uninstall::tests::test_render_uninstall_preview_mentions_manual_cleanup ... ok
test commands::uninstall::tests::test_resolve_uninstall_tools_all_mode_includes_stipe ... ok
test commands::update::tests::installed_profile_tools_only_keep_installed_or_broken_members ... ok
test commands::update::tests::installed_profile_tools_with_helper_keeps_only_present_tools ... ok
test ecosystem::status::tests::test_render_tool_status_snapshot_for_installed ... ok
test ecosystem::status::tests::test_installed_version_does_not_panic_for_optional_tool ... ok
test tests::test_install_accepts_full_profile_alias ... ok
test tests::test_install_accepts_standard_profile ... ok
test tests::test_install_accepts_developer_profile_alias ... ok
test commands::uninstall::tests::test_build_uninstall_targets_marks_existing_files ... ok
test commands::doctor::tool_checks::tests::missing_volva_has_an_install_repair_action ... ok
test commands::install::release::tests::verify_mcp_handshake_accepts_initialize_round_trip ... ok
test commands::install::release::tests::verify_functional_checks_expected_output ... ok

test result: ok. 48 passed; 0 failed; 0 ignored; 0 measured; 119 filtered out; finished in 0.27s
```

<!-- PASTE END -->

**Checklist:**
- [x] a command-level test covers successful approval persistence
- [x] the test stays local-only and deterministic
- [x] install flow was not broadened beyond what the test needs

---

### Step 2: Prove persistence state is written as expected

**Project:** `stipe/`
**Effort:** 1 hour
**Depends on:** Step 1

Verify that the successful path writes both pieces of state:

- saved profile selection
- approval memory / runtime policy entry

If success-path output is asserted, keep the assertion narrow enough to avoid brittle snapshot churn.

#### Verification

```bash
rg -n 'remember_install_profile_approval|Saved install profile|Updated approval memory and runtime policy' stipe/src/commands/install
```

**Output:**
<!-- PASTE START -->
```text
/Users/williamnewton/projects/basidiocarp/stipe/src/commands/install/runner.rs:398:        let policy_path = runtime_policy::remember_install_profile_approval(profile)?;
/Users/williamnewton/projects/basidiocarp/stipe/src/commands/install/runner.rs:403:            format_args!("Saved install profile: {}", profile.mode_label()),
/Users/williamnewton/projects/basidiocarp/stipe/src/commands/install/runner.rs:410:                "Updated approval memory and runtime policy",
```

```text
    Finished `test` profile [unoptimized + debuginfo] target(s) in 0.13s
     Running unittests src/main.rs (target/debug/deps/stipe-fff34bb61a74d7a3)

running 1 test
test commands::install::tests::test_install_run_persists_profile_and_approval_memory_on_success ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 166 filtered out; finished in 0.00s
```

<!-- PASTE END -->

**Checklist:**
- [x] saved profile persistence is still covered
- [x] approval persistence is covered through the success path
- [x] output or state assertions are not overly brittle

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. Any new helper seam is minimal and justified by deterministic testing
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/stipe/verify-approval-persistence-success-path.sh
```

**Output:**
<!-- PASTE START -->
```text
PASS: Handoff names approval persistence scope
PASS: Handoff points at install test files
PASS: Handoff includes final verification script
Results: 3 passed, 0 failed
```

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Follow-on from:

- `.handoffs/stipe/permission-memory-and-runtime-policy.md`

This handoff exists because the refusal path is now covered end to end, but the successful approval-persistence path still deserves one deterministic command-level test.
