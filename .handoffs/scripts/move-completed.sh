#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p archive/mycelium

# Move completed handoffs + verify scripts
mv mycelium/diagnostic-passthrough.md archive/mycelium/
mv mycelium/verify-diagnostic-passthrough.sh archive/mycelium/
mv mycelium/hook-registration.md archive/mycelium/
mv mycelium/verify-hook-registration.sh archive/mycelium/

echo "DONE"
