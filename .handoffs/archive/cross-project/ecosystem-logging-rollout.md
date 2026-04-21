# Cross-Project Ecosystem Logging Rollout

## Problem

The ecosystem already has a shared logging seam in `spore`, but the rollout is
incomplete and inconsistent. Some repos use the shared init path, some only use
generic `RUST_LOG`, some do not expose repo-specific log knobs, and subprocess
failure surfacing is uneven. That makes debugging harder across the ecosystem
and encourages one-off logging behavior instead of a common framework.

## What exists (state)

- **`spore/src/logging.rs`:** shared tracing initialization with `init` and
  `init_with_env`, both writing to stderr so MCP stdio stays clean.
- **`rhizome` and `hyphae`:** already call `spore::logging::init(...)`.
- **Repo docs:** some repos already document log env vars such as `HYPHAE_LOG`,
  while others still rely on generic `RUST_LOG` guidance or do not document a
  repo-specific knob at all.
- **Current gap:** there is no single rollout plan that lets an agent improve
  logging one repo at a time without opening the entire ecosystem context.

## What needs doing (intent)

Use `spore` as the shared owner for logging infrastructure, then roll out
adoption one product repo at a time. Each implementation step after the shared
baseline should touch only:

- `spore/`
- one target repo

That keeps context and write scope bounded while still converging on one
ecosystem-wide logging framework.

This handoff covers the Rust-based repos that already depend on or can depend on
`spore`. `cap` is out of scope here because it is not a Rust/spore logging
consumer.

---

### Step 1: Establish The Shared Spore Logging Contract

**Project:** `spore/`
**Effort:** 3-4 hours
**Depends on:** nothing

Define the shared logging contract in `spore` first.

Minimum expectations:

- app-specific env var support is part of the actual API, not just prose
- stderr-only output remains the default for MCP-safe tools
- the shared surface can support both human-readable logs and richer structured
  fields without every repo re-implementing setup
- tracing context can show where a failure occurred, not just that it occurred
- docs explain when to use `RUST_LOG` versus `<APP>_LOG`
- repeated initialization paths can fail cleanly without panicking the process

Before repo rollout, `spore` should own the common setup primitives instead of
forcing each repo to assemble them ad hoc. A good target shape is:

- an app-aware init path such as `init_app("hyphae", ...)` or an equivalent
  config-driven API that derives `HYPHAE_LOG`, `RHIZOME_LOG`, and the other
  repo-specific env vars consistently
- a non-panicking `try_init...` surface for tests, repeated startup, or embedded
  runtime paths
- a small config surface for format and output policy, for example pretty vs
  compact/json and explicit stderr behavior
- shared default directives or service metadata so logs can consistently include
  repo identity without each consumer rebuilding subscriber setup
- span-aware tracing support for request, subprocess, session, and workflow
  context so logs can carry fields such as `service`, `tool`, `request_id`,
  `session_id`, `workspace_root`, or comparable identifiers when available
- guidance for when repos should create spans versus plain events, especially
  for MCP request handling, subprocess execution, and multi-step workflows

#### Files to modify

**`spore/src/logging.rs`** — expand the shared logging API so app-specific env
support, safe re-init, output/format policy, and tracing context are
first-class.

