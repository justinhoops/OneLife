# OneLife active implementation plan


> Economy update: pre-v33 money, financial recovery, and cash-ceiling results below are historical. [Economy revision 1](ECONOMY.md) supersedes those rules; use current economy verification for release decisions.

**Date:** July 11, 2026  
**Status:** Base sandbox completion active; Founder E1 paused until all sandbox phases pass

## High-level implementation sequence

This is the canonical order for additions after the current economy work. A later phase does not begin merely because its model can be scaffolded; the prior phase must meet its exit gate first.

1. **Economy and release proof — active.** Keep economy revision 1 green, complete the ten reviewed human lives, verify VoiceOver and one-hand reach on a physical device, and profile a lower-end supported device.
2. **Living Cast presentation — first slice delivered.** The Love tab now exposes a compact People glance and read-only detail flow for the three people shaping the current chapter, the wider dormant circle, active pressure, learned traits, goals, connections, and remembered moments. Additional authored situations remain evidence-gated.
3. **Founder E1 — locked.** After the base-sandbox gates pass, Founder is the first complete special-career vertical slice: dedicated state, stage progression, instant actions, failure/recovery, family and health cost, exit, and Life Review payoff.
4. **Later-life depth.** Extend retirement identity, mentorship, grief, widowhood, grandparenthood, declining independence, and end-of-life priorities through the domains that already own them.
5. **Location and mobility.** Add moving, regional costs, commute pressure, neighborhood quality, proximity to family, and healthcare access through World + Assets rather than a new top-level tab.
6. **Lifelong education.** Add certification, community-college, employer-supported learning, failed retraining, and midlife conversion through Education + Career.
7. **Additional special careers.** Athlete follows Founder as the physical/high-variance contrast; Politics and Crime remain deferred until each can support dedicated state, recovery, post-career identity, and full cross-domain consequences.

Every slice must preserve deterministic replay, versioned persistence, domain ownership, state-contingent hibernation, the four-tab shell, and the summary-to-action interaction density.

The current goal is a proven 30–45 minute life from creation → telegraphed death → review → replay, with player-defined success, viable hybrid strategies, complete existing-domain lifecycles, and understandable recovery. Preserve the thin simulator boundary, glance rule, thumb ergonomics, and instant/yearly boundary. [Base Sandbox Completion](BASE_SANDBOX_COMPLETION.md) is the active phased gate. **Founder E1 stays paused** until all five phases pass.

## Delivered foundation + complete arc

- Dashboard shell: Stat Island, stage strip, What Matters, pressures, 2-col instants, Age Up, journal, terminal review.
- `DomainActionRegistry` + once-per-age usage (recovery exceptions).
- Life stages Launch → Build → Pressure → Legacy with headline transitions.
- Sovereign systems: Progression, Finance, Health, Mortality (+ Social).
- Deterministic seeded simulation, persistence with migrate defaults, recovery, mortality pressure, end reasons, life review model.
- Unit suite green including complete-life termination across origins/strategies.

## Chapter content slice (done)

- Stage-weighted storylets (Launch→Legacy) with concrete Voice + Echo prefixes.
- Post-school Skills actions (Network / Side hustle / Skill course); School tab label swaps.
- What Matters rows tappable → domain + suggested instant; Recovery Stabilize CTA.
- UI harness flags: `-uiTestPostSchool`, `-uiTestForceEnding`; unit coverage for skills + chapters + echo.

## Playtest gate (before Founder)

- Manual: ≥10 complete runs; median 30–45 min; no dead-ends; next action clear in 2s.
- Outcomes differ across Balanced / Academic / Social and grind vs social strategies.
- Then resume Founder E1.

## Founder revival — E1 (PAUSED)

**Goal:** Make Founder/CEO lives feel like a distinct high-stakes chapter without adding a new simulation domain.

### E1.1 — Core model and yearly resolve

