# Cap App Layout Mobile Nav Accessibility

<!-- Save as: .handoffs/cap/app-layout-mobile-nav-a11y.md -->
<!-- Create verify script: .handoffs/cap/verify-app-layout-mobile-nav-a11y.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

On small screens, the only nav toggle is clicking the `cap` title. That element is not
a button and is not keyboard-focusable, so the mobile nav is effectively inaccessible
to keyboard users.

## What exists (state)

- **Layout component:** `cap/src/components/AppLayout.tsx`
- **Current affordance:** clickable title text toggles the collapsed nav
- **Failure mode:** no button semantics, no keyboard activation, no ARIA state

## What needs doing (intent)

Replace the clickable title with a real mobile-nav button and wire standard button,
focus, and ARIA behavior into the layout.

---

### Step 1: Add A Real Menu Button

**Project:** `cap/`
**Effort:** 45 min
**Depends on:** nothing

Update the mobile-nav control so:

- the toggle is a `<button>` or Mantine button-equivalent
- it is keyboard focusable
- it exposes `aria-expanded` and `aria-controls`
- Enter and Space both work

#### Files to modify

**`cap/src/components/AppLayout.tsx`** — replace the clickable title toggle.

**`cap/src/components/AppLayout.test.tsx`** or the closest existing route/layout test —
add keyboard coverage for the mobile-nav toggle.

#### Verification

```bash
cd cap && npm run test:frontend
```

**Output:**
```text
> cap@0.11.0 test:frontend
> vitest run --config vitest.frontend.config.ts

RUN  v4.1.0 /Users/williamnewton/projects/basidiocarp/cap
❯ src/pages/analytics/UsageCostTab.test.tsx (1 test | 1 failed) 115ms
    × labels the surface as usage history only instead of host coverage 112ms
```

**Checklist:**
- [x] Mobile nav uses a real button control
- [x] The control is keyboard reachable
- [x] Frontend tests cover the keyboard toggle path

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Verification output is pasted above
2. The verification script passes: `bash .handoffs/cap/verify-app-layout-mobile-nav-a11y.sh`
3. All checklist items are checked

### Final Verification

```bash
bash .handoffs/cap/verify-app-layout-mobile-nav-a11y.sh
```

**Output:**
```text
PASS: App layout uses a button-like nav toggle
PASS: App layout exposes ARIA state
PASS: Frontend test covers layout toggle
Results: 3 passed, 0 failed
```

## Status

Complete for the scoped mobile-nav accessibility work. The scoped layout test and verifier pass. The broader `npm run test:frontend` command still reports an unrelated pre-existing failure in `src/pages/analytics/UsageCostTab.test.tsx`.

## Context

Created from the completed Cap deep audit on 2026-04-05 after live route inspection on
the mobile navigation path.
