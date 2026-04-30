# Boundary Compliance Audit Template

Validates that the C7 CLI Coupling Classification table in `septa/integration-patterns.md` matches the actual cross-tool spawn call sites in the codebase, and that the C8 system-to-system rule is honored across active hardening repos.

**Cadence:** quarterly, or after any tool-boundary refactor.
**Maps to:** F1 exit criterion #3 ("CLI coupling table is current; no untracked sibling spawns").
**Runtime:** ~1–2 hours.

---

## Handoff Metadata (instance)

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only across active hardening subprojects)
- **Allowed write scope:** `.handoffs/campaigns/<campaign-name>/findings/lane<N>-boundary-compliance.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not migrate or fix any boundary violation; does not modify the C7 table; does not modify any source
- **Verification contract:** `bash .handoffs/campaigns/<campaign-name>/verify-lane<N>-boundary-compliance.sh`

## Method

### Step 1 — Re-run existing C7 + C8 verifiers

```bash
bash .handoffs/cross-project/verify-cli-coupling-exemption-audit.sh
bash .handoffs/cross-project/verify-system-to-system-communication-boundary.sh
```

Both should exit 0. If either fails, **that is the first finding** and must be addressed before proceeding (the audit's foundation has drifted).

### Step 2 — Manual cross-repo sibling-spawn sweep

For each active hardening repo (cortina, hyphae, hymenium, mycelium, rhizome, septa, spore, stipe), grep for spawn primitives:

```bash
# Rust
grep -rnE 'Command::new|tokio::process::Command::new' <repo>/src --include='*.rs' | \
  grep -v 'clap::Command'
# TypeScript
grep -rnE 'spawn|child_process' <repo>/server --include='*.ts'
```

For each hit, classify against C7's existing rules:
- **system-to-system** (must migrate to typed endpoints)
- **hook-time exception** (CLI allowed at hook-time to avoid circular deps)
- **operator surface** (CLI allowed for operator-brokered actions; cap is the canonical example)
- **temporary compatibility** (CLI allowed during a documented migration window)

Flag any hit that:
- Doesn't appear in the C7 table — `concern` (unenumerated coupling).
- Appears in the table but the row's command/file/classification is stale — `concern` (table drift).
- Looks like a system-to-system call dressed as an operator surface — `blocker` (C8 violation).

### Step 3 — Cap operator-surface scope check

Cap is exempt under the operator-surface rule, but only when the call is read-only or operator-brokered. Sweep `cap/server/**/*.ts` for any silent system-to-system writes that should go through endpoints. Flag `blocker` if found.

### Step 4 — Documentation cross-check

Verify the three docs that codify the boundary rule still agree:
- `AGENTS.md` (workspace root)
- `septa/integration-patterns.md`
- `docs/foundations/core-hardening-freeze-roadmap.md`

Any disagreement is `nit` (doc drift) unless it changes a rule (then `concern`).

## Findings File Format

Write `findings/lane<N>-boundary-compliance.md`:

```markdown
# Lane N: Boundary Compliance Findings (YYYY-MM-DD)

## Summary
[counts by severity]

## Baseline
[C7 + C8 verifier outputs]

## Findings

### [F#.M] Title — severity: blocker|concern|nit
- **Location:** path:line
- **Evidence:** [what was found]
- **Why it matters:** [link to C7 / C8 / F1 #3 criterion]
- **Proposed handoff:** "[handoff title]"

## Clean Areas
[checks that came back clean]
```

## Severity Calibration

- `blocker` — C8 violation (system-to-system call via CLI without an endpoint migration plan); cap surface doing silent writes outside the operator-broker pattern.
- `concern` — unenumerated CLI call site; stale C7 row; row's command/classification understates the actual coupling.
- `nit` — doc drift between AGENTS.md, integration-patterns.md, freeze roadmap.

## Verify Script

Pair with `verify-lane<N>-boundary-compliance.sh`. Confirms:
- Findings file exists with the 4 required sections
- Existing C7 verifier still exits 0
- Existing C8 verifier still exits 0
- Findings file has at least the `### [F` finding-row pattern OR an explicit "no findings" note

## Style Notes

- Don't migrate any coupling — this is documentation/classification only.
- Don't add `validate-hooks` style schemas as part of this audit; that's a separate F2.8-pattern handoff.
- For each unclassified hit, attempt classification before flagging. "Doesn't fit" is itself a finding.
- The C7 verifier's KNOWN_SITES array is the enforcement gate — when adding new rows to the C7 table, the verifier's array must also expand.
