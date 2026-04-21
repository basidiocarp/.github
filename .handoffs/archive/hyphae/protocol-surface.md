# Hyphae Memory Protocol Surface

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

The first useful slice is a Hyphae-owned protocol surface. It should be built
before any Volva or Cortina integration.

## What needs doing

Add:

- `hyphae protocol` CLI output
- structured JSON output with `schema_version`
- MCP resource exposure
- project-aware protocol shaping

## Verification

```bash
cd hyphae && cargo build --workspace
cd hyphae && cargo test --workspace
bash .handoffs/archive/hyphae/verify-protocol-surface.sh
```

## Checklist

- [x] `hyphae protocol` exists
- [x] JSON output includes `schema_version: "1.0"`
- [x] protocol is project-aware
- [x] MCP resource exists
- [x] verify script passes with `Results: N passed, 0 failed`

## Verification Evidence

```text
$ cd /Users/williamnewton/projects/basidiocarp/hyphae && cargo build --workspace
Finished `dev` profile [optimized + debuginfo] target(s) in 14.07s
```

```text
$ cd /Users/williamnewton/projects/basidiocarp/hyphae && cargo run --quiet -- protocol --project demo
{
  "schema_version": "1.0",
  "artifact_type": "memory_protocol",
  "scoped_identity": {
    "project": "demo"
  },
  "project": "demo",
  "summary": "Recall selectively at task start, store durable outcomes, and use project-aware Hyphae resources instead of broad memory dumps.",
  "recall": {
    "when": [
      "At task start before broad implementation.",
      "After a context switch or when local repo context is insufficient."
    ],
    "tools": [
      "hyphae_gather_context",
      "hyphae_memory_recall"
    ],
    "passive_resource_uri": "hyphae://context/current"
  },
  "store": {
    "when": [
      "After a durable architecture or workflow decision.",
      "After resolving an error worth reusing.",
      "After project context changes that future sessions should inherit."
    ],
    "tool": "hyphae_memory_store",
    "project_topics": [
      "context/demo",
      "decisions/demo"
    ],
    "shared_topics": [
      "errors/resolved",
      "preferences"
    ]
  },
  "resources": [
    {
      "uri": "hyphae://protocol/current",
      "purpose": "Canonical memory-use protocol for hosts that need a concise Hyphae contract."
    },
    {
      "uri": "hyphae://context/current",
      "purpose": "Project-scoped passive context bundle for startup recall."
    },
    {
      "uri": "hyphae://artifacts/project-understanding/current",
      "purpose": "Project understanding bundle exported from the code memoir."
    }
  ]
}
```

```text
$ cd /Users/williamnewton/projects/basidiocarp/hyphae && cargo test --workspace
test result: ok. 157 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.42s
test result: ok. 56 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.04s
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
test result: ok. 43 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.01s
test result: ok. 166 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 1.86s
test result: ok. 5 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.05s
test result: ok. 247 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.96s
```

```text
$ bash /Users/williamnewton/projects/basidiocarp/.handoffs/archive/hyphae/verify-protocol-surface.sh
PASS: hyphae protocol surface exists
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
PASS: hyphae protocol emits versioned project-aware json
PASS: hyphae MCP protocol resource exists
pyenv: cannot rehash: /Users/williamnewton/.pyenv/shims isn't writable
PASS: hyphae tests pass
Results: 4 passed, 0 failed
```
