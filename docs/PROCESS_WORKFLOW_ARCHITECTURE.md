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

### Reassign / sell an EFIS
Confirm current EFIS -> identify new owner -> buyer accepts ownership -> issue replacement licence -> install on EFIS -> verify new ownership.

This is the first reference implementation. Current seller-side initiation/cancellation is wired to the lifecycle service. Buyer acceptance remains implementation-pending in the backend/client and therefore appears honestly as an amber waiting stage rather than being simulated as complete.

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

New user-facing EFIS Service functionality must be designed as a process/state transition first. Adding a new collection of independent buttons or tabs requires an explicit diagnostic/advanced-use justification. Existing functional screens should be migrated behind guided workflows without removing their tested recovery value until the corresponding process has full acceptance coverage.

## Physical-iPhone reference validation

On 2026-10-05 EFISService was successfully built and code-signed for the paired iPhone 13 Pro Max, installed with bundle ID `uk.co.thingies.EFISService`, and launched on the physical device. `Set up a new EFIS` is now the second state-aware workflow after reassignment. Its progress is derived from real account recognition, ACTIVE entitlement, the protected signed-licence cache, and the explicit EFIS `VALID` installation acknowledgement.
