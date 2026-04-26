# Cross-Project: Ecosystem Smoke Test

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** basidiocarp (workspace root)
- **Allowed write scope:** `scripts/smoke-test.sh` (create); `.handoffs/cross-project/verify-ecosystem-smoke-test.sh` (create)
- **Cross-repo edits:** none (the script exercises live tools, does not modify them)
- **Non-goals:** testing unit behavior of individual tools; replacing per-repo test suites; CI integration (this is a local operator check)
- **Verification contract:** running the script against a live ecosystem reports pass/fail for each seam
- **Completion update:** update dashboard when script is created and produces meaningful output

## Context

The audit confirmed that the cortina→hyphae→canopy→cap chain works in parts but has never been validated as a whole from the outside. Individual repos have unit tests, but no script verifies that the four tools are wired correctly as a running system.

This is the operator's equivalent of `curl localhost:3000/health` — a fast, external check that answers "is the ecosystem alive?" without needing to read source code.

The five seams to exercise:

1. **Cortina → Hyphae**: cortina's hook fires and hyphae stores the signal
2. **Hyphae recall**: a stored memory can be recalled by project
3. **Canopy availability**: canopy HTTP endpoint responds
4. **Cap → Canopy**: cap's canopy CLI call returns snapshot data
5. **Rhizome availability**: rhizome MCP server responds to a symbol query

Each check should be independent — a failure in seam 2 should not prevent seam 3 from running.

## What needs doing (intent)

Create `scripts/smoke-test.sh` that:

1. Checks that each tool binary or server is reachable
2. Runs one representative operation per seam
3. Reports PASS / FAIL / SKIP per seam with a reason
4. Exits non-zero if any seam fails (SKIP is not failure)
5. Finishes in under 30 seconds

The script should degrade gracefully — if a tool is not running, SKIP that seam rather than ERROR. SKIP indicates "not running in this configuration," not "broken."

## Scope

- **Primary seam:** `scripts/smoke-test.sh` (new file at workspace root)
- **Allowed files:** `scripts/smoke-test.sh`, `.handoffs/cross-project/verify-ecosystem-smoke-test.sh`
- **Explicit non-goals:** starting services that are not running; modifying any tool source code; CI integration

---

### Step 1: Enumerate what each seam needs to check

**Project:** basidiocarp root
**Effort:** 30 min
**Depends on:** nothing

Before writing the script, determine the cheapest observable signal per seam:

| Seam | Tool | Check | Expected Signal |
|------|------|-------|-----------------|
| 1 | cortina→hyphae | `hyphae memory store` then `hyphae memory recall` | recall returns the stored value |
| 2 | hyphae standalone | `hyphae memory recall --project smoke-test` | exits 0 (even if no results) |
| 3 | canopy | `curl -s http://localhost:<port>/health` | 200 OK |
| 4 | cap→canopy | `cap canopy snapshot` or equivalent CLI | exits 0 with JSON |
| 5 | rhizome | rhizome MCP handshake or `rhizome ping` | exits 0 |

Read the actual CLI interfaces before writing the script:
- `hyphae --help` — confirm `memory store` and `memory recall` subcommands exist
- `canopy --help` — confirm health check port
- `rhizome --help` — confirm health check or ping subcommand

#### Verification

```bash
hyphae --help 2>&1 | head -20
canopy --help 2>&1 | head -20
rhizome --help 2>&1 | head -20
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] CLI interfaces confirmed for each tool
- [ ] Health check port for canopy confirmed

---

### Step 2: Write the smoke test script

**Project:** basidiocarp root
**Effort:** 1 hour
**Depends on:** Step 1

Create `scripts/smoke-test.sh`:

```bash
#!/usr/bin/env bash
# Ecosystem smoke test — verifies the cortina→hyphae→canopy→cap chain is wired.
# Each seam runs independently. SKIP = not running; FAIL = running but broken.
# Exit code: 0 if all reachable seams pass; 1 if any reachable seam fails.

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1: $2"; FAIL=$((FAIL+1)); }
skip() { echo "  SKIP  $1: $2"; SKIP=$((SKIP+1)); }

echo "=== Ecosystem Smoke Test ==="
echo "Date: $(date)"
echo ""

# Seam 1: hyphae store + recall
echo "[1/5] hyphae store + recall"
if ! command -v hyphae &>/dev/null; then
  skip "hyphae" "binary not found"
