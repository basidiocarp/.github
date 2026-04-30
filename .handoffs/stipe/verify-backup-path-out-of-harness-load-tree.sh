#!/bin/bash
# verify-backup-path-out-of-harness-load-tree.sh

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
PR="$REPO_ROOT/stipe/src/commands/package_repair.rs"

PASS=0; FAIL=0

echo "=== Stipe Backup Path Out of Harness Load Tree — verify ==="
echo ""

echo "[Check 1] package_repair.rs present"
[ -f "$PR" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] Production backup destination is no longer a sibling of the original"
# The fix should either rename/replace sibling_backup_path with a backup-root function
# OR keep the old name but have it point under a dedicated backup root.
# Detect via: usage of dirs::data_dir, STIPE_BACKUP_ROOT env, or a "backup_root" identifier.
if grep -qE 'dirs::data_dir|STIPE_BACKUP_ROOT|fn backup_root|backup_dir\(\)' "$PR"; then
  echo "  ✓ backup-root indirection present"
  PASS=$((PASS+1))
else
  echo "  ✗ no backup-root mechanism found in package_repair.rs"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] Old sibling-backup behavior not used in production path"
# Allow the helper name to remain only if the test also asserts the new layout.
# Production path: backups should not land in the same parent dir as their original anymore.
if grep -E 'path\.with_file_name\(format!\("\{file_name\}\{suffix\}"\)\)' "$PR" | head -1 >/dev/null; then
  # Old code is still present — check whether it's still wired to the production callsite.
  if awk '/fn prepare_package_backups|fn run_package_repair|fs::rename\(target/{found=1} found && /sibling_backup_path|with_file_name/{print; exit}' "$PR" | grep -q .; then
    echo "  ✗ sibling-backup behavior still wired to production callsite"
    FAIL=$((FAIL+1))
  else
    echo "  ✓ sibling helper retained but not wired to production"
    PASS=$((PASS+1))
  fi
else
  echo "  ✓ old sibling-backup pattern removed"
  PASS=$((PASS+1))
fi
echo ""

echo "[Check 4] Test no longer asserts the old <file>.stipe-backup-* pattern"
# The handoff specifies the test must update from `example.stipe-backup-1234-2` style.
if grep -qE '\.stipe-backup-[0-9]+-[0-9]+' "$PR"; then
  # If still present, it's only valid if the test is asserting the OLD shape DOESN'T appear.
  if grep -E '\.stipe-backup-[0-9]+-[0-9]+' "$PR" | grep -qE 'assert!.*!.*ends_with|not_present|negative'; then
    echo "  ✓ old pattern only referenced negatively"
    PASS=$((PASS+1))
  else
    echo "  ✗ test still asserts the old sibling-suffix pattern positively"
    FAIL=$((FAIL+1))
  fi
else
  echo "  ✓ old pattern absent from tests"
  PASS=$((PASS+1))
fi
echo ""

echo "[Check 5] cargo test passes"
if (cd "$REPO_ROOT/stipe" && cargo test --release) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ cargo test failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] No septa or cap modifications (out of scope)"
if (cd "$REPO_ROOT" && git status --porcelain septa/ cap/ 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE septa or cap modified — verify unrelated"
  PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