**`spore/CLAUDE.md`** and/or **`spore/README.md`** — document the contract and
consumer expectations.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd spore && cargo build --all-targets 2>&1 | tail -20
cd spore && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Blocking waiting for file lock on artifact directory
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.25s
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
test tokens::tests::test_estimate_rounds_up ... ok
test tokens::tests::test_savings_percent_75 ... ok
test tokens::tests::test_savings_percent_empty_filtered ... ok
test tokens::tests::test_savings_percent_no_savings ... ok
test tokens::tests::test_savings_percent_zero_original ... ok
test subprocess::tests::test_is_alive_with_running_child_line_delimited ... ok
test subprocess::tests::test_drop_does_not_panic_with_live_child_content_length ... ok
test subprocess::tests::test_is_alive_with_running_child_content_length ... ok
test subprocess::tests::test_drop_does_not_panic_with_live_child_line_delimited ... ok
test types::tests::test_ext_to_language_mapping ... ok
test types::tests::test_tool_all_includes_volva ... ok
test types::tests::test_find_git_root_none_at_filesystem_root ... ok
test types::tests::test_tool_binary_name_roundtrip ... ok
test types::tests::test_tool_from_binary_name_unknown ... ok
test types::tests::test_detect_languages ... ok
test types::tests::test_detect_extracts_project_name ... ok
test types::tests::test_detect_finds_git_root ... ok
test subprocess::tests::test_ensure_alive_replaces_exited_child ... ok
test subprocess::tests::test_call_tool_on_mock_server_line_delimited ... ok
test subprocess::tests::test_call_tool_on_line_delimited_server_skips_stdout_noise ... ok
test subprocess::tests::test_call_tool_on_mock_server_content_length ... ok
test subprocess::tests::test_timeout_kills_hung_subprocess_content_length ... ok
test subprocess::tests::test_timeout_kills_hung_subprocess_line_delimited ... ok

test result: ok. 90 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.21s

   Doc-tests spore

running 7 tests
test src/config.rs - config::load (line 31) ... ignored
test src/logging.rs - logging::init_with_env (line 387) ... ignored
test src/tokens.rs - tokens::estimate (line 21) ... ok
test src/paths.rs - paths::config_dir (line 22) ... ok
test src/datetime.rs - datetime (line 8) ... ok
test src/tokens.rs - tokens::savings_percent (line 40) ... ok
test src/logging.rs - logging::init (line 352) ... ok

test result: ok. 5 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 0.00s

all doctests ran in 1.05s; merged doctests compilation took 0.83s
```

<!-- PASTE END -->

**Checklist:**
- [x] `spore` documents the shared logging contract
- [x] the shared logging API supports app-specific env configuration directly
- [x] the shared logging API has a safe non-panicking init path
- [x] the shared logging API exposes a small format/output policy surface
- [x] the shared logging contract includes span/tracing guidance for locating failures
- [x] stderr safety for MCP-style tools remains explicit

---

### Step 2: Roll Out Rhizome Logging

**Project:** `rhizome/` plus `spore/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Adopt the shared logging contract in Rhizome. Keep this step scoped to Rhizome
plus any minimal shared changes required in `spore`.

Focus on:

- `RHIZOME_LOG` as the repo-specific operator knob
- clear logging around MCP/LSP startup and failure surfaces
- request- or tool-scoped spans for MCP and LSP operations where failure
  locality matters
- docs that match the actual runtime behavior

#### Verification

```bash
cd rhizome && cargo build --workspace 2>&1 | tail -20
cd rhizome && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
warning: unused import: `tool_error`
 --> crates/rhizome-mcp/src/tools/symbol_tools/mod.rs:9:36
  |
9 | pub(crate) use super::{ToolSchema, tool_error, tool_response};
  |                                    ^^^^^^^^^^

warning: unused import: `anyhow`
  --> crates/rhizome-mcp/src/tools/symbol_tools/mod.rs:21:22
   |
21 | use anyhow::{Result, anyhow};
   |                      ^^^^^^

warning: unused import: `Value`
  --> crates/rhizome-mcp/src/tools/symbol_tools/mod.rs:22:18
   |
22 | use serde_json::{Value, json};
   |                  ^^^^^

warning: `rhizome-mcp` (lib) generated 11 warnings (run `cargo fix --lib -p rhizome-mcp` to apply 11 suggestions)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.36s
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
test tests::test_parse_cpp_symbols ... ok
test tests::test_cpp_symbol_kinds ... ok
test tests::test_cpp_functions ... ok
test tests::test_parse_large_file_under_5ms ... ok

test result: ok. 40 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.31s

     Running tests/graph_integration.rs (target/debug/deps/graph_integration-3f5fe4deb5d3ccb7)

running 3 tests
test test_build_graph_from_python_fixture ... ok
test test_build_graph_from_rust_fixture ... ok
test test_build_graph_from_typescript_fixture ... ok

test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.03s

   Doc-tests rhizome_core

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests rhizome_lsp

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests rhizome_mcp

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests rhizome_treesitter

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

<!-- PASTE END -->

**Checklist:**
- [x] Rhizome uses the shared Spore logging path
- [x] Rhizome exposes or documents `RHIZOME_LOG`
- [x] Rhizome has request/tool tracing for MCP or LSP failure localization
- [x] Rhizome docs match the real serve/runtime logging path

---

### Step 3: Roll Out Hyphae Logging

**Project:** `hyphae/` plus `spore/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Keep this step scoped to Hyphae plus any minimal shared changes required in
`spore`.

