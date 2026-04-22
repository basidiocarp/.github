#!/bin/bash
# check-umbrellas.sh — scan umbrella handoffs and report which are ready to archive
# Usage: bash .handoffs/scripts/check-umbrellas.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ready=0
open=0
no_children=0

# Resolve a child path (absolute or relative) to an absolute path.
# Handles: /absolute/path, ../sibling/file.md, sibling-file.md
resolve_child() {
  local umbrella_dir="$1" child="$2"
  if [[ "$child" == /* ]]; then
    echo "$child"
  else
    # Strip leading ./ if present, then resolve relative to umbrella dir
    child="${child#./}"
    echo "$(cd "$umbrella_dir" && cd "$(dirname "$child")" 2>/dev/null && pwd)/$(basename "$child")"
  fi
}

while IFS= read -r file; do
  rel="${file#"$ROOT/"}"
  dir="$(dirname "$file")"

  # Extract all markdown link targets ending in .md (absolute or relative)
  children=()
  while IFS= read -r raw; do
    resolved="$(resolve_child "$dir" "$raw" 2>/dev/null || true)"
    [ -n "$resolved" ] && children+=("$resolved")
  done < <(
    grep -oE '\]\([^)]+\.md\)' "$file" 2>/dev/null \
      | sed 's/^](\(.*\))$/\1/' \
      | grep -v '^http' \
      || true
  )

  if [ "${#children[@]}" -eq 0 ]; then
    ((no_children++)) || true
    continue
  fi

  active=0
  for child in "${children[@]}"; do
    [ -f "$child" ] && ((active++)) || true
  done

  total="${#children[@]}"

  if [ "$active" -eq 0 ]; then
    printf "READY TO ARCHIVE  (%d/%d children done)  %s\n" "$total" "$total" "$rel"
    ((ready++)) || true
  else
    printf "OPEN              (%d/%d children active) %s\n" "$active" "$total" "$rel"
    ((open++)) || true
  fi

done < <(
  grep -rli 'dispatch.*umbrella' "$ROOT" --include="*.md" \
    | grep -v '/archive/\|/sessions/\|/campaigns/\|/state/\|/scripts/' \
    | grep -v 'HANDOFFS\.md\|README\.md'
)

echo ""
echo "Results: $ready ready to archive, $open open, $no_children with no child links"
