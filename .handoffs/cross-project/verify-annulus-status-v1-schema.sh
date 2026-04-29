#!/bin/bash
# verify-annulus-status-v1-schema.sh
#
# Verifies that septa ships an annulus-status-v1 schema and that cap
# validates the schema/version constants at the consumer boundary.
#
# Closes lane 2 blocker F2.8 from the
# Post-Execution Boundary Compliance Audit.

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
SEPTA="$REPO_ROOT/septa"
CAP="$REPO_ROOT/cap"
SCHEMA="$SEPTA/annulus-status-v1.schema.json"
EXAMPLE_FIXTURE="$SEPTA/fixtures/annulus-status-v1.example.json"
ANNULUS_TS="$CAP/server/annulus.ts"

PASS=0
FAIL=0

echo "=== annulus-status-v1 schema + cap consumer parity — verify ==="
echo ""

# Check 1: schema file exists
echo "[Check 1] septa/annulus-status-v1.schema.json exists"
if [ -f "$SCHEMA" ]; then
  echo "  ✓ $SCHEMA"
  PASS=$((PASS+1))
else
  echo "  ✗ MISSING: $SCHEMA"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 2: schema is valid JSON and uses correct const
echo "[Check 2] Schema declares schema=annulus-status-v1 and version=1 as consts"
if [ -f "$SCHEMA" ]; then
  if python3 -c "import json,sys; s=json.load(open('$SCHEMA')); p=s.get('properties',{}); assert p.get('schema',{}).get('const')=='annulus-status-v1'; assert p.get('version',{}).get('const')=='1'" 2>/dev/null; then
    echo "  ✓ schema and version consts present and correct"
    PASS=$((PASS+1))
  else
    echo "  ✗ schema/version consts missing or wrong"
    FAIL=$((FAIL+1))
  fi
fi
echo ""

# Check 3: tier enum matches producer
echo "[Check 3] tier enum is exactly [tier1, tier2, tier3]"
if [ -f "$SCHEMA" ]; then
  if python3 -c "import json,sys; s=json.load(open('$SCHEMA'));
import re
text=open('$SCHEMA').read()
# search any nested 'tier' definition with enum
import json
data=json.loads(text)
def find_tier_enum(node):
    if isinstance(node, dict):
        if node.get('enum') and set(node['enum'])==={'tier1','tier2','tier3'}:
            return True
        return any(find_tier_enum(v) for v in node.values())
    if isinstance(node, list):
        return any(find_tier_enum(v) for v in node)
    return False
sys.exit(0 if find_tier_enum(data) else 1)" 2>/dev/null; then
    echo "  ✓ tier enum matches producer (tier1/tier2/tier3)"
    PASS=$((PASS+1))
  else
    echo "  ✗ tier enum missing or wrong"
    FAIL=$((FAIL+1))
  fi
fi
echo ""

# Check 4: at least one fixture exists for the new schema
echo "[Check 4] Fixture file exists"
if [ -f "$EXAMPLE_FIXTURE" ]; then
  echo "  ✓ $EXAMPLE_FIXTURE"
  PASS=$((PASS+1))
else
  # also accept any fixture matching annulus-status-v1.*
  if ls "$SEPTA/fixtures/annulus-status-v1."*.json >/dev/null 2>&1; then
    echo "  ✓ at least one annulus-status-v1.*.json fixture present"
    PASS=$((PASS+1))
  else
    echo "  ✗ no annulus-status-v1 fixture found in septa/fixtures/"
    FAIL=$((FAIL+1))
  fi
fi
echo ""

# Check 5: validate-all.sh passes (final line "0 failed")
echo "[Check 5] septa/validate-all.sh remains green"
if (cd "$SEPTA" && bash validate-all.sh) >/dev/null 2>&1; then
  echo "  ✓ validate-all.sh exits 0"
  PASS=$((PASS+1))
else
  echo "  ✗ validate-all.sh failing"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 6: integration-patterns.md documents the new contract
echo "[Check 6] integration-patterns.md mentions annulus-status-v1"
if grep -q "annulus-status-v1" "$SEPTA/integration-patterns.md"; then
  echo "  ✓ row present"
  PASS=$((PASS+1))
else
  echo "  ✗ no annulus-status-v1 row in integration-patterns.md"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 7: cap consumer enforces schema constant
echo "[Check 7] cap/server/annulus.ts validates schema constant"
if [ -f "$ANNULUS_TS" ]; then
  if grep -q "annulus-status-v1" "$ANNULUS_TS"; then
    echo "  ✓ schema constant referenced in consumer"
    PASS=$((PASS+1))
  else
    echo "  ✗ consumer does not reference annulus-status-v1"
    FAIL=$((FAIL+1))
  fi
else
  echo "  ✗ $ANNULUS_TS not found"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 8: cap test suite passes
echo "[Check 8] cap annulus tests pass"
if (cd "$CAP" && npm run test:server -- annulus) >/dev/null 2>&1; then
  echo "  ✓ test:server annulus green"
  PASS=$((PASS+1))
else
  echo "  ✗ test:server annulus failing"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 9: annulus producer NOT modified (out of scope)
echo "[Check 9] annulus/src/status.rs unchanged in working tree"
if (cd "$REPO_ROOT" && git status --porcelain annulus/src/status.rs 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ annulus producer modified — out of scope"
  FAIL=$((FAIL+1))
else
  echo "  ✓ annulus producer unchanged"
  PASS=$((PASS+1))
fi
echo ""

# Summary
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -eq 0 ]; then
  exit 0
else
  exit 1
fi
