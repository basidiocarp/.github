# Lifecycle Integration Test

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** only the repos explicitly named in this handoff
- **Cross-repo edits:** allowed when this handoff names the touched repos explicitly
- **Non-goals:** unplanned umbrella decomposition or opportunistic adjacent repo edits
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

No test exercises the full signal chain end-to-end. `test-lifecycle.sh` doesn't
exist. Cross-tool breaks are invisible until they surface in production — a
cortina schema change, a hyphae session bridge update, or a canopy evidence ref
format change can silently break the pipeline without any automated signal.

## What exists (state)

- **Per-repo unit tests**: each project has its own `cargo test` suite covering
  its internals; no cross-repo integration tests exist
- **`scripts/test-integration.sh`**: referenced in CLAUDE.md for contract changes
  but doesn't exist yet
- **Septa contracts**: shared schemas at `septa/` with fixture validation; septa
  tests validate schema but not the live signal pipeline
- **Signal pipeline**: cortina → hyphae → canopy → cap; each hop is untested
  end-to-end

## What needs doing (intent)

Create `scripts/test-lifecycle.sh` that exercises the full signal chain with real
binaries. The test is not a unit test — it runs real commands against real tool
binaries and checks that signals flow through correctly.

---

### Step 1: Scaffold test-lifecycle.sh with dependency checks

**Project:** `basidiocarp/` (workspace root scripts)
**Effort:** 2–4 hours
**Depends on:** nothing

Create `scripts/test-lifecycle.sh`. Start with dependency checks and clear failure
messages:

```bash
#!/usr/bin/env bash
set -euo pipefail

RESULTS=()
PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "$cmd" > /tmp/lc-check.out 2>&1; then
    RESULTS+=("PASS: $name")
    ((PASS++))
  else
    RESULTS+=("FAIL: $name")
    cat /tmp/lc-check.out
    ((FAIL++))
  fi
}

# Dependency checks
check "hyphae binary" "command -v hyphae"
check "cortina binary" "command -v cortina"
check "canopy binary" "command -v canopy"

# ... signal chain checks (Step 2)

echo ""
for r in "${RESULTS[@]}"; do echo "$r"; done
echo ""
echo "Results: $PASS passed, $FAIL failed"
exit $FAIL
```

#### Verification

```bash
bash scripts/test-lifecycle.sh 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `test-lifecycle.sh` is executable
- [ ] Dependency checks print clear PASS/FAIL per binary
- [ ] Script exits non-zero when any check fails
- [ ] Script exits 0 when all checks pass

---

### Step 2: Add signal chain integration checks

**Project:** `basidiocarp/`
**Effort:** 1 day
**Depends on:** Step 1

Add checks that exercise the signal chain:

1. **Hyphae session lifecycle**:
   ```bash
   check "hyphae session start" "hyphae session start --project test-lc"
   check "hyphae memory store" "hyphae memory store --topic 'test/lc' --content 'lifecycle test' --importance low"
   check "hyphae memory recall" "hyphae memory recall 'lifecycle test' | grep -q lifecycle"
   check "hyphae session end" "hyphae session end"
   ```

2. **Cortina signal capture** (simulated via cortina adapter):
   ```bash
   check "cortina status" "cortina status"
   check "cortina doctor" "cortina doctor"
   ```

3. **Canopy task lifecycle** (when canopy available):
   ```bash
   check "canopy snapshot" "canopy snapshot"
   check "canopy task create" "canopy task create --title 'LC test task' --output-id"
   # capture ID, then complete and verify
   ```

4. **Cross-tool: cortina → hyphae session bridge**:
   Simulate a PostToolUse event and verify that hyphae session context reflects it.

#### Verification

```bash
bash scripts/test-lifecycle.sh 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Hyphae session start/store/recall/end pass
- [ ] Cortina status and doctor pass
- [ ] Canopy snapshot passes (or gracefully skipped if not running)
- [ ] Cross-tool session bridge check passes
- [ ] Final output shows "Results: N passed, 0 failed"

---

### Step 3: Add septa contract validation to lifecycle test

**Project:** `basidiocarp/`
**Effort:** 2–4 hours
**Depends on:** Step 2

Add checks that validate live tool output against septa contracts:

```bash
check "canopy snapshot schema_version" "canopy snapshot | python3 -c \"
import sys, json
d = json.load(sys.stdin)
assert d.get('schema_version') == '1.0', f'Bad schema_version: {d.get(\"schema_version\")}'
\""

check "hyphae session context format" "hyphae session context --format json | python3 -m json.tool > /dev/null"
```

Wire `scripts/test-lifecycle.sh` as the `test-integration.sh` mentioned in CLAUDE.md:

```bash
ln -sf scripts/test-lifecycle.sh scripts/test-integration.sh
```

#### Verification

```bash
bash scripts/test-lifecycle.sh 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Canopy snapshot `schema_version: "1.0"` validated
- [ ] Hyphae session context JSON validates against schema
- [ ] `test-integration.sh` symlink created
- [ ] All checks pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. `bash scripts/test-lifecycle.sh` exits 0 with all tools installed
3. The script reports "Results: N passed, 0 failed"
4. All checklist items are checked

### Final Verification

```bash
bash /Users/williamnewton/projects/basidiocarp/scripts/test-lifecycle.sh 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsGap #16 in `docs/workspace/ECOSYSTEM-REVIEW.md`. The cross-tool contract is
tested at the schema level via septa but never exercised as a live signal chain.
This script is the `test-integration.sh` referenced in CLAUDE.md under
"Communication Contracts" — run it when a change crosses a project boundary. The
test should be runnable without a full development environment; tools that aren't
installed should produce graceful SKIP not FAIL.
