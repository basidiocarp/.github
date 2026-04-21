#!/usr/bin/env bash
set -euo pipefail

pass_count=0
fail_count=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "PASS: file exists - $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: missing file - $path"
    fail_count=$((fail_count + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "PASS: pattern '$pattern' found in $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: pattern '$pattern' missing in $path"
    fail_count=$((fail_count + 1))
  fi
}

check_checked() {
  local text="$1"
  local path="$2"
  if rg -Fq "[x] $text" "$path"; then
    echo "PASS: checked item '$text' found in $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: checked item '$text' missing in $path"
    fail_count=$((fail_count + 1))
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
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: expected $expected_blocks paste blocks in $path, found $block_count"
    fail_count=$((fail_count + 1))
  fi

  if [[ "$filled_count" == "$expected_blocks" ]]; then
    echo "PASS: all $filled_count paste blocks contain output in $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: expected $expected_blocks filled paste blocks in $path, found $filled_count"
    fail_count=$((fail_count + 1))
  fi
}

HANDOFF=".handoffs/archive/cross-project/rust-tooling-adoption.md"

check_file "$HANDOFF"
check_grep "cargo-nextest" "$HANDOFF"
check_grep "criterion" "$HANDOFF"
check_grep "whole-command timing" "$HANDOFF"
check_grep "\.handoffs/archive/mycelium/rust-tooling-adoption.md" "$HANDOFF"
check_grep "\.handoffs/archive/rhizome/rust-tooling-adoption.md" "$HANDOFF"
check_grep "\.handoffs/archive/hyphae/rust-tooling-adoption.md" "$HANDOFF"
check_grep "\.handoffs/archive/stipe/rust-tooling-adoption.md" "$HANDOFF"
check_grep "\.handoffs/archive/cortina/rust-tooling-adoption.md" "$HANDOFF"
check_grep "\.handoffs/archive/canopy/rust-tooling-adoption.md" "$HANDOFF"
check_grep "\.handoffs/archive/spore/rust-tooling-adoption.md" "$HANDOFF"
check_grep "\.handoffs/archive/volva/rust-tooling-adoption.md" "$HANDOFF"
check_checked "nextest installation and usage are documented" "$HANDOFF"
check_checked "the first-wave repos have a clear nextest command surface" "$HANDOFF"
check_checked "Criterion was added only to repos with real benchmark targets" "$HANDOFF"
check_checked "at least one meaningful benchmark compiles in each adopted repo" "$HANDOFF"
check_checked "performance investigation guidance exists" "$HANDOFF"
check_checked "docs explain where end-to-end investigation is expected to be useful in this ecosystem" "$HANDOFF"
check_nonempty_paste_blocks "$HANDOFF" 5

echo "Results: ${pass_count} passed, ${fail_count} failed"
if [[ "$fail_count" -ne 0 ]]; then
  exit 1
fi
