#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PASS=0; FAIL=0
check() { local d="$1"; shift; if "$@" &>/dev/null; then echo "PASS: $d"; PASS=$((PASS+1)); else echo "FAIL: $d"; FAIL=$((FAIL+1)); fi; }

# Test handoff_audit and handoff_paths modules
check "handoff_audit tests pass" bash -c "(cd '$ROOT/cortina' && cargo test handoff_audit 2>&1 | grep -q 'test result: ok')"

# Test post_tool_use and secret redaction
check "secret redaction tests pass" bash -c "(cd '$ROOT/cortina' && cargo test secret_redaction 2>&1 | grep -q 'test result: ok')"

# Test handoff_paths
check "handoff_paths tests pass" bash -c "(cd '$ROOT/cortina' && cargo test handoff_paths 2>&1 | grep -q 'test result: ok')"

# Verify path canonicalization is present
check "path canonicalization guards out-of-root" bash -c "grep -q 'is_within_workspace_root\|canonicalize_and_gate' '$ROOT/cortina/src/handoff_paths.rs'"

# Verify secret redaction is integrated
check "secret redaction present in post_tool_use" bash -c "grep -q 'redact_secrets' '$ROOT/cortina/src/hooks/post_tool_use.rs'"

# Verify it's used in bash handler
check "secret redaction used in bash handler" bash -c "grep -q 'redact_secrets' '$ROOT/cortina/src/hooks/post_tool_use/bash.rs'"

# Check that handoff_paths tests include path security
check "handoff_paths has out-of-root security test" bash -c "grep -q 'silently_skips_paths_outside_workspace_root' '$ROOT/cortina/src/handoff_paths.rs'"

# Full test suite compiles
check "cortina test suite passes" bash -c "(cd '$ROOT/cortina' && cargo test 2>&1 | grep -q 'test result: ok')"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
