# Audit Lane 2: Septa Contract Accuracy

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only across `septa/` and all consumers)
- **Allowed write scope:** `.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-septa-contract-accuracy.md`
- **Cross-repo edits:** none (read-only audit)
- **Non-goals:** does not fix schema drift, does not modify schemas, does not regenerate fixtures
- **Verification contract:** run the repo-local commands below and `bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane2-septa-contract-accuracy.sh`
- **Completion update:** once findings file is written and verification is green, update `.handoffs/HANDOFFS.md` campaigns row to reflect lane 2 complete

## Implementation Seam

- **Likely repo:** `septa/` for schemas; consumers across `cap/server/`, `cortina/`, `hyphae/`, `mycelium/`, `volva/`, etc.
- **Likely files/modules:**
  - `septa/*.schema.json` (schema files)
  - `septa/fixtures/` (golden fixtures)
  - `septa/validate-all.sh` (validator entry point)
  - `septa/integration-patterns.md` (consumer/producer mapping)
  - Cap consumers: `cap/server/canopy.ts`, `cap/server/lib/canopy-validators.ts`, `cap/server/mycelium/`, `cap/server/routes/settings/shared.ts`, `cap/server/db.ts`
  - Other consumers: `cortina/src/utils/hyphae_client.rs`, `volva/`, `hymenium/src/`
- **Reference seams:** the recently-closed A12 (`script_verification` evidence kind) is a recent example of how a contract change fans out to consumers — use that pattern in reverse to find drift
- **Spawn gate:** the audit is read-only and the seam is well-known — proceed directly

## Problem

Septa has 59 schemas and several producer/consumer pairs spread across repos. After A12 added `script_verification` to the evidence kind set and several recent migrations (canopy stale cache, annulus discovery), no one has re-verified that:

1. Every consumer parses every field a producer emits
2. Every fixture in `septa/fixtures/` still represents the current schema (no orphan fields, no missing required fields)
3. Every schema documented in `septa/integration-patterns.md` still has both a producer and a consumer
4. `septa/validate-all.sh` covers every schema (no untested ones)

## What exists (state)

- **Schema count:** 59 schemas under `septa/` (per `validate-all.sh` reporting from prior runs)
- **Validator:** `septa/validate-all.sh` — exits 0 with `59/59` schemas valid as of 2026-04-29
- **Recent contract changes:** A12 added `script_verification` to evidence-ref-v1; canopy-snapshot consumers may have new fields
- **Cap consumes 5 contracts:** mycelium-gain-v1, canopy-snapshot-v1, canopy-task-detail-v1, stipe-doctor-v1, stipe-init-plan-v1 (per `cap/CLAUDE.md`)

## What needs doing (intent)

Produce a findings file enumerating:

- Schemas in `septa/` with no live consumer (orphaned producers)
- Consumers parsing fields that aren't in the schema (silent drift in the consumer's favor)
- Required schema fields that consumers fail to read (silent drift in the producer's favor)
- Fixtures that don't match their schema (golden fixture drift)
- Integration-patterns.md rows that don't match the actual producer/consumer mapping
- Schema versioning gaps (e.g. `*-v1` referenced but only `*-v2` shipped)

Each finding gets a severity (`blocker | concern | nit`) and a proposed handoff title.

## Scope

- **Primary seam:** the `septa/` schema layer and the read paths in each consumer
- **Allowed files:** read everything; write only `findings/lane2-septa-contract-accuracy.md`
- **Explicit non-goals:**
  - Fixing any contract drift found (those become new handoffs)
  - Auditing CLI coupling (lane 1 owns that)
  - Triaging Low-priority handoffs (lane 3 owns that)
  - Auditing internal correctness of consumers — only the contract surface matters

---

### Step 1: Run validate-all.sh and capture state

**Project:** `septa/`
**Effort:** small
**Depends on:** nothing

Establish the baseline. If validate-all.sh fails, that's a blocker before audit can continue.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && bash validate-all.sh)
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && ls *.schema.json | wc -l)
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && ls fixtures/ 2>/dev/null | wc -l)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `validate-all.sh` exits 0
- [ ] Schema count and fixture count captured

---

### Step 2: Enumerate consumers per schema

**Project:** workspace root
**Effort:** medium
**Depends on:** Step 1