Focus on:

- preserving `HYPHAE_LOG`
- aligning CLI and MCP surfaces on one shared init path
- span context for store, recall, ingest, or MCP flows where debugging needs
  operation-level locality
- ensuring docs reflect the actual log knobs and stderr behavior

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -20
cd hyphae && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.53s
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
test store::tests::test_stats ... ok
test store::tests::test_stats_empty ... ok
test store::tests::test_store_and_get ... ok
test store::tests::test_store_round_trip_preserves_branch_and_worktree ... ok
test store::tests::test_topic_health_not_found ... ok
test store::tests::test_store_with_embedding ... ok
test store::tests::test_topic_health ... ok
test store::tests::test_update ... ok
test store::tests::test_update_access ... ok
test store::tests::test_update_concept ... ok
test store::tests::test_update_memoir ... ok
test store::tests::test_update_with_embedding ... ok
test store::tests::test_with_dims_applies_sqlite_pragmas ... ok

test result: ok. 240 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 1.64s

   Doc-tests hyphae_core

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests hyphae_ingest

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests hyphae_mcp

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests hyphae_store

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

<!-- PASTE END -->

**Checklist:**
- [x] Hyphae uses the shared Spore logging path consistently
- [x] Hyphae exposes or documents `HYPHAE_LOG`
- [x] Hyphae has operation-level tracing for key MCP or store flows
- [x] Hyphae docs match CLI and MCP runtime behavior

---

### Step 4: Roll Out Mycelium Logging

**Project:** `mycelium/` plus `spore/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Keep this step scoped to Mycelium plus any minimal shared changes required in
`spore`.

Focus on:

- `MYCELIUM_LOG`
- shared init for CLI, filters, and long-running flows where applicable
- tracing around subprocess, dispatch, or filter workflow boundaries where
  failure locality matters
- docs that clearly distinguish audit/output behavior from logging verbosity

#### Verification

```bash
cd mycelium && cargo build --workspace 2>&1 | tail -20
cd mycelium && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.28s
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
test test_filter_stash_list_snapshot ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s

     Running tests/learn_integration_test.rs (target/debug/deps/learn_integration_test-8b391555a9f248d3)

running 9 tests
test test_apply_correction_exact_match ... ok
test test_corrections_store_roundtrip ... ok
test test_fixture_captures_error_flags ... ok
test test_fixture_extracts_correct_command_count ... ok
test test_env_prefix_stripped_before_base_command ... ok
test test_total_correction_count ... ok
test test_detects_git_commit_typo_correction ... ok
test test_tdd_cycle_not_detected_as_correction ... ok
test test_detects_gh_flag_correction ... ok

test result: ok. 9 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s

   Doc-tests mycelium

