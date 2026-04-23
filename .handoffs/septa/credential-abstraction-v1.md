# Septa: Credential Abstraction V1 Contract

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `septa`
- **Allowed write scope:** `septa/` (new schema file + fixture + validation update)
- **Cross-repo edits:** none (this handoff creates the contract; adopter handoffs follow separately)
- **Non-goals:** does not implement credential storage in any tool; does not add a secret manager service; does not define rotation or key derivation protocols
- **Verification contract:** `bash septa/validate-all.sh` and the paired verify script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Identified as a missing septa gap by multiple Wave 2 audits:
- better-ccflare: OAuth token health monitoring, multi-account credential rotation
- cognee: pluggable multi-backend auth with env-driven config
- letta: per-operation usage tracking with API key attribution
- headroom: provider backend abstraction needing unified credential contract

> "Basidiocarp lacks a unified secret store. Define a septa contract for how tools share credentials safely, with lifecycle management (refresh, rotation, expiry)."

## Implementation Seam

- **Likely repo:** `septa`
- **Likely files/modules:**
  - `credential-v1.schema.json` (new) — the JSON Schema definition
  - `credential-v1.fixture.json` (new) — concrete examples for multiple credential types
  - `validate-all.sh` — add the new schema to the validation run
- **Reference seams:**
  - `septa/code-graph-v1.schema.json` — follow the same schema file conventions
  - `septa/context-envelope-v1.schema.json` — just-added envelope schema to follow for style
- **Spawn gate:** seam confirmed; schema can be written directly

## Problem

Multiple basidiocarp tools need credentials:
- `hyphae` needs API keys for optional remote backends (Elasticsearch, Mem0)
- `cortina` needs credentials for telemetry or remote logging targets
- `stipe` needs credentials for host config and MCP registration
- `volva` needs credentials for provider selection (which account/model to use)

Today, each tool handles credentials ad-hoc via raw environment variable reads with no shared schema, no lifecycle tracking (expiry, refresh), and no way to distinguish credential types (API key vs. OAuth token vs. service account).

The contract defines what a credential *looks like* when referenced across tools — not how it is stored (that stays in each tool or a future secret manager).

## What the schema should define

A `credential-v1` payload:

```json
{
  "schema_version": "credential-v1",
  "credential_id": "cred-abc123",
  "credential_type": "api_key",
  "provider": "anthropic",
  "scopes": ["messages:write"],
  "source": "env",
  "source_ref": "ANTHROPIC_API_KEY",
  "status": "active",
  "expires_at": null,
  "refreshable": false,
  "last_used_at": "2026-04-23T12:00:00Z",
  "metadata": {}
}
```

Credential types: `api_key`, `oauth_token`, `service_account`, `bearer_token`.
Sources: `env` (environment variable), `file` (path to secret file), `managed` (secret manager reference).
Statuses: `active`, `expired`, `revoked`, `refreshing`.

## Scope

- **Allowed files:** `septa/credential-v1.schema.json`, `septa/credential-v1.fixture.json`, `septa/validate-all.sh` (update)
- **Explicit non-goals:**
  - No implementation of credential storage — the schema describes the shape, not the store
  - No rotation protocol — that's a future contract
  - No encryption requirements — the schema describes the envelope, not the storage format

---

### Step 1: Write the JSON Schema

**Project:** `septa/`
**Effort:** small
**Depends on:** nothing (read `septa/code-graph-v1.schema.json` and `septa/context-envelope-v1.schema.json` first)

Create `septa/credential-v1.schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "credential-v1",
  "title": "Credential V1",
  "description": "A versioned envelope describing a credential reference shared between ecosystem tools.",
  "type": "object",
  "required": ["schema_version", "credential_id", "credential_type", "provider", "source", "status"],
  "additionalProperties": false,
  "properties": {
    "schema_version": {
      "type": "string",
      "const": "credential-v1"
    },
    "credential_id": {
      "type": "string",
      "description": "Unique identifier for this credential reference."
    },
    "credential_type": {
      "type": "string",
      "enum": ["api_key", "oauth_token", "service_account", "bearer_token"],
      "description": "The type of credential."
    },
    "provider": {
      "type": "string",
      "description": "The service or provider this credential authenticates with (e.g. 'anthropic', 'aws', 'google')."
    },
    "scopes": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Permission scopes granted by this credential."
    },
    "source": {
      "type": "string",
      "enum": ["env", "file", "managed"],
      "description": "Where the credential value is stored. 'env' = environment variable; 'file' = local file path; 'managed' = external secret manager."
    },
    "source_ref": {
      "type": "string",
      "description": "Reference to the credential value in the source. For 'env': variable name. For 'file': file path. For 'managed': secret ARN or key name."
    },
    "status": {
      "type": "string",
      "enum": ["active", "expired", "revoked", "refreshing"],
      "description": "Current lifecycle status of the credential."
    },
    "expires_at": {
      "type": ["string", "null"],
      "format": "date-time",
      "description": "When the credential expires. Null for non-expiring credentials."
    },
    "refreshable": {
      "type": "boolean",
      "description": "True if the credential can be automatically refreshed.",
      "default": false
    },
    "last_used_at": {
      "type": ["string", "null"],
      "format": "date-time",
      "description": "When this credential was last used."
    },
    "metadata": {
      "type": "object",
      "description": "Provider-specific or tool-specific additional fields.",
      "additionalProperties": true
    }
  }
}
```

