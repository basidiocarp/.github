#!/bin/bash
# Verification script for binary-verification-depth.md
# Run: bash .handoffs/stipe/verify-binary-verification-depth.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STIPE="$ROOT/stipe"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

echo "=== BINARY-VERIFICATION-DEPTH Verification ==="
echo ""

echo "--- Step 1: VerifyLevel Enum ---"
check "VerifyLevel enum exists" \
  "grep -q 'VerifyLevel' $STIPE/src/commands/tool_registry/probe.rs"
check "Version variant exists" \
  "grep -q 'Version' $STIPE/src/commands/tool_registry/probe.rs"
check "Functional variant exists" \
  "grep -q 'Functional' $STIPE/src/commands/tool_registry/probe.rs"
check "McpHandshake variant exists" \
  "grep -q 'McpHandshake' $STIPE/src/commands/tool_registry/probe.rs"

echo ""
echo "--- Step 2: Per-Tool Smoke Tests ---"
check "smoke_test_args in ToolSpec" \
  "grep -q 'smoke_test_args' $STIPE/src/commands/tool_registry/specs.rs"
check "hyphae doctor smoke test" \
  "grep -q 'doctor' $STIPE/src/commands/tool_registry/specs.rs"

echo ""
echo "--- Step 3: MCP Handshake Config ---"
check "mcp_serve_args in ToolSpec" \
  "grep -q 'mcp_serve_args' $STIPE/src/commands/tool_registry/specs.rs"

echo ""
echo "--- Step 4: verify_functional Implementation ---"
check "verify_functional function exists" \
  "grep -rq 'verify_functional\|fn verify_functional' $STIPE/src/"
check "wait-timeout dependency" \
  "grep -q 'wait-timeout' $STIPE/Cargo.toml"
check "timeout handling exists" \
  "grep -rq 'TimedOut\|timed.out\|wait_timeout' $STIPE/src/"

echo ""
echo "--- Step 5: verify_mcp_handshake Implementation ---"
check "verify_mcp_handshake function exists" \
  "grep -rq 'verify_mcp_handshake\|fn verify_mcp' $STIPE/src/"
check "MCP initialize request defined" \
  "grep -rq 'initialize\|MCP_INITIALIZE' $STIPE/src/"
check "protocolVersion check" \
  "grep -rq 'protocolVersion\|protocol_version' $STIPE/src/"

echo ""
echo "--- Step 6: Integration ---"
check "L1 called in install flow" \
  "grep -rq 'verify_functional\|functional.*check' $STIPE/src/commands/install/"
check "L2 called in ecosystem flow" \
  "grep -rq 'verify_mcp\|mcp.*handshake\|mcp.*verify' $STIPE/src/ecosystem/"
check "--deep flag in doctor" \
  "grep -rq 'deep' $STIPE/src/commands/doctor.rs"

echo ""
echo "--- Step 7: --from-source Fallback ---"
check "from_source flag exists" \
  "grep -rq 'from_source\|from.source' $STIPE/src/"
check "install_from_source function exists" \
  "grep -rq 'install_from_source\|fn.*from_source' $STIPE/src/"

echo ""
echo "--- Build Verification ---"
check "cargo test passes" \
  "cd $STIPE && cargo test --quiet 2>&1"
check "cargo clippy clean" \
  "cd $STIPE && cargo clippy --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
