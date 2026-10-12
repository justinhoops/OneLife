# OneLife — Instant Actions Domain Inventory
**Status:** Core Complete (D1 + D2 + Static Always-Available Quick Actions pass + P1–P4 polish)  
**Date:** 2026-06-20  
**Owner:** COO / Engineering (for launch tracking)  
**Purpose:** Single source of truth for every instant/"Right Now" action across domains. Used by agents for polish, balance, narrative, and discoverability work. Answers: "How are the instant actions across each domain?"

---

## Executive Summary (for Launch)

The instant action layer is **one of the strongest, most complete systems** in OneLife right now. It delivers true BitLife-style frictionless play ("tap and the world reacts instantly") while feeding every modern system we built:

- InstantReactionCoordinator (autonomous reactions + ledger pulses)
- Momentum strip + floating deltas + shape carry (D4)
- Fame Web propagation
- SilentYearEngine / ContinuityThreadEngine reactivity (quiet years now remember your focus)
- LifeResilience differentiation
- Family spillover & adult child modeling

**Architecture (How They Actually Work)**
1. **Definition** — `DomainActionRegistry.swift`: `staticCoreInstantActions(for:)` + `availableInstantPromotions(for:)` return the lists. Special tracks (athlete/founder/creator/politics/crime) get promoted when active.
2. **Catalog** — `Models.swift`: Every `ActionChoiceID` has full definition (title, subtitle, previewTags, microBeat, quickActionTitle short label, baseResolutionTier = .instant).
3. **UI Surface** — `LifeConsoleView.swift` ActionTray: 2-column LazyVGrid per domain tab. "ALWAYS" green capsule badge + "HOLD TO PREVIEW". Long-press calls `previewAction` (now appends D4 shape/legacy impact from P2).
4. **Execution Path (Cheap & Safe)** — `GameViewModel.performQuickAction` → `previewInstantAction` (warm cache, pure query) → `applyInstantActionWithAutonomousReaction` (no heavy `refreshGeneratedCaches` or snapshot nuke on chained taps) → domain System `applyAction` (mutates state, produces `DomainNote`) → `InstantReactionCoordinator` (health/finance/NPC/family autonomous reactions, ledger `instantActionPulse`, momentum update) → floating deltas + history + strip refresh.
5. **Background Magic** — Ledger signal → `SilentYearEngine.pickNote` (D4 flavored quiet year notes), `ContinuityThreadEngine` (stance/shape residue), Fame propagation, WorldAutonomy event bias, adult child developmentNotes.
6. **No Yearly Cost** — All of this stays out of `resolvePreparedYearChapter`. The "micro move vs year commitment" mental model is respected and taught lightly (first-life journal + adult children coach).

**Result for Player:** Every domain tab has a living "Right Now" grid. Taps feel meaningful, world pushes back, and your choices echo in quiet years, fame, family, and legacy. This is exactly the frictionless immersion the Codex demands.

**Launch Verdict:** Green for core loop. Yellow only on Founder depth parity with Athlete (instant wiring exists; core simulation still lighter).

---

## Domain-by-Domain Inventory

### 1. Life (Home / Identity Domain) — Always Available
**UI Location:** Life tab → Quick Actions "Right Now" grid (priorityDomains includes .identity)  
**Static Core Instants (D1):**  
- `morningReflection` — identityCoherence + mental nudge, dossier flavor (analytical vs social wiring)  
- `reconcileWithPast` — past processing, mental/rep effects  
- `tryNewPersona` — identity shift experiment  
- `publicReset` — reputation/image management  
- `therapySession` — mental health anchor (cost + gain)  
- `processCrisis` — acute stress handling  

**System Owner:** `EducationCareerSystems.swift` (apply helper) + `InstantReactionCoordinator`  
**Flavor/Notes:** Dossier-seeded, resilience-aware possible, strong ledger pulse for Silent/Continuity.  
**Depth:** Excellent. First real "self work" domain. Coherence stat (0-100) moves visibly.  
**Gaps:** None. Could add 1-2 more for late-game identity crises if needed.  
**Launch Polish:** Ensure first-life journal entry teaches that these are *always* here (no year plan required).

