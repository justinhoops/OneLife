# Politics Career Path - Depth Gap Analysis (Bare Bones State)

**Date:** July 10, 2026 (Post Massive Refactor to Bare Bones)
**Context:** OneLife is now extremely minimal after refactor for clean architecture per Codex. No special careers (Athlete, Founder, Politics, Crime, etc.) implemented yet. Basic JobState only has tier (unemployed/entry/skilled). This analysis identifies what would make a Politics path shallow vs. deep, to guide future implementation with proper depth matching the vision (raw authenticity, frictionless immersion, domain sovereignty, Vibe Layers).

**Permanent .md Files (Persist Across All Sessions):**
- `/home/workdir/AGENTS.md` — Role definitions and coordination rules (you are COO, plan features, guide launch).
- `/home/workdir/CODEX.md` — Core philosophy (to be created/ported from attachments: Orchestrator pattern, Glance Rule, Thumb Zone, Vibe Layers: Voice/Echo/Silence/Mood, Domain Sovereignty).
- `/home/workdir/ROADMAP.md` — High-level launch roadmap, milestones, success criteria (new, to be created).
- `/home/workdir/CORE_DESIGN.md` — Bare bones core interaction loop, stat island, instant actions, pressures (ported/adapted from attachments/OneLifeCore.md).
- `/home/workdir/SPECIAL_CAREERS.md` — Master tracker for all special paths (Athlete revival status, Founder/E1 plan, Politics gaps + revival plan, etc.). Updated after every career slice.

**Session-Only / Temporary .md Files (One Agent Session or Until Resolved):**
- `/home/workdir/POLITICS_CAREER_ANALYSIS.md` — This file. For deep-dive analysis and planning. Archive or delete after Politics revival implementation.
- `/home/workdir/FOUNDER_REVIVAL_PLAN.md` — Dedicated E1–E4 plan (when we start CEO/Entrepreneur work).
- `/home/workdir/LAUNCH_TESTING.md` — Playtest scripts, balance scenarios, edge cases for a specific slice.

**Why This Matters (Codex Alignment):**
Per Codex II (Raw Authenticity): Politics should feel like real power, compromise, public scrutiny — not a shallow "get famous" button. 
Per Codex IV (UI/UX): Must satisfy Glance Rule (2-sec audit of approval/heat/legacy), Thumb Zone (instant actions always tappable).
Per Vibe Layers: Strong Voice (second-person present), Echo (past scandals affect future), Silence (quiet years in office feel heavy with pressure), Mood (UI shifts with scandal heat or high approval glow).
Per Domain Sovereignty: Politics must own its state/logic but integrate bidirectionally with Family, Health, Finance, Fame without god-objects.

---

## Current State Diagnosis (Bare Bones — No Politics Path)

**What Exists:**
- Basic `JobState` with `JobTier` (unemployed, entry, skilled) and simple income/cost.
- `LifeState` has aggregates, history, pendingEvent.
- DomainActionRegistry + LifeSimulator for generic actions (school/love/play/health focused in bare bones).
- No `SpecialCareerState`, no `PoliticsState`, no dedicated resolve logic, no instant actions for political life.
- No fame/notoriety unification, no resilience divergence for public figures.

**If We Added a Shallow Politics Path (What to Avoid — Lessons from Old Entrepreneur Diagnosis):**
A naive implementation would reuse generic job/fame fields and add a few yearly "campaign" events. This would create the same problems we diagnosed for pre-revival Entrepreneur and fragmented Fame:

1. **No Dedicated `PoliticsState` Model**
   - Would use only generic fields (e.g., "audience" as approval, "heat" as scandal).
   - Missing: approvalRating (0-100), scandalHeat, integrityScore or ethicalCompromise, policyInfluence, voterBase segments (urban/rural/youth), mediaPresence, stage (CityCouncil → StateRep → Senator → President or Lobbyist post-career), donorLoyalty, rivalThreats.
   - Result: No real progression or "rise/peak/decline" arc. Just number go up.

2. **Extremely Shallow Core Simulation**
   - `resolvePoliticsYear` would be ~20-30 lines of generic rolls (approval drift + random scandal + money from donors).
   - No age/stage curve (early career idealism vs. late cynicism), no election cycle tension, no bill-passing drama or committee power plays, no "lame duck" years.
   - No dedicated sub-state contrast to rich future AthleteState or planned FounderState.

3. **Almost Nonexistent Instant/Frictionless Layer**
   - No politics-specific quick actions (unlike planned Athlete: extraTraining, mediaAppearance, recoveryFocus).
   - Missing always-available taps: holdTownHall, cutAttackAd, buildBipartisanBridge, leakOppositionResearch, damageControlPresser, courtDonor, familyPhotoOp.
   - Actions would be high-friction "committed" yearly moves only. Violates BitLife-style "Right Now" static instant fantasy and Codex frictionless immersion.

4. **Weak / Zero Integration with Modern Systems**
   - No bidirectional links:
     - High approval → easier asset deals, family pride/pressure on kids, sponsor interest.
     - ScandalHeat → family strain (kids bullied at school, partner stress), health (public scrutiny burnout), finance (donor flight or legal costs).
     - No unified FameProfile contribution (public figure fame should feed culturalFame/notoriety cleanly).
     - No D4 LifeResilience divergence: Grounded politicians should have harsher spotlight but bigger "fighting back / redemption" stories; Resilient ones compound power but carry visible scars into legacy.
   - No momentum carry specific to political actions (high instant momentum should temporarily boost approval or suppress heat).

