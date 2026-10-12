# OneLife UI Overhaul — Instant Actions & Frictionless Layer (Post-D4)

**Date:** 2026-06-21  
**Status:** Tier 1 COMPLETE (2026-06-21) · Tier 2–3 pending  
**Owner:** COO (planning) + iOS Dev (Justin)  
**Scope:** Targeted surface overhaul of the instant actions / quick actions / "Right Now" frictionless layer. **Not a full UI redesign.** Preserve the top stat island (Happy/Health/Smart/Looks/Rep/cash) exactly. Preserve and lightly enhance the bottom domain tab bar (standardize to Home/Life, Occupation/Career, Assets/Finance, Family, Activities/Play).  

Focus: Fix erosion of Glance Rule, Thumb Zone ergonomics, and discoverability caused by recent D4 integrations (Year Goals, stances, life shapes, focus residue, continuity notes) bleeding into or competing with instant action surfaces.  

All changes must keep the game **more playable** after every edit. Low-overhead (reuse existing ActionTray, previewInstantAction, momentum strip, ALWAYS badges, floating deltas). No new heavy systems or snapshot work.

---

## Core Diagnosis from Latest Playtest

After integrating D4 (stances + life shapes + year goals + residue in forecasts/silent years/legacy) + prior P1–P4 polish + fame/sports depth:

**Strengths preserved:**
- Stat bar remains glanceable and persistent.
- Bottom domain tabs provide clear navigation.
- Instant layer (static always quick actions, dedicated subdomain actions for athlete/founder/etc., frictionless pipeline) is mechanically excellent and responsive.
- ALWAYS badges, long-press previews, floating deltas, momentum strip, and autonomous reactions already exist and work.

**Problems surfaced in play:**
1. **Glance Rule Erosion in Action Areas**: Stance chips, life shape subtitle in momentum strip, year goal line, and focus residue notes are competing for visual weight near or inside the "Right Now" / Quick Actions 2-col grids. Player has to work harder to scan available instant moves.
2. **Discoverability Still Weak for Previews**: Long-press is powerful (shows D4 carry now) but affordance (how player knows to hold) is not visceral enough after D4 additions. New players miss the "hold for what this does to my shape/legacy" layer.
3. **Action Grid Crispness Regression**: More static instants + D4 flavor in notes/previews made some 2-col grids feel slightly denser or less thumb-ergonomic in mid/late game. Titles/subtitles could be tighter.
4. **Momentum Strip + D4 Integration**: Shape info is valuable but the strip can feel busier; D4 residue sometimes leaks into places it shouldn't (strip itself vs preview/summary).
5. **Mental Model Blur**: Instant micro-moves vs yearly stance/goal commitment is clear in code/docs but the UI surfaces don't always reinforce the boundary visually after recent changes.

**Codex Alignment Check:**
- Glance Rule (2s audit): Currently strained in console/action zones.
- Thumb Zone: Mostly good but grids need re-confirmation for late-game density.
- Frictionless Immersion: Mechanically there; surface needs to feel as clean as the pipeline.
- Continuity: Must feel like the same game — same visual language, no new tutorial walls.

Success looks like: A player opens the console, sees top 3 pressures + 3–4 obvious instant taps in <2 seconds, knows to hold for preview (including shape/legacy echo), and the D4 elements add weight without noise.

---

## Scope Boundaries (What We Are NOT Doing)

- No changes to stat bar (top island) — keep exactly as-is or only micro polish if it conflicts.
- No full bottom tab redesign — only ensure domain tabs surface the right instant trays cleanly and standardize labels if needed (Home/Life, Occupation, Assets, Family, Activities).
- No new models, orchestrator changes, or heavy logic. Pure UI hierarchy, affordance, copy, and layout tweaks in existing components.
- No heavy onboarding/tutorial. Lightweight affordances + contextual preview text only.
- No late-game full compact mode overhaul (already exists from Phase 6); just apply consistent rules to action grids.
- Full UI polish (P5) deferred; this is focused instant layer recovery.

---

## Proposed Overhaul Deliverables (Tiered)

### Tier 1 — Immediate (Restore Glance + Basic Affordance)
**Goal:** Make instant actions the clearest, most thumb-friendly thing on screen again. D4 context supportive and secondary.

