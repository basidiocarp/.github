#!/bin/sh
# Basidiocarp Ecosystem Installer
# POSIX sh compatible — no bashisms.
# Usage: curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
#   or:  sh install.sh --tools mycelium,hyphae --prefix /usr/local/bin

set -e

# --- Defaults ----------------------------------------------------------------

ALL_TOOLS="mycelium hyphae rhizome"
TOOLS="$ALL_TOOLS"
PREFIX="$HOME/.local/bin"
CONFIGURE=1
VERSION=""
UNINSTALL=0
GH_ORG="basidiocarp"

# --- Colors (disabled when not a terminal) ------------------------------------

if [ -t 1 ]; then
  GREEN='\033[32m' RED='\033[31m' YELLOW='\033[33m' BOLD='\033[1m' RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' BOLD='' RESET=''
fi

info()  { printf "${BOLD}%s${RESET}\n" "$*"; }
ok()    { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn()  { printf "${YELLOW}⚠${RESET} %s\n" "$*" >&2; }
err()   { printf "${RED}✗${RESET} %s\n" "$*" >&2; }

# --- Usage --------------------------------------------------------------------

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
  install.sh                              # install everything
  install.sh --tools mycelium,hyphae      # install selected tools
  install.sh --prefix /usr/local/bin      # custom directory
  install.sh --uninstall                  # remove everything
EOF
  exit 0
}

# --- Argument parsing ---------------------------------------------------------

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

# --- Platform detection -------------------------------------------------------

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
        x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
        *)      err "Unsupported Linux architecture: $arch"; exit 1 ;;
      esac ;;
    *)  err "Unsupported OS: $os"; exit 1 ;;
  esac
}

# --- HTTP fetcher detection ---------------------------------------------------

detect_fetcher() {
  if command -v curl >/dev/null 2>&1; then
    FETCH="curl -fsSL"
    FETCH_OUT="curl -fsSL -o"
  elif command -v wget >/dev/null 2>&1; then
    FETCH="wget -qO-"
    FETCH_OUT="wget -qO"
  else
    err "Neither curl nor wget found. Please install one and retry."
    exit 1
  fi
}

# --- Download & install a single tool ----------------------------------------

install_tool() {
  tool="$1"

  if [ -n "$VERSION" ]; then
    url="https://github.com/${GH_ORG}/${tool}/releases/download/v${VERSION}/${tool}-${TARGET}.tar.gz"
  else
    url="https://github.com/${GH_ORG}/${tool}/releases/latest/download/${tool}-${TARGET}.tar.gz"
  fi

  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT

  info "Downloading ${tool}..."
  if ! $FETCH_OUT "${tmpdir}/${tool}.tar.gz" "$url" 2>/dev/null; then
    err "Failed to download ${tool} from ${url}"
    return 1
  fi

  tar -xzf "${tmpdir}/${tool}.tar.gz" -C "$tmpdir"
  chmod +x "${tmpdir}/${tool}"
  mv "${tmpdir}/${tool}" "${PREFIX}/${tool}"

  rm -rf "$tmpdir"
  trap - EXIT
  return 0
}

# --- Uninstall ----------------------------------------------------------------

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
      claude mcp remove --scope user "$tool" 2>/dev/null && ok "Claude Code MCP server '${tool}' removed" || true
    done
  fi

  info "Uninstall complete."
  exit 0
}

# --- Configure Claude Code ----------------------------------------------------

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
        mycelium init --global 2>/dev/null \
          && ok "Mycelium hooks configured" \
          || warn "Failed to configure mycelium hooks" ;;
    esac
  done
}

# --- Verify installations -----------------------------------------------------

verify() {
  info "Verifying installations..."
  for tool in $TOOLS; do
    if ver=$("${PREFIX}/${tool}" --version 2>/dev/null); then
      ok "${ver}"
    else
      err "${tool} --version failed"
    fi
  done
}

# --- PATH check ---------------------------------------------------------------

check_path() {
  case ":${PATH}:" in
    *":${PREFIX}:"*) ;;
    *)
      warn "${PREFIX} is not in your PATH."
      printf "  Add it with:\n"
      printf "    export PATH=\"%s:\$PATH\"\n" "$PREFIX"
      printf "  Then add that line to your shell profile (~/.profile, ~/.zshrc, etc.)\n"
      ;;
  esac
}

# --- Main ---------------------------------------------------------------------

main() {
  parse_args "$@"

  printf "\n${BOLD}Basidiocarp Ecosystem Installer${RESET}\n\n"

  if [ $UNINSTALL -eq 1 ]; then
    do_uninstall
  fi

  detect_target
  detect_fetcher

  # Ensure prefix directory exists
  mkdir -p "$PREFIX"

  # Install each tool, track failures
  failed=""
  succeeded=""
  for tool in $TOOLS; do
    if install_tool "$tool"; then
      succeeded="$succeeded $tool"
    else
      failed="$failed $tool"
    fi
  done

  # Configure Claude Code integration
  if [ $CONFIGURE -eq 1 ] && [ -n "$succeeded" ]; then
    configure_claude
  fi

  # Verify installed tools
  if [ -n "$succeeded" ]; then
    verify
  fi

  # Summary
  printf "\n"
  for tool in $succeeded; do
    ver=$("${PREFIX}/${tool}" --version 2>/dev/null || echo "${tool} installed")
    ok "$ver"
  done
  for tool in $failed; do
    err "${tool} failed to install"
  done
  if [ $CONFIGURE -eq 1 ] && [ -n "$succeeded" ] && command -v claude >/dev/null 2>&1; then
    ok "Claude Code configured"
  fi

  # Next steps
  printf "\n${BOLD}Next steps:${RESET}\n"
  printf "  1. Restart Claude Code to pick up MCP servers\n"
  case "$succeeded" in *mycelium*)  printf "  2. Run: mycelium gain\n" ;; esac
  case "$succeeded" in *hyphae*)   printf "  3. Run: hyphae store \"test memory\"\n" ;; esac
  printf "\n"

  check_path

  # Exit non-zero if anything failed
  [ -z "$failed" ] || exit 1
}

main "$@"
