# Internal Incident Report: [Incident Title]

[Summarize the failure mode, user impact, and current state in one or two sentences.]

---

## Incident Metadata

| Field | Value |
| --- | --- |
| Investigation Date & Start Time | [Month Day, Year, HH:MM timezone] |
| Incident Type | [Short category name] |
| Severity | [Customer-facing degradation / SEV1 / SEV2 / SEV3 / Internal-only] |
| Status | [Investigating / Mitigated / Monitoring / Closed] |
| Incident Origin | [Short cause summary] |
| Detection Method | [Alert, customer report, support ticket, manual observation] |

## Description

[Describe what failed, where it appeared, and how users or operators experienced it. Start with the observable symptom before explaining the underlying issue.]

## Impact

### Customer Impact

- [What customers saw]
- [How many users, orders, sessions, or transactions were affected]
- [Whether customers recovered automatically or needed support]

### Business Impact

- [Revenue impact, support burden, operational disruption, SLA risk]

### Technical Impact

- [Systems, services, flows, or environments affected]

## Root Cause Analysis

[Describe the primary mechanism behind the incident in clear technical prose.]

### Trigger

[Explain what change or condition caused the incident to surface. If traffic or scale amplified the issue, say that explicitly.]

### Contributing Conditions

- [Condition that made the incident more likely]
- [Condition that increased impact]
- [Condition that delayed detection or response]

### Failure Path

1. [First failure step]
2. [Second failure step]
3. [Third failure step]
4. [Resulting system or user-visible effect]

## Detection

### What Worked

- [Signal, alert, or observation that helped]
- [Tooling or data source that reduced investigation time]

### What Did Not Work

- [Missing alert]
- [Noisy or ambiguous signal]
- [Observability gap]

### Detection Gap

[State what should have detected this sooner and why it did not.]

## Containment

- [Immediate mitigation]
- [Operational workaround]
- [Traffic, feature, or configuration control used]

## Resolution

- [Permanent fix]
- [Validation step]
- [Rollback or fallback path, if relevant]

## Countermeasures

### Applied Countermeasures

- [Fix already shipped]
- [Logging, alerting, or instrumentation change]
- [Guardrail, validation, or process improvement]

### Planned Countermeasures

#### Near Term

- [Work item]
- [Work item]

#### Medium Term

- [Structural improvement]
- [Testing or automation improvement]

#### Long Term

- [Architecture or process change]
- [Operational or organizational change]

## Timeline

| Time | Event |
| --- | --- |
| [Month Day, Year or HH:MM timezone] | [What happened] |
| [Month Day, Year or HH:MM timezone] | [Detection or escalation] |
| [Month Day, Year or HH:MM timezone] | [Mitigation applied] |
| [Month Day, Year or HH:MM timezone] | [Fix deployed or verified] |

## Lessons Learned

### What Went Well

- [Positive response behavior]
- [Process or tooling that helped]

### What Went Wrong

- [Gap in system design]
- [Gap in process or communication]

### Where We Got Lucky

- [Factor that reduced impact but was not by design]

## Continue Investigating

- [Open question]
- [Unverified assumption]
- [Related area that still needs review]

## Closure

[Closed on Month Day, Year by team or owner.]

Or, if still open:

[Pending. Closure should wait until the following are complete:]

- [Required verification]
- [Required follow-up item]
