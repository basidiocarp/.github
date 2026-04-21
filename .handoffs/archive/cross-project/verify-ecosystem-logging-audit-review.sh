#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
REPORT_ROOT="$ROOT/.handoffs/archive/campaigns/logging-audit"
SUMMARY="$REPORT_ROOT/summary.md"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "Summary report exists" test -f "$SUMMARY"

check "Summary report describes bounded fresh-subagent review flow" \
  rg -q 'fresh subagent|two fresh subagents|one target repo at a time|spore/' "$SUMMARY"

for repo in rhizome hyphae mycelium cortina canopy stipe volva; do
  report="$REPORT_ROOT/$repo.md"

  check "Report exists for $repo" test -f "$report"

  for section in "Status" "Coverage" "Findings" "Fragile Areas" "Recommendations"; do
    check "Report for $repo has $section section" \
      rg -q "^## $section$" "$report"
  done

  check "Report for $repo mentions spore logging contract or tracing coverage" \
    rg -q 'spore|init_app|request_span|tool_span|workflow_span|subprocess_span|root_span|request_id|session_id|workspace_root' "$report"
done

for repo in rhizome hyphae mycelium cortina canopy stipe volva; do
  check "Summary mentions $repo" \
    rg -q "$repo" "$SUMMARY"
done

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
