# Auth and Access Control Audit

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** cross-project (volva, canopy, cap — read-only audit first)
- **Allowed write scope:** audit report only; no code changes in Pass 1
- **Cross-repo edits:** audit reads only
- **Non-goals:** implementing new auth mechanisms; changing business logic; this is a discovery-and-report pass
- **Verification contract:** a written findings report with per-surface verdict (adequate / gap / N/A) and ordered remediation recommendations
- **Completion update:** update dashboard to reflect findings; open child handoffs for any gaps found

## Context

The Phase 5 audit noted that auth was explicitly out of scope. The ecosystem is localhost-by-default, but that assumption may not hold indefinitely — and even on localhost, MCP tools (canopy, hyphae) are called by agents that could be misconfigured or compromised. The canopy `DispatchPolicy` and `pre_dispatch_check` logic in particular gatekeep multi-agent task access, and its correctness has not been independently verified.

## Implementation Seam

- **Likely repos:** volva (auth flows), canopy (DispatchPolicy, dispatch gating), cap (server auth model)
- **Likely files:** `volva/crates/volva-auth/`, `canopy/src/tools/policy.rs`, `cap/server/`
- **Reference seams:** read CLAUDE.md constraints for each repo before reading code
- **Spawn gate:** do not spawn an implementer — this is an audit pass. Spawn an Explore agent only.

## Problem

Three surfaces have auth-adjacent logic that has not been independently audited:
1. **volva auth flows** — volva manages Claude API and oauth credentials; how are they stored and validated?
2. **canopy DispatchPolicy** — gatekeeps which agents can accept handoffs; is the policy enforced correctly against all dispatch paths?
3. **cap server** — localhost-only by design, but does it have any auth at all? What happens if the port is exposed accidentally?

## What needs doing (intent)

Audit each surface for:
- Credential storage: where are credentials stored, what permissions, are they in plaintext?
- Access control: is the policy logic reachable by all relevant paths, or are there bypass routes?
- Exposure model: what is the attack surface if the tool is exposed beyond localhost?

Produce a findings report. Open child handoffs for any gaps found.

## Scope

- **Primary seam:** read-only audit of volva auth, canopy dispatch policy, cap server auth model
- **Allowed files:** read-only — no code changes in this handoff
- **Explicit non-goals:** implementing new auth; adding encryption; this is audit-only

---

### Step 1: volva auth flow audit

**Project:** `volva/`
**Effort:** 1-2 hours
**Depends on:** nothing

Read:
- `volva/crates/volva-auth/src/` — full audit
- `volva/CLAUDE.md` — stated auth boundaries
- Look for: credential file locations, key storage, token refresh logic, what happens on invalid token

Answer per surface:
- Where are credentials stored? (plaintext file, keychain, env var?)
- What file permissions are set on credential files?
- Is token validation done before use or assumed valid?
- What happens on expired/invalid credentials — error or silent failure?

#### Verification

```bash
grep -rn "keychain\|plaintext\|token\|secret\|credential\|permission\|chmod" \
  volva/crates/volva-auth/src/ | head -30
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Credential storage location confirmed
- [ ] File permissions model documented
- [ ] Token validation path traced

---

### Step 2: canopy DispatchPolicy audit

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** nothing

Read:
- `canopy/src/tools/policy.rs` — `DispatchPolicy::evaluate()` logic
- `canopy/src/runtime.rs` — `pre_dispatch_check` and `DispatchDecision`
- Any place in canopy that creates or modifies tasks without going through dispatch gating

Answer:
- What are the conditions under which `DispatchDecision::Allow` is returned?
- Are there any task-create or task-update paths that bypass `pre_dispatch_check`?
- Can an agent claim a task that is owned by another agent? Is ownership enforced?
- Is there any rate limiting on task creation or dispatch calls?

#### Verification

```bash
grep -rn "DispatchDecision\|pre_dispatch_check\|DispatchPolicy" \
  canopy/src/ | grep -v test
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] All dispatch paths confirmed to go through policy check
- [ ] Ownership enforcement confirmed or gap identified
- [ ] Bypass paths (if any) documented

---

### Step 3: cap server auth model audit

**Project:** `cap/`
**Effort:** 1 hour
**Depends on:** nothing

Read:
- `cap/server/` — all route handlers
- Any middleware or authentication middleware
- `cap/CLAUDE.md` — stated "localhost only" assumption

Answer:
- Does cap server have any authentication at all?
- What happens if the port (typically 5173/3000) is exposed on a LAN or via port forwarding?
- Are there any write routes in cap that modify ecosystem state? (Cap CLAUDE.md says "only explicit write-through actions")
- Is CORS configured to restrict origins?

#### Verification

```bash
grep -rn "auth\|cors\|origin\|middleware\|bearer\|token" cap/server/ | head -30
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Auth model (or lack thereof) confirmed
- [ ] Write routes enumerated
- [ ] CORS policy confirmed

---

### Step 4: Write findings report

**Project:** audit output
**Effort:** 30 min
**Depends on:** Steps 1-3

Write findings to `.handoffs/cross-project/auth-audit-findings.md` with:
- Per-surface verdict table (adequate / gap / N/A)
- Ordered list of gaps by severity
- Recommended child handoffs for any gaps that warrant fixes

#### Verification

```bash
ls .handoffs/cross-project/auth-audit-findings.md
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Findings report written
- [ ] Per-surface verdict table complete
- [ ] Child handoffs opened for any High/Critical gaps

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. All three surfaces audited (volva auth, canopy dispatch policy, cap server)
2. Findings report written with per-surface verdict
3. Child handoffs opened for any gaps rated High or Critical
4. No code was changed — this is audit only
5. Dashboard updated

### Final Verification

```bash
bash .handoffs/cross-project/verify-auth-audit.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->
