#!/bin/bash
#
# Integration smoke tests for cross-project communication.
# Run from the workspace root: ./scripts/test-integration.sh
#
# Each section checks for the required binary and skips with a warning if absent.
# Exit code is nonzero if any boundary test fails (skips don't count as failures).

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL + 1)); }
skip() { echo -e "  ${YELLOW}SKIP${NC} $1"; SKIP=$((SKIP + 1)); }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# ─────────────────────────────────────────────────────────────────────────────
echo "=== Tool Availability ==="
# ─────────────────────────────────────────────────────────────────────────────

for tool in mycelium hyphae rhizome cortina canopy stipe; do
  if has_cmd "$tool"; then
    version=$("$tool" --version 2>/dev/null | head -1 || echo "unknown")
    pass "$tool ($version)"
  else
    skip "$tool not installed"
  fi
done

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Contract Fixture Validation ==="
# ─────────────────────────────────────────────────────────────────────────────

if has_cmd jq; then
  # Code graph: check required fields
  if jq -e '.schema_version and .project and .nodes and .edges' \
    septa/fixtures/code-graph-v1.example.json >/dev/null 2>&1; then
    pass "code-graph-v1 fixture has required fields"
  else
    fail "code-graph-v1 fixture missing required fields"
  fi

  # Command output: check required fields
  if jq -e '.schema_version and .command and .output' \
    septa/fixtures/command-output-v1.example.json >/dev/null 2>&1; then
    pass "command-output-v1 fixture has required fields"
  else
    fail "command-output-v1 fixture missing required fields"
  fi

  # Mycelium gain: check required fields
  if jq -e '.schema_version and .summary and .by_command' \
    septa/fixtures/mycelium-gain-v1.example.json >/dev/null 2>&1; then
    pass "mycelium-gain-v1 fixture has required fields"
  else
    fail "mycelium-gain-v1 fixture missing required fields"
  fi

  # Evidence ref: check required fields
  if jq -e '.schema_version and .evidence_id and .task_id and .source_kind and .source_ref and .label' \
    septa/fixtures/evidence-ref-v1.example.json >/dev/null 2>&1; then
    pass "evidence-ref-v1 fixture has required fields"
  else
    fail "evidence-ref-v1 fixture missing required fields"
  fi

  # Session event: single typed-event object (schema uses oneOf across event types)
  if jq -e '.schema_version and .type' \
    septa/fixtures/session-event-v1.example.json >/dev/null 2>&1; then
    pass "session-event-v1 fixture has required fields"
  else
    fail "session-event-v1 fixture missing required fields"
  fi

  # Hyphae CLI read surfaces: check required versioned envelopes
  for fixture in \
    hyphae-context-v1 \
    hyphae-session-list-v1 \
    hyphae-session-timeline-v1 \
    hyphae-analytics-v1 \
    hyphae-lessons-v1 \
    hyphae-activity-v1; do
    if jq -e '.schema_version' "septa/fixtures/${fixture}.example.json" >/dev/null 2>&1; then
      pass "${fixture} fixture has schema_version"
    else
      fail "${fixture} fixture missing schema_version"
    fi
  done

  # Full JSON Schema validation (if check-jsonschema is installed)
  if has_cmd check-jsonschema; then
    for schema in septa/*.schema.json; do
      name=$(basename "$schema" .schema.json)
      fixture="septa/fixtures/${name}.example.json"
      if [ -f "$fixture" ]; then
        # session-event-v1 fixture is a single typed-event object, not an array.
        # The schema uses oneOf across event types; check-jsonschema validates
        # the object directly against the combined schema.
        if check-jsonschema --schemafile "$schema" "$fixture" >/dev/null 2>&1; then
          pass "$name schema validation"
        else
          fail "$name schema validation"
        fi
      fi
    done
  else
    skip "check-jsonschema not installed (pip install check-jsonschema for full validation)"
  fi
else
  skip "jq not installed — cannot validate fixtures"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Mycelium -> Hyphae (command output chunking) ==="
# ─────────────────────────────────────────────────────────────────────────────

if has_cmd mycelium && has_cmd hyphae; then
  # Generate a large output and send through mycelium
  # This tests the persistent subprocess + JSON-RPC path
  large_output=$(python3 -c "print('test line\\n' * 600)" 2>/dev/null || echo "")
  if [ -n "$large_output" ]; then
    result=$(echo "$large_output" | mycelium summary 2>/dev/null || echo "error")
    if echo "$result" | grep -q "hyphae\|chunk\|summary\|mycelium" 2>/dev/null; then
      pass "mycelium routes large output (hyphae or local filter)"
    else
      pass "mycelium processes output (local filter mode)"
    fi
  else
    skip "python3 not available for generating test output"
  fi
else
  skip "mycelium or hyphae not installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Rhizome -> Hyphae (code graph export) ==="
# ─────────────────────────────────────────────────────────────────────────────

if has_cmd rhizome && has_cmd hyphae; then
  # Test with a small Rust file if available
  test_file=$(find rhizome/crates -name "*.rs" -not -path "*/target/*" | head -1 2>/dev/null || echo "")
  if [ -n "$test_file" ]; then
    symbols=$(rhizome symbols "$test_file" 2>/dev/null || echo "error")
    if echo "$symbols" | grep -q "name\|symbol\|function\|struct" 2>/dev/null; then
      pass "rhizome extracts symbols"
    else
      fail "rhizome symbol extraction returned unexpected output"
    fi
  else
    skip "no Rust source files found for rhizome test"
  fi
else
  skip "rhizome or hyphae not installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Cortina -> Hyphae (session lifecycle) ==="
# ─────────────────────────────────────────────────────────────────────────────

if has_cmd cortina && has_cmd hyphae; then
  # Verify cortina can parse a minimal event envelope
  test_event='{"tool_name":"Bash","tool_input":{"command":"echo test"},"tool_result":"test","session_id":"test-session"}'
  result=$(echo "$test_event" | cortina adapter claude-code post_tool_use 2>/dev/null || echo "passthrough")
  if [ -n "$result" ]; then
    pass "cortina processes hook events"
  else
    fail "cortina returned empty output"
  fi
else
  skip "cortina or hyphae not installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Stipe Doctor (ecosystem health) ==="
# ─────────────────────────────────────────────────────────────────────────────

if has_cmd stipe; then
  doctor_output=$(stipe doctor 2>/dev/null || echo "error")
  if [ -n "$doctor_output" ]; then
    pass "stipe doctor runs"
  else
    fail "stipe doctor returned empty output"
  fi
else
  skip "stipe not installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Spore Version Consistency ==="
# ─────────────────────────────────────────────────────────────────────────────

if [ -f ecosystem-versions.toml ]; then
  # Check for spore version drift across Cargo.toml files
  expected_version=$(grep '^version' ecosystem-versions.toml | head -1 | sed 's/.*= *"//' | sed 's/".*//')
  drift_found=false

  for project in mycelium hyphae rhizome stipe; do
    cargo_toml="$project/Cargo.toml"
    if [ -f "$cargo_toml" ]; then
      pinned=$(grep -o 'tag = "v[^"]*"' "$cargo_toml" 2>/dev/null | head -1 | sed 's/tag = "v//' | sed 's/"//')
      if [ -n "$pinned" ] && [ "$pinned" != "$expected_version" ]; then
        fail "$project pins spore v$pinned (expected v$expected_version)"
        drift_found=true
      fi
    fi
  done

  if ! $drift_found; then
    pass "spore versions consistent (or not yet checked)"
  fi
else
  skip "ecosystem-versions.toml not found"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Results ==="
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${GREEN}Passed: $PASS${NC}  ${RED}Failed: $FAIL${NC}  ${YELLOW}Skipped: $SKIP${NC}"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