- Add `FounderState` to the existing special-career state model.
- Track vision, execution, team health, product stage, personal legend, company culture, mental load, and competitive moat.
- Seed Founder state from existing dossier/early-stance inputs.
- Add stage progression, crises, board pressure, scaling dynamics, and exit paths to the yearly resolver.
- Expose compact Founder metrics in the existing Occupation UI.

### E1.2 — Instant and momentum integration

- Add `closeMajorDeal`, `aggressiveExpansion`, `keyHire`, `cultureReset`, `mediaSpotlight`, and `pivotBusiness` through the existing action registry.
- Route each action through the established instant-reaction pipeline.
- Add autonomous reactions for morale, investor attention, mental load, and family ripple.
- Let momentum influence execution/traction or board pressure without bypassing requirements.

### E1.3 — Follow-up after E1 validation

- Add founder-specific narrative voices and D4/resilience flavor.
- Feed personal legend into the existing Fame Web.
- Add founder legacy flags and family spillover notes.

E1.3 starts only after E1.1/E1.2 compile, play, and pass deterministic verification.

## Parallel launch work

- Finish discoverability micro-affordances and late-game compaction.
- Strengthen terminal life and legacy payoff.
- Run seeded dashboard/console parity and internal beta checks.
- Profile on a lower-end supported device after the Founder slice is stable.

## Explicit deferrals

Extra careers, new simulation domains, expanded family systems, assets, social graphs, networking, cloud saves, and analytics remain out of scope for this slice.

## Status update rule

After each focused slice, update this file and the relevant permanent inventory with a `COMPLETE` block, player impact, verification evidence, and any known follow-up.

## COMPLETE — Phase 1 sandbox diagnostics (July 28, 2026)

**Player impact:** Instrumented tester lives now produce comparable evidence about dominant routines, action variety, domain neglect, passive years, and failure recovery without adding a player-facing chore or changing simulation outcomes.

**Architecture:** The existing playtest source captures its action domain at record time. `PlaytestRunReport` derives sandbox diagnostics from its immutable moment history; analysis does not mutate state, query live gameplay state, or consume RNG. Old reports without the new optional domain field continue to decode.

**Verification:** App, unit-test, and UI-test products build for both simulator architectures. Focused resume/export and sandbox-diagnostic tests pass. The native probe terminates 360/360 lives with zero replay failures and 270/270 strategy divergence. Performance timings from that run are not release evidence because other Xcode workloads were active concurrently.

**Evidence gate:** Human review remains 0/10. Phase 2 balance changes must be selected from a weakness recurring in at least two independent reports.

## COMPLETE — Phase 1 cohort gate (July 28, 2026)

**Tester impact:** Debug Playtest Notes now records the intended Grind, Social, Survival, or Mixed approach and can export a combined ten-life gate summary. The summary reports unique completed lives, origin/style coverage, median duration, recurring evidence, and the exact requirements still preventing Phase 2.

**Architecture:** Declared style is optional report-only schema v8 metadata. Cohort analysis reads the bounded completed-report directory, deduplicates by run seed, and groups warnings and annotations by independent seed, age, and captured owning domain. It has no dependency on `LifeState`, gameplay persistence, or RNG.

**Verification:** An isolated simulator test build succeeds. Focused resume/export, sandbox diagnostic, backward-compatibility, and synthetic ten-life cohort tests pass. The native probe still terminates 360/360 lives, reports zero replay failures, and diverges 270/270 strategies.

**Evidence gate:** The real cohort remains 0/10. Synthetic reports verify the gate mechanics only; they do not count as human playtest evidence.

## COMPLETE — Phase 3 Career lifecycle slice (July 29, 2026)

**Player impact:** Leaving a career now creates a real transition instead of a disguised job swap. The old job ends immediately, the player chooses a new direction, and a separate seeded job search determines whether work is actually found. Ordinary careers can also plateau and reach retirement without a forced spectacular success or failure.

