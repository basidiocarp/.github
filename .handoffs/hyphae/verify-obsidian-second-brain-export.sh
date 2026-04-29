#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
DESIGN="$ROOT/hyphae/docs/obsidian-export-design.md"

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

check "design doc exists" test -f "$DESIGN"

check "design has required sections" \
  /bin/zsh -lc "rg -q '^## Source Of Truth' '$DESIGN' && rg -q '^## Exported Note Types' '$DESIGN' && rg -q '^## Markdown Layout' '$DESIGN' && rg -q '^## Redaction Rules' '$DESIGN' && rg -q '^## Contract Needs' '$DESIGN' && rg -q '^## Cap Relationship' '$DESIGN'"

check "design keeps Hyphae canonical" \
  /bin/zsh -lc "rg -q 'Hyphae.*canonical|source of truth' '$DESIGN'"

check "design defines Obsidian markdown projection" \
  /bin/zsh -lc "rg -q 'Obsidian|Markdown|frontmatter|vault' '$DESIGN'"

check "design excludes Cap ownership" \
  /bin/zsh -lc "rg -q 'Cap.*links|Cap.*preview|no.*Cap.*ownership|not.*Cap' '$DESIGN'"

check "design covers redaction" \
  /bin/zsh -lc "rg -q 'redaction|secret|PII|transcript|raw command' '$DESIGN'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0

