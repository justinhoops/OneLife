# OneLife — Instant Actions Expansion Roadmap (BitLife-Style Density + Agency)
**Status:** Planning Phase (Post user feedback on BitLife-style direct control)  
**Date:** 2026-06-20  
**Type:** Permanent tracking document (update after every batch)  
**Owner:** COO + Engineering + Narrative Agent  
**Goal:** Give players *a lot* of direct, low-friction, high-agency "Right Now" actions across every domain so they feel they are truly steering the life — matching or exceeding BitLife's Activities lists while staying true to OneLife's deeper simulation, D4 life-shape, Fame Web, Resilience, and ledger reactivity.

---

## Vision Alignment (Why This Matters)

The screenshots the user shared (Girlfriend Activities, Crime, Midcentury Home Property Management) show exactly the feeling we want:

- Dense, scannable lists of **direct, concrete actions**
- Emoji + short title + one-line description
- Player can tap almost anything relevant to the current context (relationship, crime risk, property, etc.)
- High perceived control: "I can decide to do *this* right now"

Current OneLife instant layer (D1/D2 + Static Always pass) is architecturally excellent but **surface area is still too thin**. We have good coverage in core domains and strong special-track actions (especially Athlete), but not enough *choices* for the player to feel they are micro-managing and authoring their life moment-to-moment.

**Target Feel:** Every major domain tab should feel like a rich "Activities" or "Management" screen with 8–15+ meaningful instant taps when relevant, all calculating instantly, all feeding the deep systems.

**Constraints (Non-Negotiable for Launch)**
- Every new action must be `.instant` tier (cheap execution path, no yearly resolve cost).
- Must have short `quickActionTitle`, good preview (now with D4 shape/legacy), and produce `DomainNote` + ledger pulse.
- Must integrate with existing systems: autonomous reactions (health/finance/NPC/family), momentum, Fame Web, SilentYear/Continuity reactivity, LifeResilience flavor, adult-child developmentNotes where relevant.
- Keep thumb ergonomics (2-col grids, strong tap targets).
- Maintain "micro move vs year commitment" mental model — these are always-available direct actions, not planner items.

---

## Current State Snapshot (as of 2026-06-20)

**Strengths**
- Architecture is clean and scalable (DomainActionRegistry + catalog + cheap instant path + coordinator).
- Core domains have solid base (Identity 6, Family 2 + parenting levers, Health 3, Finance 3, Relationships 3).
- Special tracks have good dedicated sets (Athlete 5 is excellent; others functional).
- All feed ledger → world reactivity (quiet years now remember player focus).

**Gaps vs BitLife-style density**
- Relationships/Love: Only 3 core + parenting. BitLife has 10+ girlfriend/wife activities.
- Crime/Risk: Has advanced actions but not the full "Bank Robbery / Burglary / Embezzle / GTA / Hack / Hitman / Mischief / Murder / Pickpocket / Porch Pirate" density.
- Assets / Property (Midcentury Home style): Very light. We have collector actions but not rich property management (Rent, Renovate, Party, Inspect, Amenities, Sell, etc.).
- Health: Only 3. Missing many direct self-care, condition management, aging, or risk behaviors.
- Career sub-tracks: Founder/creator/politics still lighter than Athlete.
- Play/Activities: Thin.
- General life micro-actions: Missing many "daily life" direct controls (e.g., specific social, hobby, risk, self-improvement taps).

**Result:** Player has good *systems* but not enough *levers* to feel full control. We need to expand the surface significantly.

---

## Expansion Strategy (Phased, Launch-Focused)

We will expand in **batches** so every addition is high-quality, fully integrated, and immediately playable. No "add 50 and figure out integration later."

**Batch Philosophy**
- Start with highest player-agency domains (Relationships/Love, Crime, Assets/Property, Health).
- Add 5–8 new direct actions per batch.
- Every action gets: registry entry + catalog definition (with previewTags, microBeat, quick title) + apply case in the right System + DomainNote flavor + ledger pulse + autonomous reaction hooks where natural.
- Narrative Agent ensures flavor matches dossier/era/stance/resilience/D4.
- After each batch: update this roadmap + the main INSTANT_ACTIONS_DOMAIN_INVENTORY.md, test in sim, verify no perf regression on instant path.

