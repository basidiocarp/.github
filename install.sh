#!/bin/sh
# ─────────────────────────────────────────────────────────────────────────────
# Basidiocarp Ecosystem Installer
# ─────────────────────────────────────────────────────────────────────────────
# POSIX sh compatible — no bashisms.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
#   sh install.sh --tools mycelium,hyphae --prefix /usr/local/bin

set -e

# ─────────────────────────────────────────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────────────────────────────────────────

ALL_TOOLS="mycelium hyphae rhizome"
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
  GREEN='\033[32m' RED='\033[31m' YELLOW='\033[33m' BOLD='\033[1m' RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' BOLD='' RESET=''
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
                    Available: mycelium, hyphae, rhizome
  --prefix DIR      Install directory (default: ~/.local/bin)
  --no-configure    Skip Claude Code configuration
  --version VER     Install a specific version (default: latest)
  --uninstall       Remove installed binaries and configuration

Examples:
  curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
  install.sh --tools mycelium,hyphae
  install.sh --prefix /usr/local/bin
  install.sh --version 0.3.0
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
# Release assets are named: {tool}-{target}.tar.gz (no version in filename)
# URLs:
#   latest:  https://github.com/{org}/{tool}/releases/latest/download/{tool}-{target}.tar.gz
#   pinned:  https://github.com/{org}/{tool}/releases/download/v{ver}/{tool}-{target}.tar.gz

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
  for tool in $TOOLS; do
    if [ -f "${PREFIX}/${tool}" ]; then
      rm -f "${PREFIX}/${tool}"
      ok "${tool} removed"
    else
      warn "${tool} not found in ${PREFIX}"
    fi
  done

  if [ $CONFIGURE -eq 1 ] && command -v claude >/dev/null 2>&1; then
    for tool in hyphae rhizome; do
      claude mcp remove --scope user "$tool" 2>/dev/null \
        && ok "Claude Code MCP server '${tool}' removed" || true
    done
  fi

  info "Uninstall complete."
  exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Configure Claude Code
# ─────────────────────────────────────────────────────────────────────────────

configure_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    warn "Claude Code CLI not found — skipping configuration."
    return
  fi

  info "Configuring Claude Code..."

  for tool in $TOOLS; do
    case "$tool" in
      hyphae)
        claude mcp add --scope user hyphae -- hyphae serve 2>/dev/null \
          && ok "MCP server 'hyphae' registered" \
          || warn "Failed to register MCP server 'hyphae'" ;;
      rhizome)
        claude mcp add --scope user rhizome -- rhizome serve --expanded 2>/dev/null \
          && ok "MCP server 'rhizome' registered" \
          || warn "Failed to register MCP server 'rhizome'" ;;
      mycelium)
        if [ -x "${PREFIX}/mycelium" ]; then
          "${PREFIX}/mycelium" init --global 2>/dev/null \
            && ok "Mycelium hooks configured" \
            || warn "Failed to configure mycelium hooks"
        fi ;;
    esac
  done
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

  failed=""
  succeeded=""
  for tool in $TOOLS; do
    if install_tool "$tool"; then
      succeeded="$succeeded $tool"
    else
      failed="$failed $tool"
    fi
  done

  if [ $CONFIGURE -eq 1 ] && [ -n "$succeeded" ]; then
    configure_claude
  fi

  printf "\n"
  info "Summary"
  verify

  for tool in $failed; do
    err "${tool} failed to install"
  done

  printf "\n${BOLD}Next steps:${RESET}\n"
  printf "  1. Restart Claude Code to pick up MCP servers\n"
  case "$succeeded" in *mycelium*)  printf "  2. Run: mycelium gain\n" ;; esac
  case "$succeeded" in *hyphae*)   printf "  3. Run: hyphae --help\n" ;; esac
  printf "\n"

  check_path

  [ -z "$failed" ] || exit 1
}

main "$@"
