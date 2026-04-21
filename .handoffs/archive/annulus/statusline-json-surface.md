# Annulus Statusline JSON Surface

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `annulus`
- **Allowed write scope:** annulus/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Problem

The core implementation seam in `unified-output-aggregation` is the structured
JSON output from Annulus. That needs to stand alone so downstream Cap work can
build against one stable producer.

## What needs doing

Add `annulus statusline --json` and the companion contract:

- `annulus statusline --json`
- `septa/annulus-statusline-v1.schema.json`
- `ecosystem-versions.toml` pin

Required behavior:

- all core segments are represented
- unavailable segments stay in the payload with `available: false`
- output is stable enough for Cap and scripts to consume

Keep this handoff limited to the Annulus JSON surface and its contract. Do not
build the Cap panel here.

## Files to modify

- `annulus/src/...`
- `septa/annulus-statusline-v1.schema.json`
- `septa/fixtures/...` if needed
- `ecosystem-versions.toml`

## Verification

```bash
cd annulus && cargo test statusline --quiet
bash .handoffs/annulus/verify-statusline-json-surface.sh
```

## Verification Results

### Build & Test
```
cd annulus && cargo build
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.06s

cd annulus && cargo test --quiet
test result: ok. 45 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out

cd annulus && cargo clippy --all-targets -- -D warnings
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.17s
```

### JSON Output Examples

Full example with all segments available:
```json
{
  "schema": "annulus-statusline-v1",
  "version": "1",
  "segments": [
    {
      "name": "context",
      "available": true,
      "value": {"context_limit": 0, "percent": 43, "prompt_tokens": 0}
    },
    {
      "name": "usage",
      "available": true,
      "value": {
        "cache_creation_tokens": 5000,
        "cache_read_tokens": 30000,
        "input_tokens": 50000,
        "output_tokens": 10000
      }
    },
    {
      "name": "cost",
      "available": true,
      "value": {"dollars": 0.33, "model": "sonnet 4.6"}
    },
    {
      "name": "model",
      "available": true,
      "value": {"display_name": "sonnet 4.6"}
    },
    {
      "name": "savings",
      "available": false,
      "reason": "no active session"
    },
    {
      "name": "branch",
      "available": true,
      "value": {"branch": "main"}
    },
    {
      "name": "workspace",
      "available": true,
      "value": {"name": "basidiocarp"}
    },
    {
      "name": "context-bar",
      "available": true,
      "value": {"color_tier": "ok", "fill_chars": 5, "percent": 43, "total_chars": 12}
    }
  ]
}
```

### Schema & Contract Validation
```
cd septa && bash validate-all.sh
Results: 38 passed, 0 failed, 0 skipped

verify-statusline-json-surface.sh
PASS: annulus statusline json wiring exists
PASS: statusline schema exists
PASS: cargo statusline tests pass
Results: 3 passed, 0 failed
```

### CLI Interface
```bash
# Terminal output (unchanged)
annulus statusline
[2mctx: --[0m │ [36m--[0m │ [35m--[0m │ [2m[ctx ░░░░░░░░░░░░ --][0m
[34msonnet 4.6[0m │ [2mws: tmp[0m

# JSON output (new)
annulus statusline --json
{...valid JSON payload as above...}

# --no-color still works
annulus statusline --no-color
ctx: -- │ -- │ -- │ [ctx ░░░░░░░░░░░░ --]
sonnet 4.6 │ ws: tmp
```

## Checklist

- [x] `annulus statusline --json` emits valid JSON
- [x] unavailable segments carry `available: false` and `reason`
- [x] the septa schema and version pin exist
- [x] tests cover at least one degraded segment case
- [x] verify script passes with `Results: N passed, 0 failed`