### 2. Family Domain — Contextually Always (when children exist)
**UI Location:** Family tab → "Family — Right Now" tray (appended via familyPhaseQuickChoices) + Life quick if relevant  
**Static Core Instants (D1 light + Phase 2):**  
- `familyMeal` — bond gain, mental wellness, developmentNotes seed  
- `storyTime` — bond + curiosity/emotionalSensitivity nudge, dossier (social aptitude) flavor, "Heard stories..." note  

**Parenting Trade-off Instants (Phase 2.2):** 4 temperament-aware actions with real costs/benefits (protect routine, push independence, pour attention, etc.).  
**System Owner:** `RelationshipFamilyHealthAssetSystems.swift`  
**Flavor/Notes:** Rich emotional texture, adult child outcome seeding at emancipation, D4 stance residue in leaving notes (P3).  
**Depth:** One of the strongest in the genre now. Children feel different; adult outcomes carry your focus history.  
**Gaps:** None critical. Instant layer is light but persistent — perfect.  
**Launch Polish:** Adult Children section already has explanatory line on first appearance (good discoverability win).

### 3. Health Domain — Always Available
**UI Location:** Health/Life tab Quick Actions  
**Static Core Instants (D2):**  
- `recurringTherapy` — ongoing mental work  
- `manageMeds` — condition management (cost + stability)  
- `bodyConditioning` — physical edge, shines for athlete/creator paths  

**System Owner:** `RelationshipFamilyHealthAssetSystems.swift` (HealthSystem apply)  
**Flavor/Notes:** Path-aware ("Athlete paths feel the edge"), resilience spillover text stronger in P4, aging hooks ready.  
**Depth:** Good foundation for mastery/collector loops. Feeds burnout, mentalLoad (founder), peakPerformance (athlete).  
**Gaps:** Could use 1-2 more aging-specific or chronic condition actions later.  
**Launch Polish:** Verify Grounded vs Resilient recovery actions feel viscerally different (already tuned in P4/P5).

### 4. Finance / Assets Domain — Always Available + Collector Flavor
**UI Location:** Cash/Assets tab Quick Actions  
**Static Core Instants (D2):**  
- `curateCollection` — maintain signature assets, prestige/lifestyle/fame boost  
- `hostSignatureEvent` — flex + audience/knownFor  
- `maintainAsset` — ongoing cost for long-term value  

**System Owner:** `FinanceInvestmentSystems.swift` (apply base + reactToPlayerFinanceAction)  
**Flavor/Notes:** Era-sensitive, path track boosts (athlete gear vs founder compound vs creator studio vs crime fronts), LifestyleScore now feeds unified FameProfile (F1).  
**Depth:** Turns money into visible status/legacy flex. Strong autonomous reactions (stress, family ripple).  
**Gaps:** None for launch. "Enough unique assets to spend on" itch is scratched.  
**Launch Polish:** Ensure high LifestyleScore visibly moves Recognition card and knownFor tags.

### 5. Relationships Domain — Always Available + Depth Tools + Batch 1
**UI Location:** Love/People tab Quick Actions  
**Static Core Instants (D2):**  
- `deepenSpecificBond` — targeted friend/partner work (first friend bias)  
- `fuelRivalry` — competitive edge + rumorHeat  
- `splitReputation` — public vs private face trade-off (rep split)  

**Batch 1 Romance / Partner (when partner active):**  
`giveCompliment`, `goOnDate`, `giveGift`, `intimateMoment`, `fightOrArgue`, `supportTheirCareer`, `askForMoney`, `discussBirthControl`, `breakUp`, `attendCouplesCounseling`, `makeADeal`, `elope`, `introduceToFriendsOrFamily`, `publicDisplayOfAffection`, `getMatchingTattoos`, `spyOnPartner`, `celebrateAnniversary` (married), plus wired existing `strengthenBond`, `moveInTogether`, `proposeMarriage`, `repairTension`

