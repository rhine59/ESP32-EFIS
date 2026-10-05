# EFIS Service process-workflow architecture

Status: ADOPTED — reference implementation started 2026-10-05.

## Principle

EFIS Service is process-oriented, not function-oriented. The normal user chooses the outcome they want and follows a guided state machine. Low-level licence/service controls remain available only under Advanced for diagnostics and recovery.

Every workflow uses the same state language:

- GREEN — step is positively confirmed complete.
- BLUE — current actionable step.
- GREY — future step, unavailable until prerequisites complete.
- AMBER — waiting or user/operator attention is required.
- RED — failed; corrective action is required before progression.

A workflow must derive progress from authoritative service/EFIS state wherever possible. Visiting a screen does not make a step complete. Each stage explains what happened, what is happening now and the next valid action. Normal flows should expose one obvious primary action rather than a collection of unrelated controls.

## Canonical process catalogue

### Set up a new EFIS
Identify EFIS -> register owner -> choose licence -> obtain signed licence -> install on EFIS -> verify installation.

### Buy / activate a licence
Identify RedOne -> check included first-year entitlement -> confirm owner -> activate included year OR buy a licence -> obtain signed licence -> install on EFIS -> verify VALID -> show renewal date.

Commercial rule: a new RedOne includes its first year of licence service. The included year is an entitlement attached to that RedOne and starts on first activation, not manufacture. It may be consumed only once. A later ownership transfer does not create another free year; any remaining active term stays with the RedOne until its existing expiry. After the included term, normal paid renewal applies. A production implementation should also define a reasonable maximum period after purchase in which the included year may first be activated.

The app must check this entitlement before presenting payment. If the included year is available, the primary action is **Activate included first year**, never **Buy**. Price/payment controls are shown only when no included entitlement and no suitable active licence exists.

### Reassign / sell an EFIS
Confirm current EFIS -> identify new owner -> buyer accepts ownership -> issue replacement licence -> install on EFIS -> verify new ownership.

This is the first reference implementation. Seller-side initiation/cancellation is wired to the lifecycle service. Buyer acceptance is now implemented end-to-end in the development simulator/client with invited-email validation; production buyer authentication and single-use invitation credentials remain implementation-pending.

### Receive a transferred EFIS
Open transfer invitation -> authenticate buyer -> accept ownership -> obtain replacement licence -> install on EFIS -> verify ownership.

### Renew / manage a licence
Identify licence -> review status -> choose renewal action -> confirm change -> verify entitlement.

### Install / update a licence
Connect to EFIS -> obtain signed entitlement -> transfer to EFIS -> verify signature/device -> persist licence -> confirm VALID.

### Replace an EFIS
Identify old EFIS -> identify replacement -> check eligibility -> migrate entitlement -> install licence -> retire old association.

### Recover licence access
Authenticate -> find owned EFIS -> retrieve entitlement -> reconnect to EFIS -> install licence -> verify.

### Update EFIS firmware
Identify EFIS -> check versions -> check compatibility -> acquire firmware -> transfer/validate -> activate/reboot -> post-update checks.

### Commission an EFIS
Connect -> identify hardware -> check firmware -> check licence -> discover SMUX/CAN -> configure sensors -> set units/thresholds -> validate displays -> complete commissioning.

### Diagnose a problem
Connect -> collect system state -> identify affected subsystem -> guided checks -> corrective action -> retest -> record result.

## UI architecture

`ProcessHomeView` is the normal application entry point. It presents the outcome-oriented catalogue. `ProcessStepRow` is the common visual progression component. `ReassignEFISFlowView` is the first state-aware reference workflow. Other catalogue entries currently use the common progression presentation while their service actions are migrated incrementally.

The previously validated `LicenceView` remains available under Advanced -> Licence diagnostics & manual controls. It is not the preferred normal user journey.

## State-machine requirements

A production workflow must have stable process and step identifiers; explicit prerequisites; authoritative completion predicates; current/waiting/error states; idempotent actions where practical; safe retry; cancellation/recovery paths; and auditable transitions. Server-owned transitions such as ownership acceptance must never be inferred locally.

Workflow progress must ultimately be resumable after app termination or phone replacement. Persist only workflow identifiers and safe UI context locally; reconstruct authoritative progress from account, licence and EFIS state on resume. Secrets and signed licence material remain in their existing protected storage.

## Migration rule

Every process screen must begin with a plain-language guidance panel stating (1) what has already been completed and (2) exactly what the user should do next. This guidance is derived from authoritative workflow state and must not require the user to interpret technical status fields or the flow diagram.

The canonical interaction is **tap the current process step to advance**. The blue/current row is an actionable control when the step can be performed on the phone. Grey future rows are disabled. Amber waiting/attention rows may expose refresh, cancellation or another safe waiting-state action. Red failed rows expose correction/retry. Green completed rows are historical confirmation and must not silently repeat a state-changing action. Separate action controls are retained only where the step requires input (for example an email address or plan choice), and should be visually associated with that current step.

New user-facing EFIS Service functionality must be designed as a process/state transition first. Adding a new collection of independent buttons or tabs requires an explicit diagnostic/advanced-use justification. Existing functional screens should be migrated behind guided workflows without removing their tested recovery value until the corresponding process has full acceptance coverage.

## Physical-iPhone reference validation

On 2026-10-05 EFISService was successfully built and code-signed for the paired iPhone 13 Pro Max, installed with bundle ID `uk.co.thingies.EFISService`, and launched on the physical device. `Set up a new EFIS` is now the second state-aware workflow after reassignment. Its progress is derived from real account recognition, ACTIVE entitlement, the protected signed-licence cache, and the explicit EFIS `VALID` installation acknowledgement.

## Receive-transferred-EFIS reference workflow

The development simulator now supports the complete process shape: locate a pending transfer, match the invited buyer, accept ownership atomically, obtain a replacement signed entitlement, install it on the EFIS, and finish only after the EFIS reports `VALID`. A buyer identity mismatch is rejected.

The current email match is deliberately marked simulation-only and MUST NOT be promoted as production authentication. The production account service must authenticate the buyer independently and bind acceptance to a short-lived, single-use transfer invitation credential. The service, not the phone, owns the atomic ownership transition and audit event.