**Architecture:** Career owns track, level, transitions, and employment synchronization. The action registry owns the pivot's cash effect, eliminating the former second domain-side charge. A typed requirement prevents job search before a direction is chosen; `LifeSimulator` remains the orchestrator.

**Verification:** The simulator test product builds and all 150 unit tests pass. New coverage exercises one-cost pivoting, direction and search ordering, uncertain re-entry, flag synchronization, persistence, ordinary plateau, retirement, and continuation through a complete life. The native probe terminates 360/360 lives, replays with zero failures, and diverges all 270 strategy comparisons; personality, talent, and world comparisons each diverge 30/30.

**Known follow-up:** Phase 3 is not complete. Household finance is completed in the following slice; relationship/family, health, assets/housing, and legal/world parity remain pending. Phase 2 balance tuning still requires repeated human evidence and cannot be inferred from synthetic lives.

## COMPLETE — Phase 3 Household-finance lifecycle slice (July 29, 2026)

**Player impact:** Retirement saving now has an actual late-life purpose. Contributions stop after retirement, the balance supplies a bounded annual draw, and the yearly summary names that draw. A funded retiree can cover an ordinary gap; an unfunded retiree still feels it. Existing debt, delinquency, sale/downsize, and financial-recovery paths complete the surrounding lifecycle.

**Architecture:** `FinanceSystem` remains sovereign over the annual ledger, retirement balance, and withdrawal calculation. Assets supply a read-only financial snapshot and separately own mortgage principal and delinquency. The simulator only sequences those results and opens typed consequences.

**Verification:** All 151 unit tests pass, including funded/unfunded retirement, canonical cash/equity, property delinquency, financial recovery, persistence, and complete-life termination. The native probe terminates 360/360 lives with zero replay failures, 270/270 strategy divergence, and 30/30 divergence for personality, talent, and world comparisons. Maximum observed cash remains $7,711.

**Known follow-up:** Relationships and family are completed in the following slice. Phase 2 still remains human-evidence gated.

## COMPLETE — Phase 3 Relationships-and-family lifecycle slice (July 29, 2026)

**Player impact:** Players can explicitly choose a childfree future without the game treating it as failure, reverse that intention before parenthood, and see it acknowledged in Life Review. Relationships that end now remain part of the life instead of disappearing. Caregiving names the relative involved and can resolve as a season, while children report and retain their adult outcomes.

**Architecture:** `RelationshipSystem` is the single ending/archive path used by player separation and partner rupture. Save v27 adds a bounded former-relationship ledger with neutral v26 migration. `FamilySystem` owns child and caregiving transitions; Finance remains the sole owner of annual dependent cash costs, eliminating the previous duplicate family charge.

**Verification:** The app and test products build, and all 157 unit tests pass. Coverage includes explicit/reversible childfree intention, parenthood locking, both relationship-ending paths, v26 migration, persistence and Life Review, named caregiving resolution, readable adult-child transitions, one-time dependent costs, existing repair/ultimatum behavior, and complete-life termination. The native probe terminates 360/360 lives with zero replay failures, 270/270 strategy divergence, and 30/30 personality, talent, and world divergence. Maximum observed cash remains $7,711.

**Known follow-up:** Physical and mental health are the next Phase 3 lifecycle audit. Phase 2 remains gated on ten human playtest reports.

## COMPLETE — Phase 3 Physical-and-mental-health lifecycle slice (July 29, 2026)

**Player impact:** Chronic illness now has a future the player can change without turning it into a cure fantasy. Consistent management can make a condition stable, easing body load and suppressing active-symptom events; letting maintenance lapse can reactivate it. Condition damage is included in the yearly result, health crises require real canonical recovery before aging resumes, and Life Review remembers whether chronic conditions ended active or stable.

