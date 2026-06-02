#!/usr/bin/env bash
# Regenerates the [contracts] / [contracts.draft] block in ecosystem-versions.toml
# from septa's enforced contract registry (septa/CROSS-TOOL-PAYLOADS.md).
#
# The block is a DERIVED artifact: the Schema-Backed table becomes [contracts]
# (active) and the Draft/Deferred table becomes [contracts.draft]. Curated
# coordination versions already in the file are preserved; new families default
# to "1.0". Families in neither septa table are pruned.
#
# Usage:
#   bash scripts/sync-contracts.sh           # rewrite the block in place
#   bash scripts/sync-contracts.sh --check    # exit 1 if the block is stale (CI gate)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOML="$ROOT/ecosystem-versions.toml"
REGISTRY="$ROOT/septa/CROSS-TOOL-PAYLOADS.md"

MODE="${1:-write}"
case "$MODE" in
    --check) MODE="check" ;;
    write|"") MODE="write" ;;
    *) echo "usage: sync-contracts.sh [--check]" >&2; exit 2 ;;
esac

MODE="$MODE" python3 - "$TOML" "$REGISTRY" <<'PY'
import os, re, sys

toml_path, registry_path = sys.argv[1], sys.argv[2]
mode = os.environ["MODE"]

# --- 1. Parse septa's enforced registry: Schema-Backed -> active, Draft -> draft.
with open(registry_path) as f:
    reg_lines = f.readlines()

def parse_section(lines, header):
    """Return the payload names (first table column) under a `## header` section."""
    names, in_section = [], False
    for line in lines:
        s = line.strip()
        if s.startswith("## "):
            in_section = s[3:].strip().startswith(header)
            continue
        if not in_section or not s.startswith("|"):
            continue
        cells = [c.strip() for c in s.strip("|").split("|")]
        first = cells[0]
        if not first or first == "Payload" or set(first) <= {"-", ":"}:
            continue  # header or separator row
        if first == "(none)":
            continue
        names.append(first)
    return names

active = parse_section(reg_lines, "Schema-Backed Payloads")
draft = parse_section(reg_lines, "Draft / Deferred Payloads")

active_set, draft_set = set(active), set(draft)
overlap = active_set & draft_set
if overlap:
    sys.exit(f"sync-contracts: family in both Backed and Draft tables: {sorted(overlap)}")
if len(active) != len(active_set):
    dupes = sorted({n for n in active if active.count(n) > 1})
    sys.exit(f"sync-contracts: duplicate Schema-Backed rows: {dupes}")

# --- 2. Capture existing curated versions (across both [contracts] tables).
with open(toml_path) as f:
    toml_lines = f.readlines()

contracts_start = None
for i, line in enumerate(toml_lines):
    if line.strip() == "[contracts]":
        contracts_start = i
        break
if contracts_start is None:
    sys.exit("sync-contracts: [contracts] section not found in ecosystem-versions.toml")

existing = {}
kv = re.compile(r'^([A-Za-z0-9._-]+)\s*=\s*"([^"]*)"\s*$')
for line in toml_lines[contracts_start + 1:]:
    s = line.strip()
    if s.startswith("[") and s.endswith("]"):
        if s not in ("[contracts]", "[contracts.draft]"):
            break  # a different top-level section (defensive; block is last today)
        continue
    m = kv.match(s)
    if m:
        existing[m.group(1)] = m.group(2)

def version_for(name):
    return existing.get(name, "1.0")

# --- 3. Render the regenerated block.
def render():
    out = []
    out.append("[contracts]\n")
    out.append("# GENERATED from septa/CROSS-TOOL-PAYLOADS.md by scripts/sync-contracts.sh — do not edit by hand.\n")
    out.append("# Run `bash scripts/sync-contracts.sh` to regenerate; the root drift gate fails if this is stale.\n")
    out.append("# Active (Schema-Backed) contract families. Values are coordination versions for the\n")
    out.append("# contract family, not necessarily the literal `schema_version` field in each payload.\n")
    for name in sorted(active_set):
        out.append(f'{name} = "{version_for(name)}"\n')
    out.append("\n")
    out.append("[contracts.draft]\n")
    out.append("# Deferred (Draft) contract families from septa/draft/ — designed but not yet schema-validated.\n")
    for name in sorted(draft_set):
        out.append(f'{name} = "{version_for(name)}"\n')
    return out

new_block = render()
new_lines = toml_lines[:contracts_start] + new_block

if mode == "check":
    if toml_lines == new_lines:
        print(f"PASS: [contracts] mirror in sync with septa ({len(active_set)} active, {len(draft_set)} draft)")
        sys.exit(0)
    print("FAIL: [contracts] mirror is stale — run `bash scripts/sync-contracts.sh`", file=sys.stderr)
    old_set = set(existing)
    pruned = sorted(old_set - active_set - draft_set)
    added = sorted((active_set | draft_set) - old_set)
    if added:
        print(f"  missing (would add):   {added}", file=sys.stderr)
    if pruned:
        print(f"  phantom (would prune): {pruned}", file=sys.stderr)
    sys.exit(1)

with open(toml_path, "w") as f:
    f.writelines(new_lines)
print(f"wrote [contracts] ({len(active_set)} active) + [contracts.draft] ({len(draft_set)} draft)")
PY
