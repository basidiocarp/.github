# Hymenium: Migrate to Post-`0bc2e878` Spore Capability API

## Handoff Metadata

- **Dispatch:** `direct` after the new spore capability API surface is identified
- **Owning repo:** `hymenium`
- **Allowed write scope:** `hymenium/src/dispatch/capability_client.rs` and any tests/fixtures that exercise it; `hymenium/Cargo.toml` (rev bump)
- **Cross-repo edits:** none — spore is upstream and is not modified here
- **Non-goals:** does not redesign the dispatch capability flow; does not refactor unrelated dispatch code; does not change Canopy or other consumers
- **Verification contract:** after the migration, `hymenium/Cargo.toml` should pin `spore` at the workspace rev (currently `0bc2e878010e75e30e26fa517d747e97d59628b0`) and `cargo build && cargo test` must be green
- **Completion update:** Stage 1 + Stage 2 review pass → commit → update `ecosystem-versions.toml`'s `pending` array (drop `hymenium`) and `consumers` array (add it back) → mark handoff done

## Problem

The 2026-04-30 ecosystem drift audit found that `ecosystem-versions.toml` documented spore at rev `a3c7f5bf…` while 8 of 9 consumers pinned `0bc2e878…`. F3.1 chose Option A (bump the doc to match the 8 consumers and update the lone holdout — hymenium).

When the parent agent applied F3.1, hymenium did not compile against the new rev:

```
error[E0432]: unresolved import `spore::capability`
  --> src/dispatch/capability_client.rs:25:12
error[E0425]: cannot find function `capability_registry_path` in module `spore::paths`
error[E0425]: cannot find function `capability_lease_dir` in module `spore::paths`
```

Hymenium's `dispatch/capability_client.rs` uses three spore APIs that were removed (or renamed) between revs `a3c7f5bf` and `0bc2e878`:

- `spore::capability` (entire module)
- `spore::paths::capability_registry_path()`
- `spore::paths::capability_lease_dir()`

Hymenium was therefore held at the older rev (`a3c7f5bf`) and listed under `[spore].pending` in `ecosystem-versions.toml`. This handoff finishes the F3.1 alignment by updating hymenium for the new spore API.

## Step 1 — Identify the new spore capability surface

Read spore at the current workspace rev (`0bc2e878010e75e30e26fa517d747e97d59628b0`):

```bash
cd /Users/williamnewton/projects/personal/basidiocarp/spore
git log --oneline a3c7f5bf..0bc2e878 -- src/capability.rs src/paths.rs 2>/dev/null
git show 0bc2e878 -- src/capability.rs src/paths.rs 2>/dev/null | head -40
ls src/capability* 2>/dev/null
grep -rn 'capability_registry_path\|capability_lease_dir' src/ 2>/dev/null
```

Determine:
1. Whether `spore::capability` was renamed (e.g. to `spore::capabilities` or moved into another module).
2. What replaced `capability_registry_path` and `capability_lease_dir` — these are likely surfaced through a new builder, registry handle, or `LocalServiceClient`-style API.

If the audit shows the capability surface was deliberately removed without a replacement, escalate the handoff to a design question (does hymenium still need this functionality, or can it use a different spore primitive?). Don't guess; read the spore code.

## Step 2 — Migrate `capability_client.rs`

Rewrite the imports and call sites against the new spore API. Keep the public function signatures of `capability_client.rs` unchanged so hymenium's other modules don't have to change. The migration should be local to this one file.

If the new spore API requires a different shape (e.g. async vs sync, different return types), thread it through the minimum surrounding code — do not refactor adjacent modules.

## Step 3 — Bump the spore pin

In `hymenium/Cargo.toml`, change:

```toml
spore = { git = "...", rev = "a3c7f5bf8f4025b7a507f44d68a338244ad2d6e4" }
```

to match the workspace pin:

```toml
spore = { git = "...", rev = "0bc2e878010e75e30e26fa517d747e97d59628b0" }
```

(Verify against `ecosystem-versions.toml` `[spore].rev` at the time of dispatch — if the workspace has bumped further, use the current pin.)

## Step 4 — Tests

Add or update tests covering the migrated `capability_client.rs` paths. The existing test suite should already exercise `dispatch_request-v1` flows; ensure they still pass end-to-end.

```bash
cd hymenium && cargo build --release && cargo test --release && cargo clippy
```

## Step 5 — Update `ecosystem-versions.toml`

Once hymenium is on the new rev:

- Remove `hymenium` from `[spore].pending`
- Add it back into `[spore].consumers`
- Remove the explanatory note from the `note =` field (or shorten it now that the exception is closed)

## Verify Script

`bash .handoffs/hymenium/verify-spore-capability-api-migration.sh` (TBD; pattern after the existing per-handoff verify scripts):
- Hymenium Cargo.toml spore rev matches `ecosystem-versions.toml` workspace pin
- `cargo build --release` and `cargo test --release` pass
- No unresolved imports of `spore::capability` or removed path helpers
- `ecosystem-versions.toml` no longer lists hymenium in `pending`

## Context

Closes the deferred portion of F3.1 from the 2026-04-30 ecosystem drift follow-up audit. Pairs with the workspace-side commit that bumped the `[spore].rev` doc to `0bc2e878` and listed hymenium as the lone exception.

## Style Notes

- Don't redesign the capability flow. The new spore API is the constraint; map hymenium's existing usage to it as directly as possible.
- If the new spore API truly removed functionality without replacement, surface that as a finding before writing migration code; the answer might be to move the logic to canopy or remove it entirely.
- Preserve the public function signatures of `capability_client.rs` so callers in `dispatch/orchestrate.rs` don't need to change.
