# Cortina Usage Event Producer Serialization

## Problem

The cross-project `usage-event-v1` contract now exists in `septa`, and
`mycelium` has a consumer-side guard that pins the fields needed for
deterministic summaries. What is still missing is a producer-side regression
seam in `cortina`. Without that, the producer boundary is only documented, not
proven against the shared fixture.

## What exists (state)

- **`septa/`:** owns `usage-event-v1` and its example fixture
- **`cortina`:** owns edge capture and host normalization
- **`mycelium`:** has a workspace-alignment guard for the consumer boundary
- **No producer fixture seam:** `cortina` does not yet prove that its normalized
  usage emission can serialize to the shared shape

## What needs doing (intent)

Add one narrow producer-side test or serialization seam in `cortina` that
proves the emitted normalized usage payload aligns with `usage-event-v1`.

Keep this small:

- identify the producer surface
- serialize one representative normalized usage event
- compare the resulting shape to the shared contract or fixture

---

### Step 1: Name the producer path explicitly

**Project:** `cortina/`
**Effort:** 1-2 hours
**Depends on:** Cross-Project Usage Event Contract

Document the exact `cortina` path that is responsible for normalized usage
capture or emission.

#### Files to modify

**`cortina/README.md`** or adjacent docs — note the producer path and how it
maps to `usage-event-v1`.

#### Verification

```bash
rg -n 'usage-event-v1|normalized usage|producer' cortina
```

**Output:**
<!-- PASTE START -->
README.md:84:3. Normalize usage edges: transcript-derived token and cost counters should converge on Septa's `usage-event-v1` contract before downstream summary layers.
README.md:113:- Normalized usage-event producer boundary before downstream summaries
README.md:119:The current production-adjacent `usage-event-v1` producer path lives in
README.md:123:Septa's `usage-event-v1` field names. Cortina does not expose a standalone
README.md:124:usage-event emission command yet, so the producer-side regression seam also
README.md:128:`../septa/fixtures/usage-event-v1.example.json`.
src/statusline.rs:136:    producer: &'static str,
src/statusline.rs:319:            producer: "cortina",
src/statusline.rs:702:            .join("../septa/fixtures/usage-event-v1.example.json");
<!-- PASTE END -->

**Checklist:**
- [x] `cortina` explicitly names the usage-event producer path
- [x] docs connect that path to `usage-event-v1`

---

### Step 2: Add a producer-side serialization regression seam

**Project:** `cortina/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Add one narrow test that serializes a representative normalized usage event and
asserts that the emitted payload matches the shared contract expectations.

Good options:

- load the `septa` fixture and compare required fields
- deserialize `usage-event-v1.example.json` into a `cortina` type
- serialize a `cortina` normalized usage payload and assert required field
  presence and stable names

#### Files to modify

**`cortina/src/` or `cortina/tests/`** — add the focused serialization or
fixture-alignment test.

#### Verification

```bash
cd cortina && cargo test usage_event
bash .handoffs/cortina/verify-usage-event-producer-serialization.sh
```

**Output:**
<!-- PASTE START -->
running 1 test
test statusline::tests::usage_event_serialization_matches_septa_fixture_shape ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 162 filtered out; finished in 0.00s

PASS: Cortina docs mention usage-event-v1 producer boundary
PASS: Septa usage-event fixture exists
PASS: Cortina has a usage-event regression test
Results: 3 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] a producer-side usage-event regression test exists
- [x] the test references the shared contract or fixture
- [x] the verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/cortina/verify-usage-event-producer-serialization.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/cortina/verify-usage-event-producer-serialization.sh
```

**Output:**
<!-- PASTE START -->
PASS: Cortina docs mention usage-event-v1 producer boundary
PASS: Septa usage-event fixture exists
PASS: Cortina has a usage-event regression test
Results: 3 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Follow-up to:

- `.handoffs/cross-project/usage-event-contract.md`
- `septa/usage-event-v1.schema.json`
- `septa/fixtures/usage-event-v1.example.json`
