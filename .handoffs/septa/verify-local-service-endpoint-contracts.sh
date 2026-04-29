#!/usr/bin/env bash
# Verify C5: Local Service Endpoint Contracts
# Checks schema creation, fixture validity, integration patterns update, and foundation doc.

set -euo pipefail

BASEDIR="/Users/williamnewton/projects/basidiocarp"
SEPTA_DIR="$BASEDIR/septa"
DOCS_DIR="$BASEDIR/docs/foundations"

PASS=0
FAIL=0

echo "=== C5: Local Service Endpoint Contracts Verification ==="
echo

# Check 1: Schema exists
if [ -f "$SEPTA_DIR/local-service-endpoint-v1.schema.json" ]; then
  echo "PASS  Schema file exists"
  PASS=$((PASS+1))
else
  echo "FAIL  Schema file missing: $SEPTA_DIR/local-service-endpoint-v1.schema.json"
  FAIL=$((FAIL+1))
fi

# Check 2: Primary (unix-socket) fixture exists
if [ -f "$SEPTA_DIR/fixtures/local-service-endpoint-v1.example.json" ]; then
  echo "PASS  Primary unix-socket fixture exists (local-service-endpoint-v1.example.json)"
  PASS=$((PASS+1))
else
  echo "FAIL  Primary fixture missing: $SEPTA_DIR/fixtures/local-service-endpoint-v1.example.json"
  FAIL=$((FAIL+1))
fi

# Check 3: Alternate transport fixture exists (tcp/loopback variant, registered as .full.json)
if [ -f "$SEPTA_DIR/fixtures/local-service-endpoint-v1.full.json" ]; then
  echo "PASS  TCP/loopback fixture exists (local-service-endpoint-v1.full.json)"
  PASS=$((PASS+1))
else
  echo "FAIL  TCP/loopback fixture missing: $SEPTA_DIR/fixtures/local-service-endpoint-v1.full.json"
  FAIL=$((FAIL+1))
fi

# Check 4: Run validate-all.sh
echo
if cd "$SEPTA_DIR" && bash validate-all.sh > /tmp/validate-all.log 2>&1; then
  if grep -q "0 failed" /tmp/validate-all.log; then
    echo "PASS  validate-all.sh passed"
    PASS=$((PASS+1))
  else
    echo "FAIL  validate-all.sh reported failures"
    cat /tmp/validate-all.log
    FAIL=$((FAIL+1))
  fi
else
  echo "FAIL  validate-all.sh exited with error"
  cat /tmp/validate-all.log
  FAIL=$((FAIL+1))
fi

# Check 5: Integration patterns updated
if grep -q "CLI Coupling Classification" "$SEPTA_DIR/integration-patterns.md"; then
  echo "PASS  integration-patterns.md has CLI Coupling Classification section"
  PASS=$((PASS+1))
else
  echo "FAIL  integration-patterns.md missing CLI Coupling Classification section"
  FAIL=$((FAIL+1))
fi

# Check 6: Foundation doc exists
if [ -f "$DOCS_DIR/inter-app-communication.md" ]; then
  echo "PASS  inter-app-communication.md exists"
  PASS=$((PASS+1))
else
  echo "FAIL  inter-app-communication.md missing: $DOCS_DIR/inter-app-communication.md"
  FAIL=$((FAIL+1))
fi

# Check 7: Foundation doc has required sections
if grep -q "^## Rule$" "$DOCS_DIR/inter-app-communication.md" && \
   grep -q "^## Integration Hierarchy$" "$DOCS_DIR/inter-app-communication.md" && \
   grep -q "^## Contract References$" "$DOCS_DIR/inter-app-communication.md"; then
  echo "PASS  inter-app-communication.md has all required sections"
  PASS=$((PASS+1))
else
  echo "FAIL  inter-app-communication.md missing required sections"
  FAIL=$((FAIL+1))
fi

echo
echo "Results: $PASS passed, $FAIL failed"

[ $FAIL -eq 0 ]
