# Executive Incident Report: Payment Token Verification Errors

Checkout token verification errors increased on February 2, 2025 and created payment friction for a small percentage of customers. The immediate failure mode has been contained, and follow-up work is focused on reducing the chance of recurrence through a broader checkout rewrite.

---

## Incident Summary

| Field | Value |
| --- | --- |
| Investigation Date | February 2, 2025 |
| Incident Type | Increase in payment token verification failures |
| Status | Mitigated; longer-term remediation in progress |
| Primary Impact | Checkout friction for a subset of customers |
| Incident Origin | Payment data was sent to the payment provider before the checkout flow was in a valid state |

## Business Impact

The incident increased checkout friction and generated a noticeable rise in failed payment notifications. A small-sample review suggested that the issue affected a small percentage of orders and contributed to cart abandonment in roughly 1% of affected cases. The broader business risk was not revenue loss at system scale; it was erosion of customer trust during the most sensitive part of the buying journey.

## What Happened

Traffic increased through the storefront, and payment token verification failures rose with it. The team traced the increase to race conditions in the checkout flow that allowed payment data to be submitted before the form was complete or to be submitted twice when the customer clicked `Place Order`. In both cases, the payment provider received requests that were invalid or duplicative, which surfaced as token verification errors.

## Root Cause

The primary cause was premature or duplicate submission of payment data from the front end. The checkout flow allowed payment-provider requests to fire before the user had completed the payment step, and in some cases allowed the submission flow to run twice.

### Contributing Factors

- Existing front-end complexity made race conditions difficult to spot and isolate.
- A memory leak in some checkout states could repeatedly submit invalid payment data using the same payment token.
- Existing checkout architecture made it harder to validate state cleanly before external payment calls were made.

## Containment and Resolution

- The team patched the checkout paths that could submit payment data before the flow was complete.
- The team prevented the duplicate submission path tied to the `Place Order` action.
- Front-end validation now returns clearer customer feedback for invalid card details instead of allowing ambiguous payment-provider failures to surface first.

## Countermeasures

### Completed

- Patched the known premature-submission and duplicate-submission paths.
- Added logging around these scenarios to improve visibility into similar race conditions.
- Increased scrutiny of failed payment notifications to monitor residual issues.

### Planned

- Complete a broader rewrite and re-architecture of checkout.
- Isolate payment-provider-specific logic from the rest of the checkout flow.
- Add targeted unit and end-to-end tests for common payment and validation scenarios.

## Risks and Exposure

- The immediate issue is mitigated, but the broader checkout architecture still carries race-condition risk.
- Similar errors may still exist in paths that were not reproduced during this investigation.
- Long-term risk will remain elevated until the checkout flow is simplified and better covered by automated tests.

## Lessons Learned

- Session replay and monitoring data remain valuable for understanding customer behavior during checkout failures.
- The investigation produced a deeper understanding of how the checkout flow behaves from front end to back end.
- A prototype checkout re-architecture performed well in a sandbox environment and gives the team a credible path toward a more stable design.

## Closure Criteria

- Monitor payment token verification failures and confirm that rates remain stable after the patches.
- Track the checkout rewrite and automated test work as follow-up items.
- Close the incident after the team confirms the patched paths remain stable in production and the remaining risk is formally accepted.