**Batch 1 Dating / Social (single or always):**  
`swipeOnDatingApp`, `ghostSomeone`, `juggleMultiplePeople`, `reconnectWithEx`, `startRumorAboutSomeone`, `defendFriendInDrama`, `askFriendForFavor`, `setUpFriendWithSomeone`, `hostDinnerParty`

**Batch 1 Family / Parenting (Family tab, when children present):**  
`helpWithHomework`, `attendSchoolEvent`, `haveFamilyGameNight`, `disciplineChild`, `giveAllowance`, `takeKidToDoctorOrTherapy`, `planFamilyVacation`, `recordFamilyMemory`, `apologizeToChild`, `teachLifeLesson` (+ existing `familyMeal`, `storyTime`)

**System Owner:** `RelationshipFamilyHealthAssetSystems.swift` + `RelationshipBatch1Systems.swift`  
**Flavor/Notes:** Session doc `SESSION_Narrative_Agent_Relationships_Batch1_Flavor.md` — BitLife-style DomainNotes, resilience/D4 carry, ledger pulses on every tap. Risky actions (spy, juggle, ghost, fight) include discovery/emotional cost language.  
**Depth:** Love and Family tabs now feel like dense Activities lists with direct control. Partner bond, rumorHeat, child developmentNotes, and publicRep all react instantly.  
**Gaps:** Monitor balance on high-risk actions in long saves; variant notes by bond level can deepen further in Batch 1.1 polish.  
**Launch Polish:** Preview text includes "Shapes your life (X) + legacy echoes" pattern from narrative session.

### 6. Education / Teen Precursors (Subdomain)
**UI Location:** School tab (age 14-17, high physical/social/analytical dossier) → Quick Actions  
**Static Instants:** `teenAthleticDrill`, other dossier-gated precursors (seeds athlete.naturalPotential, school buffs, early dossier wiring).  
**System Owner:** `EducationCareerSystems.swift`  
**Depth:** Excellent bridge from teen → special career activation. Frictionless on-ramp.  
**Gaps:** None.  
**Launch Polish:** Ensure preview shows long-term athlete/founder/creator seeding potential.

### 7. Athlete Special Career Track (When Active)
**UI Location:** Occupation tab → "Athlete — Right Now" grid (promoted via availableInstantPromotions)  
**Dedicated Static Instants (S2 + static pass):**  
- `extraTrainingSession` — peakPerformance + durability, injury risk trade-off  
- `recoveryFocus` — body care, momentum carry to lower injury  
- `mediaAppearance` — personalBrand + audience, spotlight hit  
- `teamBonding` — team chemistry, fan loyalty  
- `edgeProtocol` — doping temptation (enhancementUses/Heat, detection/scandal, health tax, brand damage, momentum suppression of heat)  

**System Owner:** `SpecialCareerCrimeSystems.swift` (full apply cases + S3a doping/accolades)  
**Integration:** Best-in-class.  
- Momentum boosts peakPerformance temporarily  
- High instant momentum after edge can suppress detection  
- Strong family spillover (travel, public image, kids with athlete parent)  
- Accolades (MVP, Hall of Fame) → permanent knownFor + culturalFame (Fame Web)  
- "Clean One" quiet legend path for high-brand never-doped athletes  
- D4 life-shape proxy in age curve/decline resistance (P4)  
**Depth:** Excellent (S1–S3a + Fame F1–F3 + D4). Feels like a real high-variance athletic life.  
**Gaps:** None for launch. Post-career retirement paths (S3) could be expanded later but not blocking.  
**Launch Polish:** Rich event variety/rivalries already planned in S4 — keep on roadmap but not P5 critical.