**Architecture:** `HealthState` remains the sole owner of physical wellbeing, mental wellbeing, body load, addiction pressure, and conditions. `ConditionHealthSystem` owns discovery, management, stability, deterioration, and typed relapse consequences; `HealthSystem` owns yearly drift and recovery thresholds. `LifeSimulator` only sequences the results. Save v28 adds condition status with neutral v27 migration.

**Verification:** The app and test products build, and all 161 unit tests pass. New coverage proves canonical drift/self-care through clamping, stable-to-relapse behavior, health-recovery action mixes, v27 migration, persistence, and Life Review payoff. The optimized probe terminates 360/360 sampled policy lives with zero replay failures, 270/270 strategy divergence, and 30/30 personality, talent, and world divergence; its 10,000-life personality balance gate also passes. Maximum observed cash remains $7,711.

**Known follow-up:** Assets and housing are the next Phase 3 lifecycle audit. Phase 2 remains gated on ten human playtest reports.

## COMPLETE — Phase 3 Assets-and-housing lifecycle slice (July 29, 2026)

**Player impact:** Home ownership can now end cleanly or badly and the life remembers which. Recovering cash unwinds delinquency gradually; four sustained delinquent years end in foreclosure with no recovered equity. Voluntary sales and forced exits both remain visible in the Assets sheet and Life Review.

**Architecture:** `AssetSystem` remains sovereign over ownership, value, mortgage principal, amenities, delinquency, sale, foreclosure, and bounded property history. Finance consumes an immutable asset snapshot and receives foreclosure pressure only through a typed consequence. Save v29 adds neutral property-exit history.

**Verification:** All 164 unit tests pass on a clean rerun. New coverage proves gradual delinquency recovery, remembered foreclosure, sale/history persistence, Life Review payoff, v28 migration, and asset hibernation. The optimized probe terminates 360/360 lives, replays without failure, diverges 270/270 strategies plus 30/30 personality, talent, and world comparisons, and passes the 10,000-life personality balance gate. Maximum observed cash remains $7,711.

## COMPLETE — Movable asset lifecycle and social consistency pass (September 27, 2026)

Movable assets now share one finance-first lifecycle: acquisition, resale, condition, legal exposure, gifting, rare loss, liquidity, and bounded Life Review history. Vehicles, firearms, jewelry, and other movable assets do not add recurring ownership bills. Housing remains the recurring-cost domain through rent, operations, mortgage obligations, and amenity upkeep, with property appreciation preserved through market adjustments and world modifiers.

Vehicle total-loss replacement still uses the existing 55% abstract catastrophic-loss settlement; no insurance premiums, policy state, or claims domain is introduced. Gifts remain history-only for recipients, preserve transferred firearm details, improve relationships, and create bounded future reciprocity without immediate cash. Persistent NPC asset inventories and property gifting remain deferred.

Criminal asset management remains intentionally layered: operational equipment, safehouses, and front businesses belong to the criminal-path state and affect operation risk, concealment, storage, planning, heat, and organization cash flow. Personal firearms, vehicles, and jewelry remain owned by Assets; Crime reads their consequences without creating duplicate inventories or recurring ownership bills.

**Known follow-up:** Legal and world pressure are completed in the following slice. Phase 2 remains gated on ten human reports.

## COMPLETE — Phase 3 Legal-and-world-pressure lifecycle slice (July 29, 2026)

**Player impact:** The narrow legal behavior already in the base game now has an end state: abandoning risky firearm exposure lets heat decay and supervision progress, while renewed exposure stops clean-year progress. Active supervision can end, but the felony record and its life consequences are not erased. Life Review also closes both remembered world shifts and any pressure still active at death.

**Architecture:** `LegalSystem` owns heat, record, supervision, and its dedicated RNG; it emits typed Career, Finance, and Relationships consequences and never mutates those domains. `WorldSystem` continues to own seeded macro, price, and public-health transitions and exports immutable modifiers. Save v30 adds neutral legal-supervision state; `LifeSimulator` only sequences confiscation and consequence opening/resolution.