running 14 tests
test src/tracking/mod.rs - tracking (line 15) - compile ... ok
test src/tracking/mod.rs - tracking::Tracker::new (line 327) - compile ... ok
test src/tracking/mod.rs - tracking::Tracker::record (line 367) - compile ... ok
test src/tracking/queries.rs - tracking::queries::Tracker::get_all_days (line 207) - compile ... ok
test src/tracking/queries.rs - tracking::queries::Tracker::get_by_month (line 353) - compile ... ok
test src/tracking/mod.rs - tracking::Tracker (line 71) - compile ... ok
test src/tracking/timer.rs - tracking::timer::TimedExecution (line 17) - compile ... ok
test src/tracking/timer.rs - tracking::timer::TimedExecution::start (line 38) - compile ... ok
test src/tracking/queries.rs - tracking::queries::Tracker::get_recent (line 428) - compile ... ok
test src/tracking/queries.rs - tracking::queries::Tracker::get_by_week (line 279) - compile ... ok
test src/tracking/timer.rs - tracking::timer::TimedExecution::track (line 67) - compile ... ok
test src/tracking/timer.rs - tracking::timer::TimedExecution::track_passthrough (line 104) - compile ... ok
test src/tracking/utils.rs - tracking::utils::estimate_tokens (line 184) ... ok
test src/tracking/utils.rs - tracking::utils::args_display (line 202) ... ok

test result: ok. 14 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s

all doctests ran in 0.81s; merged doctests compilation took 0.62s
```

<!-- PASTE END -->

**Checklist:**
- [x] Mycelium uses the shared Spore logging path
- [x] Mycelium exposes or documents `MYCELIUM_LOG`
- [x] Mycelium has tracing around major workflow boundaries
- [x] Mycelium docs distinguish logging from command output or audit data

---

### Step 5: Roll Out Cortina Logging

**Project:** `cortina/` plus `spore/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Keep this step scoped to Cortina plus any minimal shared changes required in
`spore`.

Focus on:

- `CORTINA_LOG`
- hook/runtime-safe stderr behavior
- tracing for lifecycle capture, adapters, or hook processing boundaries
- docs for lifecycle capture and operator debugging

#### Verification

```bash
cd cortina && cargo build --workspace 2>&1 | tail -20
cd cortina && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Blocking waiting for file lock on artifact directory
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.21s
test utils::tests::has_error_with_error_pattern_in_output ... ok
test utils::tests::has_error_with_non_zero_exit_code ... ok
test utils::tests::has_error_with_none_exit_code_and_no_patterns ... ok
test utils::tests::has_error_with_none_exit_code_but_error_pattern ... ok
test utils::tests::has_error_with_zero_exit_code_and_no_error_patterns ... ok
test utils::tests::importance_as_str ... ok
test utils::tests::is_build_command_cargo ... ok
test utils::tests::is_build_command_non_build ... ok
test utils::tests::is_build_command_npm_and_tsc ... ok
test utils::tests::is_test_command_detects_common_runners ... ok
test utils::tests::normalize_command_empty ... ok
test utils::tests::normalize_command_multi_word ... ok
test utils::tests::normalize_command_single_word ... ok
test utils::tests::project_name_for_cwd_uses_explicit_path ... ok
test utils::tests::scope_hash_keeps_legacy_outcomes_in_the_legacy_bucket ... ok
test utils::tests::scope_hash_keeps_subdirectories_distinct_within_one_worktree ... ok
test utils::tests::scope_hash_uses_explicit_cwd_when_present ... ok
test utils::tests::session_identity_for_cwd_falls_back_to_canonical_path_identity ... ok
test utils::tests::session_identity_for_cwd_uses_canonical_cwd_and_git_dir ... ok
test utils::tests::session_outcome_feedback_classifies_failure_keywords ... ok
test utils::tests::successful_validation_feedback_prefers_test_commands ... ok
test utils::tests::temp_state_path_uses_system_temp_dir ... ok
test utils::tests::update_json_file_recovers_stale_lock ... ok
test utils::tests::update_json_file_serializes_concurrent_mutations ... ok

test result: ok. 150 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 93.38s
```

<!-- PASTE END -->

**Checklist:**
- [x] Cortina uses the shared Spore logging path
- [x] Cortina exposes or documents `CORTINA_LOG`
- [x] Cortina has tracing around hook or lifecycle processing boundaries
- [x] Cortina logging remains safe for hook and adapter surfaces

---

### Step 6: Roll Out Canopy Logging

