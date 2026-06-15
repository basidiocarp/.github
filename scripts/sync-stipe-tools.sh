#!/usr/bin/env bash
# Regenerates the [tools] block in stipe/ecosystem-versions.toml from the root
# ecosystem-versions.toml (the single source of truth). Stipe's build.rs reads
# this stipe-local file at build time and panics on drift with the root — this
# script is the authoritative way to keep them in sync after a root [tools] bump.
#
# Usage:
#   bash scripts/sync-stipe-tools.sh           # rewrite the stipe [tools] block in place
#   bash scripts/sync-stipe-tools.sh --check    # exit 1 if the block is stale
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_TOML="$ROOT/ecosystem-versions.toml"
STIPE_TOML="$ROOT/stipe/ecosystem-versions.toml"

MODE="${1:-write}"
case "$MODE" in
    --check) MODE="check" ;;
    write|"") MODE="write" ;;
    *) echo "usage: sync-stipe-tools.sh [--check]" >&2; exit 2 ;;
esac

MODE="$MODE" python3 - "$ROOT_TOML" "$STIPE_TOML" <<'PY'
import os, re, sys, tempfile

root_path, stipe_path = sys.argv[1], sys.argv[2]
mode = os.environ["MODE"]

# Fix 3: tighten section_re so inline-array values (x = ["a"]) are never
# mistaken for section headers. Section headers always start [<letter>.
kv_re = re.compile(r'^([A-Za-z0-9._-]+)\s*=\s*"([^"]*)"')
section_re = re.compile(r'^\[[A-Za-z]')

# --- 1. Parse the root [tools] block verbatim (Fix 1).
with open(root_path) as f:
    root_lines = f.readlines()

tools_start = None
for i, line in enumerate(root_lines):
    if line.strip() == "[tools]":
        tools_start = i
        break
if tools_start is None:
    sys.exit("sync-stipe-tools: [tools] section not found in root ecosystem-versions.toml")

# Find the first key=value line at/after tools_start+1 (Fix 1: skip leading
# comment/blank header lines, but keep everything from there onward verbatim).
first_kv = None
root_tools_end = len(root_lines)
for i, line in enumerate(root_lines[tools_start + 1:], start=tools_start + 1):
    if section_re.match(line):
        root_tools_end = i
        break
    if first_kv is None and kv_re.match(line):
        first_kv = i

if first_kv is None:
    sys.exit("sync-stipe-tools: no key=value lines in root [tools] — cannot sync")

# Copy the body verbatim from first_kv through to the next section (or EOF).
# This preserves interspersed comments and blank lines that appear after the
# first version entry, while intentionally dropping root's leading descriptive
# comment header (replaced below with the GENERATED header).
body = root_lines[first_kv:root_tools_end]

# Strip trailing blank/whitespace-only lines from the body.
while body and body[-1].strip() == "":
    body.pop()

# --- 2. Read the stipe file and locate its [tools] block boundaries.
with open(stipe_path) as f:
    stipe_lines = f.readlines()

stipe_tools_start = None
for i, line in enumerate(stipe_lines):
    if line.strip() == "[tools]":
        stipe_tools_start = i
        break
if stipe_tools_start is None:
    sys.exit("sync-stipe-tools: [tools] section not found in stipe/ecosystem-versions.toml")

# Find the line index of the next top-level section after [tools] in stipe.
stipe_tools_end = None
for i, line in enumerate(stipe_lines[stipe_tools_start + 1:], start=stipe_tools_start + 1):
    if section_re.match(line):
        stipe_tools_end = i
        break
if stipe_tools_end is None:
    sys.exit("sync-stipe-tools: could not find the section that follows [tools] in stipe/ecosystem-versions.toml")

# --- 3. Render the new [tools] block.
def render():
    out = []
    out.append("[tools]\n")
    out.append("# GENERATED from root ecosystem-versions.toml by scripts/sync-stipe-tools.sh — do not edit by hand.\n")
    out.append("# Run `bash scripts/sync-stipe-tools.sh` after bumping root [tools]; stipe build.rs panics on drift.\n")
    out.extend(body)
    out.append("\n")
    return out

new_block = render()

# Splice: everything before stipe's [tools] + new block + everything from the next section onward.
new_lines = stipe_lines[:stipe_tools_start] + new_block + stipe_lines[stipe_tools_end:]

# --- 4. Act on mode.

# Fix 2: normalize trailing blanks before comparison so a differing count of
# trailing blank lines before [contracts] never causes a spurious FAIL.
def strip_trailing_blanks(lines):
    out = list(lines)
    while out and out[-1].strip() == "":
        out.pop()
    return out

if mode == "check":
    current_block = stipe_lines[stipe_tools_start:stipe_tools_end]
    if strip_trailing_blanks(current_block) == strip_trailing_blanks(new_block):
        print("PASS: stipe [tools] in sync with root ecosystem-versions.toml")
        sys.exit(0)
    print("FAIL: stipe [tools] out of sync with root — run bash scripts/sync-stipe-tools.sh", file=sys.stderr)
    sys.exit(1)

# Fix 4: atomic write — write to a temp file then replace, so a crash cannot
# truncate the destination file.
dir_ = os.path.dirname(stipe_path)
fd, tmp = tempfile.mkstemp(dir=dir_, prefix=".sync-stipe-tools.", suffix=".tmp")
try:
    with os.fdopen(fd, "w") as f:
        f.writelines(new_lines)
    os.replace(tmp, stipe_path)
except BaseException:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise

print(f"wrote stipe [tools] ({len(body)} lines)")
PY
