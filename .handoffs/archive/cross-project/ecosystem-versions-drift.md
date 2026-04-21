# Ecosystem Versions Drift

## Problem

`ecosystem-versions.toml` has 3 stale version pins that no longer match the actual
Cargo.toml versions in each project. This file is the source of truth for cross-project
dependency alignment, and stale entries defeat its purpose.

## What exists (state)

| Tool | ecosystem-versions.toml | Actual Cargo.toml | Delta |
|------|------------------------|-------------------|-------|
| cortina | 0.2.5 | 0.2.6 | +1 patch |
| stipe | 0.5.6 | 0.5.7 | +1 patch |
| canopy | 0.3.0 | 0.3.1 | +1 patch |

## What needs doing (intent)

Update the 3 stale version pins to match actual Cargo.toml versions.

---

### Step 1: Update ecosystem-versions.toml

**Project:** workspace root
**Effort:** 5 min
**Depends on:** nothing

#### Files to modify

**`ecosystem-versions.toml`** — update:
- cortina: `0.2.5` → `0.2.6`
- stipe: `0.5.6` → `0.5.7`
- canopy: `0.3.0` → `0.3.1`

#### Verification

```bash
for project in cortina stipe canopy; do
  toml_ver=$(grep "^$project" ecosystem-versions.toml | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
  cargo_ver=$(grep '^version' $project/Cargo.toml | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
  echo "$project: toml=$toml_ver cargo=$cargo_ver match=$([ "$toml_ver" = "$cargo_ver" ] && echo YES || echo NO)"
done
```

**Checklist:**
- [ ] All 3 versions match their Cargo.toml
- [ ] No other versions have drifted

---

## Context

Found during global ecosystem audit (2026-04-04), Layer 3 cross-project consistency.
See `ECOSYSTEM-AUDIT-2026-04-04.md` H4.
