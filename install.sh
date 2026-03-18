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
CLIENT=""
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
                    Available: mycelium, hyphae, rhizome
  --prefix DIR      Install directory (default: ~/.local/bin)
  --client NAME     Configure only this MCP client (default: all detected)
                    Available: claude, cursor, windsurf, continue, claude-desktop, generic
  --no-configure    Skip MCP client configuration
  --version VER     Install a specific version (default: latest)
  --uninstall       Remove installed binaries and configuration

Examples:
  curl -fsSL https://raw.githubusercontent.com/basidiocarp/.github/main/install.sh | sh
  install.sh --tools mycelium,hyphae
  install.sh --client cursor
  install.sh --client generic    # Print config JSON for manual setup
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
      --client)       shift; CLIENT="$1" ;;
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
# MCP server JSON snippet (used by JSON-config clients)
# ─────────────────────────────────────────────────────────────────────────────

mcp_servers_json() {
  cat <<MCPJSON
{
  "hyphae": {
    "command": "hyphae",
    "args": ["serve"]
  },
  "rhizome": {
    "command": "rhizome",
    "args": ["serve", "--expanded"]
  }
}
MCPJSON
}

# ─────────────────────────────────────────────────────────────────────────────
# Check if an MCP server is already registered (Claude Code)
# ─────────────────────────────────────────────────────────────────────────────

mcp_exists() {
  claude mcp list 2>/dev/null | grep -q "^${1}:" 2>/dev/null
}

# ─────────────────────────────────────────────────────────────────────────────
# Write MCP config to a JSON file (Cursor, Windsurf, Continue, Claude Desktop)
# Merges into existing mcpServers without overwriting other entries.
# ─────────────────────────────────────────────────────────────────────────────

