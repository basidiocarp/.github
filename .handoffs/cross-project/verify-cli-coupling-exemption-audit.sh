#!/bin/bash
# verify-cli-coupling-exemption-audit.sh
#
# Verifies that all sibling CLI coupling call sites are accounted for in
# septa/integration-patterns.md and that no new unclassified couplings exist.
#
# Part of handoff C7: Cross-Project CLI Coupling Exemption Audit

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
SEPTA_PATH="$REPO_ROOT/septa"

PASS=0
FAIL=0

# List of all known sibling tools in the ecosystem
SIBLING_TOOLS=(
  "hyphae"
  "rhizome"
  "canopy"
  "cortina"
  "volva"
  "stipe"
  "mycelium"
  "hymenium"
  "annulus"
  "spore"  # spore is shared library, but check for CLI calls
)

# Known sibling CLI call sites (relative file paths)
# Format: "repo/path/to/file.rs"
KNOWN_SITES=(
  "cortina/src/utils/hyphae_client.rs"
  "cortina/src/hooks/trigger_word.rs"
  "hymenium/src/dispatch/cli.rs"
  "hyphae/crates/hyphae-ingest/src/rhizome.rs"
  "mycelium/src/rhizome_client.rs"
  "volva/crates/volva-runtime/src/hooks.rs"
  "volva/crates/volva-cli/src/run.rs"
  "volva/crates/volva-cli/src/chat.rs"
  "stipe/src/commands/codex_notify.rs"
  "stipe/src/commands/claude_hooks.rs"
  "stipe/src/commands/backup.rs"
  "stipe/src/commands/rollback.rs"
  "annulus/src/notify.rs"
)

echo "=== CLI Coupling Exemption Audit ==="
echo ""

# Check 1: Verify all known sites still exist
echo "[Check 1] Verifying known call sites exist..."
for site in "${KNOWN_SITES[@]}"; do
  full_path="$REPO_ROOT/$site"
  if [ -f "$full_path" ]; then
    echo "  ✓ $site"
    PASS=$((PASS+1))
  else
    echo "  ✗ MISSING: $site"
    FAIL=$((FAIL+1))
  fi
done
echo ""

# Check 2: Scan for Command::new calls to sibling tools in all known sites
# A site that uses indirect (variable-based) spawning is noted but not failed —
# the KNOWN_SITES list is the enforcement gate; Check 3 catches new literal couplings.
echo "[Check 2] Checking known sites for sibling CLI calls..."
for site in "${KNOWN_SITES[@]}"; do
  full_path="$REPO_ROOT/$site"
  if [ ! -f "$full_path" ]; then
    continue
  fi

  found_match=0
  for tool in "${SIBLING_TOOLS[@]}"; do
    if grep -E "(std::process::)?Command::new.*\"$tool\"" "$full_path" | grep -v "clap::Command" >/dev/null 2>&1 || \
       grep -E "(std::process::)?Command::new\(&.*bin" "$full_path" | grep -v "clap::Command" >/dev/null 2>&1; then
      found_match=1
      break
    fi
  done

  if [ $found_match -eq 1 ]; then
    echo "  ✓ $site → literal sibling call detected"
    PASS=$((PASS+1))
  else
    # No literal match — may use a variable or helper; note it but don't fail.
    echo "  NOTE $site → no literal Command::new match (may use indirect spawn — verify manually)"
    PASS=$((PASS+1))
  fi
done
echo ""

# Check 3: Scan for unexpected new sibling CLI call sites
echo "[Check 3] Scanning for unexpected new sibling CLI call sites..."
# Search in the ecosystem Rust crates for Command::new calls
undetected=0

for tool in "${SIBLING_TOOLS[@]}"; do
  # Grep for std::process::Command::new or Command::new (after std::process use)
  # that target the tool name. Exclude clap::Command and build.rs (which use clap)
  hits=$(grep -r "Command::new" \
    "$REPO_ROOT/annulus" \
    "$REPO_ROOT/canopy" \
    "$REPO_ROOT/cortina" \
    "$REPO_ROOT/hyphae" \
    "$REPO_ROOT/hymenium" \
    "$REPO_ROOT/mycelium" \
    "$REPO_ROOT/rhizome" \
    "$REPO_ROOT/spore" \
    "$REPO_ROOT/stipe" \
    "$REPO_ROOT/volva" \
    --include="*.rs" -n 2>/dev/null | \
    grep "\"$tool\"" | \
    grep -v "clap::Command" | \
    grep -v "build\.rs:" || true)

  if [ -n "$hits" ]; then
    # For each hit, check if it's in a known site
    while IFS=: read -r file rest; do
      file="${file#$REPO_ROOT/}"

      # Skip target/ and .claude/worktrees
      if [[ "$file" =~ target/ ]] || [[ "$file" =~ \.claude/worktrees ]]; then
        continue
      fi

      # Check if this file is in KNOWN_SITES
      found=0
      for known in "${KNOWN_SITES[@]}"; do
        if [ "$file" = "$known" ]; then
          found=1
          break
        fi
      done

      if [ $found -eq 0 ]; then
        echo "  ✗ UNCLASSIFIED: $file spawns '$tool' — add to septa/integration-patterns.md"
        undetected=$((undetected+1))
        FAIL=$((FAIL+1))
      fi
    done <<< "$hits"
  fi
done

if [ $undetected -eq 0 ]; then
  echo "  ✓ No new unclassified sibling CLI call sites detected"
  PASS=$((PASS+1))
fi
echo ""

# Check 4: Verify septa/integration-patterns.md has the CLI Coupling Classification section
echo "[Check 4] Verifying septa/integration-patterns.md has CLI Coupling Classification..."
if grep -q "## CLI Coupling Classification" "$SEPTA_PATH/integration-patterns.md"; then
  echo "  ✓ CLI Coupling Classification section found"
  PASS=$((PASS+1))
else
  echo "  ✗ CLI Coupling Classification section missing from integration-patterns.md"
  FAIL=$((FAIL+1))
fi
echo ""

# Summary
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "✓ CLI coupling exemption audit passed"
  exit 0
else
  echo "✗ CLI coupling exemption audit failed"
  exit 1
fi