**Priority Order for Launch (P5 / next feature slices)**

1. **Relationships / Love / Dating / Family** (highest agency feel — BitLife girlfriend screenshot is perfect reference)
2. **Crime / Risk / Shadow** (direct crime actions like the screenshot)
3. **Assets / Property / Lifestyle** (Midcentury Home style property management + collector flex)
4. **Health** (more direct self-care, risk, aging, condition management)
5. **Career sub-tracks** (especially Founder to reach Athlete parity; then Creator/Politics)
6. **Play / Hobbies / Activities** (new or expanded)
7. **General Life Micro** (daily routines, small risks, self-improvement that don't fit other tabs)

---

## Batch 1 Plan: Relationships / Love / Dating / Family (Start Here)

**Goal:** Make the Love/People and Family tabs feel like rich "Activities" lists with direct control over romance, dating, marriage, parenting micro-moves, and social maneuvering.

**Proposed New Direct Instant Actions** (in addition to existing `deepenSpecificBond`, `fuelRivalry`, `splitReputation`, `familyMeal`, `storyTime` + parenting levers):

**Romance / Partner / Girlfriend / Wife / Husband**
- AskForMoney (or "Hit up for cash")
- DiscussBirthControl / SafeSexTalk
- BreakUp (with flavor options or consequences)
- CelebrateAnniversary
- GiveCompliment (or specific "flirt / sweet talk")
- HaveDeepConversation
- AttendCouplesCounseling
- MakeADeal (or "propose arrangement")
- Elope
- GiveGift (specific or general)
- ProposeMarriage
- GoOnDate (quick date night)
- HaveSex / IntimateMoment (with consent/relationship context)
- Fight / Argue (with reconciliation path)
- MoveInTogether
- GetMatchingTattoos or other couple rituals
- SpyOnPartner / CheckPhone (risky, with discovery chance)
- SupportTheirCareer / HelpWithTheirGoal

**Dating Scene / Multiple Partners**
- SwipeOnDatingApp / GoOnBlindDate
- GhostSomeone
- JuggleMultiplePeople (with risk)
- IntroduceToFriends / MeetTheParents
- PublicDisplayOfAffection or "show off partner"

**Family / Parenting Micro (beyond existing)**
- HelpWithHomework
- AttendSchoolEvent
- HaveFamilyGameNight
- DisciplineChild (temperament-aware)
- GiveAllowance
- TakeKidToDoctor / Therapy
- PlanFamilyVacation (or quick "day trip")
- RecordFamilyMemory / MakeHomeVideo
- ApologizeToChild / RepairBond
- TeachLifeLesson (specific value or skill)

**Social / Extended Network**
- ReconnectWithEx
- StartRumorAboutSomeone
- DefendFriendInDrama
- AskFriendForFavor
- SetUpFriendWithSomeone
- HostDinnerParty (social flex)

**Implementation Notes for Batch 1**
- Many can reuse or lightly extend existing RelationshipSystem / FamilySystem apply logic.
- High narrative payoff: most should generate specific, flavorful DomainNotes and autonomous reactions (partner mood, family bond drift, rumorHeat, publicRep, etc.).
- Some high-risk ones (SpyOnPartner, JuggleMultiple) should have detection chance + consequences that feed ledger and future events.
- All must respect LifeResilience (Grounded feels different emotional cost/benefit).
- D4 stance carry: e.g., "driven" focus makes career-support actions stronger; "loose" makes juggling riskier but more fun in moment.

**Success Metric for Batch 1:** Love and Family tabs feel dense and controllable. Player can spend 5–10 minutes just tapping relationship actions and see meaningful, reactive outcomes + journal texture.

**Delivered (2026-06-20):**
- Narrative: `mdfiles/SESSION_Narrative_Agent_Relationships_Batch1_Flavor.md` (39 actions — DomainNote + preview + autonomous direction)
- Engineering: `RelationshipBatch1Systems.swift` — 36 new `ActionChoiceID` cases, apply logic, catalog previews, People/Family tab registry wiring, ledger pulses
- Tests: `batchOneGoOnDateBoostsPartnerBond`, `batchOneHelpWithHomeworkSeedsChildBond`, `batchOnePeopleTabSurfacesRomanceActionsWithPartner`, `batchOneFamilyTabSurfacesParentingMicroActions`
- Inventory updated under Relationships + Family sections

---

## Future Batches (High-Level)

**Batch 2: Crime / Risk Lane**
- Expand to match screenshot density: BankRobbery, Burglary, Embezzle, GrandTheftAuto, Hack, HitmanContract, Mischief, Murder (or "arrange hit"), Pickpocket, PorchPirate, plus more (DrugDeal, Smuggle, LaunderMoney, Intimidate, BribeOfficial, StartGangWar, etc.).
- Strong heat/notoriety/fame-dark-path integration + high autonomous reaction risk (arrest, injury, betrayal, family discovery).

**Batch 3: Assets / Property / Lifestyle (Midcentury Home style)**
- For owned properties + general assets: RentOut, Renovate, InspectTenant, AddAmenities, ThrowHouseParty, PayOffMortgage, SellProperty, GiftToSomeone, HostEvent, MaintainLuxury, FlauntWealth, etc.
- Strong LifestyleScore + Fame Web + prestige/knownFor payoff.

**Batch 4: Health Expansion**
- More direct: GetCheckup, StartNewDiet, HitTheGymHard, SkipSleepForWork, BingeDrink, TryExperimentalTreatment, ManageChronicCondition, MentalHealthDay, RiskyBehavior (specific), CosmeticProcedure, etc.

**Batch 5: Career Sub-track Deepening + Play/Hobbies**
- Founder/creator/politics specific micro-actions.
- Play domain: specific hobby activities, skill practice, side hustles, creative flow states, etc.

---

## File & Agent Ownership

**Permanent .md files (always maintained):**
- `INSTANT_ACTIONS_DOMAIN_INVENTORY.md` — current state + full per-domain lists (update after every batch)
- `INSTANT_ACTIONS_EXPANSION_ROADMAP.md` — this document (the strategic plan and batch tracking)

**One-session / temporary agent files (created per focused work session, then archived or merged):**
- `SESSION_Narrative_Agent_Relationships_Batch1_Flavor.md` (example) — detailed copy, DomainNote text, autonomous reaction descriptions for one batch
- `SESSION_Engineering_Agent_Registry_Expansion_BatchX.md` — exact code changes, catalog entries, apply method signatures for one batch
- `SESSION_QA_Agent_InstantActions_TestMatrix_BatchX.md` — playthrough checklist, edge cases, balance notes for one batch

We will create the session-specific ones only when we actively work a batch, then merge key learnings back into the two permanent docs.

---

## Next Immediate Steps (Ready When You Are)

1. ~~**Approve Batch 1 scope** (Relationships/Love/Family) — or adjust priority.~~ DONE
2. ~~Narrative + Engineering Batch 1 (flavor pass + registry/apply wiring).~~ DONE — see **Delivered** block under Batch 1 Plan.
3. ~~Execute Batch 1 → update both permanent .md files → sim test → player feel check.~~ DONE
4. **Batch 2: Crime / Risk Lane** — next priority per roadmap (or player feel check on Batch 1 in sim first).

This expansion directly addresses your feedback: we want the player to have *a lot of choices* and feel real moment-to-moment control while the deep systems (D4, Fame, Resilience, Family legacy, ledger reactivity) make every tap echo.

The architecture is ready to scale. The only question is how fast and in what order we add the surface area.

Say the word on Batch 1 (or change priority) and we'll start wiring.

— COO, OneLife

---

**Related Permanent Files**
- `IMPLEMENTATION_PLAN.md` (overall phased roadmap — this expansion slots into P5 / post-P4 polish)
- `CODEX.md` (especially Vibe Layer, Summary-to-Action, and frictionless immersion principles)
- `INSTANT_ACTIONS_DOMAIN_INVENTORY.md` (live list of every current action)