#### Verification

```bash
cd septa && node -e "
const s = require('./credential-v1.schema.json');
console.log('credential_type enum:', s.properties.credential_type.enum);
console.log('source enum:', s.properties.source.enum);
console.log('OK');
"
```

**Checklist:**
- [ ] Schema parses as valid JSON
- [ ] Required fields: `schema_version`, `credential_id`, `credential_type`, `provider`, `source`, `status`

---

### Step 2: Write the fixture

**Project:** `septa/`
**Effort:** tiny
**Depends on:** Step 1

Create `septa/credential-v1.fixture.json` with examples for all credential types:

```json
[
  {
    "schema_version": "credential-v1",
    "credential_id": "cred-anthropic-api",
    "credential_type": "api_key",
    "provider": "anthropic",
    "scopes": ["messages:write"],
    "source": "env",
    "source_ref": "ANTHROPIC_API_KEY",
    "status": "active",
    "expires_at": null,
    "refreshable": false,
    "last_used_at": "2026-04-23T12:00:00Z",
    "metadata": {}
  },
  {
    "schema_version": "credential-v1",
    "credential_id": "cred-claude-oauth",
    "credential_type": "oauth_token",
    "provider": "claude",
    "scopes": ["api:read", "api:write"],
    "source": "file",
    "source_ref": "~/.config/claude/oauth_token.json",
    "status": "active",
    "expires_at": "2026-04-23T17:00:00Z",
    "refreshable": true,
    "last_used_at": "2026-04-23T12:00:00Z",
    "metadata": { "session_duration_hours": 5 }
  },
  {
    "schema_version": "credential-v1",
    "credential_id": "cred-aws-bedrock",
    "credential_type": "service_account",
    "provider": "aws",
    "scopes": ["bedrock:InvokeModel"],
    "source": "managed",
    "source_ref": "arn:aws:secretsmanager:us-east-1:123456789:secret/bedrock-creds",
    "status": "active",
    "expires_at": null,
    "refreshable": false,
    "last_used_at": null,
    "metadata": { "region": "us-east-1" }
  }
]
```

Note: the fixture is an array of examples, not a single entry, so multiple types can be validated in one fixture file.

#### Verification

```bash
cd septa && node -e "
const Ajv = require('ajv');
const ajv = new Ajv({ strict: false });
const schema = require('./credential-v1.schema.json');
const fixtures = require('./credential-v1.fixture.json');
let allPass = true;
fixtures.forEach((f, i) => {
  const valid = ajv.validate(schema, f);
  if (!valid) { console.error('FAIL fixture', i, ajv.errors); allPass = false; }
});
if (allPass) console.log('PASS: all fixtures validate against schema');
" 2>/dev/null || echo "Note: if ajv not installed, validate manually"
```

**Checklist:**
- [ ] All 3 fixture examples validate against the schema
- [ ] Covers: api_key (env), oauth_token (file, refreshable), service_account (managed)

---

### Step 3: Add to validate-all.sh

**Project:** `septa/`
**Effort:** tiny
**Depends on:** Step 2

Add `credential-v1` to `septa/validate-all.sh` following the existing pattern.

#### Verification

```bash
cd septa && bash validate-all.sh 2>&1 | tail -10
```

**Checklist:**
- [ ] `validate-all.sh` includes credential-v1
- [ ] `validate-all.sh` passes

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Schema and fixture written and validated
2. `validate-all.sh` updated and passing
3. `.handoffs/HANDOFFS.md` updated to reflect completion

## Follow-on work (not in scope here)

- `stipe`: read credential-v1 shape when registering MCP servers that need auth
- `hyphae`: use credential-v1 to describe which backend credentials are configured
- `cortina`: emit credential status events (expired, refreshed) as lifecycle signals
- `septa/credential-refresh-v1.schema.json`: add refresh request/response contract

## Context

Spawned from Wave 2 audit program (2026-04-23). better-ccflare, cognee, letta, and headroom all surface the same gap: no shared credential contract means every tool invents its own shape. This contract defines the envelope only — not the storage. Tools store credentials however they need to; the schema defines what they look like when referenced across tool boundaries.
