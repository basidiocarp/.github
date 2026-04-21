# Cap: Server Canopy Route Validation Consolidation

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cap`
- **Allowed write scope:** `cap/server/...`
- **Cross-repo edits:** none
- **Non-goals:** adding Zod as a dependency, changing any API surface or response shapes
- **Verification contract:** run the commands below and the paired verify script
- **Priority:** Medium

## Problem

`server/routes/canopy.ts` is 396 lines, of which ~250 are inline validation logic: long chains of `if (!body.action) return c.json(...)` checks with repeated patterns. This is fragile (easy to forget a check), hard to test in isolation, and difficult to extend.

Additionally, the ~10 `ALLOWED_*` constant sets at the top of the file duplicate information already encoded as TypeScript union types in `cap/src/lib/types/canopy.ts`. The source of truth exists in two places.

## What exists

- **`cap/server/routes/canopy.ts`** — 396 lines; lines ~189–360 are imperative `if/return` validation chains for the POST task-action endpoint
- **Allowed sets:** ~10 `const ALLOWED_*` sets at file top that mirror values already in `src/lib/types/canopy.ts`
- **`cap/src/lib/types/canopy.ts`** — already defines `CanopySnapshotPreset`, `CanopyTaskStatus`, etc. as union types
- **No schema library** — Cap does not use Zod; simple type guard functions suffice

## What needs doing

### Step 1: Extract validation into a dedicated module

**New file:** `cap/server/lib/canopy-validators.ts`

Create validator functions for each action type. Each validator takes the raw body and returns either a validated typed object or an error descriptor:

```typescript
type ValidationResult<T> =
  | { ok: true; value: T }
  | { ok: false; status: 400; message: string }
```

### Step 2: Derive allowed sets from a single source of truth

**File:** `cap/server/lib/canopy-validators.ts` or a shared constants file

Derive the runtime allowed-value arrays from the TypeScript union types so there is one canonical list. The union type values can be extracted into a `const` array that simultaneously feeds both the type and the runtime check.

### Step 3: Slim the route file

**File:** `cap/server/routes/canopy.ts`

Replace the inline validation chains with calls to validator functions from Step 1. Target: under 120 lines for the route file.

### Step 4: Add unit tests for the validators

**New file:** `cap/server/__tests__/canopy-validators.test.ts`

Test each validator independently: missing fields, invalid values, and the happy path. These tests run without standing up the full Hono app.

## Verification

```bash
bash .handoffs/cap/verify-server-canopy-validation-consolidation.sh
```

Manual checks:
- `wc -l cap/server/routes/canopy.ts` — under 120 lines
- `cap/server/lib/canopy-validators.ts` exists
- `cap/server/__tests__/canopy-validators.test.ts` exists
- `npm run test:server` passes
- `npm run build` succeeds

## Checklist

- [ ] Validator module extracted from canopy route
- [ ] Allowed value sets derived from a single source of truth
- [ ] Canopy route file under 120 lines
- [ ] Unit tests for validator functions covering edge cases
- [ ] Server tests pass
- [ ] Build succeeds