**Project:** `canopy/` plus `spore/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Keep this step scoped to Canopy plus any minimal shared changes required in
`spore`.

Focus on:

- `CANOPY_LOG`
- MCP/server/store debugging surfaces
- tracing for task, queue, or MCP request boundaries where operators need to
  locate failures quickly
- docs that make operational debugging straightforward

#### Verification

```bash
cd canopy && cargo build --workspace 2>&1 | tail -20
cd canopy && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
   Compiling regex-syntax v0.8.10
   Compiling regex-automata v0.4.14
   Compiling matchers v0.2.0
   Compiling tracing-subscriber v0.3.23
   Compiling spore v0.4.9 (https://github.com/basidiocarp/spore?tag=v0.4.9#a899dbd6)
   Compiling canopy v0.5.7 (/Users/williamnewton/projects/basidiocarp/canopy)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 6.34s
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
test test_tool_count_matches ... ok
test test_dispatch_tools_are_in_schema ... ok
test test_schema_matches_dispatch ... ok

test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.02s

     Running tests/store_roundtrip.rs (target/debug/deps/store_roundtrip-d35d6ef8ba639341)

running 22 tests
test store_open_enables_wal_and_busy_timeout ... ok
test assign_task_enforces_required_role_when_both_task_and_agent_define_it ... ok
test assign_and_claim_task_enforce_required_capabilities_when_both_sides_declare_them ... ok
test completed_review_handoff_skips_auto_review_when_task_flag_is_disabled ... ok
test assign_task_remains_backward_compatible_when_role_is_missing_on_one_side ... ok
test assign_task_capabilities_stay_backward_compatible_for_empty_lists_and_case_sensitive ... ok
test store_requires_prior_execution_before_resume_task ... ok
test review_operator_actions_record_decision_before_closeout ... ok
test completed_review_handoff_creates_validator_review_siblings_for_auto_review_tasks ... ok
test deleting_parent_does_not_delete_children ... ok
test handoff_operator_actions_cover_resolution_paths ... ok
test graph_operator_actions_update_relationships_and_status ... ok
test task_creation_actions_reject_terminal_tasks ... ok
test update_task_status_rejects_invalid_terminal_transition ... ok
test task_deadline_updates_persist_and_record_history ... ok
test update_task_status_allows_reopen_from_closed_to_open ... ok
test subtasks_create_parent_relationships_and_enforce_single_parent ... ok
test unverified_parent_stays_open_after_children_complete ... ok
test verification_required_tasks_need_script_evidence_before_completion ... ok
test store_roundtrip_covers_agents_tasks_and_council_messages ... ok
test task_creation_actions_create_artifacts_and_record_history ... ok
test verified_parent_auto_completes_when_all_children_complete ... ok

test result: ok. 22 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.13s

   Doc-tests canopy

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

<!-- PASTE END -->

**Checklist:**
- [x] Canopy uses the shared Spore logging path
- [x] Canopy exposes or documents `CANOPY_LOG`
- [x] Canopy has tracing around server/task/store boundaries
- [x] Canopy docs cover server/store logging behavior

---

### Step 7: Roll Out Stipe Logging

**Project:** `stipe/` plus `spore/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Keep this step scoped to Stipe plus any minimal shared changes required in
`spore`.

Focus on:

- `STIPE_LOG`
- installer/doctor/operator workflows
- tracing around install, doctor, or probe phases where operators need phase
  locality
- docs that keep install output distinct from logging verbosity

#### Verification

```bash
cd stipe && cargo build --workspace 2>&1 | tail -20
cd stipe && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.31s
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
test ecosystem::clients::tests::test_collect_detected_clients_does_not_map_vscode_to_cline ... ok
test ecosystem::clients::tests::test_collect_detected_clients_keeps_claude_hybrid_detection ... ok
test ecosystem::clients::tests::test_collect_detected_clients_keeps_continue_outside_shared_overlap ... ok
test ecosystem::clients::tests::test_collect_detected_clients_preserves_inventory_order ... ok
test commands::uninstall::tests::test_build_uninstall_targets_marks_existing_files ... ok
test ecosystem::clients::tests::test_ecosystem_special_case_clients_stay_explicit ... ok
test ecosystem::clients::tests::test_from_flag_aliases ... ok
test ecosystem::clients::tests::test_print_generic_config ... ok
test ecosystem::clients::tests::test_shared_editor_mapping_covers_supported_shared_hosts ... ok
test ecosystem::clients::tests::test_shared_host_config_paths_resolve_via_spore ... ok
test commands::doctor::tests::test_optional_canopy_missing_is_not_a_failure ... ok
test ecosystem::status::tests::test_discover_codex_version_does_not_panic ... ok
test ecosystem::status::tests::test_installed_version_does_not_panic_for_optional_tool ... ok
test ecosystem::status::tests::test_render_status_report_snapshot ... ok
test ecosystem::status::tests::test_render_tool_status_snapshot_for_installed ... ok
test ecosystem::status::tests::test_render_tool_status_snapshot_for_optional_missing ... ok
test tests::test_doctor_accepts_deep_flag ... ok
test tests::test_doctor_accepts_developer_flag ... ok
test tests::test_init_accepts_force_alias ... ok
test tests::test_init_accepts_repair_flag ... ok
test tests::test_install_accepts_developer_profile_alias ... ok
test tests::test_install_accepts_full_profile_alias ... ok
test tests::test_install_accepts_standard_profile ... ok
test tests::test_removed_setup_shim_is_rejected ... ok
test tests::test_self_update_check_subcommand_parses ... ok
test tests::test_update_accepts_profile_flag ... ok
test commands::doctor::tool_checks::tests::probe_mcp_server_times_out_cleanly ... ok
test ecosystem::status::tests::test_claude_is_available_does_not_panic ... ok
test ecosystem::clients::tests::test_detect_clients_does_not_panic ... ok
test commands::doctor::tool_checks::tests::missing_volva_has_an_install_repair_action ... ok
test commands::host::tests::test_render_list_snapshot_includes_known_sections ... ok
test commands::doctor::tool_checks::tests::probe_mcp_server_accepts_initialize_response ... ok
test commands::doctor::tests::test_build_report_includes_host_inventory_checks ... ok
test commands::install::release::tests::verify_functional_checks_expected_output ... ok
test commands::install::release::tests::verify_mcp_handshake_accepts_initialize_round_trip ... ok
test commands::developer_tools::tests::developer_profile_tools_cover_all_tiers ... ok
test commands::doctor::tests::test_build_report_can_include_developer_tools ... ok

test result: ok. 136 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.96s
```

<!-- PASTE END -->

**Checklist:**
- [x] Stipe uses the shared Spore logging path
- [x] Stipe exposes or documents `STIPE_LOG`
- [x] Stipe has tracing around installer and doctor workflow phases
- [x] Stipe docs distinguish install output from log verbosity

---

### Step 8: Roll Out Volva Logging

**Project:** `volva/` plus `spore/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Keep this step scoped to Volva plus any minimal shared changes required in
`spore`.

Focus on:

- `VOLVA_LOG`
- bridge/auth/session runtime debugging
- tracing around auth, bridge, or session workflow boundaries
- docs that match the actual CLI/runtime logging path

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -20
cd volva && cargo test --workspace 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->
```text
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
    Blocking waiting for file lock on artifact directory
   Compiling volva-cli v0.1.0 (/Users/williamnewton/projects/basidiocarp/volva/crates/volva-cli)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 2.79s
    Finished `test` profile [unoptimized + debuginfo] target(s) in 0.21s
     Running unittests src/lib.rs (target/debug/deps/volva_adapters-43ded46cc595b4b6)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests src/lib.rs (target/debug/deps/volva_api-0357f9b750503e02)

running 6 tests
test tests::chat_response_shape_keeps_minimal_fields ... ok
test tests::oauth_beta_header_matches_validated_auth_contract ... ok
test tests::formats_structured_rate_limit_errors_cleanly ... ok
test tests::summarizes_token_limit_exhaustion ... ok
test tests::extract_text_joins_text_blocks ... ok
test tests::formats_request_metadata_for_non_rate_limit_errors ... ok

test result: ok. 6 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests src/lib.rs (target/debug/deps/volva_auth-ea150a965ed62fbe)

running 20 tests
test anthropic::account::tests::console_login_discards_oauth_bearer_secrets_before_storage ... ok
test anthropic::account::tests::console_login_requires_api_key ... ok
test anthropic::account::tests::claude_ai_login_requires_inference_scope ... ok
test anthropic::oauth::tests::bearer_mode_is_derived_from_scopes ... ok
test anthropic::account::tests::finalized_login_carries_metadata_and_mode ... ok
test anthropic::oauth::tests::provider_paths_and_redirects_match_first_slice_contract ... ok
test anthropic::oauth::tests::scope_normalization_handles_empty_values ... ok
test anthropic::oauth::tests::console_authorization_url_requests_console_scopes_only ... ok
test anthropic::pkce::tests::challenge_is_derived_from_verifier ... ok
test anthropic::tests::request_shape_still_supports_provider_flow_defaults ... ok
test anthropic::pkce::tests::generated_state_is_non_empty ... ok
test status::tests::expired_saved_bearer_credentials_do_not_authenticate ... ok
test anthropic::oauth::tests::authorization_url_contains_expected_parameters ... ok
test status::tests::status_prefers_env_api_key_over_saved_credentials ... ok
test anthropic::pkce::tests::generated_verifier_is_rfc7636_shaped ... ok
test storage::tests::anthropic_tokens_path_is_provider_namespaced ... ok
test storage::tests::atomic_write_replaces_target_without_leaving_temporary_file ... ok
test anthropic::callback_server::tests::callback_server_accepts_valid_code_and_state ... ok
test anthropic::callback_server::tests::callback_server_allows_valid_second_callback_after_bad_first_request ... ok
test anthropic::callback_server::tests::callback_server_rejects_state_mismatch ... ok

test result: ok. 20 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 3.00s

     Running unittests src/lib.rs (target/debug/deps/volva_bridge-bac4b6062a5cfb61)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests src/main.rs (target/debug/deps/volva-b75c8bc0205e44f0)

running 18 tests
test backend::tests::command_resolved_rejects_missing_binary_path ... ok
test backend::tests::command_resolved_accepts_real_binary_path ... ok
test backend::tests::backend_status_includes_hook_adapter_configuration ... ok
test backend::tests::backend_doctor_reports_unsupported_backend_as_not_ready ... ok
test backend::tests::backend_doctor_reports_missing_hook_adapter_command_when_enabled ... ok
test backend::tests::backend_doctor_renders_hook_adapter_argv_with_runtime_quoting ... ok
test backend::tests::command_resolved_rejects_non_executable_file ... ok
test backend::tests::cortina_probe_command_derives_status_prefix_from_adapter_invocation ... ok
test tests::auth_logout_parses_provider_explicit_surface ... ok
test tests::auth_login_parses_provider_explicit_surface ... ok
test tests::backend_doctor_parses_cleanly ... ok
test tests::auth_status_parses_without_provider ... ok
test tests::chat_parses_prompt_words ... ok
test tests::backend_status_parses_cleanly ... ok
test tests::run_parses_backend_override_and_prompt ... ok
test backend::tests::backend_doctor_reports_readiness_and_resolution ... ok
test backend::tests::backend_doctor_respects_hook_timeout_for_cortina_probe ... ok
test backend::tests::backend_doctor_reports_observed_hook_delivery_from_cortina_json_surfaces ... ok

test result: ok. 18 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.36s

     Running unittests src/lib.rs (target/debug/deps/volva_compat-731fa2f63108e788)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests src/lib.rs (target/debug/deps/volva_config-b722377a9e5b4689)

running 6 tests
test tests::default_config_uses_official_cli_backend ... ok
test tests::backend_defaults_when_missing_from_json ... ok
test tests::hook_adapter_defaults_when_missing_from_json ... ok
test tests::hook_adapter_deserializes_command_and_args ... ok
test tests::hook_adapter_deserializes_enabled_and_command ... ok
test tests::hook_adapter_deserializes_timeout_ms ... ok

test result: ok. 6 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests src/lib.rs (target/debug/deps/volva_core-f3ca730115561012)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

     Running unittests src/lib.rs (target/debug/deps/volva_runtime-7f171a17f23d140f)

running 23 tests
test context::tests::assemble_prompt_omits_blank_model_lines ... ok
test context::tests::assemble_prompt_prepends_static_host_envelope ... ok
test backend::official_cli::tests::build_args_uses_print_mode_with_assembled_prompt_payload ... ok
test hooks::tests::configured_hook_shell_reports_active_external_state_when_command_is_present ... ok
test hooks::tests::configured_hook_shell_reports_noop_state_without_command ... ok
test hooks::tests::default_hook_shell_is_disabled ... ok
test tests::configured_hook_adapter_is_reported_as_configured_when_command_is_present ... ok
test tests::injected_adapter_is_reported_as_active ... ok
test backend::official_cli::tests::missing_command_returns_launch_error ... ok
test tests::run_backend_emits_failure_hooks_in_order ... ok
test tests::status_lines_include_backend_information ... ok
test backend::official_cli::tests::successful_command_captures_stdout_and_exit_code ... ok
test tests::run_backend_emits_assembled_prompt_in_hook_context ... ok
test tests::unsupported_run_backend_does_not_emit_hooks ... ok
test tests::run_backend_emits_success_hooks_in_order ... ok
test tests::run_backend_forwards_hooks_to_adapter_in_order ... ok
test backend::official_cli::tests::launched_command_can_exit_nonzero ... ok
test tests::run_backend_emits_failure_hooks_for_nonzero_exit ... ok
test tests::run_backend_passes_assembled_prompt_to_backend_command ... ok
test hooks::tests::configured_hook_shell_times_out_hung_adapter_and_records_diagnostic ... ok
test hooks::tests::configured_hook_shell_records_diagnostic_when_adapter_fails ... ok
test hooks::tests::configured_hook_shell_passes_configured_args_to_external_adapter ... ok
test hooks::tests::configured_hook_shell_invokes_external_adapter_with_json_payload ... ok

test result: ok. 23 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.60s

     Running unittests src/lib.rs (target/debug/deps/volva_tools-0d17e668c80ecb44)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_adapters

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_api

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_auth

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_bridge

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_compat

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_config

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_core

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_runtime

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests volva_tools

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
```

<!-- PASTE END -->

**Checklist:**
- [x] Volva uses the shared Spore logging path
- [x] Volva exposes or documents `VOLVA_LOG`
- [x] Volva has tracing around auth or bridge workflow boundaries
- [x] Volva docs match the actual runtime logging path

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cross-project/verify-ecosystem-logging-rollout.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/cross-project/verify-ecosystem-logging-rollout.sh
```

**Output:**
<!-- PASTE START -->
```text
PASS: Spore owns shared logging surface
PASS: Spore exposes app-aware and safe logging init surface
PASS: Spore documents tracing or span-aware failure localization
PASS: Rhizome exposes repo-specific logging
PASS: Hyphae exposes repo-specific logging
PASS: Mycelium exposes repo-specific logging
PASS: Cortina exposes repo-specific logging
PASS: Canopy exposes repo-specific logging
PASS: Stipe exposes repo-specific logging
PASS: Volva exposes repo-specific logging
Results: 10 passed, 0 failed
```

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

This handoff is intentionally structured to keep agent context bounded.

- Shared logging ownership lives in `spore`
- each rollout step should touch only one product repo plus `spore`
- the Rhizome runtime bug has its own separate handoff because it is a current
  correctness issue, not just a logging standardization task
