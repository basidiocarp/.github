#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# Basidiocarp Ecosystem Installer
# ─────────────────────────────────────────────────────────────────────────────
# POSIX sh compatible — no bashisms.
#
# Downloads binaries, then delegates editor configuration to stipe.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
#   sh install.sh --tools mycelium,hyphae --prefix /usr/local/bin

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────────────────────────────────────────

ALL_TOOLS="stipe mycelium hyphae rhizome cortina"
TOOLS="$ALL_TOOLS"
PREFIX="$HOME/.local/bin"
CONFIGURE=1
VERSION=""
UNINSTALL=0
GH_ORG="basidiocarp"

# ─────────────────────────────────────────────────────────────────────────────
# Colors (disabled when not a terminal)
# ─────────────────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  GREEN='\033[32m' RED='\033[31m' YELLOW='\033[33m' BOLD='\033[1m' DIM='\033[2m' RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' BOLD='' DIM='' RESET=''
fi

info()  { printf "${BOLD}%s${RESET}\n" "$*"; }
ok()    { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}⚠${RESET} %s\n" "$*" >&2; }
err()   { printf "${RED}✗${RESET} %s\n" "$*" >&2; }

# ─────────────────────────────────────────────────────────────────────────────
# Usage
# ─────────────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Basidiocarp Ecosystem Installer

Usage: install.sh [OPTIONS]

Options:
  --help            Show this help message
  --tools LIST      Comma-separated tools to install (default: all)
                    Available: stipe, mycelium, hyphae, rhizome, cortina
  --prefix DIR      Install directory (default: ~/.local/bin)
  --no-configure    Skip editor configuration (just download binaries)
  --version VER     Install a specific version (default: latest)
  --uninstall       Remove installed binaries and configuration

Examples:
  curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
  install.sh --tools mycelium,hyphae
  install.sh --prefix /usr/local/bin
  install.sh --no-configure
  install.sh --uninstall
EOF
  exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Argument parsing
# ─────────────────────────────────────────────────────────────────────────────

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help)         usage ;;
      --tools)        shift; TOOLS=$(echo "$1" | tr ',' ' ') ;;
      --prefix)       shift; PREFIX="$1" ;;
      --no-configure) CONFIGURE=0 ;;
      --version)      shift; VERSION="$1" ;;
      --uninstall)    UNINSTALL=1 ;;
      *)              err "Unknown option: $1"; usage ;;
    esac
    shift
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# Platform detection
# ─────────────────────────────────────────────────────────────────────────────

detect_target() {
  os=$(uname -s)
  arch=$(uname -m)

  case "$os" in
    Darwin)
      case "$arch" in
        arm64)  TARGET="aarch64-apple-darwin" ;;
        x86_64) TARGET="x86_64-apple-darwin" ;;
        *)      err "Unsupported macOS architecture: $arch"; exit 1 ;;
      esac ;;
    Linux)
      case "$arch" in
        x86_64)  TARGET="x86_64-unknown-linux-musl" ;;
        aarch64) TARGET="aarch64-unknown-linux-musl" ;;
        *)       err "Unsupported Linux architecture: $arch"; exit 1 ;;
      esac ;;
    *)  err "Unsupported OS: $os"; exit 1 ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# HTTP fetcher detection
# ─────────────────────────────────────────────────────────────────────────────

