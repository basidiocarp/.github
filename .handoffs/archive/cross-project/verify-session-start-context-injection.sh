#!/usr/bin/env bash
# Verify: session-start-context-injection handoff
# Checks that session-start.js is deployed and SessionStart hook is wired.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1: $2"; FAIL=$((FAIL+1)); }

echo "=== Verify: session-start-context-injection ==="

SCRIPT="$HOME/.claude/hooks/scripts/session-start.js"
SETTINGS="$HOME/.claude/settings.json"

# Check script exists
if [ -f "$SCRIPT" ]; then
  pass "session-start.js exists at $SCRIPT"
else
  fail "session-start.js" "not found at $SCRIPT"
fi

# Check script is valid JS
if node --check "$SCRIPT" 2>/dev/null; then
  pass "session-start.js passes node --check"
else
  fail "session-start.js" "node --check failed"
fi

# Check script exits cleanly when hyphae unavailable
if PATH="/dev/null" node "$SCRIPT" 2>/dev/null; then
  pass "session-start.js exits cleanly when hyphae unavailable"
else
  EXITCODE=$?
  if [ "$EXITCODE" -ne 0 ]; then
    fail "session-start.js" "non-zero exit ($EXITCODE) when hyphae unavailable"
  fi
fi

# Check SessionStart hook in settings.json
if [ ! -f "$SETTINGS" ]; then
  fail "~/.claude/settings.json" "file not found"
else
  SS_COUNT=$(python3 -c "
import sys, json
try:
    d = json.load(open('$SETTINGS'))
    hooks = d.get('hooks', {})
    ss = hooks.get('SessionStart', [])
    count = sum(len(h.get('hooks', [])) for h in ss)
    print(count)
except Exception as e:
    print(0)
" 2>/dev/null || echo 0)

  if [ "$SS_COUNT" -gt 0 ]; then
    pass "SessionStart hook present in ~/.claude/settings.json ($SS_COUNT hook(s))"
  else
    fail "~/.claude/settings.json" "no SessionStart hooks found"
  fi

  # Check script path appears in settings
  if grep -q "session-start.js" "$SETTINGS"; then
    pass "session-start.js path referenced in settings.json"
  else
    fail "settings.json" "session-start.js not referenced in hook command"
  fi
fi

echo ""
echo "Results: ${PASS} pass / ${FAIL} fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
