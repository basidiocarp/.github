# Seam-Pass Checklist

Run this during every seam-finding pass, before checking the dispatch gate. Each item is a recurring review finding promoted out of an individual handoff — skipping the checklist means re-paying for a lesson already learned. Mark each item checked or `n/a` in the handoff's checklist gate.

This file is the **durable sink** for recurring findings (Delegation Contract → recurring-finding feedback). When Stage 1 or Stage 2 surfaces a finding that repeats a class seen in a prior handoff, add it here (and capture it with `hyphae extract-lessons`) instead of leaving it in one handoff's Residual Work.

## Platform / CI matrix

- [ ] **Enumerate the repo's CI OS matrix** in the handoff metadata before writing invariants. A change green on macOS can red on Linux (case-sensitivity) or Windows (paths, env). _(annulus #111, lamella #99)_
- [ ] **Windows-touching code:** `dirs::home_dir()` ignores `$HOME` on Windows, so HOME-override test harnesses are unix-only — gate them `#[cfg(unix)]`. Verify `cfg(windows)` code actually compiles: `touch` the file, then `cargo check --target x86_64-pc-windows-gnu`. `OpenProcess` failure is `NULL`, not `INVALID_HANDLE_VALUE`. _(annulus #111, hymenium windows-lock)_
- [ ] **Case-sensitivity audits** use `git ls-files` (the index is case-sensitive), never `fs.existsSync` (lies on macOS/Windows). _(lamella #99)_

## Rust verification

- [ ] **Four-pack, each standalone:** `cargo build`, `cargo test`, `cargo clippy --all-targets`, `cargo fmt --check`. Run clippy **un-chained** — `&&`-chained clippy through mycelium can report a false exit code; only a standalone run gives a true exit. `fmt --check` is a separate CI gate from clippy; don't infer one from the other. _(mycelium clippy argv, stipe fmt gate)_
- [ ] **Env-var tests:** locks serializing env mutation must be **crate-wide** (`#[cfg(test)] pub(crate)` static), not per-module — per-module locks don't compose and race across modules. Make them poison-tolerant. _(stipe BACKUP_DIR)_

## Exhaustiveness / blast radius

- [ ] **New enum or clap variant:** audit **every wildcard-free `match`** on that type across the crate — the compiler errors are the map; list the sites in the seam table. A new `Commands` variant typically also needs a `mod.rs` export. _(hyphae #113: 3 match sites)_
- [ ] **Caller census done** (`find_references` / `get_call_sites` / `analyze_impact`); > 5 callers or any cross-repo caller ⇒ cross-call invariant + callers' tests in verification.

## Packaging / distribution

- [ ] **Prove packaging by filename**, never content-grep: `find dist -name '<artifact>'` — `grep -rl <slug> dist/` false-FAILs, and dist-placement is what proves manifest registration. A skill passing `make validate` can still ship in **no** plugin (forward-only validator); grep `dist/` to prove it landed. _(lamella #76, unregistered-skill trap)_

## Borrow handoffs (idea imported from an external/source repo)

- [ ] **Target-surface existence:** the construct the borrow names must exist in the **target** repo, not just the source. Verify the seam in the target before freezing the plan. _(septa borrows mis-homed)_
- [ ] **Emitted instance vs generator:** if the borrow targets a generated or gitignored artifact (e.g. a settings.json), the real seam is the **generator** that emits it, not the emitted file. _(wave1 L2 #83)_
- [ ] **Compiled-pin ancestor check:** a borrowed symbol must be an ancestor of the consumer's **pinned** rev, not merely present in the source repo's HEAD: `git merge-base --is-ancestor <symbol-commit> <pinned-rev>`. _(pre-dispatch pin check)_

## Cross-tool contracts (§septa)

- [ ] **Consumer-reachability 3-point gate** (schema validation is not consumer proof): (1) the producer command/method exists and is invoked the way the consumer calls it — run the **real CLI/socket call against the built binary**; (2) the consumer's parse struct matches the **real emitted JSON** (flat vs nested, exact field names, transport); (3) at least one **real-JSON round-trip integration test** exists — an all-mock suite hides command-name and shape drift. Confirm the intended transport (socket/HTTP, not ad-hoc CLI shell-outs). _(tasks #58/#60/#52 — recurred three times)_

---

> Adding an item: one bullet, imperative, with the failure it prevents and the originating lane(s) in parentheses. Keep it scannable — if a class needs more than ~3 lines, link out to a memory or doc instead.