**Verification:** The final 173-test suite passes with no skips or expected failures, including exposure-gated supervision, legacy migration without RNG changes, permanent-record review, current/recorded world payoff, and the repaired queued-persistence ordering fixture. The post-v30 optimized probe ends 360/360 lives, diverges 270/270 strategies, and reports zero replay failures.

**Known follow-up:** Phase 3 implementation is complete. Phase 4 now audits typed consequence/recovery coverage. Phase 2 still requires ten human reports and cannot be closed by automated fixtures.

## COMPLETE — Phase 4 consequence and recovery web (July 29, 2026)

**Player impact:** Work burnout, debt, illness, caregiving, housing instability, and a felony record now continue into the parts of life they plausibly constrain. Recovery has a visible price and a changed future: boundaries cost performance, thin cash may not immediately cure delinquency, care consumes household capacity, and separation preserves the relationship that ended while allowing another to begin. Life Review names unresolved burdens instead of silently dropping them.

**Architecture:** Source systems emit typed, bounded `DomainConsequence` values and do not mutate their receivers. Career, Finance, Health, Family, Assets, and Legal consume only pressure addressed to their owned state; World remains an immutable policy-modifier source. `LifeThreadSystem` deduplicates, selectively stabilizes by source/target, expires, and caps the live web at three threads. `LifeSimulator` only sequences these results.

**Verification:** All 173 unit tests pass with no skips or expected failures. Coverage proves every new handoff, receiver sovereignty, selective recovery, changed relationship futures, unresolved-burden review, thread caps, persistence ordering, and complete-life termination. The optimized probe ends 360/360 lives, produces 270/270 strategy divergences, reports zero replay failures, and diverges personality/talent/world axes 30/30 each. Its 10,000-life personality balance gate passes; maximum cash remains $7,711. Action latency is p50 78,208 ns, p95 112,458 ns, p99 190,041 ns; yearly ticks are p50 425,292 ns and p95 457,709 ns.

**Known follow-up:** Phase 5 now owns identity, legacy, accessibility, device, and release proof. Phase 2 remains at 0/10 human reports; automation does not satisfy that gate.

## IN PROGRESS — Phase 5 identity, legacy, and release proof (July 29, 2026)

**Player impact:** Repeated connection choices now produce a recognizable People-centered life alongside Driven, Careful, Loose, Pragmatic, and Balanced lives. Year summaries distinguish quiet, notable, major, and critical developments with typed deltas and world context, while Life Review connects personality movement, relationships, pivotal events, housing history, and unresolved burdens into one explanation of the life.

**Architecture:** `YearSummarySystem` distills domain-owned results into persisted presentation data; SwiftUI only renders it. Save v32 migrates recorded summaries without recalculating gameplay. Life-shape derivation remains state-based and does not introduce a new mutable domain. Assets owns the rental-property lifecycle and exports a financial snapshot to Finance rather than mutating Finance directly.

**Verification:** The current sequential iPhone 17 Pro Max simulator baseline passes all 188 unit tests with no skips or expected failures. The save-v32 optimized probe ends 360/360 lives, diverges 270/270 strategies, reports zero replay failures, diverges personality/talent/world axes 30/30 each, passes the 10,000-life identity balance gate, and keeps peak cash at $7,711. The corrected persistence-inclusive benchmark samples every action deeply instead of ranking cold-queue outliers; quiet-host repeats report action p95 of 121,125–137,667 ns and yearly p95 of 510,083–653,750 ns. Separate clean, sequential iPhone 17 Pro Max and iPad mini (A17 Pro) simulator bundles each pass all 33 UI tests with zero failures. The iPad pass covers centered-sheet scrolling, save/relaunch, playtest export, terminal outcome assessment, multiple-property management, and the full Assets purchase-and-amenity journey at Accessibility XXXL. Focused creation and ending journeys separately pass cohort-target persistence and structured outcome assessment. Six focused iPhone 17e journeys pass across the current result bundles: Accessibility XXXL creation and bottom-control reach, world recap, public-health care, the full Assets lifecycle, Reduce Motion particle suppression, and a pressure-heavy age-72 glance-density gate that keeps all three priorities above the fixed thumb controls without scrolling.

