# OneLife Special Careers Master Tracker

**Purpose:** Track depth, status, and gaps for every special career path. Ensures we never ship shallow versions. Updated after every revival slice. Permanent file.

**Core Rule (from POLITICS_CAREER_ANALYSIS.md and old diagnosis):** Every special path must have:
- Dedicated State struct (not generic fame/heat reuse)
- Real stage/age curve + drama
- Full instant/frictionless quick actions with autonomous reactions
- Bidirectional integration (Family, Health, Finance, Fame, D4 LifeShape/Resilience)
- Rich narrative (5-voice, Echo, Silence with flavor, legacy)
- UI dashboard + glanceable metrics
- Post-career paths + meta/legacy weight
- Resilience divergence in stories and payoffs

Failure to meet this = shallow gap. We fix before moving on.

---

## Current Status (Bare Bones — July 2026)

**No special careers implemented yet.** Only basic `JobState` with `JobTier`.

All paths below are planned. We will implement in priority order after core stabilization (Phase 0).

---

## 1. Athlete Path (Highest Variance Physical + Cultural Drama)

**Status:** Not started (S1 Foundation pending)

**Planned Depth (from old Sports revival):**
- Dedicated `AthleteState`: sport, peakPerformance, naturalPotential, personalBrand, accolades, enhancement/edge state, durability, injury risk, fanLoyalty, sponsorships.
- Age curve + real decline resistance gated by potential/brand.
- Injury system + recovery trade-offs.
- Instant actions: extraTrainingSession, recoveryFocus, mediaAppearance, teamBonding, edgeProtocol (doping temptation).
- Full autonomous reactions + momentum carry (high momentum boosts peak temporarily, suppresses detection).
- Family impact (travel, public image on kids), health tax, post-career (coaching, business, media, regret).
- "Clean One" legend vs. edge user divergence.
- UI: Pillar metrics (Peak Form / Potential / Brand / Accolades), Edge Heat.
- Legacy: Hall of Fame, Clean Legend flags; D4 shape modifiers on decline.

**Gaps if Shallow:** Generic "athlete job" with fame number. No temptation, no family cost, no age reality, no instant training feel.

**Target Implementation Order:** Second special after Founder. Use the completed Founder vertical slice as the architecture template, then make Athlete the physical/high-variance contrast.

---

## 2. Founder / CEO / Entrepreneur Path

**Status:** Not started (E1 Foundation pending)

**Planned Depth (from old Entrepreneur revival diagnosis):**
- Dedicated `FounderState`: vision, execution, teamHealth, productStage, control/equity, personalLegend, companyCulture, keyHires, competitiveMoat, founderMentalLoad, boardPressure.
- Stage progression (idea → traction → scale → maturity → exit/legacy).
- Real drama: key hires, product crises, down rounds, competitor attacks, culture wars, founder mode vs manager mode.
- Instant actions: closeMajorDeal, aggressiveExpansion, cultureBuild, founderModeSprint, pivotBusiness, ipoExit (high friction but previewable).
- Board ouster risk at 100 pressure. Equity dilution trade-offs.
- Deep integration: Family strain from 80-hour weeks + success pride; Fame from valuation/IPO; Resilience divergence (Grounded harsher burn but bigger comeback stories).
- Post-exit paths: Angel/VC, serial founder, politics entry, regretful "sold too early", building next thing while rich.
- UI: Valuation trend, burn story, team health, control %, Recognition card.
- Legacy: "Built X from nothing", serial entrepreneur flags, D4 mentalLoad echoes.

**Gaps if Shallow:** Just "raise capital → IPO" with generic audience/heat. No team dynamics, no instant deal-making, no family cost of ambition, no post-exit identity.

**Target:** First special after the base-sandbox release gates (high agency/economic contrast to ordinary careers).

---

## 3. Politics Path (Public Power + Moral Complexity — Current Analysis Focus)

**Status:** Not started. Full gap analysis in `/home/workdir/POLITICS_CAREER_ANALYSIS.md`

