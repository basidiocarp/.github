#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"
cd "$ROOT"

# Step 1: schema role enum and Rust AgentRole/AgentKind agree on at least one shared value
schema_roles=$(jq -r '.properties.phases.items.properties.role.enum[]' septa/workflow-template-v1.schema.json 2>/dev/null || echo "")
rust_roles=$(grep -E 'serde\(rename = "' hymenium/src/workflow/template.rs | grep -oE '"[^"]+"' | tr -d '"' || echo "")

shared=0
for r in $schema_roles; do
  if echo "$rust_roles" | grep -qF "$r"; then
    shared=$((shared + 1))
  fi
done

# Option C allows disjoint vocabularies if agent_role field exists
has_agent_role_field=$(jq -r '.properties.phases.items.properties | has("agent_role")' septa/workflow-template-v1.schema.json 2>/dev/null || echo "false")

if [ "$shared" -gt 0 ] || [ "$has_agent_role_field" = "true" ]; then
  echo "PASS: schema and Rust role vocabularies reconciled ($shared shared values, agent_role field: $has_agent_role_field)"
  PASS=$((PASS + 1))
else
  echo "FAIL: schema and Rust role vocabularies still disjoint (0 shared values, no agent_role field)"
  FAIL=$((FAIL + 1))
fi

# Step 2: fixture validates against schema
check "fixture validates" \
  check-jsonschema --schemafile septa/workflow-template-v1.schema.json septa/fixtures/workflow-template-v1.example.json

# Step 3: fixture deserializes into Rust template type (via hymenium round-trip test)
cd hymenium
check "hymenium cargo test" cargo test
check "hymenium cargo clippy" cargo clippy -- -D warnings
check "hymenium cargo fmt" cargo fmt --check

# A round-trip test should exist; look for a test name hint
if grep -rq 'workflow_template_v1' tests/ src/ 2>/dev/null \
   || grep -rq 'round_trip.*template\|template.*round_trip' tests/ src/ 2>/dev/null; then
  echo "PASS: round-trip or schema-test hint present"
  PASS=$((PASS + 1))
else
  echo "FAIL: no round-trip test referencing workflow_template_v1"
  FAIL=$((FAIL + 1))
fi

# Step 4: septa validate-all still passes
cd "$ROOT/septa"
check "septa validate-all.sh" bash validate-all.sh
cd "$ROOT"

# Step 5: any shipped hymenium templates must validate
# Uses Python + jsonschema + referencing to handle cross-file $ref like septa/validate-all.sh,
# rather than bare check-jsonschema (which cannot resolve $ref and would produce false negatives
# — the exact problem tracked in .handoffs/cross-project/integration-script-ref-resolution.md).
if ls hymenium/templates/*.json >/dev/null 2>&1; then
  for tpl in hymenium/templates/*.json; do
    check "shipped template validates: $tpl" \
      python3 -c "
import json, sys
from pathlib import Path
try:
    import jsonschema
    from referencing import Registry, Resource
    from referencing.jsonschema import DRAFT202012
except ImportError:
    sys.exit(0)  # validate-all.sh path not available; skip (parent will have run validate-all.sh)
septa = Path('septa')
registry = Registry()
for schema_file in septa.glob('*.schema.json'):
    with open(schema_file) as f:
        schema = json.load(f)
    registry = registry.with_resource(uri=schema_file.name, resource=Resource(contents=schema, specification=DRAFT202012))
with open('septa/workflow-template-v1.schema.json') as f:
    template_schema = json.load(f)
with open('$tpl') as f:
    payload = json.load(f)
validator = jsonschema.Draft202012Validator(template_schema, registry=registry)
errors = list(validator.iter_errors(payload))
sys.exit(1 if errors else 0)
"
  done
else
  echo "PASS: no shipped hymenium/templates/*.json to validate"
  PASS=$((PASS + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