**Known follow-up:** Simulator small-screen, Reduce Motion, portrait late-life density, creation-time cohort targeting, and terminal outcome-assessment proof is green. A compiled 34th journey now covers the target's declared landscape orientation, but it has not run because every simulator is shut down. The paired iPhone 16 Pro Max is on iOS 26.3 beta build 23D127 with Developer Mode enabled; its last connected check reached the current developer image but found the phone locked, and the latest check lists it offline. Landscape runtime, physical-device accessibility/performance, and ten reviewed human lives therefore remain open. Reconnect, unlock, and keep the phone awake for the next device run; the recorder already captures explanation agreement and recommends the next missing coverage run directly, but Phase 2 remains at 0/10 human reports, so the expansion lock stays in force.

## COMPLETE — Unified seeded life differentiation (July 25, 2026)

**Player impact:** Random Life now previews a complete shareable-seed identity and world before commitment; Custom Life offers templates, one defining trait, and an optional aptitude without stat allocation. The same five-axis personality model drives the player, partner, friend, teacher, and boss. Choices accumulate bounded personality movement, relationship state stays sovereign, world/talent/personality causes appear in previews, and life review closes the starting-to-final identity arc.

**Architecture:** Save v22 persists personality profiles and independent domain RNG lanes. Generic reaction rules and validated bundled events consume one read-only signal snapshot covering axes/flags, target role, stance, talent, world, stage, domain states, and stats. Bundled and Swift events share eligibility, weighting, cooldown, seeded selection, and result application. There are no model calls, networking, credits, or player-data transmission.

**Verification:** The simulator build and complete unit suite pass, including 1,000-seed generation distribution, ~25% talent incidence, custom trait strength, gradual development, hibernation, stream independence, bundled-content validation, v21 migration, relationship targeting, and exact persistence. Focused Random/Custom/Identity UI journeys pass. The optimized probe terminates 360/360 lives, replays with zero failures, diverges 270/270 strategies plus 30/30 personality, talent, and world comparisons, and keeps peak cash below $10,000.

**Known follow-up:** Multiple simultaneous friends/coworkers, a full social graph, and the four special-career implementations remain separate domain slices. Talents are useful aptitudes and extension points today; they do not claim those careers already ship.

## COMPLETE — End-to-end core life

**Player impact:** A life now progresses from Launch through Build, Pressure, and Legacy, with once-per-age actions, stage-specific economics and health pressure, recovery crises, telegraphed mortality, guaranteed termination, and a structured life review. The dashboard surfaces the current stage and three most important priorities while keeping immediate actions above supporting detail.

**Verification:** Release simulator build succeeded. All 32 unit tests pass, including seeded complete-life termination, stage boundaries, mortality pressure, recovery, persistence, and anti-farming coverage. All three UI flows pass; the partner-confrontation flow was reverified after restoring action visibility above secondary dashboard context.

**Known follow-up:** Validate the 30–45 minute target through ten manual complete-life playtests and tune event frequency/economic pressure from observed run data. Founder E1 remains paused until that qualitative gate is complete.

## COMPLETE — Core engine contracts (July 17, 2026)

**Player impact:** Core actions now return their outcome before persistence work, wrong-chapter actions no longer crowd the grid, every bottom-tab tap returns the player to the selected action surface, and the UI communicates a compact state-derived vibe. Starting seed identity survives the advancing RNG state, while recent event memory prevents immediate storylet repeats.