1. **Momentum Strip Polish (LifeConsoleView.swift)**
   - Keep at top of console (persistent, always visible).
   - Life shape: Move from inline subtitle to a compact, reactive colored pill/capsule next to domain bars (e.g., "Driven" in purple, "Loose" in orange, "Careful" in green). Tappable → short explanation sheet: "Your recent focuses are quietly writing this shape into silent years, forecasts, and legacy echoes."
   - Domain momentum bars/icons: Cleaner spacing, domain color coding preserved, tap still shows context or history if useful.
   - Remove any D4 residue text from the strip itself. Shape pill + domain bars only. D4 details live in previews, year summary, and journal.
   - Haptic on tap for shape pill (light impact).

2. **Action Grids / "Right Now" Refinement (ActionTray component + LifeConsoleView + per-domain views in ContentView.swift)**
   - Header standardization: "Right Now — Instant (ALWAYS)" with refined green-tinted ALWAYS capsule. Consistent across all domain tabs and Home.
   - 2-col LazyVGrid rules (enforce):
     - Min tap target 56–64pt.
     - Short titles (already using quickActionTitle overrides — audit and tighten any that crept long).
     - Subtitles: Max 1–2 lines, flavorful but scannable. Leverage existing microBeat / identityLine where present.
     - Even row heights for visual calm.
   - Long-press affordance upgrade (discoverability win):
     - Add subtle persistent "hold" icon or micro-text ("hold") to the right of action title on buttons that have rich previews (most do now with D4).
     - First-time or low-interaction: Very subtle border pulse or icon highlight for 3–5 seconds on first open of a tab (cheap, dismisses after interaction).
     - Preview popup: Keep rich (effects + autonomous reaction summary) + append **one** D4 line when relevant: "Reinforces your driven current — will echo in quiet years and shape next-life starting signals." Or "Aligns with your careful stance this year." Keep it optional and short.
   - Visual separation: Instant action grids must feel distinct from stance/year-goal/commit area. Use subtle card/background treatment or spacing so player never confuses "tap now for instant" with "choose stance for the year."

3. **Stance / Year Goal / Focus UI Separation (ContentView planner area + year summary)**
   - Keep Year Goal choice and stance selection in the central planner / commit flow (not inside instant grids).
   - Stance chips and focus residue: Confine primarily to year summary card (already improved in P1) and preview tooltips. Small optional chips only if they don't crowd action grids.
   - In forecast / anticipation text: Keep the D4 flavor ("The shape of recent years is still with you") but ensure it doesn't push instant actions down or make grids feel secondary.

### Tier 2 — Domain Tab Consistency + Polish
**Goal:** Every domain tab feels like it has its own sovereign instant toolkit without visual conflict.

- Standardize bottom tabs (if not already perfect): Home/Life (general + self instants + quick access), Occupation/Career (regular + special track statics), Assets/Finance (collector + maintenance), Family (parenting + light anchors), Activities/Play (or merge with Home if needed). Max 5 tabs.
- Each tab's instant tray shows: Relevant staticCore + promoted subdomain instants (athlete on Occupation when active, etc.) + general always-available where they fit (protect energy, etc.).
- Subtle domain momentum or shape hint in tab header only if it passes glance (optional, low priority).
- Late-game: If action count grows, reuse existing compact/collapsible patterns from Phase 6 on the grids.

### Tier 3 — Final Micro Polish & Verification
- Accessibility: VoiceOver labels on hold icons, good contrast on shape pills.
- Longevity test: 60+ year life + multiple adult children + high fame/notoriety — ensure action grids don't accumulate clutter.
- Playtest loop: New player run + "weird" run (heavy drift or extreme special path) + verify 2s glance + preview usage.
- Update this plan with COMPLETE blocks per tier (like D/P phases).

---

## Files Expected to Change (Targeted, Low Risk)

- **LifeConsoleView.swift** (primary): Momentum strip (shape pill), ActionTray header/grid affordances, preview handling, domain tab instant surfaces.
- **ContentView.swift**: Per-domain tab views (instant trays), previewAction D4 append logic, year summary stance/shape block (already good from P1 — minor tighten), spawnYearlyDeltas if needed for consistency.
- **DomainActionRegistry.swift**: Audit quickActionTitle shorts for any that are too long post-D4; add lightweight previewHint strings if the "hold" treatment needs data-driven copy (optional, can be static first).
- **Possibly**: InteractionCardCoordinator.swift or FeedbackCoordinator.swift for preview polish/haptics (minor).
- **No changes**: Models.swift, Orchestrator, any resolve*Year, InstantReactionCoordinator, SilentYearEngine, etc. Pure surface.

