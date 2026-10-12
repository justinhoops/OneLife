# Base Sandbox Completion


> Economy update: pre-v33 money, financial recovery, and cash-ceiling results below are historical. [Economy revision 1](ECONOMY.md) supersedes those rules; use current economy verification for release decisions.

**Status:** Active before special-career or new-domain expansion  
**North star:** Ten reviewed lives, six recognizable life shapes, zero universal action loops

One Life is a finite-life sandbox. Death ends a run, but the simulation does not define a winning career, household, wealth target, personality, or relationship path. Failure changes the life that remains available; it does not invalidate the run.

## Improvement rule

Every change follows the same loop:

1. Observe complete lives and collect comparable evidence.
2. Select the most frequent player-experience weakness.
3. Assign the change to one sovereign domain.
4. Implement the smallest complete vertical slice.
5. Connect at most two typed downstream consequences.
6. Verify deterministic replay, persistence, UI clarity, and complete-life behavior.
7. Replay the same seeds and retain the change only when agency improves without added chore density.

Except for crashes, data loss, inaccessible controls, and dead ends, a systemic balance change requires the same weakness in at least two independent human runs.

## Phase 1 — Sandbox baseline and evidence

**Goal:** Establish what players actually repeat, neglect, misunderstand, and fail to recover from.

**Implementation status:** Diagnostic pipeline complete; human evidence gate remains 0/10.

Delivered instrumentation:

- Playtest sources retain their action domain without consulting the live registry during report analysis.
- Testers declare Grind, Social, Survival, or Mixed intent as debug-only report metadata; it never enters the gameplay save.
- Markdown exports summarize proactive and unique actions, the most-used action share, consecutive repetition, domain engagement, passive years, and recovery resolution.
- Automatic warnings flag a dominant action at 35% or more of at least 12 proactive actions, four-action streaks, untouched domains, at least 20% passive years, and unresolved recovery arcs.
- A cohort summary deduplicates completed lives by seed, checks origin/style mix and median duration, and groups recurring warnings or annotations by seed, age, and owning domain.
- The cohort supplies an explicit Phase 2 readiness verdict and lists each unmet requirement instead of silently treating incomplete evidence as a pass.
- Debug life creation derives the next missing origin/style target from completed reports, preselects that origin and style, and records the style when the life starts. The recommendation follows the real gate—three of each origin, ten total, and one each of Grind, Social, and Survival—without making Mixed mandatory.
- Analysis is derived from recorded moments and cannot mutate gameplay state or consume RNG.

Verification:

- Debug app, unit-test, and UI-test products build for both simulator architectures.
- Focused resume/export, sandbox-diagnostic, report-compatibility, and ten-life cohort tests pass on iOS Simulator.
- The native matrix still terminates 360/360 lives, replays with zero failures, and diverges all 270 strategy comparisons.

Exit gate:

- Ten complete exported reports: at least three Balanced, three Academic, three Social, and one additional origin.
- Grind, Social, and Survival play styles are represented; Mixed is optional exploratory evidence.
- Median run length is 30–45 minutes.
- Every recurring warning or player annotation is grouped by seed, age, and owning domain.
- The first Phase 2 target is chosen from evidence repeated in at least two lives.

## Phase 2 — Choice balance and viable hybrids

**Goal:** Remove universal routines without replacing them with rigid strategy classes.

Work is selected from Phase 1 evidence. Likely interventions include situational requirements, opportunity costs, diminishing contextual value, world sensitivity, or clearer previews. Personality changes expression and tradeoffs; it does not become an action lock.

Exit gate:

- No proactive action exceeds 35% across the reviewed report set unless it is a temporary recovery verb.
- Balanced, Grind, Social, Survival, and at least two mixed approaches remain viable.
- Replaying the same seeds shows intentional divergence without breaking exact same-input replay.
- No fix increases required taps or creates a maintenance chore.

## Phase 3 — Existing-domain lifecycle parity

**Goal:** Give every shipped domain an entry, development, disruption, recovery, and resolution arc.

**Implementation status:** Complete for every currently shipped domain. See [Base Domain Lifecycle Matrix](BASE_DOMAIN_LIFECYCLES.md). Phase 2 remains separately gated on 10 human reports and is not inferred from automated runs.

Order:

1. Career and household finance
2. Relationships and family
3. Physical and mental health
4. Assets and housing
5. Legal and world pressure

Each slice supplies sovereign state and processing, explicit activation, registered actions, persistence migration, glance-level UI, progressive disclosure, deterministic tests, and a complete-life regression. No new top-level domain is introduced.

Exit gate:

- Each lifecycle can be traversed through success, stagnation, failure, and recovery fixtures.
- No required transition exists only in narrative text or compatibility flags.
- Background systems hibernate when inactive.

