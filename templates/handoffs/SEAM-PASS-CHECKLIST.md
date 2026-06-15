# Seam-Pass Checklist

Run this during every seam-finding pass, before checking the dispatch gate. Each item is a recurring review finding promoted out of an individual handoff — skipping the checklist means re-paying for a lesson already learned. Mark each item checked or `n/a` in the handoff's checklist gate.

This file is the **durable sink** for recurring findings (Delegation Contract → recurring-finding feedback). When Stage 1 or Stage 2 surfaces a finding that repeats a class seen in a prior handoff, add it here (and capture it with `hyphae extract-lessons`) instead of leaving it in one handoff's Residual Work.

## Platform / CI matrix

- [ ] **Enumerate the repo's CI OS matrix** in the handoff metadata before writing invariants. A change green on macOS can red on Linux (case-sensitivity) or Windows (paths, env). _(annulus #111, lamella #99)_
- [ ] **Windows-touching code:** `dirs::home_dir()` ignores `$HOME` on Windows, so HOME-override test harnesses are unix-only — gate them `#[cfg(unix)]`. Verify `cfg(windows)` code actually compiles: `touch` the file, then `cargo check --target x86_64-pc-windows-gnu`. `OpenProcess` failure is `NULL`, not `INVALID_HANDLE_VALUE`. _(annulus #111, hymenium windows-lock)_
- [ ] **Case-sensitivity audits** use `git ls-files` (the index is case-sensitive), never `fs.existsSync` (lies on macOS/Windows). _(lamella #99)_

## Rust verification

- [ ] **Four-pack, each standalone:** `cargo build`, `cargo test`, `cargo clippy --all-targets -- -D warnings`, `cargo fmt --check`. **Match the CI gate exactly: clippy MUST include `-- -D warnings`.** Plain `cargo clippy --all-targets` exits 0 on warnings (incl. `clippy::pedantic` like `too_many_lines`), so it green-lights changes that CI's `-D warnings` reds — and a warning surfaced by a diff is *not* "pre-existing" unless it also fires on clean HEAD (`git stash` and re-run to confirm). Run clippy **un-chained** — `&&`-chained clippy through mycelium can report a false exit code; only a standalone run gives a true exit. `fmt --check` is a separate CI gate from clippy; don't infer one from the other. _(mycelium clippy argv, stipe fmt gate, stipe #132 too_many_lines mislabel)_
- [ ] **Env-var tests:** locks serializing env mutation must be **crate-wide** (`#[cfg(test)] pub(crate)` static), not per-module — per-module locks don't compose and race across modules. Make them poison-tolerant. _(stipe BACKUP_DIR)_

## SQLite

- [ ] **Dynamic `IN (...)` clauses hit `SQLITE_LIMIT_VARIABLE_NUMBER` (default 999).** A `WHERE id IN (?1, …, ?N)` built one-bind-per-value fails at scale with "too many SQL variables". For unbounded id sets, chunk into batches of ≤900 and merge, or use a temp-table JOIN. Grep the crate for an existing temp-table pattern before inventing one — hyphae-store already did this in `prune_concepts`. _(hyphae prune_concepts, hyphae #128 infer_cooccurrence_links)_
- [ ] **Counting over a `json_each` self-join:** `COUNT(*)` counts join rows, which inflate when an array holds duplicate values within a single row. Use `COUNT(DISTINCT <parent-row-id>)` when you mean "distinct parent rows". _(hyphae #128)_

## Exhaustiveness / blast radius

- [ ] **New enum or clap variant:** audit **every wildcard-free `match`** on that type across the crate — the compiler errors are the map; list the sites in the seam table. A new `Commands` variant typically also needs a `mod.rs` export. _(hyphae #113: 3 match sites)_
- [ ] **Caller census done** (`find_references` / `get_call_sites` / `analyze_impact`); > 5 callers or any cross-repo caller ⇒ cross-call invariant + callers' tests in verification.

## Cache / index coherence

- [ ] **Adding a cache or derived side-table over a row keyed by id:** enumerate **every** write path that mutates or deletes that row and invalidate on each — known-id writes `pop(id)`, bulk/unenumerable writes `clear()`. Grep the *whole crate* for writes to the backing table (`rg 'UPDATE|DELETE|INSERT' … <table>`), not just the obvious mutator methods. The path that gets missed is the **inverse/restore operation** — a rollback/un-invalidate/undo arm that reverses a forward op but lives in a different module (e.g. `audit_rollback`'s Invalidate arm reversing `invalidate`). A miss on a delete/un-invalidate path is a **correctness bug** (phantom or stale-state serve), not mere staleness — especially if the read path doesn't itself filter the toggled column (e.g. a `get` with no `invalidated_at IS NULL` filter caches invalidated rows). Lock discipline: never hold the cache lock across a DB call; invalidate **only after the write commits**. _(hyphae #133 audit_rollback Invalidate-arm miss)_

## Packaging / distribution

- [ ] **Prove packaging by filename**, never content-grep: `find dist -name '<artifact>'` — `grep -rl <slug> dist/` false-FAILs, and dist-placement is what proves manifest registration. A skill passing `make validate` can still ship in **no** plugin (forward-only validator); grep `dist/` to prove it landed. _(lamella #76, unregistered-skill trap)_
- [ ] **Two-repo split-push:** when a manifest/registration in repo A names a construct that lives in repo B (e.g. lamella manifest → lamella-skills SKILL.md), pushing A without B reds A's CI — CI clones B **fresh from its remote HEAD**, so a locally-committed-but-unpushed B is invisible. Before signoff: `git -C <B> branch -r --contains <commit>` must show `origin/...` for the construct's commit. _(lamella #129 split-push)_

## CI workflows / generated artifacts

- [ ] **A CI workflow cannot `git push` to a protected `main`** (GH013 / "changes must be made through a pull request"). For a generated artifact that must stay current, use a **drift check** (regenerate in place, `git diff --exit-code`, fail loudly telling the author to regenerate + commit in their PR) — not auto-commit-and-push. Drop `permissions:` to `contents: read`. _(lamella #126 GH013)_
- [ ] **A committed + drift-checked artifact must be byte-reproducible across machines.** Absolute paths (`$HOME` vs `/home/runner/work`), timestamps, `Date.now()`, or unsorted `find`/glob output baked into the file make it drift on every CI run even with no content change. Embed basenames/relative paths only; sort all enumerations. **Verify by regenerating from a *different* absolute path with the same basename and diffing — a local regen from the same path is a false green.** _(lamella #126 content_root absolute path)_

## Borrow handoffs (idea imported from an external/source repo)

- [ ] **Target-surface existence:** the construct the borrow names must exist in the **target** repo, not just the source. Verify the seam in the target before freezing the plan. _(septa borrows mis-homed)_
- [ ] **Emitted instance vs generator:** if the borrow targets a generated or gitignored artifact (e.g. a settings.json), the real seam is the **generator** that emits it, not the emitted file. _(wave1 L2 #83)_
- [ ] **Compiled-pin ancestor check:** a borrowed symbol must be an ancestor of the consumer's **pinned** rev, not merely present in the source repo's HEAD: `git merge-base --is-ancestor <symbol-commit> <pinned-rev>`. _(pre-dispatch pin check)_

## Cross-tool contracts (§septa)

- [ ] **Consumer-reachability 3-point gate** (schema validation is not consumer proof): (1) the producer command/method exists and is invoked the way the consumer calls it — run the **real CLI/socket call against the built binary**; (2) the consumer's parse struct matches the **real emitted JSON** (flat vs nested, exact field names, transport); (3) at least one **real-JSON round-trip integration test** exists — an all-mock suite hides command-name and shape drift. Confirm the intended transport (socket/HTTP, not ad-hoc CLI shell-outs). _(tasks #58/#60/#52 — recurred three times)_

---

> Adding an item: one bullet, imperative, with the failure it prevents and the originating lane(s) in parentheses. Keep it scannable — if a class needs more than ~3 lines, link out to a memory or doc instead.
