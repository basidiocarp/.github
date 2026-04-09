# Internal Incident Report: Increase in Payment Token Verification Failures

On February 2, 2025, the storefront saw a meaningful increase in payment token verification failures during checkout. The incident was traced to front-end race conditions that submitted payment data too early or more than once, which created customer friction and drove a rise in failed payment notifications.

---

## Incident Metadata

| Field | Value |
| --- | --- |
| Investigation Date & Start Time | February 2, 2025 |
| Incident Type | Increase in payment token verification failures |
| Severity | Customer-facing checkout degradation |
| Status | Mitigated; deeper remediation in progress |
| Incident Origin | Data being sent to the payment provider prematurely |
| Detection Method | Review of failed payment notifications and investigation of checkout behavior |

## Description

The customer-facing symptom was a rise in failed payment attempts with messages similar to `Token verification failed`. These failures appeared during checkout and created friction at the point where customers expected the transaction to complete. The visible failure was only part of the problem; the underlying issue was that front-end logic could send payment-provider requests from an invalid or duplicated checkout state.

## Impact

### Customer Impact

- Customers encountered failed payment attempts during checkout.
- Some customers likely retried successfully, while others experienced enough friction to abandon their carts.
- A small-sample review suggested the issue affected a small percentage of orders, with cart abandonment in roughly 1% of affected cases.

### Business Impact

- Failed payment notifications increased and required investigation.
- The incident added support and engineering overhead during a period of elevated traffic.
- The larger business concern was customer trust during checkout rather than broad platform instability.

### Technical Impact

- The checkout front end submitted payment data in invalid states.
- The payment provider saw requests that were premature, duplicated, or both.
- Existing observability was useful, but not specific enough to isolate every race-condition path quickly.

## Root Cause Analysis

The root cause was a set of race conditions in checkout. Payment data could be sent to the payment provider before the review and payment flow had reached a valid final state, and certain `Place Order` paths could cause the submission logic to run twice.

### Trigger

Traffic increased through the storefront, which made the existing race conditions show up more often. The higher request volume did not create the bug, but it made the bug easier to observe and more painful in production.

### Contributing Conditions

- Checkout code complexity made state ownership and side effects hard to reason about.
- Some front-end states could leak behavior that repeatedly submitted invalid payment data using the same payment token.
- Validation logic did not consistently stop invalid external payment requests before they reached the payment provider.

### Failure Path

1. A customer moved through checkout and entered payment details.
2. Front-end logic submitted payment data before the checkout flow was fully valid, or submitted twice when `Place Order` was clicked.
3. The payment provider received an invalid or duplicate request tied to the same token.
4. The payment provider returned token verification failures, which surfaced to the customer as payment errors.

## Detection

### What Worked

- Failed payment notifications made the issue visible.
- Session replay helped reconstruct customer behavior and isolate failure patterns.
- Deeper front-end investigation identified two distinct categories of race conditions.

### What Did Not Work

- Existing logs did not immediately distinguish premature submission from duplicate submission.
- The checkout flow did not expose enough structured state data to make root cause obvious at first glance.

### Detection Gap

The system lacked targeted logging around payment submission state, especially before the payment-provider handoff. Earlier detection would have been easier if the application logged when checkout requests were initiated, repeated, or attempted from incomplete form states.

## Containment

- Patched the Category 1 paths that allowed payment data to be sent before checkout was complete.
- Patched the Category 2 duplicate-submission paths around the `Place Order` action.
- Improved front-end validation so customers now receive clearer feedback for invalid card details.

## Resolution

- The known premature-submission and duplicate-submission paths were fixed.
- Additional logging was added to improve visibility into similar race conditions.
- The team verified that customer-facing validation now behaves more specifically and prevents some invalid submissions from reaching the payment provider.

## Countermeasures

### Applied Countermeasures

- Patch the premature-submission paths.
- Patch duplicate-submission behavior during final order placement.
- Add logging around the affected checkout states.
- Review failed payment notifications more closely for residual patterns.

### Planned Countermeasures

#### Near Term

- Continue monitoring payment-provider-related payment failures.
- Extend logging and analysis around payment submission state.

#### Medium Term

- Complete the checkout re-architecture already underway.
- Add targeted unit and end-to-end test coverage for payment and validation flows.

#### Long Term

- Modularize payment logic so payment-provider behavior is isolated from broader checkout state handling.
- Reduce reliance on legacy patterns that make race conditions difficult to identify and prevent.

## Timeline

| Time | Event |
| --- | --- |
| February 2, 2025 | Increase in payment token verification failures observed |
| February 2, 2025 | Investigation traced the issue to checkout race conditions |
| February 2, 2025 | Category 1 and Category 2 patches were identified and applied |
| After mitigation | Monitoring and follow-up re-architecture work continued |

## Lessons Learned

### What Went Well

- The team isolated distinct failure categories instead of treating the incident as a single vague gateway problem.
- Session replay and sandbox testing were both useful in narrowing the issue.

### What Went Wrong

- Checkout complexity made the failure modes harder to find than they should have been.
- Existing logs did not provide enough direct evidence about payment submission timing or duplication.

### Where We Got Lucky

- The incident appears to have affected a limited percentage of orders rather than the full checkout flow.
- A sandbox re-architecture prototype already existed and helped validate a more stable direction.

## Continue Investigating

- Continue the front-end re-architecture work.
- Map the full checkout user journey to identify additional race-condition paths.
- Watch for new payment-provider failure patterns that may point to unresolved edge cases.

## Closure

Pending. Closure should wait until production monitoring confirms the mitigations are stable and the remaining structural follow-up work is tracked.
