# Work Since GitHub Download

Baseline: `origin/main` at commit `30f75f3`.

## Completed

- Stabilized the launch-ready app and release setup.
- Audited order flows and added offline sharing and order tracking.
- Corrected debug-banner behavior.
- Added persisted per-person payment tracking.
- Added paid checkmark avatar status.
- Moved payment toggling to double-tap on the person card.
- Restored the default card frame for paid cards.
- Muted paid details and added a total strikethrough.
- Lightened the paid-state gray and neutralized the paid “Your share” amount.
- Added the remaining unpaid balance beside “Who ordered what”; it includes all extras and subtracts paid people.
- Added Arabic localization and regression coverage for the payment and remaining-balance behavior.

## Current Verification

- `flutter analyze` passes.
- Full `flutter test` passes with 141 tests.
- Current `master` is pushed through commit `56d5c53`.
