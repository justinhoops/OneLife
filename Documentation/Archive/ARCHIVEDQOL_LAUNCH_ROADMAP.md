# OneLife - QoL Launch Roadmap (Post P1-P4)

**Date:** 2026-06-20 (Post all D-phases, Fame Web F3, Athlete S3a, Immersion D4, P1 baseline complete)  
**Owner:** COO / Game Director  
**Goal:** Turn the mechanically deep game into a *delightful, glanceable, discoverable, replayable* experience that honors the Codex and ships.

## Current State Diagnosis (Honest)
- **Mechanical Core:** Excellent. Frictionless instant layer + autonomous reactions, LifeResilience, deep Family (personality → adult outcomes → legacy), Athlete revival (potential/brand/accolades/doping), Fame Web unification, D1-D4 domain parity with static always-instants, D4 stance/life-shape/ledger reactivity, dossier seeding, quiet year + continuity engines.
- **Surface Problems (Launch Blockers):**
  1. **Discoverability** still #1: Powerful systems (long-press previews, momentum strip, stance impact on quiet years/legacy, resilience mode, adult child stories) have weak affordances. New players won't find them.
  2. **Glance Rule Erosion:** Late game (adult children + momentum + pressure + shape) gets dense. 2-second audit fails in complex runs.
  3. **Feedback Imbalance:** Instant layer is visceral (deltas, strip, haptics). Yearly "Age Up" is still closer to text cards despite P1/P2 work.
  4. **Onboarding for New Systems:** Stance/life-shape, D4 residue, Fame gravity, adult child persistence — players experience them but don't *understand* why or how to steer.
  5. **Endgame Emotional Punch:** "The End of the Road" and legacy harvest are richer post-P3 but still not consistently novelistic or D4-flavored across all paths.
  6. **Longevity Micro-Friction:** Note accumulation, list density at 60+, edge cases (zero kids, max notoriety, extreme drift) not fully sanded.

**Philosophy (Codex-aligned):** Every QoL change must:
- Make the *core loop more fun right now* (no regressions).
- Preserve frictionless instant vs committed yearly boundary.
- Keep thumb zone + 2-col grids + glanceable chips.
- Add at least one visible feedback moment (note, delta, chip, forecast line, journal echo).
- Be low-overhead (reuse ledger/recentStances/dossier/UI patterns).
- Test: full normal life + special path + weird (heavy drift) life after changes.

---

## Prioritized QoL Feature Backlog for Launch

### Tier 1: Critical Path (Do Immediately — "Players can actually use what we built")
**Priority 1: Discoverability & First-Time Teaching (Phase 4 Completion + D4 extensions)**

**Why:** Highest leverage. The game has *more* depth than most life sims, but players won't experience it if they can't find the levers.

**Key Deliverables:**
- Persistent subtle affordances on *all* action rows: small "hold" icon + micro-text ("Hold to preview") or pulsing border hint on first interaction.
- Momentum strip v3: Domain color coding, tappable for one-tap explanation modal ("This bar shows how your quick actions are shaping the next year"), short "How to build: X actions" hints per domain.
- LifeResilience indicator: Subtle persistent badge or header phrase that evolves ("Grounded — fighting back", "Resilient — riding the wave") + journal reflections that name the mode's flavor in quiet years/forecasts.
- D4 / Stance / Life-Shape teaching: 2-3 lightweight contextual first-life journal entries + forecast subtitles ("Your recent pushCareer focus is already coloring what the world brings you.", "The looseness you allowed is still in the frame.").
- Adult children first-appearance coach: Short explanatory line + "These are the same children from earlier years — watch their outcomes" when the section appears.
- Long-press preview enhancements: Append D4 impact ("Shapes your life (driven) + legacy echoes") + stance residue note.

**Files Likely Touched:** LifeConsoleView.swift (strip, hints, badges), ContentView.swift (previewAction, forecast, journal seeding), DomainActionRegistry.swift (hint strings if needed), SilentYearEngine.swift / ContinuityThreadEngine.swift (D4 flavored notes), NarrativeToneResolver.swift (if tone shifts).

**Success Metric:** New player can describe what the momentum strip does and use long-press preview without external help within first 15 active minutes. Stance choice feels intentional by year 3-4.