detect_fetcher() {
  if command -v curl >/dev/null 2>&1; then
    FETCH_OUT="curl -fsSL -o"
  elif command -v wget >/dev/null 2>&1; then
    FETCH_OUT="wget -qO"
  else
    err "Neither curl nor wget found. Please install one and retry."
    exit 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Download and install a single tool
# ─────────────────────────────────────────────────────────────────────────────

install_tool() {
  tool="$1"
  asset="${tool}-${TARGET}.tar.gz"

  if [ -n "$VERSION" ]; then
    url="https://github.com/${GH_ORG}/${tool}/releases/download/v${VERSION}/${asset}"
  else
    url="https://github.com/${GH_ORG}/${tool}/releases/latest/download/${asset}"
  fi

  tmpdir=$(mktemp -d)

  info "Downloading ${tool} (${TARGET})..."
  if ! $FETCH_OUT "${tmpdir}/${asset}" "$url" 2>/dev/null; then
    err "Failed to download ${tool} from ${url}"
    rm -rf "$tmpdir"
    return 1
  fi

  tar -xzf "${tmpdir}/${asset}" -C "$tmpdir"

  if [ ! -f "${tmpdir}/${tool}" ]; then
    err "Binary '${tool}' not found in archive"
    rm -rf "$tmpdir"
    return 1
  fi

  chmod +x "${tmpdir}/${tool}"
  mv "${tmpdir}/${tool}" "${PREFIX}/${tool}"
  rm -rf "$tmpdir"

  ok "${tool} installed to ${PREFIX}/${tool}"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Uninstall
# ─────────────────────────────────────────────────────────────────────────────

do_uninstall() {
  info "Uninstalling basidiocarp tools from ${PREFIX}..."
  for tool in $ALL_TOOLS; do
    if [ -f "${PREFIX}/${tool}" ]; then
      rm -f "${PREFIX}/${tool}"
      ok "${tool} removed"
    else
      warn "${tool} not found in ${PREFIX}"
    fi
  done

  info "Uninstall complete."
  info "MCP server registrations may remain in your editor configs."
  info "Run 'stipe uninstall --all' before removing stipe for full cleanup."
  exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Verify installations
# ─────────────────────────────────────────────────────────────────────────────

verify() {
  for tool in $TOOLS; do
    if [ -x "${PREFIX}/${tool}" ]; then
      ver=$("${PREFIX}/${tool}" --version 2>&1 || echo "installed")
      ok "${ver}"
    fi
  done
}

# ─────────────────────────────────────────────────────────────────────────────
# PATH check
# ─────────────────────────────────────────────────────────────────────────────

check_path() {
  case ":${PATH}:" in
    *":${PREFIX}:"*) ;;
    *)
      printf "\n"
      warn "${PREFIX} is not in your PATH."
      printf "  Add it with:\n"
      printf "    export PATH=\"%s:\$PATH\"\n" "$PREFIX"
      printf "  Then add that line to ~/.zshrc or ~/.bashrc\n"
      ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
  parse_args "$@"

  printf "\n${BOLD}Basidiocarp Ecosystem Installer${RESET}\n\n"

  if [ $UNINSTALL -eq 1 ]; then
    do_uninstall
  fi

  detect_target
  detect_fetcher
  mkdir -p "$PREFIX"

  # Install stipe first so it can configure editors afterward
  failed=""
  succeeded=""
  for tool in $TOOLS; do
    if install_tool "$tool"; then
      succeeded="$succeeded $tool"
    else
      failed="$failed $tool"
    fi
  done

  # Delegate editor configuration to stipe
  if [ $CONFIGURE -eq 1 ] && [ -x "${PREFIX}/stipe" ]; then
    printf "\n"
    info "Configuring editors..."
    "${PREFIX}/stipe" init 2>&1 || warn "stipe init had issues (run 'stipe doctor' to diagnose)"
  elif [ $CONFIGURE -eq 1 ]; then
    warn "stipe not installed — skipping editor configuration"
    warn "Run 'stipe init' manually after installing stipe"
  fi

  printf "\n"
  info "Summary"
  verify

  for tool in $failed; do
    err "${tool} failed to install"
  done

  printf "\n${BOLD}Next steps:${RESET}\n"
  printf "  1. Restart your editor to pick up MCP servers\n"
  printf "  2. Run: stipe doctor        (verify ecosystem health)\n"
  printf "  3. Run: stipe update --all  (update to latest versions)\n"
  printf "\n"

  check_path

  [ -z "$failed" ] || exit 1
}

main "$@"
