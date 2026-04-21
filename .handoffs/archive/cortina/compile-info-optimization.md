# Cortina: Compile-Info Optimization

## Completed

- `cortina` now links SQLite from the system on non-Windows targets and keeps
  the bundled SQLite fallback only on Windows.
- The command classifier is regex-free now; `command_signals.rs` uses simple
  token and phrase matching instead of a direct `regex` dependency.
- `spore` logging remains shared and intentional. There is no local
  `spore`-logging split to wire up in `cortina`.
- There is no `modern_sqlite` feature in `cortina`; the SQLite work here is
  just the target-scoped bundling split above.

## Verification

- `cd cortina && cargo build`
  - `Finished \`dev\` profile [unoptimized + debuginfo] target(s) in 18.31s`
- `cd cortina && cargo test non_zero_exit`
  - `test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 153 filtered out; finished in 5.04s`
- `cd cortina && cargo test is_significant_command`
  - `test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 154 filtered out; finished in 0.00s`
- `cd cortina && cargo tree -p cortina | rg -n 'regex|rusqlite|tracing-subscriber'`
  - showed `rusqlite v0.39.0`
  - showed `tracing-subscriber v0.3.23`
  - showed only `regex-automata` via `spore`; there is no direct `regex v...` line

## Notes

- The original audit concern about bundled SQLite was addressed by making the
  bundled build path target-specific instead of universal.
- The original regex-stack concern was addressed by removing the direct `regex`
  crate from `cortina` and keeping the classifier logic local and lightweight.
- The remaining `regex-automata` dependency comes from `spore` via
  `tracing-subscriber` and is intentionally left in place.
- The full `cargo test` suite still has a flaky session-state test unrelated
  to this compile-info pass, so the targeted checks above are the completion
  gate for this handoff.

This handoff is complete under the current scope.
