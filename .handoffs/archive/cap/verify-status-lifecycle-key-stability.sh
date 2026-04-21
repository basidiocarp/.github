#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../cap"
npm run test:frontend -- --run src/pages/status/LifecycleAdaptersCard.test.tsx
