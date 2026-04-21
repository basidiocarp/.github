#!/usr/bin/env bash
set -euo pipefail

handoff=".handoffs/archive/hyphae/backup-restore.md"
pass=0
fail=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "PASS: file exists - $path"
    pass=$((pass + 1))
  else
    echo "FAIL: missing file - $path"
    fail=$((fail + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "PASS: pattern '$pattern' found in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: pattern '$pattern' missing in $path"
    fail=$((fail + 1))
  fi
}

check_checked() {
  local text="$1"
  local path="$2"
  if rg -Fq "[x] $text" "$path"; then
    echo "PASS: checked item '$text' found in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: checked item '$text' missing in $path"
    fail=$((fail + 1))
  fi
}

check_nonempty_paste_blocks() {
  local path="$1"
  local expected_blocks="$2"
  local result

  result="$(awk '
    /<!-- PASTE START -->/ { in_block=1; block_count++; has_content=0; next }
    /<!-- PASTE END -->/ {
      if (in_block && has_content) {
        filled_count++;
      }
      in_block=0;
      next
    }
    in_block {
      line=$0;
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line);
      if (line != "") {
        has_content=1;
      }
    }
    END {
      printf "%d %d\n", block_count, filled_count;
    }
  ' "$path")"

  local block_count="${result%% *}"
  local filled_count="${result##* }"

  if [[ "$block_count" == "$expected_blocks" ]]; then
    echo "PASS: found $block_count paste blocks in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: expected $expected_blocks paste blocks in $path, found $block_count"
    fail=$((fail + 1))
  fi

  if [[ "$filled_count" == "$expected_blocks" ]]; then
    echo "PASS: all $filled_count paste blocks contain output in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: expected $expected_blocks filled paste blocks in $path, found $filled_count"
    fail=$((fail + 1))
  fi
}

check_file "$handoff"
check_file "hyphae/crates/hyphae-cli/src/commands/backup.rs"
check_file "hyphae/crates/hyphae-cli/src/commands/consolidate.rs"
check_file "hyphae/crates/hyphae-cli/src/commands/purge.rs"
check_file "hyphae/crates/hyphae-cli/src/cli.rs"
check_file "hyphae/docs/cli-reference.md"
check_file "hyphae/docs/guide.md"

check_grep "cmd_backup_list" "hyphae/crates/hyphae-cli/src/commands/backup.rs"
check_grep "auto_backup" "hyphae/crates/hyphae-cli/src/commands/backup.rs"
check_grep "validate_sqlite_backup" "hyphae/crates/hyphae-cli/src/commands/backup.rs"
check_grep "prompt_restore_confirmation" "hyphae/crates/hyphae-cli/src/commands/backup.rs"
check_grep "list: bool" "hyphae/crates/hyphae-cli/src/cli.rs"
check_grep "no_backup" "hyphae/crates/hyphae-cli/src/cli.rs"
check_grep "no_backup" "hyphae/crates/hyphae-cli/src/commands/consolidate.rs"
check_grep "no_backup" "hyphae/crates/hyphae-cli/src/commands/purge.rs"
check_grep "Auto-backup created at" "hyphae/crates/hyphae-cli/src/commands/consolidate.rs"
check_grep "Auto-backup created at" "hyphae/crates/hyphae-cli/src/commands/purge.rs"
check_grep "backup \[--list\]" "hyphae/docs/cli-reference.md"
check_grep "Restore from a backup after validating" "hyphae/docs/cli-reference.md"
check_grep "automatic pre-write backup" "hyphae/docs/guide.md"
check_checked "hyphae backup creates timestamped copy" "$handoff"
check_checked "hyphae backup --list lists backups" "$handoff"
check_checked "hyphae restore <file> validates SQLite before replacing" "$handoff"
check_checked "Restore requires confirmation" "$handoff"
check_checked "hyphae consolidate auto-backs up first" "$handoff"
check_checked "hyphae purge auto-backs up first" "$handoff"
check_checked "--no-backup skips it" "$handoff"
check_checked "Backup path printed to stderr" "$handoff"
check_checked "the verification output is pasted into this handoff" "$handoff"
check_nonempty_paste_blocks "$handoff" 2

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
