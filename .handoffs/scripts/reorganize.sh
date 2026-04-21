#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Create directories
mkdir -p canopy mycelium lamella cross-project campaigns state scripts sessions/open

# Canopy
mv HANDOFF-CANOPY-FILE-CONFLICT-DETECTION.md canopy/file-conflict-detection.md
mv HANDOFF-CANOPY-VERIFICATION-ENFORCEMENT.md canopy/verification-enforcement.md
mv verify-canopy-file-conflict-detection.sh canopy/verify-file-conflict-detection.sh
mv verify-canopy-verification-enforcement.sh canopy/verify-verification-enforcement.sh

# Mycelium
mv HANDOFF-MYCELIUM-DIAGNOSTIC-PASSTHROUGH.md mycelium/diagnostic-passthrough.md
mv verify-mycelium-diagnostic-passthrough.sh mycelium/verify-diagnostic-passthrough.sh

# Lamella
mv HANDOFF-LAMELLA-REQUIRES-TAGGING.md lamella/requires-tagging.md
mv verify-lamella-requires-tagging.sh lamella/verify-requires-tagging.sh

# Cross-project
mv HANDOFF-TOOL-NUDGING.md cross-project/tool-nudging.md
mv verify-tool-nudging.sh cross-project/verify-tool-nudging.sh

# Global audit → campaigns
if [ -d global-audit ]; then
  cp -r global-audit/* campaigns/global-audit/
  rm -rf global-audit
fi

echo "Done: legacy handoff files were moved into the current layout."
