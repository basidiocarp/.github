# Stipe: Install Hooks And Secret Safety

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `stipe`
- **Allowed write scope:** `stipe/src/lockfile.rs`, `stipe/src/backup.rs`, `stipe/src/commands/install/`, `stipe/src/commands/package_repair.rs`, `stipe/src/commands/provider.rs`, `stipe/src/commands/claude_hooks.rs`, `stipe/src/commands/doctor/`, `stipe/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no Lamella hook bundle redesign and no Volva auth backend implementation
- **Verification contract:** run the repo-local commands below and `bash .handoffs/stipe/verify-install-hooks-and-secret-safety.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `stipe`
- **Likely files/modules:** lockfile, install runner, package repair, Hyphae backup integration, provider setup, Claude hook registration
- **Reference seams:** release install timeout helper, existing provider and claude_hooks tests, Hyphae backup CLI
- **Spawn gate:** do not launch an implementer until the parent agent inspects the dirty Stipe worktree and decides whether provider setup should ever write repo-local `.env` files

## Problem

Stipe has several runtime safety gaps in install/control-plane paths: lock acquisition is non-atomic, install/repair subprocesses can hang without deadlines, Hyphae pre-upgrade backup copies a WAL-mode DB directly, provider setup can persist API keys into the current repo `.env` or shell profile in plaintext, and generated Claude hook settings omit file-write GateGuard coverage while using shorter teardown timeouts than Lamella.

## What needs doing

1. Make lock acquisition atomic with `create_new` and release only the lock owned by the current process/token.
2. Reuse bounded subprocess execution for install runner and package repair paths.
3. Use a WAL-safe Hyphae backup path rather than copying `hyphae.db` directly.
4. Make plaintext API key persistence explicit opt-in, permission-restricted, and protected from accidental repo commits.
5. Reject unsafe API key values or render shell-profile exports with safe quoting so command substitution, backticks, whitespace, quotes, and semicolons cannot execute when a profile is sourced.
6. Align Stipe-generated hook matchers/timeouts/session-end behavior with the intended Cortina/Lamella policy.

## Verification

```bash
cd stipe && cargo test lockfile
cd stipe && cargo test install package_repair
cd stipe && cargo test backup
cd stipe && cargo test provider claude_hooks
bash .handoffs/stipe/verify-install-hooks-and-secret-safety.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] install/update lock acquisition is atomic and owner-scoped
- [ ] install and repair subprocesses have deadlines and cleanup
- [ ] Hyphae backup through Stipe is WAL-safe
- [ ] provider setup does not silently write API keys into repo `.env`
- [ ] shell-profile API key exports cannot execute metacharacters from a pasted value
- [ ] generated hooks match the intended PreToolUse/Stop/SessionEnd policy
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit. Severity: high/medium.