else
  SMOKE_KEY="smoke-test-$(date +%s)"
  if hyphae memory store --topic "smoke/test" --content "smoke-$SMOKE_KEY" --project smoke-test &>/dev/null 2>&1; then
    RECALL=$(hyphae memory recall --project smoke-test --topic "smoke/test" 2>/dev/null || true)
    if echo "$RECALL" | grep -q "smoke-$SMOKE_KEY"; then
      pass "hyphae store+recall"
    else
      fail "hyphae recall" "stored value not found in recall output"
    fi
  else
    fail "hyphae store" "store command failed"
  fi
fi

# Seam 2: hyphae standalone recall (no write)
echo "[2/5] hyphae baseline recall"
if ! command -v hyphae &>/dev/null; then
  skip "hyphae" "binary not found"
else
  if hyphae memory recall --project basidiocarp &>/dev/null 2>&1; then
    pass "hyphae recall basidiocarp"
  else
    fail "hyphae recall" "non-zero exit for project recall"
  fi
fi

# Seam 3: canopy health check
echo "[3/5] canopy health"
CANOPY_PORT="${CANOPY_PORT:-8080}"
if curl -sf "http://localhost:${CANOPY_PORT}/health" &>/dev/null 2>&1; then
  pass "canopy health http://localhost:${CANOPY_PORT}/health"
else
  skip "canopy" "not reachable at localhost:${CANOPY_PORT}"
fi

# Seam 4: cap → canopy snapshot
echo "[4/5] cap→canopy snapshot"
if ! command -v cap &>/dev/null; then
  skip "cap" "binary not found"
else
  if cap canopy snapshot &>/dev/null 2>&1; then
    pass "cap canopy snapshot"
  else
    skip "cap canopy" "snapshot call failed (canopy may not be running)"
  fi
fi

# Seam 5: rhizome availability
echo "[5/5] rhizome health"
if ! command -v rhizome &>/dev/null; then
  skip "rhizome" "binary not found"
else
  if rhizome --version &>/dev/null 2>&1; then
    pass "rhizome binary reachable"
  else
    fail "rhizome" "binary found but --version failed"
  fi
fi

echo ""
echo "Results: ${PASS} pass / ${FAIL} fail / ${SKIP} skip"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "ECOSYSTEM: DEGRADED — ${FAIL} seam(s) failed"
  exit 1
elif [ "$PASS" -eq 0 ]; then
  echo "ECOSYSTEM: UNKNOWN — all seams skipped (nothing running?)"
  exit 0
else
  echo "ECOSYSTEM: OK — all reachable seams pass"
  exit 0
fi
```

**Important:** Read the actual hyphae, canopy, and rhizome CLI help output from Step 1 before finalizing subcommand names. The script above uses plausible names but they must be verified against real output.

#### Verification

```bash
chmod +x scripts/smoke-test.sh
bash scripts/smoke-test.sh
# Should print PASS/FAIL/SKIP per seam
# Should not hang — each check should complete in seconds
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Script runs without syntax errors
- [ ] Each seam produces PASS, FAIL, or SKIP (never hangs)
- [ ] SKIP is used correctly for tools not running (not FAIL)
- [ ] Exit code is 0 when no failures; 1 when any seam fails
- [ ] Total runtime under 30 seconds

---

### Step 3: Document SKIP conditions

**Project:** basidiocarp root
**Effort:** 15 min
**Depends on:** Step 2

Add a short block comment at the top of the script explaining when each seam will SKIP:

```bash
# SKIP conditions (normal, not an error):
#   hyphae — binary not installed or not on PATH
#   canopy — not running (expected in baseline mode without volva)
#   cap canopy — canopy unavailable (cap is running but canopy is not)
#   rhizome — binary not installed or MCP server not started
#
# FAIL conditions (something is broken):
#   hyphae store succeeds but recall doesn't return the stored value
#   rhizome binary found but --version exits non-zero
#
# In baseline mode (no volva), expect canopy seam to SKIP.
# In full mode (with volva), all 5 seams should PASS.
```

**Checklist:**
- [ ] SKIP vs FAIL conditions documented in script header
- [ ] Baseline mode vs full mode expected output documented

---

## Completion Protocol

1. `scripts/smoke-test.sh` exists and is executable
2. Running the script in a live ecosystem produces meaningful PASS/FAIL/SKIP output
3. Script exits 0 when no failures (even if some seams skip)
4. Script exits 1 when any reachable seam fails
5. Dashboard updated

### Final Verification

```bash
bash .handoffs/cross-project/verify-ecosystem-smoke-test.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