For each `*.schema.json` in `septa/`, grep the workspace for references to:

- The schema name (e.g. `canopy-snapshot-v1`)
- The schema's top-level type names
- Field names unique to that schema

Build a producer/consumer map. Flag schemas with zero consumers (orphans) and consumers that reference removed schemas.

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && ls *.schema.json | head -20)
(cd /Users/williamnewton/projects/personal/basidiocarp && grep -rn "canopy-snapshot-v1" --include="*.rs" --include="*.ts" -l | head)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Each schema mapped to at least one consumer (or flagged as orphan)
- [ ] Each consumer reference mapped to an existing schema (or flagged as stale)

---

### Step 3: Field-level drift sweep on the 5 Cap-consumed schemas

**Project:** workspace root
**Effort:** medium
**Depends on:** Step 2

Per `cap/CLAUDE.md`, Cap consumes 5 contracts. Open the schema and the matching consumer source, and compare field-by-field:

| Schema | Consumer file |
|--------|---------------|
| `mycelium-gain-v1` | `cap/server/mycelium/` |
| `canopy-snapshot-v1` | `cap/server/canopy.ts` |
| `canopy-task-detail-v1` | `cap/server/canopy.ts` |
| `stipe-doctor-v1` | `cap/server/routes/settings/shared.ts` |
| `stipe-init-plan-v1` | `cap/server/routes/settings/shared.ts` |

Look for:
- Required schema fields the consumer doesn't read
- Optional schema fields the consumer assumes are present
- Consumer-side fields that aren't in the schema
- Type mismatches (string vs number, array vs object)

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && cat canopy-snapshot-v1.schema.json | head -40)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Each of the 5 schemas compared against its consumer
- [ ] All field-level drift recorded

---

### Step 4: Cross-check `septa/integration-patterns.md`

**Project:** workspace root
**Effort:** small
**Depends on:** Step 3

Verify that:
- Every "Producer" listed has an actual emitter in the named repo
- Every "Consumer" listed has an actual reader in the named repo
- Recently-migrated couplings mentioned (the 2026-04-29 batch) are reflected accurately

#### Verification

```bash
(cd /Users/williamnewton/projects/personal/basidiocarp/septa && grep -c "^|" integration-patterns.md)
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Producer/consumer rows each match a real call site
- [ ] No stale rows describing removed integrations

---

### Step 5: Write findings file

**Project:** workspace root
**Effort:** small
**Depends on:** Steps 1-4

Write `findings/lane2-septa-contract-accuracy.md`:

```markdown
# Lane 2: Septa Contract Accuracy Findings (2026-04-29)

## Summary
[1-2 sentences: how many findings, severity breakdown]

## Baseline
[validate-all.sh output, schema count, fixture count]

## Producer/Consumer Map
[table of schema → producer → consumer(s); flag orphans and stale rows]

## Findings

### [F2.1] Title — severity: blocker|concern|nit
- **Schema:** path:line or schema name
- **Consumer:** path:line
- **Drift:** [what's missing or extra]
- **Why it matters:** [F1 criterion 2: validate-all.sh stays green]
- **Proposed handoff:** "[handoff title]"

[repeat per finding]

## Clean Areas
[contracts that came back clean]
```

#### Verification

```bash
test -f /Users/williamnewton/projects/personal/basidiocarp/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-septa-contract-accuracy.md && echo "findings file exists"
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Findings file exists with the five sections
- [ ] Producer/consumer map is concrete (no "TBD" rows)
- [ ] No fixes attempted in this run

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane2-septa-contract-accuracy.sh`
3. All checklist items are checked
4. The campaign README's lane table is updated (lane 2 row marked complete)

### Final Verification

```bash
bash .handoffs/campaigns/post-execution-boundary-audit-2026-04-29/verify-lane2-septa-contract-accuracy.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Septa is the contract layer for the entire ecosystem. F1 exit criterion #2 says `validate-all.sh` must stay green; this lane confirms that's not the only thing that needs to be true.

## Style Notes

- Findings are evidence-only. Do not propose fixes beyond a one-line "Proposed handoff" title.
- A schema with no consumer is `concern`, not `blocker` — it just means the producer is wasting work, not that something is broken.
- A consumer reading a removed field is `blocker` — that's a runtime failure waiting to happen.
