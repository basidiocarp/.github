# Cross-Project: Release Smoke Tests

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple` (canopy, stipe, hymenium, cortina, annulus, volva — one release.yml per repo)
- **Allowed write scope:** `<repo>/.github/workflows/release.yml` in each of the six repos above
- **Cross-repo edits:** each repo's release.yml is edited independently; no shared files touched
- **Non-goals:** does not add runtime integration tests, does not add MCP smoke tests (rhizome/hyphae already have those and they require tree-sitter/sqlite setup that varies per binary), does not change CI or coverage workflows
- **Verification contract:** run `bash .handoffs/cross-project/verify-release-smoke-tests.sh` — checks that each release.yml contains a Smoke step with `--version` and a L1 command, and that no step is missing the cross-skip guard
- **Completion update:** once verify is green, update `.handoffs/HANDOFFS.md` and archive this handoff

## Implementation Seam

- **Likely repos:** canopy, stipe, hymenium, cortina, annulus, volva
- **Likely files:** `.github/workflows/release.yml` in each repo (one file per repo, ~3 lines added)
- **Reference seam:** `rhizome/.github/workflows/release.yml` — the `Smoke test` step starting after the `Build` step is the authoritative pattern; copy and adapt it for each binary
- **Spawn gate:** do not launch an implementer until they have read rhizome's release.yml Smoke step and the target release.yml Build/Package step sequence, and can name the binary path expression and the L1 command for that repo

## Problem

Six binary repos — canopy, stipe, hymenium, cortina, annulus, volva — have release workflows
that build multi-platform binaries but never run the resulting binary before packaging it.
A broken binary (linker error, missing symbol, bad build config) would be uploaded to the
GitHub release undetected. Rhizome and hyphae already prove this is fixable with a
`Smoke test` step that takes ~2s per native target.

## What exists

- **rhizome/release.yml**: authoritative pattern — `Smoke test` step runs after `Build`,
  sets `BINARY=target/${{ matrix.target }}/release/rhizome`, runs L0 (`--version`),
  L1 (symbols command), L2 (MCP initialize). Gated on `matrix.cross != 'true'` so
  cross-compiled targets (aarch64-linux) are skipped since the runner can't execute them.
- **hyphae/release.yml**: similar pattern embedded in a `build_variant` shell function —
  runs `--version` and MCP initialize per feature variant.
- **mycelium/release.yml**: no dedicated Smoke step; binary is never exercised before upload.
- **canopy, stipe, hymenium, cortina, annulus, volva/release.yml**: no Smoke step.

## What needs doing

Add a `Smoke test` step to each of the six release.yml files. The step must:

1. **Run after `Build`, before `Package (unix)`** — catches a broken binary before it is tarred.
2. **Skip cross-compiled targets** — gate with `if: matrix.cross != 'true'` (cross targets
   can't execute on the build runner).
3. **Set `BINARY`** from `target/${{ matrix.target }}/release/<binary-name>`.
4. **Run L0**: `"$BINARY" --version` — prints version, proves the binary starts.
5. **Run L1**: a safe read-only command (see per-repo table below). Must not require a running
   service, write to disk, or block waiting for input.
6. **Use `shell: bash`** and `set -euo pipefail`.

### Per-repo smoke commands

| Repo | Binary | L0 | L1 |
|------|--------|----|----|
| canopy | `canopy` | `canopy --version` | `canopy list` (lists tasks; exits 0 with empty list) |
| stipe | `stipe` | `stipe --version` | `stipe status` (prints install status; exits 0) |
| hymenium | `hymenium` | `hymenium --version` | `hymenium --help` (exits 0; no DB required) |
| cortina | `cortina` | `cortina --version` | `cortina --help` (exits 0; no hook context needed) |
| annulus | `annulus` | `annulus --version` | `annulus status --json` (exits 0; prints JSON stub) |
| volva | `volva` | `volva --version` | `volva --help` (exits 0) |

### Step template (adapt binary name and L1 per repo)

```yaml
      - name: Smoke test
        if: matrix.cross != 'true'
        run: |
          set -euo pipefail
          BINARY=target/${{ matrix.target }}/release/<binary-name>
          echo "--- L0: version ---"
          "$BINARY" --version
          echo "--- L1: <command description> ---"
          "$BINARY" <l1-command>
        shell: bash
```

Insert this step immediately after the `Build` step and before `Package (unix)`.

## Scope

- **Primary seam:** `.github/workflows/release.yml` in each of the six repos
- **Allowed files:** `.github/workflows/release.yml` only — no Cargo.toml, no source changes
- **One PR per repo** — each is a 1–3 line addition; commit directly to main (no branch needed for this size)

## Verification

After editing all six files, run the verify script. It checks:

1. Each release.yml contains a step named `Smoke test`
2. Each Smoke step contains `--version`
3. Each Smoke step has the cross-skip guard (`matrix.cross != 'true'`)
4. Each Smoke step uses `set -euo pipefail`
5. Each Smoke step runs a L1 command beyond `--version`

The verify script does **not** build or run the binaries — that happens in CI on the next tag push.

## Context

Identified during the 2026-04-28 CI pipeline audit. Rhizome and hyphae proved the pattern
works and catches broken release builds before they reach users. The pattern is a 3-minute
addition per repo with no runtime dependencies.
