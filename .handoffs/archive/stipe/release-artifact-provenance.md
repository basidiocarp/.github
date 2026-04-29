# Stipe: Release Artifact Provenance

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/commands/install/release.rs`, `stipe/src/commands/install/runner.rs`, `stipe/src/commands/self_update.rs`, `stipe/src/commands/tool_registry/`, `stipe/tests/`, `stipe/.github/workflows/release.yml`
- **Cross-repo edits:** none
- **Non-goals:** no package registry migration and no installer UI redesign
- **Verification contract:** run the commands below and `bash .handoffs/stipe/verify-release-artifact-provenance.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** GitHub release download client, install runner extraction, self-update, release workflow
- **Reference seams:** existing release install tests, generated `SHA256SUMS`, tool registry release archive metadata
- **Spawn gate:** do not launch an implementer until the parent agent decides whether checksum files are sufficient or release assets must also use GitHub artifact attestations/signatures

## Problem

Stipe installs and self-updates release binaries by downloading release asset bytes and running `--version` as verification. It does not verify `SHA256SUMS`, signatures, provenance, or exact expected version before replacing executables. Release downloads also allow unbounded archive reads and extract into predictable temp paths.

## What needs doing

1. Download and verify release archive SHA-256 before extraction.
2. Require the extracted binary `--version` to match the expected release tag/version.
3. Add signed checksums or GitHub artifact attestations if the release process supports them.
4. Cap release asset size and stream downloads to a secure temp file/tempdir.
5. Use unique secure temp extraction directories and clean them reliably.
6. Add mismatch tests for missing checksum, bad checksum, oversized asset, and version mismatch.

## Verification

```bash
cd stipe && cargo test install self_update
cd stipe && cargo test install::release
bash .handoffs/stipe/verify-release-artifact-provenance.sh
```

**Output:**
<!-- PASTE START -->
Results: 3 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] release archives are digest-verified before extraction
- [x] extracted binary version must match expected version
- [x] self-update uses the same provenance checks as install
- [x] oversized assets are rejected before unbounded reads
- [x] extraction uses secure unique temp directories
- [x] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 6 dependency and supply-chain audit. Severity: high/medium.
