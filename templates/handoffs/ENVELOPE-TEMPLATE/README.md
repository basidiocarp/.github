# Handoff Envelope Format

The envelope directory format bundles a handoff with its verify script, evidence,
and contract snapshots, making complex handoffs self-contained.

## When to use

Use the envelope format when a handoff:
- Has a paired verify script longer than ~20 lines
- Needs to snapshot septa schemas at dispatch time
- Produces evidence artifacts (test output, screenshots) that should travel with the handoff

For simple handoffs, the flat `<slug>.md` format is still preferred.

## Structure

```
.handoffs/<project>/<slug>/
├── handoff.md      # main handoff body (required)
├── verify.sh       # verify script (required)
├── evidence/       # verification output, screenshots, test results
├── contracts/      # read-only septa schema snapshots at dispatch time
└── research.md     # optional audit notes or prior art
```

## Naming evidence files

Name evidence files `step-N-<command>.txt` by convention, e.g. `step-1-cargo-test.txt`.

## Backward compatibility

Flat `.handoffs/<project>/<slug>.md` files remain valid and take priority if both formats exist.
