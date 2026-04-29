#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

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

check_file_exists() {
  local name="$1"
  local file="$2"
  if [ -f "$file" ]; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check_line_count() {
  local name="$1"
  local file="$2"
  local min_lines="$3"
  local count
  count=$(wc -l < "$file")
  if [ "$count" -ge "$min_lines" ]; then
    printf 'PASS: %s (%d lines)\n' "$name" "$count"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s (%d lines, need %d+)\n' "$name" "$count" "$min_lines"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Verification Command And Script Hardening ==="
echo

echo "--- Active verify scripts syntax validation ---"
check "all active verify scripts pass bash -n syntax check" \
  bash -lc "bash -n $ROOT/.handoffs/*/verify-*.sh $ROOT/.handoffs/cross-project/verify-*.sh"

echo
echo "--- Template and documentation updates ---"
check "WORK-ITEM-TEMPLATE.md recommends cwd-safe commands" \
  bash -lc "rg -c 'cd.*&&|subshell|cwd-safe' '$ROOT/templates/handoffs/WORK-ITEM-TEMPLATE.md' | grep -qE '^[1-9]'"

echo
echo "--- Active handoff verify scripts (A19, A23, A24) ---"
check_file_exists "A19 (Hyphae) verify script exists" \
  "$ROOT/.handoffs/hyphae/verify-storage-and-ingest-runtime-safety.sh"
check_line_count "A19 (Hyphae) verify script is substantive" \
  "$ROOT/.handoffs/hyphae/verify-storage-and-ingest-runtime-safety.sh" 15
check "A19 verify script includes test count guards" \
  bash -lc "rg 'check_test_count' '$ROOT/.handoffs/hyphae/verify-storage-and-ingest-runtime-safety.sh'"

check_file_exists "A23 (Volva) verify script exists" \
  "$ROOT/.handoffs/volva/verify-backend-and-credential-runtime-safety.sh"
check_line_count "A23 (Volva) verify script is substantive" \
  "$ROOT/.handoffs/volva/verify-backend-and-credential-runtime-safety.sh" 20
check "A23 verify script includes test count guards" \
  bash -lc "rg 'check_test_count' '$ROOT/.handoffs/volva/verify-backend-and-credential-runtime-safety.sh'"

check_file_exists "A24 (Mycelium) verify script exists" \
  "$ROOT/.handoffs/mycelium/verify-input-size-boundaries.sh"
check_line_count "A24 (Mycelium) verify script is substantive" \
  "$ROOT/.handoffs/mycelium/verify-input-size-boundaries.sh" 20
check "A24 verify script includes test count guards" \
  bash -lc "rg 'check_test_count' '$ROOT/.handoffs/mycelium/verify-input-size-boundaries.sh'"

echo
echo "--- Done verify scripts moved to archive ---"
check "A18 (Canopy) verify script moved to archive" \
  bash -lc "[ -f '$ROOT/.handoffs/archive/canopy/verify-mcp-handoff-runtime-boundaries.sh' ]"
check "A21 (Cap) verify script moved to archive" \
  bash -lc "[ -f '$ROOT/.handoffs/archive/cap/verify-api-auth-and-webhook-defaults.sh' ]"

echo
echo "================================"
printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