**Priority 2: Glance Rule & Late-Game Hierarchy (Phase 6 Full + Compact Mode)**

**Why:** Mid/late game is where the depth shines (adult children stories, fame gravity, accumulated shape, multiple pressures). If it becomes a wall of text, players disengage.

**Key Deliverables:**
- Compact late-game mode (trigger age 32+ or childCount > 2 or heavy career): Collapsible console sections (Family at-home vs adult glance chips), context ribbon showing top 3 pressures with icons + short labels.
- Adult child glance chips: Icon + name + current vibe/status + recent story teaser (tap expands). No functionality lost.
- Pressure deck & planner cards: Icon-first + shorter labels, entire rows remain strong tap targets. Collapsible feed cards where safe.
- Main console 2-second audit pass: Re-validate stat island, momentum strip, top pressures, recommended chips are glanceable.
- Progressive disclosure: "Show more" on dense lists (notes, history) with smart defaults.

**Files Likely Touched:** LifeConsoleView.swift (compact mode logic, chips, ribbon), ContentView.swift (summaryView, pressure views, family sections), existing compact patterns from Phase 6.

**Success Metric:** Player can accurately name their top 3 current pressures/states + what their life shape is within 2 seconds of opening the console, even at age 45 with 2 adult children.

**Priority 3: Yearly Feedback Parity & Visceral Commitment (P1/P2 Polish + Extension)**

**Why:** The "big commit" (Age Up) must feel as rewarding/punishing as the instant micro-moves. Currently instant wins on visceral feel.

**Key Deliverables:**
- spawnYearlyDeltas extended: Always fire for stanceOutcome, focusOutcome, lifeShape shift, major pressure changes, resilience spillover. Match instant floating style + color + haptics (AppFeedback.impact medium/heavy).
- summaryView overhaul: Prominent "Stance & Shape" block with recent focus arrows, repeat count ("pushCareer ×3 — rut forming"), "This is writing your life shape" narrative line, D4 residue callout.
- Momentum block always surfaced on year summary (with shape color).
- "Small Win To Try" or lesson even on harsh years (tied to protectHealth / stabilize / recent stance).
- Haptic/visual unification: Consistent pulse language across instant and yearly beats.

**Files Likely Touched:** ContentView.swift (spawnYearlyDeltas, summaryView, onAppear haptics), LifeConsoleView.swift (momentum strip shape), AppFeedback.swift if new patterns, GameViewModel.swift.

**Success Metric:** Players report that committing to a year "feels worth it" and the review card gives clear "what changed because of my focus" signal. Yearly now matches instant joy/pain.

---

### Tier 2: High-Impact Polish (Next After Tier 1 — "Feels Complete & Professional")
**Priority 4: Endgame, Legacy & Replay Emotional Payoff (P3/P5 + D4 extensions)**

**Why:** The game earns replay when previous lives visibly matter and endings feel like real closure, not "you died, try again".

**Key Deliverables:**
- Richer "The End of the Road" variants (5+ per major path + D4 shape modifiers + stance residue + resilience flavor). E.g., driven founder coup vs loose founder quiet fade; athlete clean legend vs edge scandal exit.
- Legacy harvest expansion: More D4 flags ("lived_driven", "left_loose_ends", "modeled_steady_care", "fought_back_late_and_won"), adult child specific callbacks in harvest text, stance scars visible in next-life echo.
- "One More Life" flow: In creation or post-end screen, show previous life echo summary (shape, key flags, adult child outcomes teaser) + how it seeds starting conditions. Make replay hook visceral.
- Adult child reappearance events: More variety tied to player history (reconciliation, asking for help, proud update) with D4 flavor.

**Files Likely Touched:** ProgressCoreSystems.swift (harvest, flags, end notes), SpecialCareerCrimeSystems.swift + EducationCareerSystems.swift (path-specific end text + D4), RelationshipFamilyHealthAssetSystems.swift (adult leaving + reappear), OriginSystem.swift (meta echo + starting notes), ContentView.swift (end screen + one more life UI).

**Success Metric:** Players describe different endings based on their stance/shape choices. "One more life" feels compelling because the new start *remembers* the last run.

**Priority 5: Narrative Micro-Texture & Quiet Year Variety (P1/P3 extension)**