5. **Thin Drama, Narrative, and Progression**
   - Main tension = generic "approval low → lose election". Everything else is flat heat/burnout/fame.
   - Missing rich moments: key endorsement, viral gaffe, primary challenge, whistleblower, "I have a plan" policy win with real domain effects, family dinner during campaign trail, post-election concession or victory speech flavor.
   - No archetypes/5-voice treatment (Idealist Reformer vs. Machine Politician vs. Populist Outsider vs. Establishment Insider vs. Scandal-Plagued Survivor).

6. **Generic UI and Feedback**
   - No dedicated Politics dashboard (approval trend line, heat meter with "media narrative" subtitle, stage progress, "Current Mandate" chips).
   - Narrative description weak/generic.
   - No rich legacy harvest ( "The Reformer Who Changed X", "The Scandal That Ended a Career", "Quietly Powerful in the Background").

7. **Weak Post-Career / Late-Game Identity**
   - Exit = "Retired from public life" one-liner.
   - Missing meaningful paths: Lobbyist (influence for hire), Pundit/Media (brand monetization), Memoir/Author, Regretful Elder Statesman, "I Sold Out" vs "I Stayed Clean" divergence, possible legal consequences or redemption arcs.
   - Almost no legacy texture or adult-child modeling of "growing up in the spotlight."

**Result if Shallow:** You can "enter politics," grind approval, maybe become President — and the rest of the simulation barely notices or reacts differently. Politics becomes just another fame vector instead of a distinct, high-stakes life chapter with real personal cost and cultural weight. Violates "Uncomfortable Realism" and "meaningful depth proportional to impact."

---

## Proposed Architecture for Deep Politics Path (Matching Athlete Revival Quality)

**Core Pillars (to Implement in Phases P1–P4 style):**
- Dedicated `PoliticsState` struct (lightweight, like future FounderState).
  - approvalRating, scandalHeat, integrity (or compromiseLevel), influence, stage (enum: local → regional → national), voterSegments: [String: Int], mediaNarrative: String, donorHeat, rivalPressure.
  - Optional: peakApprovalYear, lastScandalAge, signaturePolicy, postCareerPath.
- One source of truth integration with GameState (or SpecialCareer wrapper).
- Propagation/orchestrator hooks: yearly resolve after instant layer, feeds unified Fame, affects preferredEventWeights, family developmentNotes, health spillover.
- Strong instant layer: 5–8 static always-available quick actions per stage (townHall, mediaStrategy, coalitionBuild, oppositionResearch, etc.) with autonomous reactions (media reacts, donors shift, family note, approval pulse).
- Full D4 + LifeResilience + Momentum integration (high momentum = temporary approval buffer or heat resistance; Grounded mode = harsher scrutiny but stronger redemption payoffs in legacy).
- Rich narrative: 5-voice per archetype in resolves + quiet years. Echo lines for past compromises/scandals. Silence notes heavy with "the weight of the office."
- UI: Dedicated metrics card when active (glanceable approval/heat bars + stage chip + "Mandate" summary). Long-press previews show political capital cost/gain + family ripple. Consistent with momentum strip and floating deltas.
- Legacy + Meta: Strong harvest flags ("reformer_legacy", "scandal_plagued", "bipartisan_builder", "sold_the_soul"). Adult children have specific "child of politician" modeling (pressure, idealism, cynicism). Post-career paths feed next-life echoes.
- Post-career depth: Multiple retirement paths with mechanical + narrative weight (lobbying income vs. quiet legacy vs. media career vs. legal troubles).

**Phased Revival Plan Sketch (Similar to Sports S1–S4 + Fame F1–F3)**
- **P1 (Foundation):** Add `PoliticsState` + seed on activation. Basic stage progression + yearly resolve with approval drift, election checks, basic scandal roll.
- **P2 (Instant + Momentum):** New dedicated quick actions + full InstantReactionCoordinator handling + autonomous reactions. Extend applyInstantMomentumBenefits for politics.
- **P3 (Depth & Integration):** Full drama (rival attacks, policy wins with domain effects, family spotlight pressure). Deep Fame Web + Family + Health + Finance bidirectional wiring. 5-voice narrative + D4 shape modifiers.
- **P4 (Polish & Legacy):** Rich event variety, dedicated dashboard, post-career paths, legacy harvest expansion, resilience divergence in stories.

**Success Metric:** Players report that entering politics feels like stepping into a completely different (high-stakes, public, compromise-heavy) life chapter. Approval/heat changes feel visceral. Scandals have lasting family + legacy weight. Clean vs. dirty paths create meaningfully different 20–40 year arcs and next-life starting conditions.

---

## Next Steps Recommendation (as COO)

1. **Immediate (This Session):** Create permanent ROADMAP.md and SPECIAL_CAREERS.md. Port/adapt CODEX.md and CORE_DESIGN.md into /home/workdir/ as clean Markdown.
2. **Core Stabilization First:** Finish bare-bones core (stat island, pressures, instant actions per domain, Age Up feedback parity, basic history/journal) before adding any special career. Use P1–P2 polish patterns from old plan but adapted to new minimal architecture.
3. **Then Special Careers Order:** Athlete (high variance physical drama) → Founder/CEO (economic agency) → **Politics** (public power + moral complexity) → Crime (dark mirror). Each gets dedicated state + instant layer + full modern integration (D4, Fame, Resilience, Family).
4. **Launch Criteria:** One fully deep special path (e.g. Athlete or Politics) + core loop satisfying Glance/Thumb/Codex for 30–60 year satisfying playthroughs. Replayability via LifeResilience + meta echoes.

This keeps us aligned with the original Codex vision while building sustainably on the clean bare-bones foundation.

**Ready for next command:** "Create permanent docs", "Start core stabilization plan", "Draft Founder revival first", or "Implement basic Politics stub with gaps in mind". 

The game is now a clean slate — perfect opportunity to get every special path right from the start with proper depth. Let's make Politics feel like real power with real cost. 

What's your priority, boss?