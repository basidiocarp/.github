# Mycelium: Compressed Format Experiments

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** mycelium/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

<!-- Save as: .handoffs/mycelium/compressed-format-experiments.md -->

## Problem

JSON payloads (test results, dependency trees, config dumps) are verbose and tokenize poorly. Emerging formats like TOON (Token-Optimized Object Notation) claim 40-60% token reduction while maintaining model comprehension. Whether this holds for basidiocarp's use cases is unproven.

## What exists (state)

- **Mycelium**: Outputs filtered text — no format transformation layer
- **TOON and similar**: Community formats optimized for LLM tokenization, not yet widely adopted
- **No benchmarks**: No measurement of how format changes affect response quality in this ecosystem

## What needs doing (intent)

Run controlled experiments comparing standard JSON, TOON, and other compressed formats on real mycelium output. Measure both token savings AND response quality.

---

### Step 1: Build evaluation framework

**Project:** `mycelium/`
**Effort:** 2-3 hours
**Depends on:** nothing

Create a test harness that takes real command output, encodes it in multiple formats, and measures: token count per format, model response accuracy per format.

#### Verification
```bash
ls mycelium/tests/format_eval/ 2>/dev/null || echo "needs creation"
```

**Checklist:**
- [ ] Test harness accepts real command output fixtures
- [ ] Supports at least 3 formats: raw JSON, TOON, compact JSON (whitespace-stripped)
- [ ] Token counting via tiktoken or similar
- [ ] Response quality scoring framework defined

---

### Step 2: Run experiments on representative outputs

**Project:** `mycelium/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Test each format against real outputs: cargo test results, git log, dependency trees, build errors. Measure token savings and whether the model can still extract the same information.

#### Verification
```bash
echo "Experiment results documented"
```

**Checklist:**
- [ ] At least 5 representative output types tested
- [ ] Token savings measured per format per output type
- [ ] Response quality scored (can model extract same facts?)
- [ ] Results documented with recommendation

---

### Step 3: Implement winning format if results justify

**Project:** `mycelium/`
**Effort:** 2-3 hours
**Depends on:** Step 2

If a compressed format shows >30% token savings with no quality degradation, add it as an option in Mycelium's output pipeline. Make it configurable — don't force it.

#### Verification
```bash
cd mycelium && cargo test
```

**Checklist:**
- [ ] Format transformation implemented (if justified)
- [ ] Configurable via mycelium config (opt-in, not default)
- [ ] Fallback to standard format always available
- [ ] Decision documented if experiments show no benefit

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked

## Context

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsToken optimization strategy documented in docs/architecture/token-optimization-design-note.md. This is the most speculative of the token optimization strategies — run experiments before committing. The other strategies (structural parsing, summary+detail, cache layout) have more predictable returns.