Career slice delivered:

- A pivot clears the old job and direction immediately without double-charging its cost.
- A new direction is chosen before job search, and choosing it no longer grants work automatically.
- Seeded job-search uncertainty, ordinary plateau, retirement, persistence, and terminal-life continuation have regression coverage.

Household-finance slice delivered:

- Existing solvency, debt pressure, delinquency, recovery, and liquidation paths are covered as one lifecycle.
- Retirement contributions stop after work, and accumulated savings become bounded, player-readable annual income.
- Funded retirement can cover an ordinary shortfall; an unfunded retirement retains real financial pressure.

Relationships-and-family slice delivered:

- Childfree life is an explicit path rather than an unreachable modeled state.
- Separation and rupture preserve bounded former-relationship history through persistence and Life Review.
- Named caregiving pressure can ease, and child adulthood becomes a visible, persisted transition.
- Dependent costs are charged once by Finance; Family retains time pressure without a duplicate cash penalty.

Physical-and-mental-health slice delivered:

- Health changes from yearly drift, self-care, professional care, conditions, and events land in one canonical Health state and remain synchronized with the glance stat.
- Condition deterioration is included in the yearly outcome rather than hidden from the player.
- Ongoing management can stabilize a chronic condition; neglected maintenance can reactivate it through a typed illness consequence.
- Stable and active condition status persists in save v28, appears in the Health sheet, and closes in Life Review without pretending chronic illness was erased.
- Health recovery requires enough physical/mental margin before aging resumes, and the unresolved-crisis ending remains intact.

Assets-and-housing slice delivered:

- Purchase, mortgage principal, property costs, amenities, sale, and bounded ownership history form one persisted arc.
- Delinquency eases one year at a time when cash recovers instead of disappearing immediately.
- Four sustained delinquent years end in foreclosure, erase trapped equity, emit a typed Finance consequence, and remain visible in Life Review.

Legal-and-world-pressure slice delivered:

- The shipped legal scope now resolves from illicit-firearm exposure through confiscation, felony record, bounded supervision, clean years, and completion after exposure ends.
- The permanent record remains after active supervision, affects Career through a typed consequence, persists in save v30, and closes in Life Review.
- Seeded macro, price, and public-health pressures already transition, recover, expire, and hibernate through world-owned state. Life Review now closes both recorded shifts and any condition still active at death.

## Phase 4 — Consequence and recovery web

**Goal:** Make existing systems combine into emergent lives while preserving domain sovereignty.

**Implementation status:** Complete in code and automated verification. Human Phase 2 evidence and Phase 5 device/accessibility proof remain separate gates.

Priority handoffs:

- Career → Health, Finance, Relationships
- Finance → Housing, Relationships, Health
- Health → Career, Finance, Family
- Family → Career, Finance, Health
- World → Career, Housing, healthcare access
- Legal → Career, Finance, Relationships

Every source emits a typed consequence. Only the receiving domain mutates its state. Recovery costs time, money, opportunity, trust, or identity and creates a changed future rather than restoring an earlier snapshot.

Delivered consequence web:

- Career burnout opens bounded Health and Relationships pressure; those receivers own the resulting health, trust, and capacity effects. Protecting boundaries stabilizes only Career burnout and costs performance.
- Finance debt/stress opens Relationships, Assets, and Health pressure. Housing recovery reads that pressure and can remain delinquent even when a thin cash margin returns.
- Low Health opens Career and Family capacity pressure. Professional care selectively stabilizes health-targeted illness, burnout, or debt threads instead of erasing unrelated history.
- Sustained Family caregiving opens Health, Career, and Finance pressure. Active illness prevents caregiving from disappearing in the same yearly pass; care can ease after the illness pressure resolves.
- World pressure continues through immutable labor, housing-cost, and healthcare-access modifiers owned by the Policy domain.
- A felony record opens Career, Finance, and Relationships pressure while Legal remains the sole owner of record, heat, and supervision.
- Separation preserves the former relationship and permits a different future rather than restoring the prior partner state.
- Life Review names up to three unresolved cross-domain burdens with destination and remaining window.

Exit gate:

- Every handoff has deterministic cause, receiving-domain effect, player-readable explanation, and expiry or resolution.
- At most three unresolved continuity threads remain active.
- Complete lives demonstrate recovery from unemployment, debt, illness, separation, education setbacks, and housing pressure without guaranteed restoration.

Automated evidence:

- All 188 unit tests pass with no skips or expected failures on the current save-v32 source.
- The current save-v32 optimized matrix ends 360/360 lives, produces 270/270 intentional strategy divergences, and has zero replay failures.
- Personality, talent, and world comparisons each diverge 30/30; the 10,000-life personality balance gate passes with 71.99% identity retention and 88.89% preference divergence.
- Peak observed cash remains $7,711. The corrected persistence-inclusive benchmark warms every action, drains background saves outside the timed interval, and samples 5,000 actions plus 250 yearly ticks. Across quiet-host repeats, action p95 is 121,125–137,667 ns and yearly p95 is 510,083–653,750 ns. The earlier apparent caregiving regression was measurement noise caused by cold per-sample queues and competing background commits. Physical lower-end-device proof remains a separate Phase 5 gate.

## Phase 5 — Identity, legacy, and release proof

**Goal:** Ensure the game remembers the life the player remembers and is durable on supported devices.

**Implementation status:** Code-side identity, summary, runtime, and simulator UI proof are complete. The sandbox now derives six ordinary-life shapes, including a distinct People-centered life, and Life Review closes repeated choices, defining relationships, personality movement, turning points, housing history, and unresolved continuity pressure. The current 188-test unit baseline, exhaustive optimized probe, clean 33-test iPhone and iPad UI bundles, and six focused narrow-device accessibility, motion, and density journeys pass. This phase is not complete: explanation agreement, ten reviewed human lives, physical-device accessibility/reachability, and lower-end-device performance remain open evidence gates.

Delivered code-side proof:

- Six life shapes emerge from repeated universal choices: Driven, People-centered, Careful, Loose, Pragmatic, and Balanced.
- Year summaries store typed importance, ranked developments, world news, stage movement, mortality warnings, and semantic deltas instead of asking the UI to infer meaning.
- Life Review includes the player's identity arc, defining relationship, pivotal events, housing outcome, unresolved burdens, and continuity line.
- Debug playtests now end with a structured player explanation and Life Review agreement check. The ten-life cohort cannot pass with missing explanations or unresolved mismatches, does not require testers to manufacture a recurring problem, and requires the declared Grind, Social, and Survival strategies while leaving Mixed optional.
- Debug creation now shows the next coverage target before a run, defaults to its origin, and persists its preselected report-only strategy at life start; Playtest Notes and the cohort export repeat the next target.
- Save v32 migrates earlier summaries into the typed presentation model without changing gameplay state or random streams.
- Primary yearly actions remain above high-school detail, event choices expose stable accessibility identifiers, and locked actions disclose their requirement.
- At accessibility text sizes, the Cash overview keeps Work, Household, and Assets as compact reachable rows with complete spoken values; the Assets category control remains pinned above its ledger. Complete iPhone 17 Pro Max and iPad mini (A17 Pro) simulator UI bundles each pass 33/33 journeys. The iPad pass includes centered-sheet navigation, save/relaunch, playtest export, terminal outcome assessment, multiple-property management, and the full Assets purchase-and-amenity flow at Accessibility XXXL. Six focused iPhone 17e journeys pass across the current result bundles: Accessibility XXXL creation and bottom-control reach, world recap, public-health care, the full Assets purchase-and-management flow, Reduce Motion particle suppression, and late-life summary density.
- A deterministic age-72 fixture combines vulnerable mortality, low health, thin cash, retirement pressure, and unresolved health/finance consequences. On iPhone 17e, all three prioritized pressures remain above the fixed thumb navigation without scrolling, while every domain control and Age Up remains reachable.
- Because the target declares portrait and landscape support, a 34th UI journey now rotates the age-72 fixture to landscape and verifies the glance, all domain controls, Age Up, and Cash overview reachability. The complete test target compiles for both simulator architectures, but the landscape journey has not run because no simulator is currently booted; it is not yet exit-gate evidence.
- Reduce Motion suppresses the floating-delta layer and all explicit transition/press animations. Immediate feedback remains visible longer in this mode, and the durable action-result line exposes a stable accessibility identity.
- Generic effects now normalize only Stats, Health, and Cash; domain actions normalize their owned state, and the yearly boundary retains one whole-state validation. Pure deterministic probes can opt out of automatic persistence while explicit lifecycle saves remain available.

Exit gate:

- Life Review identifies repeated choices, sacrifices, defining relationships, turning points, unresolved burdens, personality movement, and legacy.
- At least six recognizable life shapes emerge without special-career content.
- Players can explain why their outcome occurred, and the review agrees with that explanation.
- Save/relaunch, New Life ordering, VoiceOver, accessibility text sizes, Reduce Motion, small-screen reach, late-life density, and lower-end-device performance pass.
- The automated complete-life and replay probes remain green.

## Expansion lock

Founder, Athlete, Politics, Crime, unrestricted social graphs, and other new simulation domains remain paused until all five phases pass. A special career may resume only after the base sandbox is complete enough that it adds a rare life path rather than compensating for a shallow universal loop.