**Why:** Quiet years are where immersion lives or dies. D4 made them reactive; we need more volume and specificity so 60-year runs don't feel repetitive.

**Key Deliverables:**
- Expand SilentYearEngine.pickNote pool with more D4/stance/ledger/era/path specific lines (target +15-20 high-quality variants).
- ContinuityThreadEngine lookbacks and age milestones get stronger recentStances + lifeShape flavor.
- Forecast subtitles and year anticipation text always name the current shape + dominant stance residue.
- Special path voices (already 5-voice) extended to more regular archetypes and edge cases (e.g., gig economy with drift, high-fame parent pressure on kids).

**Files Likely Touched:** SilentYearEngine.swift, ContinuityThreadEngine.swift, EventEngine.swift (if new conditions), NarrativeToneResolver.swift, SpecialCareerCrimeSystems.swift / EducationCareerSystems.swift (voice injection points).

**Success Metric:** A 40-year run has visibly different quiet year texture based on whether the player was driven vs loose vs careful. No two lives feel narratively identical in the middle years.

**Priority 6: Accessibility, Ergonomics, Longevity & Edge Polish (P5)**

**Why:** Professional ship quality. Long runs must stay pleasant; all players (including with disabilities) can access the depth.

**Key Deliverables:**
- Full VoiceOver audit: Meaningful labels on all chips, strips, action rows, modals, adult child cards. Dynamic Type support pass on dense views.
- Thumb zone & target audit: Re-confirm all primary actions (Age Up, quick grids, long-press areas) meet 52-74pt minimums even in compact mode.
- Performance & accumulation hygiene: Cap or smart-truncate history/notes for 80+ year lives + 4+ adult children. Test save size and load times.
- Edge case handling: Zero kids legacy paths feel complete (not empty), max fame/notoriety has proper scrutiny language without breaking UI, extreme drift runs have coherent "loose edges" narrative without soft-locking.
- Reduced motion / haptic intensity options in settings (if not already).

**Files Likely Touched:** ContentView.swift, LifeConsoleView.swift, various System files for note capping, Accessibility modifiers, Persistence.swift (if save optimization).

**Success Metric:** 80+ year life with heavy family loads smoothly. VoiceOver user can navigate core loop and understand state without visual reliance. No rage-quit edges.

---

### Tier 3: v1.0+ or Post-Launch (If Time)
- Journal search/filter by domain/tag or text.
- Life stats dashboard (achievements, shape history graph teaser, key decision log, "what shaped you most").
- Settings: Haptic intensity, color-blind accent palette, "reduced prose" mode for glance-heavy players.
- Creation flow: Stronger dossier impact preview with "this wiring tends toward X shape" teaser + resilience mode feel hint.
- Meta progression UI: Visible "Echo from Before" in creation with flavor.

---

## Implementation Principles for All QoL Work
- **Playability First:** After every change, the game must feel *better to play* immediately. No "we'll polish later" that breaks current flow.
- **Reuse & Low Overhead:** Leverage existing patterns (long-press preview system, AppFeedback, recentStances tally, ledger pulses, DomainNote style, compactItem views, ALWAYS badges).
- **Visible Feedback Mandate:** Every new surface element must have at least one clear "the world noticed" moment (delta, chip change, journal note, forecast line, shape color shift).
- **Test Protocol:** After major QoL slice — manual full life (normal dossier), one special path (athlete or founder), one weird run (heavy drift or max variance). Verify 2-second glance + discoverability.
- **Agent-Ready:** All work broken into small, file-specific tasks with clear patterns and integration notes.

---

## Next Commands / Agent Handoff
- **"qol discoverability"** → Execute Priority 1 tasks (create or update agent file with concrete edits).
- **"qol glance"** → Execute Priority 2 compact mode + chips.
- **"qol feedback"** → Polish yearly deltas + summaryView.
- **"qol endgame"** → Richer endings + one-more-life echo.
- **"qol launch checklist"** → Full pre-ship audit mapped to above.

This roadmap turns the current "impressive systems game" into the Codex vision: raw, immersive, glanceable, thumb-friendly, and replayable. The depth is already there — QoL makes players *feel* it without friction or confusion.

Ready when you are. Say the priority or command and we'll spin up the agent task file + targeted implementation.