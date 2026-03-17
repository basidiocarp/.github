#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# Basidiocarp Ecosystem — Update All Tools
# ─────────────────────────────────────────────────────────────────────────────
# Updates mycelium, hyphae, and rhizome to their latest releases.
# Each tool's self-update checks GitHub Releases and replaces the binary.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/update.sh | sh
#   sh update.sh --check
#   sh update.sh mycelium

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  GREEN='\033[32m' RED='\033[31m' YELLOW='\033[33m' BOLD='\033[1m' DIM='\033[2m' RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' BOLD='' DIM='' RESET=''
fi

ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${RESET} %s\n" "$*"; }
err()  { printf "${RED}✗${RESET} %s\n" "$*"; }
info() { printf "${BOLD}%s${RESET}\n" "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
# Parse args
# ─────────────────────────────────────────────────────────────────────────────

CHECK_ONLY=0
TOOLS=""

for arg in "$@"; do
  case "$arg" in
    --check|-c) CHECK_ONLY=1 ;;
    --help|-h)
      cat <<EOF
Basidiocarp Ecosystem — Update All Tools

Usage:
  curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/update.sh | sh
  sh update.sh [OPTIONS] [TOOLS...]

Options:
  --check, -c    Only check for updates, don't install
  --help, -h     Show this help

Tools: mycelium, hyphae, rhizome (default: all installed)

Each tool uses its built-in self-update command to check GitHub Releases
and download the latest binary for your platform.
EOF
      exit 0 ;;
    mycelium|hyphae|rhizome) TOOLS="$TOOLS $arg" ;;
    *) err "Unknown argument: $arg"; exit 1 ;;
  esac
done

# Default to all tools if none specified
if [ -z "$TOOLS" ]; then
  TOOLS="mycelium hyphae rhizome"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Update each tool
# ─────────────────────────────────────────────────────────────────────────────

printf "\n${BOLD}Basidiocarp Ecosystem Update${RESET}\n\n"

updated=0
skipped=0
failed=0

for tool in $TOOLS; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    warn "$tool not installed — skipping"
    printf "  Install with: curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh -s -- --tools %s\n" "$tool"
    skipped=$((skipped + 1))
    continue
  fi

  printf "${DIM}─────────────────────────────────────────${RESET}\n"

  if [ $CHECK_ONLY -eq 1 ]; then
    if "$tool" self-update --check 2>&1; then
      updated=$((updated + 1))
    else
      err "$tool update check failed"
      failed=$((failed + 1))
    fi
  else
    if "$tool" self-update 2>&1; then
      updated=$((updated + 1))
    else
      err "$tool update failed"
      failed=$((failed + 1))
    fi
  fi

  echo ""
done

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

printf "${DIM}─────────────────────────────────────────${RESET}\n"
info "Summary"
[ $updated -gt 0 ] && ok "$updated tool(s) checked/updated"
[ $skipped -gt 0 ] && warn "$skipped tool(s) not installed"
[ $failed -gt 0 ] && err "$failed tool(s) failed"
echo ""

[ $failed -eq 0 ] || exit 1