### 8. Founder / CEO / Entrepreneur Track (When Active)
**UI Location:** Occupation tab → Founder quick grid (promoted)  
**Dedicated Static Instants (E2 + static always pass):** `closeMajorDeal`, and other E2 founder actions (pitch traction, advisor leverage, board management, etc. — wired in static pass).  
**System Owner:** `SpecialCareerCrimeSystems.swift` (handles + apply)  
**Current Depth:** Functional but lighter than Athlete.  
- No dedicated `FounderState` (uses generic SpecialCareerState + tiny advisors array)  
- `resolveFounderYear` still ~35 lines (sector multipliers + boardPressure + ouster + burnout) vs rich athlete age curve + injury + accolades + doping  
- Instant actions exist and calculate instantly with notes/reactions, but lack the deep autonomous family/health/fame flavor athlete has  
- BoardPressure → coup is the main tension; missing product crises, key hires, culture wars, founder mental spirals, post-exit paths  
**Fame Web Integration:** Good (success → unified culturalFame + personalLegend potential via F1/F2). D4 shape now multiplies burn/traction (P4).  
**Gaps (Critical for Parity):** Founder path still pre-S1 level compared to Athlete revival. Instant layer is there; core simulation and narrative voice are not.  
**Launch Recommendation:** Elevate to E1–E3 revival priority *after* P5 shine if time, or accept as "good enough for launch" with note that founder lives feel less distinct than athlete ones. Fame Web + D4 already give it more gravity than before.  
**Launch Polish:** At minimum ensure all E2 instants have rich DomainNote + autonomous reaction text matching athlete quality.

### 9. Creator Track (When Active)
**UI Location:** Occupation tab quick grid  
**Dedicated Instants (C2 + static pass):** `postDaily`, content strategy actions, brand deal drops, audience engagement, etc. (wired).  
**Depth:** Solid mid-tier. Platform/brand/voice/burnout/audience 5-voice treatment (P3). Instant actions feed audience + fame.  
**Gaps:** Less deep than Athlete; acceptable for launch.  
**Polish:** Verify D4 shape affects burnout/audience retention.

### 10. Politics Track (When Active)
**UI Location:** Occupation quick grid  
**Dedicated Instants (P2 + static):** `townHall`, `attackOpponent`, approval/ethics/power/scandal actions.  
**Depth:** Good scandal/approval tension. 5-voice + D4.  
**Gaps:** Minor.  
**Polish:** Heat/scandal interaction with Fame Web notoriety.

### 11. Crime / Shadow Track (When Active)
**UI Location:** Occupation or Risk lane quick actions  
**Dedicated Instants:** Advanced crime actions promoted to instant (from earlier phases + static pass).  
**Depth:** Rich (CE4 5-voice, heat/loyalty/notoriety, D4 tuning in P4). Dark fame path fully wired into Fame Web.  
**Gaps:** None blocking. High variance is intentional.  
**Polish:** Grounded mode should feel meaningfully harsher on crime paths (already in P4 resilience divergence).

### 12. Military Track (When Active)
**UI Location:** Occupation tab (gated 18+ / active)  
**Static Instants (D1):** `ptFocus`, `seekCounsel`, `studyTradition`  
**Committed High-Impact:** `deployTour` (years + trauma/medal/performance swing)  
**System Owner:** `SpecialCareerCrimeSystems.swift` (MilitarySystem)  
**Depth:** Functional + veteran flavor in jobHunt. Small but correct.  
**Gaps:** Lightest special track. Acceptable — military is often a chapter, not whole life.  
**Polish:** Ensure deployTour has strong narrative weight and legacy medal → culturalFame (Fame Web already does).

---

## Cross-Domain / Universal Patterns (Launch Checklist)

