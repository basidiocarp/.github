#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/williamnewton/projects/basidiocarp"
cd "$ROOT/cap"

npm run build
npm run test:frontend
