# Rhizome: Compile-Info Optimization

## Problem

The audit in [`.audit/workspace/compile-info/rhizome.md`](/Users/williamnewton/projects/basidiocarp/.audit/workspace/compile-info/rhizome.md) found unusually large parser and runtime costs that warranted a dedicated optimization handoff.

## What exists (state)

- niche tree-sitter grammars dominated the binary footprint, especially C#,
  Swift, and Haskell
- `rhizome-cli`, `rhizome-mcp`, and `rhizome-lsp` all used `tokio = { features = ["full"] }`
- repo-local `[profile.dev]` tuning was absent
- `tree-sitter-toml` was declared but not used anywhere in the crate

## What was implemented

- added a tuned repo-local `[profile.dev]` block in
  [rhizome/Cargo.toml](/Users/williamnewton/projects/basidiocarp/rhizome/Cargo.toml)
- narrowed Tokio features in:
  - [rhizome-cli/Cargo.toml](/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-cli/Cargo.toml)
  - [rhizome-mcp/Cargo.toml](/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-mcp/Cargo.toml)
  - [rhizome-lsp/Cargo.toml](/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-lsp/Cargo.toml)
- feature-flagged tree-sitter grammars in
  [rhizome-treesitter/Cargo.toml](/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-treesitter/Cargo.toml)
  with a smaller default set and an opt-in `lang-all` pack
- moved the heaviest niche grammars out of the default tree-sitter build:
  `C#`, `Swift`, and `Haskell` are now LSP-backed by default and only become
  tree-sitter-backed when `rhizome-treesitter/lang-all` is enabled
- removed the unused `tree-sitter-toml` dependency
- updated the shipped docs so the default grammar set and optional grammar pack
  are described consistently

## Status

- `tokio/full` is gone from the workspace graph
- the default tree-sitter grammar set keeps `C++` and `TypeScript` online but
  excludes `C#`, `Swift`, and `Haskell`
- the compile-info fixes are landed and documented

## Completion

This handoff is complete under the current scope.

- the heaviest niche grammars are feature-flagged behind `lang-all`
- the default build ships a smaller tree-sitter set without losing LSP support
- Tokio no longer uses `full` in the Rhizome workspace crates
- repo-local dev profile tuning is present

## Verification targets

- `cd rhizome && cargo build --workspace`
- `cd rhizome && cargo test --workspace`
- `cd rhizome && cargo tree -e features | rg 'tokio feature "full"|tree-sitter-c-sharp|tree-sitter-swift|tree-sitter-haskell|tree-sitter-cpp|tree-sitter-typescript'`
- `bash .handoffs/archive/rhizome/verify-compile-info-optimization.sh`

## Verification Notes

- `cd rhizome && cargo build --workspace`
- `cd rhizome && cargo test --workspace`
- `cd rhizome && cargo tree -e features | rg 'tokio feature "full"|tree-sitter-c-sharp|tree-sitter-swift|tree-sitter-haskell|tree-sitter-cpp|tree-sitter-typescript'`
- `bash .handoffs/archive/rhizome/verify-compile-info-optimization.sh`

## Output

```text
<!-- PASTE START -->
   Compiling rhizome-treesitter v0.7.7 (/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-treesitter)
   Compiling rhizome-mcp v0.7.7 (/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-mcp)
   Compiling rhizome-cli v0.7.7 (/Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-cli)
    Finished `dev` profile [optimized + debuginfo] target(s) in 3.78s
<!-- PASTE END -->
```

```text
<!-- PASTE START -->
test result: ok. 19 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.17s
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 1.14s
test result: ok. 97 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.14s
test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
test result: ok. 19 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
test result: ok. 0 passed; 0 failed; 2 ignored; 0 measured; 0 filtered out; finished in 0.00s
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.04s
test result: ok. 25 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s
test result: ok. 53 passed; 0 failed; 1 ignored; 0 measured; 0 filtered out; finished in 0.08s
test result: ok. 40 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.08s
test result: ok. 3 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s
<!-- PASTE END -->
```

```text
<!-- PASTE START -->
│           │   ├── tree-sitter-cpp feature "default"
│           │   │   └── tree-sitter-cpp v0.23.4
│           │   ├── tree-sitter-typescript feature "default"
│           │   │   └── tree-sitter-typescript v0.23.2
<!-- PASTE END -->
```

## Checklist

- [x] the heaviest niche grammars are feature-flagged behind `lang-all`
- [x] `C#`, `Swift`, and `Haskell` are no longer tree-sitter-backed in the default build
- [x] `tokio/full` is removed from the Rhizome workspace crates
- [x] repo-local `[profile.dev]` tuning is present
- [x] the default grammar set is documented in repo docs
- [x] the verification output is pasted into this handoff
