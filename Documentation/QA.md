# QA and release checks

## Automated

- Run all unit and UI tests with `xcodebuild test`.
- Run `Scripts/run_core_probe.sh`; it must terminate every seeded life, reproduce every replay exactly, diverge every strategy comparison, exercise relationship formation, remain below the anti-zillionaire ceiling, and return synchronous action outcomes.
- Exercise deterministic 50- and 80-year lives, rapid Age Up sequences, repeated event choices, recovery windows, min/max stats, cash floors, game-over boundaries, and save/load during active play.
- Confirm the same seed produces identical simulator state/history through dashboard and console paths.
- Run the accessibility-text journey at `UICTContentSizeCategoryAccessibilityXXXL`; creation must scroll, bottom domains and Age Up must remain hittable, and instant actions must collapse to one column.
- Run the locked-action disclosure journey; tapping a locked card must reveal its requirement and ripple details instead of becoming a dead control.

## Seeded release gate

Run the five scenarios in [SeededRunChecklist.md](Working/SeededRunChecklist.md) through both player surfaces before internal beta. The test suite mirrors their deterministic simulator coverage; the checklist captures UI parity and qualitative feedback.

## Manual

- Verify bottom controls and Age Up are reachable one-handed.
- Confirm VoiceOver traverses individual vitals (including the Health button), names domains/action requirements/Age Up, exposes the Show Preview custom action, and announces immediate outcomes.
- Enable Reduce Motion and confirm floating particles and press scaling are suppressed while feedback remains readable.
- Test corrupt/old saves and low-storage save failure: the valid existing save must not be silently overwritten.
- Confirm release builds have no console route or dead navigation paths.

## Current beta-readiness evidence — July 29, 2026

- 188/188 unit tests and 33/33 UI journeys pass on iPhone 17 Pro Max / iOS 26.4 Simulator; focused journeys also pass for terminal outcome assessment and creation-time cohort targeting with report-only strategy persistence.
- A separate clean iPad mini (A17 Pro) / iOS 26.4 Simulator bundle passes all 33 UI journeys. It covers centered-sheet scrolling, save/relaunch, playtest export, terminal outcome assessment, multi-property management, and the complete Assets purchase/rename/amenity journey at Accessibility XXXL.
- A compiled 34th journey rotates the declared supported interface to landscape and checks the late-life glance, all four domain controls, Age Up, and the Cash overview. Runtime proof is pending because every simulator is currently shut down; compilation alone does not count as a pass.
- Six focused journeys pass on the narrower iPhone 17e simulator: Accessibility XXXL creation and bottom controls, world recap, public-health care, the full Assets lifecycle, Reduce Motion particle suppression, and a pressure-heavy age-72 summary-density check.
- The optimized native core probe passes complete-life, replay, strategy-divergence, identity-balance, and latency gates.
- Physical iPhone 16 Pro Max validation is pending: the phone runs iOS 26.3 beta build 23D127 with Developer Mode enabled. Its last connected check reached the correct developer image but found the phone locked; the latest check now lists the phone offline and unavailable. Reconnect, unlock, and keep it awake before retrying.
- Manual seeded parity, accessibility review, tester sessions, and ten complete-life timing runs remain human gates; record them in [InternalBetaRunLog.md](Working/InternalBetaRunLog.md).