**Key Planned Depth (Summary from Analysis):**
- Dedicated `PoliticsState`: approvalRating, scandalHeat, integrity/compromiseLevel, influence, stage (local→regional→national), voterSegments, mediaNarrative, donorLoyalty, rivalPressure, signaturePolicy.
- Election cycle tension + stage progression.
- Instant actions: holdTownHall, cutAttackAd, buildBipartisanBridge, leakOppositionResearch, damageControlPresser, courtDonor, familyPhotoOp (with spotlight risk).
- Autonomous reactions: media spin, donor shift, family tension/pressure on kids, approval pulse, heat changes.
- Strong bidirectional integration: High approval → easier deals/family pride; Scandal → family strain, health burnout, finance/legal costs. Feeds unified Fame cleanly.
- D4 + LifeResilience: Grounded = harsher scrutiny + bigger redemption arcs; Resilient = power compounding but visible scars in legacy.
- 5-voice narrative per archetype (Idealist Reformer, Machine Politician, Populist Outsider, Establishment Insider, Scandal Survivor).
- Rich drama: viral gaffe, primary challenge, whistleblower, policy win with domain effects, campaign trail family cost.
- Post-career: Lobbyist (influence for hire), Pundit/Media, Memoir, Elder Statesman (quiet legacy), legal consequences or redemption.
- UI: Dedicated card (approval/heat bars + stage + Mandate chips). Glanceable + tappable for details.
- Legacy harvest: "reformer_legacy", "scandal_plagued", "bipartisan_builder", "sold_the_soul". Adult children "child of politician" modeling (pressure/idealism/cynicism). Meta echoes for next life.

**Gaps if Shallow (Detailed in POLITICS_CAREER_ANALYSIS.md):** Generic approval grind. No dedicated state, no instant campaigning feel, no family spotlight cost, no compromise edge, no post-career identity, weak narrative/legacy. Politics becomes just another fame silo instead of high-stakes moral/power chapter.

**Target:** Third special (moral complexity + public life contrast to previous paths). See full analysis file for phased P1–P4 plan.

---

## 4. Crime Path (Dark Mirror — High Risk/Reward)

**Status:** Not started (basic CrimeState may exist in old code; needs full revival)

**Planned Depth (Symmetric to others):**
- Dedicated state: notoriety, heat, loyaltyNetwork, criminalEmpireStage, rackets, lawEnforcementPressure, moralDebt.
- Instant actions: recruit, expandRacket, launder, callInFavor, eliminateThreat, layLow (with paranoia cost).
- Deep integration: Family in danger or benefiting from wealth; Health (paranoia/stress); Fame as dark notoriety feeding unified profile; strong Resilience divergence (Grounded = harder but cleaner exits; Resilient = faster rise + heavier scars).
- Narrative: 5-voice (Ruthless Operator, Charismatic Boss, Paranoid Kingpin, etc.). Rich betrayal, loyalty tests, "one last score" drama.
- Post-career: Go straight (witness protection or quiet life), Prison legacy, Kingpin retirement, Flipped informant.
- Legacy: "Built empire from nothing", "Died in the life", family criminal modeling or rejection.

**Gaps if Shallow:** Generic "crime job" with heat. No instant underworld tools, no real family risk/reward, no moral debt texture, no post-exit paths.

**Target:** Fourth (dark contrast completes the set).

---

## Implementation Rules for All Special Careers
- **Never reuse generic fields only.** Always add dedicated State.
- **Instant layer mandatory** before deep yearly resolve.
- **Full modern integration** (D4 stance/life-shape, LifeResilience, Fame Web, Family adult outcomes, Health spillover) in P3 slice.
- **Playable after every sub-phase.** Build green + manual 10–20 year test on the path.
- **UI/Ergonomics:** 2-col instant grids, long-press previews with political capital + ripple preview, thumb zone respected.
- **Narrative Contract:** Voice (second-person present, specific), Echo (past choices remembered), Silence (office/spotlight weight), Mood (UI tone shifts with approval vs scandal heat).
- Update this file + ROADMAP.md with COMPLETE block + player impact after each slice.

**Current Priority Order:** Base-sandbox release proof → Founder/CEO → Athlete → **Politics** (moral depth) → Crime.

**Next Command Examples:** "Update SPECIAL_CAREERS with Athlete S1 start", "Create CODEX.md", "Begin Politics stub implementation", "Core Phase 0 checklist".

This tracker keeps us honest. No shallow special careers ship. Every path must feel like a different book in the same library.