All edits must compile clean and keep one-handed play intact.

---

## Success Metrics (Measurable)

1. **Glance Rule Restored**: In playtest, average player identifies current top pressures + at least 3 available instant actions within 2 seconds of opening main console (video or timed observation).
2. **Discoverability**: ≥70% of new players use long-press preview on at least one action in first 15 minutes without external prompt (or after minimal coach line).
3. **No Regression**: Instant actions still calculate instantly with floating deltas + autonomous reactions. D4 carry visible in previews/summary but does not slow or clutter the tap flow.
4. **Player Language**: "The quick actions feel clean again." "I can see what my stance is doing without hunting." "Hold to preview is obvious now."
5. **Thumb Ergonomics**: All grids comfortably reachable one-handed; no increase in mis-taps or scrolling in action areas.
6. **Build + Launch**: Clean simulator build + manual 30–60 year play session (normal + one special path) with no UI breakage.

---

## Execution Notes for Agents / Future Work

- **Low-overhead rule**: Reuse existing previewInstantAction, applyInstantActionWithAutonomousReaction, momentum strip component, ALWAYS badge pattern, floating delta spawner. No new snapshot or heavy yearly work.
- **Visual language continuity**: Same colors (domain tints, purple for world reactions, resilience accents), same haptic patterns (AppFeedback.impact), same card treatments.
- **D4 integration philosophy**: D4 (shape, stance residue, year goal) should feel like "background texture that rewards attention" not "front-and-center noise competing with instant taps." Previews and year summary are the right homes for depth; grids stay for action.
- **Permanent vs Session**: This plan file is **permanent** project artifact. Session-specific playtest notes and decisions live in /docs/sessions/ (see companion file for this date). After Tier 1–2 complete, move session file to archive/ if desired.
- **Update cadence**: After each tier execution, append a **COMPLETE** block here (date, what shipped, files touched, verification) exactly like the D/P phase blocks in the main Implementation Plan.
- **Next after this**: Resume P5 final shine or next short command (e.g., balance pass on new instant surfaces, more content for quiet years, or sports/fame polish). This overhaul unblocks clean feel for launch trajectory.

---

## Player Impact Statement (What This Fixes for Justin's Vision)

The frictionless instant layer was one of the strongest recent additions — it makes every domain feel alive and responsive without chore. D4 made the game feel like *your* life with real shape and consequence memory. This targeted overhaul ensures the two strengths don't fight each other on screen. Instant actions stay the delightful, thumb-friendly "Right Now" toolkit. D4 adds the quiet novelistic weight in the right places (previews, summaries, legacy, next-life echoes). The game stays raw/authentic, glanceable, one-hand playable, and genuinely replayable.

The mechanical core is solid. The surface now needs to match so players actually feel the depth without working for it.

**Ready for execution.** Say "tier 1" or "start instant ui overhaul" or give refinements and we'll begin editing LifeConsoleView.swift + ContentView.swift with the usual targeted, build-verified approach.

---

## Tier 1 COMPLETE — 2026-06-21

**Shipped:**
- **Momentum strip:** Life shape moved to tappable colored pill (`LifeShapePill`) with explanation sheet + light haptic; removed inline D4 teach text and domain micro-hint from strip.
- **Action grids:** Standardized header to "Right Now — Instant" + green ALWAYS capsule; hold icon inline on title row; 64pt grid / 56pt list min heights; subtle purple pulse border on first-tab coach.
- **Layout:** `DomainPanelView` instant deck moved above domain header/metrics; `InstantYearPlanDivider` separates instant from Year Plan trays.
- **Previews:** `previewContextLines` tightened to one short D4 line per hold preview.

**Files touched:** `LifeConsoleView.swift`, `SessionUXState.swift`, `Documentation/AgentWork/UI_Overhaul_InstantActions_Plan.md`, `Documentation/Archive/sessions/Playtest_Feedback_2026-06-21_InstantActions_UI.md`

**Verification:** Clean `xcodebuild` for iPhone 17 simulator (Release).

---

*This file is permanent. Do not delete. Link from main IMPLEMENTATION_PLAN.md when convenient.*