# Version Pin Drift Audit Template

Validates that each repo's `Cargo.toml` (and `package.json` where applicable) matches the workspace pins documented in `ecosystem-versions.toml`. Mechanical, scriptable, runs fast.

**Cadence:** monthly during active hardening; before each release.
**Maps to:** operational hygiene that supports F1 exit criterion #2 (shared crates' ABIs stay aligned across repos).
**Runtime:** ~30 minutes for the whole ecosystem.

---

## Handoff Metadata (instance)

- **Dispatch:** `direct`
- **Owning repo:** workspace root (read-only)
- **Allowed write scope:** `.handoffs/campaigns/<campaign-name>/findings/lane<N>-version-pin-drift.md`
- **Cross-repo edits:** none — read-only audit
- **Non-goals:** does not bump any pin; does not modify `ecosystem-versions.toml` or any `Cargo.toml`/`package.json`

## Method

```bash
# 1. Read workspace pins
cat ecosystem-versions.toml

# 2. For each shared key, grep across the consuming repos
for dep in spore tokio anyhow thiserror serde rusqlite which clap; do
  echo "=== $dep ==="
  grep -nE "^${dep}\s*=" \
    cortina/Cargo.toml hyphae/Cargo.toml hymenium/Cargo.toml \
    mycelium/Cargo.toml rhizome/Cargo.toml stipe/Cargo.toml \
    volva/Cargo.toml canopy/Cargo.toml annulus/Cargo.toml \
    spore/Cargo.toml \
    2>/dev/null
done

# 3. Check workspace member crates too (e.g. hyphae/crates/*/Cargo.toml,
#    volva/crates/volva-*/Cargo.toml). They often pin shared deps separately.
fd Cargo.toml --type f --exclude target | xargs grep -lE 'spore\s*=' 2>/dev/null
```

For each shared dep:
- Flag exact-version mismatches with the workspace pin (`blocker` for shared-types crates like spore; `concern` otherwise).
- Flag version ranges (`>=`, `~`) that include the pin but invite drift (`concern`).
- Flag deps used by a consumer but not pinned in `ecosystem-versions.toml` (`concern` — undocumented dependency).
- A path-dep within the same repo (`{ path = "..." }`) is correct — never flag it.

For git-rev pins (e.g. `spore = { git = "...", rev = "..." }`), compare the rev across consumers AND against the workspace pin. Drift in rev is the same as drift in version.

## Findings File Format

Write `findings/lane<N>-version-pin-drift.md`:

```markdown
# Lane N: Shared Version Pin Drift Findings (YYYY-MM-DD)

## Summary
[counts by severity]

## Workspace-Pinned Versions
[table from ecosystem-versions.toml]

## Per-Repo Comparison
| Repo | Dependency | Declared | Workspace Pin | Verdict |
|------|------------|----------|---------------|---------|
| ... | ... | ... | ... | match / drift / range |

## Findings

### [F#.M] Title — severity: blocker|concern|nit
- **Repo:** ...
- **Dependency:** ...
- **Declared:** ...
- **Workspace pin:** ...
- **Why it matters:** [shared ABI drift / undocumented dep / etc.]
- **Proposed handoff:** "[handoff title]"

## Clean Areas
[deps that align across all consumers]
```

## Severity Calibration

| Severity | When |
|----------|------|
| `blocker` | Exact mismatch with workspace pin for a shared-types crate (spore in particular); rev mismatch across consumers for a git-rev'd shared dep. |
| `concern` | Version range that includes the pin but invites drift; consumer uses a dep not documented in `ecosystem-versions.toml`; pin file out of sync with reality. |
| `nit` | Tighter pin than doc (e.g. `1.1` vs workspace `1`); deprecated version that still works. |

## Verify Script

Pair with `verify-lane<N>-version-pin-drift.sh`. Confirms:
- Findings file exists with the 5 required sections (Summary, Workspace-Pinned Versions, Per-Repo Comparison, Findings, Clean Areas)
- `ecosystem-versions.toml` is referenced in the findings
- Per-Repo Comparison table has rows
- No `Cargo.toml` modified by the audit (scope discipline)

## Style Notes

- Use the actual files, not `cargo metadata` — the audit is about **declared** pins, not resolved ones.
- Workspace member crates (e.g. `hyphae/crates/*/Cargo.toml`) count as separate consumers; check them too.
- Don't propose a single sweeping fix. Each drift is its own follow-up handoff.
- The pin file becomes "source of truth" only if everyone agrees with it — if reality has diverged, that's a finding about the doc, not just the consumers.