- **ALWAYS Badge & Language:** Consistent "Right Now — Instant ALWAYS" across all quick decks (P2 verified).  
- **Preview Strength:** Long-press now includes "Shapes your life (X) + legacy echoes" and D4 carry notes (P2). Good.  
- **Feedback Parity:** Floating deltas + momentum strip update on every instant tap. Yearly Age Up now spawns stance/focus/shape deltas too (P1/P2).  
- **Ledger → World Reactivity:** Every instant publishes `instantActionPulse`. Quiet years, continuity lookbacks, autonomy events, and fame now react to what the player actually did in micro moves. This is the secret sauce for "my life feels authored."  
- **Resilience Interaction:** Grounded vs Resilient already differentiates recovery actions and late/legacy texture (P4/P5).  
- **Thumb Ergonomics:** 2-col grids, min 52-74pt targets, primary actions in natural thumb zone. Still holds after all additions.  
- **Discoverability:** First-life journal + adult children coach line + P2 shape visibility in strip/previews. Still room for one gentle "Right Now actions never require a year plan" hint.  
- **Perf:** Chained quick actions hit zero heavy snapshot rebuilds (Phase 1 orchestrator cleanup). Long saves (80+ years, 3+ adult kids) stable.  
- **Narrative Voice:** Most apply cases have era/dossier/stance/path flavor. Founder and some lighter tracks need love to match athlete/ crime richness (P3 uniform 5-voice was done but founder lighter).

---

## Recommended Next Features / Polish (Prioritized for Launch)

1. **Founder Depth Revival (High Value)** — Match Athlete quality. Add `FounderState` (vision/execution/teamHealth/productStage/personalLegend/companyCulture), rewrite `resolveFounderYear` with stage curve + crises + culture dynamics, richer post-exit paths, stronger instant autonomous reactions/family cost. Leverage existing Fame Web + D4 multipliers. (E1–E3)
2. **Micro Discoverability Coach** — One lightweight, non-intrusive banner or journal note on first open of any domain tab: "These Right Now actions calculate instantly and shape quiet years — no Age Up needed."
3. **Founder Instant Flavor Pass** — Ensure every E2 action has athlete-level DomainNote + autonomous reaction text + D4/resilience flavor.
4. **P5 Final Shine** — Complete microcopy pass, edge long-life perf, accessibility (VoiceOver on quick grids), "The End of the Road" + legacy screens feel like payoff (already improved in P3).
5. **Balance Sweep** — High-variance paths (crime edge, founder board coup, athlete doping) vs Grounded mode feel test. Normal non-special lives should still reach satisfying mid/late game without feeling grindy.

---

## Agent Ownership Recommendations

- **Engineering Agent:** Own instant path perf, any new wiring, snapshot hygiene, and founder simulation depth (E1). Update this doc after changes.
- **Design / UX Agent:** Polish ALWAYS badges, preview popups (shape/legacy lines), thumb targets in 2-col grids, consistent header language, subtle coach for discoverability. Never break one-handed play.
- **Narrative Agent:** Audit and enrich DomainNotes + autonomous reaction copy for founder/creator/politics to match athlete/crime richness. Ensure every instant tap can produce a flavorful journal line that references stance/shape/resilience when relevant.
- **Product / QA Agent:** Build a 15-minute new player test script focused on "Can they discover and use Right Now actions without being told?" + full life playthrough matrix (normal, athlete, founder, heavy family, Grounded vs Resilient). Flag any tap that feels meaningless or any quiet year that still feels generic.

---

## How to Use This Document

- Before any new instant action: Add to this inventory with owner system, UI location, flavor notes, and integration checklist.
- After any change to instant layer: Update status, gaps, and launch polish items.
- For sprint planning: Filter by "Gaps" or "Launch Polish" sections.
- This file + IMPLEMENTATION_PLAN.md + CODEX.md are the three pillars for all agents.

**The instant actions now make the game feel alive at the micro level while the deep systems (Fame Web, D4 life-shape, Family legacy, Resilience) make every choice echo for 60+ years.** This is the frictionless + meaningful depth the original vision demanded.

Ready for founder revival command, P5 execution, or any targeted polish pass. Just say the word.

— COO, OneLife