write_mcp_json() {
  config_file="$1"
  client_name="$2"

  if [ ! -d "$(dirname "$config_file")" ]; then
    warn "$client_name config directory not found — skipping"
    return 1
  fi

  # Backup existing config
  if [ -f "$config_file" ]; then
    cp "$config_file" "${config_file}.bak" 2>/dev/null || true
  fi

  # Check if jq is available for proper JSON merging
  if command -v jq >/dev/null 2>&1; then
    if [ -f "$config_file" ]; then
      # Merge into existing config
      jq --argjson servers "$(mcp_servers_json)" '.mcpServers = (.mcpServers // {}) + $servers' "$config_file" > "${config_file}.tmp" \
        && mv "${config_file}.tmp" "$config_file" \
        && ok "$client_name: MCP servers added to $config_file" \
        || { warn "Failed to update $client_name config"; return 1; }
    else
      # Create new config with just mcpServers
      printf '{"mcpServers": %s}\n' "$(mcp_servers_json)" | jq '.' > "$config_file" \
        && ok "$client_name: MCP config created at $config_file" \
        || { warn "Failed to create $client_name config"; return 1; }
    fi
  else
    # No jq — write simple config (may overwrite existing)
    if [ -f "$config_file" ]; then
      warn "$client_name: jq not installed — cannot safely merge config. Skipping."
      warn "  Install jq and re-run, or manually add to $config_file:"
      printf "  %s\n" "$(mcp_servers_json | head -8)"
      return 1
    else
      printf '{"mcpServers": %s}\n' "$(mcp_servers_json)" > "$config_file" \
        && ok "$client_name: MCP config created at $config_file" \
        || { warn "Failed to create $client_name config"; return 1; }
    fi
  fi
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Configure MCP clients
# ─────────────────────────────────────────────────────────────────────────────

configure_clients() {
  info "Configuring MCP clients..."

  configured=0

  # Generic mode — just print the config
  if [ "$CLIENT" = "generic" ]; then
    info "MCP server configuration (add to your client's config):"
    printf "\n"
    mcp_servers_json
    printf "\n"
    return
  fi

  # Claude Code
  if [ -z "$CLIENT" ] || [ "$CLIENT" = "claude" ]; then
    if command -v claude >/dev/null 2>&1; then
      for tool in $TOOLS; do
        case "$tool" in
          hyphae)
            if mcp_exists hyphae; then
              ok "Claude Code: hyphae already registered"
            else
              claude mcp add --scope user hyphae -- hyphae serve 2>/dev/null \
                && ok "Claude Code: hyphae MCP registered" \
                || warn "Claude Code: failed to register hyphae"
            fi ;;
          rhizome)
            if mcp_exists rhizome; then
              ok "Claude Code: rhizome already registered"
            else
              claude mcp add --scope user rhizome -- rhizome serve --expanded 2>/dev/null \
                && ok "Claude Code: rhizome MCP registered" \
                || warn "Claude Code: failed to register rhizome"
            fi ;;
          mycelium)
            if [ -x "${PREFIX}/mycelium" ]; then
              "${PREFIX}/mycelium" init --global 2>/dev/null \
                && ok "Claude Code: mycelium hooks configured" \
                || warn "Claude Code: failed to configure mycelium"
            fi ;;
        esac
      done
      configured=$((configured + 1))
    elif [ "$CLIENT" = "claude" ]; then
      warn "Claude Code CLI not found"
    fi
  fi

  # Cursor
  if [ -z "$CLIENT" ] || [ "$CLIENT" = "cursor" ]; then
    cursor_config="$HOME/.cursor/mcp.json"
    if [ -d "$HOME/.cursor" ] || [ "$CLIENT" = "cursor" ]; then
      mkdir -p "$HOME/.cursor"
      write_mcp_json "$cursor_config" "Cursor" && configured=$((configured + 1))
    fi
  fi

  # Windsurf
  if [ -z "$CLIENT" ] || [ "$CLIENT" = "windsurf" ]; then
    windsurf_config="$HOME/.windsurf/mcp.json"
    if [ -d "$HOME/.windsurf" ] || [ "$CLIENT" = "windsurf" ]; then
      mkdir -p "$HOME/.windsurf"
      write_mcp_json "$windsurf_config" "Windsurf" && configured=$((configured + 1))
    fi
  fi

  # Continue
  if [ -z "$CLIENT" ] || [ "$CLIENT" = "continue" ]; then
    continue_config="$HOME/.continue/config.json"
    if [ -d "$HOME/.continue" ] || [ "$CLIENT" = "continue" ]; then
      mkdir -p "$HOME/.continue"
      write_mcp_json "$continue_config" "Continue" && configured=$((configured + 1))
    fi
  fi

  # Claude Desktop
  if [ -z "$CLIENT" ] || [ "$CLIENT" = "claude-desktop" ]; then
    case "$(uname -s)" in
      Darwin) desktop_config="$HOME/Library/Application Support/Claude/claude_desktop_config.json" ;;
      Linux)  desktop_config="${XDG_CONFIG_HOME:-$HOME/.config}/Claude/claude_desktop_config.json" ;;
      *)      desktop_config="" ;;
    esac
    if [ -n "$desktop_config" ]; then
      if [ -d "$(dirname "$desktop_config")" ] || [ "$CLIENT" = "claude-desktop" ]; then
        mkdir -p "$(dirname "$desktop_config")"
        write_mcp_json "$desktop_config" "Claude Desktop" && configured=$((configured + 1))
      fi
    fi
  fi

  if [ $configured -eq 0 ] && [ -z "$CLIENT" ]; then
    warn "No MCP clients detected. Install one of: Claude Code, Cursor, Windsurf, Continue"
    info "  Or run with --client generic to print config for manual setup"
  fi
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
    configure_clients
  fi

  printf "\n"
  info "Summary"
  verify

  for tool in $failed; do
    err "${tool} failed to install"
  done

  printf "\n${BOLD}Next steps:${RESET}\n"
  printf "  1. Restart your editor to pick up MCP servers\n"
  case "$succeeded" in *mycelium*)  printf "  2. Run: mycelium gain\n" ;; esac
  case "$succeeded" in *hyphae*)   printf "  3. Run: hyphae --help\n" ;; esac
  printf "\n"

  check_path

  [ -z "$failed" ] || exit 1
}

main "$@"
