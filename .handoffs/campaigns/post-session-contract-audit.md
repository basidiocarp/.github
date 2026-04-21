# Post-Session Contract and Alignment Audit

## Campaign Metadata

- **Type:** Audit
- **Priority:** High — run at the start of the next session before any new implementation work
- **Scope:** Workspace-wide; all repos touched in the 2026-04-21 session
- **Trigger:** Complete this before picking up #89, #112, #23, #20, #32, or any Tier 6 work

---

## Context

The 2026-04-21 session shipped features across hyphae, stipe, canopy, lamella, cortina, cap, and the workspace root. The following changes have cross-tool contract implications that need verification before new work begins:

| Repo | Change | Contract risk |
|------|--------|--------------|
| hyphae | `content_hash` added to `Document` struct + schema migration | Any septa fixture or consumer that serializes `Document` may be stale |
| hyphae | `compute_content_hash` + skip-on-reindex in `tool_ingest_file` | MCP contract for `hyphae_ingest_file` response shape changed (added `skipped`) |
| hyphae | `hyphae bench-retrieval` CLI command added | CLI reference docs updated this session; check nothing else references old bench commands |
| stipe | `stipe init --interactive`, `stipe backup hyphae` added | Stipe CLI surface changed; check any doc/integration that invokes init |
| canopy | Task tree + completion guard | `canopy task complete` now errors on open children — check any automation that calls it |
| lamella | Session-end shim removed; `cortina adapter claude-code session-end` is live hook | Any environment with old lamella + new cortina should reinstall |
| lamella | 6 new commits including 2 new skills + eval harness | Manifests updated; check consumers haven't cached stale manifests |
| cap | TelemetryTab, UsageCostTab, EcosystemTab fully wired | UI routes valid; septa contract for telemetry/usage response shapes |

---

## Audit Steps

### Step 1: Septa contract validation
```bash
cd /Users/williamnewton/projects/basidiocarp
bash septa/validate-all.sh
```
Expected: all schemas validate. If `Document` fixture is stale (missing `content_hash`), update it.

### Step 2: Lifecycle signal chain
```bash
bash scripts/test-lifecycle.sh
```
Expected: 14 passed, 0 failed, 1 skipped (or better). If anything regressed, investigate before proceeding.

### Step 3: Per-repo test health
```bash
cd hyphae && cargo test --workspace 2>&1 | tail -3
cd ../stipe && cargo test 2>&1 | tail -3
cd ../canopy && cargo test --all 2>&1 | tail -3
```
Expected: all pass. Focus on hyphae (Document struct change touched many test helpers).

### Step 4: Hyphae MCP contract surface
```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test -p hyphae-mcp -- contract 2>&1 | tail -10
```
Confirm `tool_ingest_file` contract tests reflect the new `skipped` field in responses.

### Step 5: Ecosystem version pins
```bash
cat /Users/williamnewton/projects/basidiocarp/ecosystem-versions.toml
```
Confirm any shared spore/hyphae version pins are still consistent with the releases cut at end of 2026-04-21 session.

### Step 6: Lamella reinstall check
If working in an environment that had the old `session-end.js` shim:
```bash
cd /Users/williamnewton/projects/basidiocarp/lamella
./lamella install core
make validate
```

---

## Known Issues / Pre-Existing State

- `canopy task create` UUID extraction in `test-lifecycle.sh` produces 1 SKIP — this is expected and pre-existing
- Cortina `CLAUDE.md` is gitignored by design; the cache-friendly assembly section added this session is local-only

---

## Completion

This campaign is complete when all six steps above pass. Archive this file to `.handoffs/archive/campaigns/` and note the date verified.
