# Core engine completion audit


> Economy update: old money and cash-ceiling findings below are historical. [Economy revision 1](../ECONOMY.md) supersedes those rules.

**Date:** July 29, 2026
**Authority:** Active Xcode target and automated tests, not archived pre-refactor files

## Executive finding

The compact refactor is a playable core, not yet the complete game. Its foundation is substantially healthier than the archived engine: `LifeSimulator` is the mutation boundary, domain content is registry-backed, yearly logic is split into sovereign systems, runs are deterministic, and the dashboard follows the glance-to-action loop.

The largest remaining body of work is not another engine rewrite. It is controlled end-to-end integration of the archived feature domains into the new contracts, plus qualitative playtest and device-performance gates. Restoring old files wholesale would recreate the coupling this refactor removed.

## Current proof by requirement

| Requirement | Current evidence | Status |
| --- | --- | --- |
| Playable life loop | Creation → instant actions → yearly ticks → recovery/mortality → life review; deterministic complete-life tests | Proven for the compact core |
| DomainActionRegistry end to end | Every `ActionID` is uniquely registered, indexed by ID/domain, carries requirements/effects/narrative/preview metadata, and is executed in a valid fixture test; domain mutation completes before outcome prose is resolved | Proven for 20 core actions |
| Immediate action result | `execute(_:)` returns the same complete `ActionOutcome` published to the UI; domain mutation finishes before prose; reported deltas equal clamped state mutations; persistence is queued and coalesced to one running plus the latest snapshot; Points of Interest bracket both paths | Simulator probe is below budget; physical-device latency still needs profiling |
| System hibernation | Yearly mortality/social and instant progression/influence/social/recovery have explicit activation plans; empty effects short-circuit; irrelevant chapter actions stay off the UI surface | Proven by activation and RNG-stream tests |
| Narrative/vibe correlation | State-derived, seed-stable wording; choice echo; life-shape silence; partner/NPC context; 18 stage/collision storylets; and persisted anti-repeat memory | Core contract implemented; qualitative breadth gate remains |
| Persistence and seeding | Atomic versioned JSON, migrations/defaults, immutable run seed, advancing RNG state, deterministic replay tests, six-beat event memory, preserved corrupt/future-save recovery copies, and serialized abandon/reset ordering | Proven for one local save slot |
| Domain sovereignty | The simulator sequences but does not calculate instant effects, progression, influence, recovery, social response, storylet selection, or narrative flavor; canonical partner/job state reconciles compatibility flags instead of allowing two truths | Proven for current domains; archived domains are not integrated |
| Readable/playable UI | Individual VoiceOver vitals and outcome announcements; adaptive one-column actions at accessibility sizes; vertical overflow fallbacks; 44pt thumb tabs; locked-action disclosure; Reduce Motion handling | Separate 33/33 full UI bundles pass on iPhone 17 Pro Max and iPad mini Simulators; six focused Accessibility XXXL, Reduce Motion, and late-life-density journeys pass on iPhone 17e Simulator; the compiled landscape journey and physical-device gate remain pending |

## Remaining work size

### Gate 1 — Core performance and durability

- Enforce the numeric budgets in [CORE_PERFORMANCE_BUDGETS.md](CORE_PERFORMANCE_BUDGETS.md) with simulator and physical-device evidence.
- Keep the optimized native core probe green. The current 5,000-action/250-year-tick, persistence-inclusive evidence records action p95 at 121–138 μs and yearly-tick p95 at 510–654 μs; this isolates the simulator gate but does not replace physical-device ETTrace.
- Profile a lower-end supported device with signposts/Instruments.
- Keep the lifecycle-flush ordering regression green: it proves queued snapshots drain before the newest synchronous background/termination save and cannot overwrite it afterward.
- Keep the abandon ordering regression green: an explicit New Life drains older queued writes and clears last, so an abandoned run cannot resurrect.
- Keep the blocked-store coalescing regression green: rapid actions may retain one in-flight write and the newest queued snapshot, never every intermediate snapshot.
- Migration fixtures for versions 3–5 and future-version rejection are implemented; the full 188-test unit suite is green.

### Gate 2 — Narrative breadth and continuity

- The registry now has 18 storylets without raising interaction density; four explicit collisions connect work/home, money/trust, overtime/health, and career isolation/friendship.
- Vibe flavor now selects state-specific, seed-stable variants without consuming gameplay RNG or repeating a single mood suffix.
- Validate during play that the new variants are noticeable, coherent, and sufficiently broad across complete lives.
- Run seeded qualitative passes to identify the first boring/inconsequential year.
- For every completed human life, record what the player believes most shaped the outcome and whether Life Review agrees. Any mismatch must be resolved or explicitly validated before the ten-life gate can pass.

### Gate 3 — UI release quality

- Keep the compiled accessibility-XXXL, locked-action disclosure, Reduce Motion, and small-screen simulator journeys green; repeat them with VoiceOver and one-hand reach review on a physical device.
- Repeat the simulator-proven top-three late-life glance check with real players and VoiceOver on a physical device.
- Measure and fix any scroll or action-card occlusion on supported devices.
- The paired iPhone 16 Pro Max is on iOS 26.3 beta build 23D127 with Developer Mode enabled. Its last connected verbose check selected the current developer image and reported `kAMDMobileImageMounterDeviceLocked`; the latest check lists it offline and unavailable. Reconnect, unlock, and keep the phone awake before retrying the Release install/profile gate.

### Gate 4 — Feature-domain integration

Integrate one vertical slice at a time. Each imported domain must provide:

1. A pure data state owned by `LifeState`.
2. A sovereign system with an explicit activation rule in `SystemRegistry`.
3. Registry-backed actions with requirements, previews, deterministic effects, narrative/vibe output, and cross-domain deltas.
4. Versioned persistence/migration.
5. A glance-level UI summary and progressive disclosure.
6. Deterministic unit coverage, UI journey coverage, and a complete-life regression.

Recommended order: deeper Career/Finance → Family/Relationships → Assets → special careers (Founder/Athlete) → Crime/Politics. This maximizes reuse of the current core contracts before introducing rare paths.

### Gate 5 — Polish and playtest

- The reproducible native gate currently proves 360/360 seeded lives terminate, 360/360 exact replays match, all 270 policy comparisons diverge, all 90 social-policy lives form a relationship, and peak cash remains $7,711 (well below the $50,000 anti-exploit ceiling).
- Ten or more complete manual lives across origins and strategies.
- Require Grind, Social, and Survival coverage across that cohort; Mixed is informative but optional. A clean cohort does not need to invent a recurring defect.
- Confirm choices create materially different outcomes without a zillionaire exploit.
- Tune event frequency, economics, recovery, and mortality from recurring evidence.
- Only then declare the core integration-ready and begin expanding breadth at full speed.

## Scope conclusion

The engine foundation is close to integration-ready, but the product is not feature-complete. The remaining work is best understood as five release gates plus one vertical slice per archived domain—not as a monolithic refactor. The active core should remain small while domain breadth is rebuilt through the registry/system/persistence/UI contract above.
