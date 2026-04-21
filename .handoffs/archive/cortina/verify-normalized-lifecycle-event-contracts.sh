#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
HANDOFF="$SCRIPT_DIR/normalized-lifecycle-event-contracts.md"

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

check "Cortina defines a normalized lifecycle vocabulary module" \
  test -f "$ROOT/cortina/src/events/normalized_lifecycle.rs"

check "Cortina docs explain the normalized lifecycle vocabulary" \
  rg -q 'Normalized Lifecycle Vocabulary|fail-open' \
    "$ROOT/cortina/docs/normalized-lifecycle-vocabulary.md" \
    "$ROOT/cortina/README.md"

check "Septa owns a shared cortina lifecycle schema" \
  test -f "$ROOT/septa/cortina-lifecycle-event-v1.schema.json"

check "Septa includes a cortina lifecycle fixture" \
  test -f "$ROOT/septa/fixtures/cortina-lifecycle-event-v1.example.json"

check "Cortina compaction capture includes a normalized lifecycle envelope" \
  rg -q 'normalized_lifecycle_event|from_pre_compact' "$ROOT/cortina/src/hooks/pre_compact.rs"

check "Cortina council lifecycle capture exists" \
  rg -q 'COUNCIL_TOPIC|council_lifecycle_content|is_council_prompt' \
    "$ROOT/cortina/src/hooks/user_prompt_submit.rs"

check "Fail-open lifecycle invariant is explicit in policy" \
  rg -q 'FAIL_OPEN_LIFECYCLE_CAPTURE|fail_open_lifecycle_capture' "$ROOT/cortina/src/policy.rs"

check "Volva adapter preserves fail-open behavior" \
  rg -q 'FAIL_OPEN_LIFECYCLE_CAPTURE|failed-open on volva hook event' \
    "$ROOT/cortina/src/adapters/volva.rs"

check "Cortina handoff checklist is marked complete" \
  rg -Fq '[x] compaction lifecycle capture exists' "$HANDOFF" && \
  rg -Fq '[x] council lifecycle capture exists' "$HANDOFF" && \
  rg -Fq '[x] fail-open policy is explicit and preserved' "$HANDOFF" && \
  rg -Fq '[x] verify script passes' "$HANDOFF"

check "Cortina handoff includes pasted verification output" \
  awk '
    /<!-- PASTE START -->/ { in_block=1; block_count++; has_content=0; next }
    /<!-- PASTE END -->/ {
      if (in_block && has_content) filled_count++;
      in_block=0;
      next
    }
    in_block {
      line=$0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line != "") has_content=1
    }
    END { exit !(block_count == 4 && filled_count == 4) }
  ' "$HANDOFF"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