**Architecture:** `DomainActionRegistry` is indexed and exhaustively validated. `SystemRegistry` keeps progression, finance, health, and influence active while mortality and social hibernate until relevant. Saves are serialized off the interaction path and lifecycle flushes cannot be overwritten by older queued snapshots.

**Verification:** Current regression evidence supersedes the original checkpoint: 188 unit tests and 33 UI journeys pass, the Release simulator build succeeds, and the optimized native core gate passes 360 complete lives and exact replays, 270/270 strategy divergences, relationship traversal, and the persistence-inclusive action/yearly latency budgets. See [CORE_ENGINE_COMPLETION_AUDIT.md](Working/CORE_ENGINE_COMPLETION_AUDIT.md) for the remaining physical-device and human gates.

**Known follow-up:** Numeric budgets and Points of Interest instrumentation are defined; migration fixtures cover versions 3–5 plus future-version rejection; accessibility layouts, VoiceOver semantics, locked-action disclosure, Reduce Motion behavior, and deterministic narrative breadth are implemented with compiled journeys. ETTrace/runtime accessibility evidence, qualitative narrative passes, manual playtests, and one-by-one archived-domain integration remain required before calling the whole game polished.

## COMPLETE — Internal beta code readiness (July 18, 2026)

**Player impact:** Career advancement now reports both the earned skilled-work milestone and any NPC reaction. Engaged students have through age 24 to finish a credential instead of being forced out at 22 with partial progress. The dashboard restores summary-to-action ordering by placing instant actions ahead of pressure detail and first-run teaching.

**Verification:** All 56 unit tests and seven UI journeys pass on the iPhone 17 / iOS 26.4 simulator. Debug tests and the Release simulator build succeed. The optimized native gate terminates 360/360 lives with zero replay failures, diverges 270/270 strategy comparisons, keeps maximum peak cash at $9,983, samples all 20 synchronous actions, and reports 100 warmed yearly ticks.

**Known follow-up:** The paired iPhone 16 Pro Max is currently locked, so iOS rejects Xcode's selected developer-image mount and physical-device VoiceOver, Reduce Motion, reachability, save/relaunch, and ETTrace evidence remain open. Unlock and keep the phone awake for the next device run. Local tester sessions and ten complete manual lives have not yet occurred. Founder E1 stays paused.

## COMPLETE — Instrumented playtest checkpoint (July 18, 2026)

**Player impact:** Debug runs launched with `-playtest` capture the complete uncapped action/year/event timeline, accept age-linked boring/weak/confusing annotations, resume after relaunch, and export local JSON plus Markdown from the menu or terminal review. Release builds expose no playtest UI.

**Verification:** Recorder-on and recorder-off seeded lives remain identical. Persistence resume, export round-trip, timelines beyond 40 moments, abandonment/finalization, 20-report retention, the playtest UI journey, all 67 unit/UI tests, Release build, and the 360-life optimized probe pass.

**Evidence gate:** 0/10 reviewed manual exports exist. Career/Finance Checkpoint 2 remains intentionally blocked until ten complete reports satisfy the documented origin/style mix and recurring observations are identified.

## COMPLETE — Glance-and-response polish (September 24, 2026)

**Player impact:** Character creation now opens with the game’s identity instead of a generic symbol. The action surface distinguishes ready, used, and locked moves; the thumb-zone tabs show an unmistakable selection; and Age Up previews the next age and current yearly cash forecast. Pressure chips now open a compact explanation with up to three immediate response options, completing the intended glance → inspect → act path without adding a separate management screen.

**Architecture:** The pass is presentation-only. Pressure inspection consumes existing `DomainPressure`, action-registry, availability, and economy-forecast queries; it does not calculate or mutate domain logic outside `LifeSimulator`’s established action boundary.

**Verification:** The app builds successfully for the iPhone 17e simulator target, and the complete unit/UI test bundles compile for generic iOS Simulator. Runtime visual and interaction proof remains pending because no simulator was booted during this pass.
