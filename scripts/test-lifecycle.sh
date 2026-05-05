#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
SKIP=0

# Colors off if not a tty
if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; NC=''
fi

check() {
  local name="$1"; shift
  if "$@" >/tmp/lc-check.out 2>&1; then
    printf "${GREEN}PASS${NC}: %s\n" "$name"
    PASS=$((PASS + 1))
  else
    printf "${RED}FAIL${NC}: %s\n" "$name"
    cat /tmp/lc-check.out
    FAIL=$((FAIL + 1))
  fi
}

skip_if_missing() {
  local bin="$1"; shift
  local name="$1"; shift
  if ! command -v "$bin" >/dev/null 2>&1; then
    printf "${YELLOW}SKIP${NC}: %s (%s not installed)\n" "$name" "$bin"
    SKIP=$((SKIP + 1))
    return 0
  fi
  check "$name" "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
echo "=== Dependency checks ==="
# ─────────────────────────────────────────────────────────────────────────────
check "hyphae available" command -v hyphae
check "cortina available" command -v cortina
skip_if_missing canopy "canopy available" command -v canopy

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Hyphae session lifecycle ==="
# ─────────────────────────────────────────────────────────────────────────────
check "hyphae version" hyphae --version

# Start a session and capture the session ID
SESSION_ID=""
if bash -c "SESSION_ID=\$(hyphae session start -p lc-test 2>&1); [ -n \"\$SESSION_ID\" ]" >/tmp/lc-check.out 2>&1; then
  SESSION_ID=$(hyphae session start -p lc-test 2>/dev/null)
  printf "${GREEN}PASS${NC}: hyphae session start\n"
  PASS=$((PASS + 1))
else
  printf "${RED}FAIL${NC}: hyphae session start\n"
  cat /tmp/lc-check.out
  FAIL=$((FAIL + 1))
fi

check "hyphae store memory" hyphae store --topic test/lc --content "lifecycle integration test memory" --importance low -P lc-test
check "hyphae search recalls memory" bash -c "hyphae search --query 'lifecycle integration' --json -P lc-test | grep -q 'lifecycle'"

# End the session if we have a valid session ID
if [ -n "$SESSION_ID" ]; then
  check "hyphae session end" hyphae session end -i "$SESSION_ID" -P lc-test
else
  printf "${YELLOW}SKIP${NC}: hyphae session end (no session ID)\n"
  SKIP=$((SKIP + 1))
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Cortina lifecycle signals ==="
# ─────────────────────────────────────────────────────────────────────────────
check "cortina version" cortina --version
check "cortina status" cortina status
check "cortina doctor" cortina doctor

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Canopy task lifecycle ==="
# ─────────────────────────────────────────────────────────────────────────────
TASK_ID=""
skip_if_missing canopy "canopy version" canopy --version
skip_if_missing canopy "canopy situation" canopy situation
# Create a test task and capture ID
if command -v canopy >/dev/null 2>&1; then
  TASK_ID=$(canopy task create --title "Lifecycle test task" --requested-by "test-lifecycle.sh" 2>/dev/null | grep -o '[0-9a-f-]\{36\}' | head -1 || echo "")
  if [ -n "$TASK_ID" ]; then
    check "canopy task status" canopy task status "$TASK_ID"
    check "canopy task complete" canopy task complete "$TASK_ID"
  else
    printf "${YELLOW}SKIP${NC}: canopy task create (could not capture task ID)\n"
    SKIP=$((SKIP + 1))
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Cortina signal chain ==="
# ─────────────────────────────────────────────────────────────────────────────
skip_if_missing cortina "cortina post-tool-use (Write adapter)" \
  bash -c "echo '{}' | cortina adapter claude-code post-tool-use"

skip_if_missing cortina "cortina session-end (session summary)" \
  bash -c "echo '{}' | cortina adapter claude-code session-end"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Canopy evidence bridge ==="
# ─────────────────────────────────────────────────────────────────────────────
if command -v canopy >/dev/null 2>&1 && [ -n "$TASK_ID" ]; then
  check "canopy evidence add" canopy evidence add \
    --task-id "$TASK_ID" \
    --source-kind "cortina_event" \
    --source-ref "lc-test-evt-$(date +%s)" \
    --label "Lifecycle test evidence attachment"

  check "canopy evidence list" canopy evidence list --task-id "$TASK_ID"
else
  printf "${YELLOW}SKIP${NC}: canopy evidence tests (canopy not available or no task ID)\n"
  SKIP=$((SKIP + 1))
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Cap API connectivity ==="
# ─────────────────────────────────────────────────────────────────────────────
CAP_URL="${CAP_URL:-http://localhost:3001}"
if curl -sf --max-time 2 "$CAP_URL/api/status" >/dev/null 2>&1; then
  check "cap status endpoint" curl -sf --max-time 5 "$CAP_URL/api/status"
  check "cap canopy snapshot" curl -sf --max-time 5 "$CAP_URL/api/canopy/snapshot"
  check "cap canopy facts" curl -sf --max-time 5 "$CAP_URL/api/canopy/facts"
else
  printf "${YELLOW}SKIP${NC}: cap connectivity (cap server not running at $CAP_URL)\n"
  SKIP=$((SKIP + 1))
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=== Septa contract validation ==="
# ─────────────────────────────────────────────────────────────────────────────
check "septa validate passes" bash /Users/williamnewton/projects/personal/basidiocarp/septa/validate-all.sh

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
# ─────────────────────────────────────────────────────────────────────────────

# Cleanup test memories (best-effort)
hyphae prune --project lc-test >/dev/null 2>&1 || true

# Cleanup canopy test task (best-effort)
if command -v canopy >/dev/null 2>&1 && [ -n "$TASK_ID" ]; then
  canopy task complete "$TASK_ID" 2>/dev/null || true
fi

exit $FAIL
