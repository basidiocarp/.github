#!/bin/bash
# verify-gain-weekly-monthly-producer-fix.sh — closes F2.13

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
TRACKING="$REPO_ROOT/mycelium/src/tracking/mod.rs"

PASS=0; FAIL=0

echo "=== Mycelium Gain Weekly/Monthly Producer Fix — verify ==="
echo ""

echo "[Check 1] tracking/mod.rs present"
[ -f "$TRACKING" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] No serialized week_start/week_end/month field names remain"
# Allow these as private/internal Rust field names if marked skip_serializing.
# What we want to fail: a public serde-default field with these names.
if grep -nE '^\s*pub (week_start|week_end|month)\s*:' "$TRACKING" | grep -v 'skip_serializing'; then
  echo "  ✗ public unskipped serialization of week_start/week_end/month found"
  FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 3] WeekStats and MonthStats reference 'date' as a serialized field"
if grep -A 14 "struct WeekStats" "$TRACKING" | grep -qE 'pub date|#\[serde\(rename\s*=\s*"date"'; then
  echo "  ✓ WeekStats has 'date'"
  PASS=$((PASS+1))
else
  echo "  ✗ WeekStats missing 'date'"
  FAIL=$((FAIL+1))
fi
if grep -A 14 "struct MonthStats" "$TRACKING" | grep -qE 'pub date|#\[serde\(rename\s*=\s*"date"'; then
  echo "  ✓ MonthStats has 'date'"
  PASS=$((PASS+1))
else
  echo "  ✗ MonthStats missing 'date'"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] cargo test passes for tracking module"
if (cd "$REPO_ROOT/mycelium" && cargo test --lib tracking) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ cargo test failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] septa/validate-all.sh still green"
if (cd "$REPO_ROOT/septa" && bash validate-all.sh) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] septa schema unchanged (out of scope)"
if (cd "$REPO_ROOT" && git status --porcelain septa/mycelium-gain-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ schema modified"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
