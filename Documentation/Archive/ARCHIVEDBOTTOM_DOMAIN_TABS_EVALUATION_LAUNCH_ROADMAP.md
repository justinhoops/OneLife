# OneLife - Bottom Domain Tabs Evaluation & Launch Roadmap

**Role:** COO Assessment & Agent Briefing  
**Date:** June 20, 2026 (Post all D-phases, Fame Web F3, Athlete S3a + S3 Family/Health depth, P1-P4 Polish, D4 Immersion)  
**Context:** Follow-up to popup reduction (only essential, game-correlated modals/sheets remain: long-press previews, major narrative payoffs, player-initiated depth sheets, first-time coaches). The bottom tabs + inline cards + floating deltas now carry even more of the feedback and hierarchy load.  
**Goal:** Evaluate the current native TabView + domain console implementation for launch readiness. Identify polish/features that make the bottom domain navigation feel sovereign, glanceable, unified by Fame/D4/Resilience, and frictionless. Prioritize work that contributes directly to a shippable, replayable product.

---

## Executive Summary (COO View)

The bottom domain tabs have undergone a major successful refactor: dead custom bar code (~150 lines) deleted, native iOS `TabView` as stable root with system-managed tab bar at true bottom, `LifeConsoleView` now derives `currentDomain` cleanly from `vm.selectedTab`, and every domain hosts prominent BitLife-style "Right Now" 2-col instant action grids that are always available and wired to the full instant pipeline (reactions, ledger, D4 stance/life-shape, Fame propagation).

**This is a strong foundation for launch.** It delivers domain sovereignty in the UI, thumb ergonomics (Age Up FAB + Assets jump + stance affordance overlaid just above the native tab bar in the green zone), and frictionless play (static quick actions per domain + sub-track when active).

However, for a polished launch experience that honors the Codex (Glance Rule / 2-second audit, Thumb Zone, Summary-to-Action, Domain Sovereignty + unified signals via Fame Web and D4), the tabs themselves need surface-level enhancements. They currently feel functional but not yet "alive" with the depth of the mechanical systems (athlete pillars, founder stage, adult child outcomes, life-shape residue, unified Recognition, resilience divergence).

**Launch Verdict:** Tabs are mechanically solid and stable. They are not the blocker. The next 2-4 weeks of focused polish on glance indicators, dynamic headers per special track, and consistent affordances will make the bottom navigation a strength rather than neutral infrastructure. This directly supports the "playable core loop" and "visceral feedback" goals without reintroducing popup bloat.

**Recommended Focus:** Keep popups/sheets to the essential minimum already agreed (previews for discoverability, major narrative beats, opt-in depth). Let the tabs + floating deltas + stance chips + compressed cards do the heavy lifting for moment-to-moment play.

---

## Current Architecture (What We Have)

- **Root:** Native `TabView(selection: $vm.selectedTab)` with `GameViewModel.Tab` enum (5 tabs). Each tab hosts thin `DomainTabContent` wrapper → `LifeConsoleView`.
- **Domain Derivation:** `currentDomain` computed from selectedTab. `panel` (DomainPanelModel) and grids update reactively. No more `@State` sync hacks.
- **Bottom Bar:** System tab bar (true bottom, safe areas respected). Persistent controls (big Age Up min 52pt bouncy FAB, quick Assets jump button, "Continue last stance" affordance) in `.overlay(alignment: .bottom)` positioned reliably above the tab bar.
- **Per-Tab Content:** 
  - Prominent "Right Now" / Quick Actions 2-col LazyVGrid with static always-available instants (ALWAYS badge).
  - Domain-specific deeper panels (metrics, lists, history).
  - Special handling: Military replaces Occupation tab when track active. Athlete/founder/creator/politics/crime quick actions appear contextually when track active.
  - Life/Home tab: Identity self-work + general quicks + priority domains surfaced.
  - Family: Phase-gated but integrated (at-home vs adult children separation improving).
- **Wiring:** All static instants route through `DomainActionRegistry` → `ActionSystem` → instant apply + `InstantReactionCoordinator` (ledger pulse for D4/Silent/Continuity/Autonomy) + momentum + Fame effects.
- **Feedback Surface:** Floating deltas (now on yearly too via P2), momentum strip (with life-shape subtitle + color), stance chips with residue, compressed year summary cards (headline + bullets + "because of your focus").
- **Cleanup Wins:** Removed custom bottomConsoleBar, bottomGameBar, safeAreaInset fights. TabView is the single source of truth for domain navigation.

This architecture directly supports the two-speed contract, popup stability, and frictionless immersion.

---

## Honest Evaluation (Strengths + Gaps for Launch)

### Strengths (Launch-Ready Foundation)
- **Ergonomics & Stability:** Native tab bar + overlay controls = reliable thumb zone, no geometry wars, consistent iOS behavior across devices/safe areas. Big win after previous custom bar issues.
- **Frictionless Domain Access:** Every tab has its "Right Now" grid of static instants that calculate instantly with full autonomous reactions. No planner commitment needed for micro-moves. This is exactly the BitLife-style request delivered.
- **Domain Sovereignty + Cross-System Integration:** Tabs react to active special tracks, dossier, era, resilience mode, and now feed/present D4 life-shape and Fame Web effects. Stance choice in one domain visibly shapes quiet years and other domains via ledger.
- **Glance + Action Pipeline:** 2-col grids + long-press previews (essential for discoverability) + floating deltas keep most interactions in flow. Ties perfectly to the popup reduction decision — only essential correlated popups remain.
- **Scalability:** Easy to add new domains or sub-track quicks without breaking the root. Military swap is already handled.
- **Performance:** Thin wrappers, computed properties, cached snapshots in instant path. No heavy work on tab switch.

### Gaps (What Prevents "Feels Complete" at Launch)
1. **Tab-Level Glance Rule Erosion (Highest Priority Polish Item):** The bottom tab bar itself is neutral. It doesn't surface key live states (domain momentum/pressure, life-shape tint, Recognition weight, active track health). Player must tap to audit top pressures. Violates the original "2-second audit" and "Information Hierarchy" diagnosis. With fewer popups, this matters more.

2. **Dynamic Special Track Surface in Occupation Tab:** When athlete/founder/creator/politics active, the tab should feel like *that career's dashboard*, not a generic Occupation console with extra quick actions. Athlete pillars (Peak/Potential/Brand/Accolades/Edge Heat), founder stage/valuation/board pressure, etc., need prominent, glanceable real estate. Currently the metrics are there but not elevated to "this tab is now the athlete control center."

3. **Family Tab as Legacy Dashboard:** Adult children + outcomes are mechanically deep (personality, bond, adult milestones, D4-modeled departure notes, legacy flags). The tab needs clearer visual separation ("At Home" vs "Adult Children" with status chips + recent story teaser) and emotional texture so it feels like the long-term consequence layer, not just another list. Phase-gating is good, but presentation can be tighter.

4. **Unified Fame/Recognition & Life-Shape Signals Across Tabs:** Fame Web and D4 are powerful but mostly surfaced in dedicated cards or journal. Tabs should subtly reflect cross-domain gravity (e.g., high culturalFame/notoriety tints Opportunities or adds subtle "Name carries weight" header; driven current life-shape adds a persistent accent or subtitle in active tab). Without this, the unification feels mechanical rather than lived.

5. **Consistent Affordance & Micro-Feedback:** Long-press "hold to preview" hints, domain color coding, and ALWAYS badges are good but not uniformly applied or visually crisp across all 5 tabs. Haptics on meaningful tab interactions or delta spawns could be more consistent. Late-game density (many adult children, long history) still risks scroll fatigue even with Phase 6 compact mode started.

6. **Assets Jump & Cross-Tab Navigation:** The floating Assets button is useful but could be smarter (contextual to current domain or highlight when collector opportunities exist). No quick "jump to relevant tab" from year summary or events when a domain spikes.

These gaps are surface/polish, not architecture. They are exactly the "surface, discoverability, and feel" work called out as remaining after mechanical lifts.

---

## Recommended Feature Prioritization (Launch-Focused)

Prioritize in this order so every slice improves playability and contributes to a shippable product. All work respects: low overhead (reuse ledger, recentStances, dossier, existing UI patterns), visible feedback on every change, thumb ergonomics preserved, no regression on instant path.

### Tier 1 (Immediate — This Slice / Next 1-2 Weeks): Glance & Tab Polish
**Goal:** Make the bottom tab bar itself part of the 2-second audit. Player knows top domain pressures + life-shape + Recognition weight without tapping.

**Status:** COMPLETE (June 19, 2026)

**Features:**
- Add subtle live indicators on tab icons or labels: small colored dots/bars for domain momentum/pressure (H/Money/People), life-shape color accent (orange loose, purple driven, green careful) on active tab or header strip.
- Recognition / Fame flavor header subtitle when high (e.g., "Your name carries weight (and risk)" or "The world already has expectations" — reuse forecast tone language). Appears in active tab header or as a persistent ribbon.
- Consistent long-press affordance polish: "HOLD" micro-text or icon on all action rows in every domain's Right Now grid. Subtle spring animation on press.
- Life/Home tab header: Add current life-shape + recent stance residue line (already in year summary; surface lightly here too).

**Delivered:**
- `PillDockTabBar`: domain pressure dots on dock icons; life-shape accent strip on active tab
- `GameViewModel`: `consoleDomain(for:)`, `dockTabSignal(for:)`, `lifeShapeAccentColor()`, `lifeTabResidueLine()`
- `CohesionNarrative.tabHeaderRecognitionSubtitle` (fame ≥ 24) wired into domain panel headers
- Right Now grids: persistent HOLD affordance when previews exist; Play tab hub matches with long-press previews
- Life tab panel header shows shape + stance residue line

**Files to Touch:** `LifeConsoleView.swift` (header/tab indicators, computed shape/momentum props), `ContentView.swift` or `GameViewModel` (expose lightweight domain pressure + Recognition summary), `DomainActionRegistry.swift` (if new static affordance helpers needed).

**Success Metric:** New player can name their top 2-3 domain pressures + current life-shape + whether they have meaningful Recognition within 2 seconds of opening any tab. No new popups added.

### Tier 2 (High — Polish Phase Continuation): Dynamic Occupation & Family Dashboards
**Goal:** When special tracks or family depth are active, the relevant tab feels like the soul of that chapter of life.

**Status:** COMPLETE (June 20, 2026)

**Features:**
- **Occupation Tab:** Dynamic header/metrics block that elevates the active track.
  - Athlete active: Prominent "Peak Form / Potential / Brand / Accolades" pillars + Edge Heat indicator + quick access to athlete-specific dashboard view (or expandable). Narrative voice line ("The clean one chasing legacy" or "Pushing the edge").
  - Founder active: Valuation trend, traction stage, board pressure gauge, founder mental load note.
  - Regular career: Archetype voice + performance vs burnout glance.
  - Always show how current track contributes to unified culturalFame/notoriety.
- **Family Tab:** Visual + emotional upgrade.
  - Clear split sections: "At Home (support load X)" with child chips (name, age, bond vibe, temperament hint).
  - "Adult Children" section with outcome/status chips + recent story teaser line (D4 flavored: "They swore this would look different..." or pride/worry residue).
  - Subtle legacy pressure indicator if high-stakes adult outcomes pending.
  - Quick actions grid always includes family anchors (meal, story time) + parenting levers when relevant.

**Delivered:**
- `ConsoleTabDashboards.swift`: `OccupationTrackDashboardView`, `FamilyTabDashboardView`
- `CohesionNarrative`: athlete/founder/career dashboard builders + family dashboard + fame contribution line
- Work panel founder metrics branch; family quick actions prepend `familyMeal` / `storyTime`
- People tab: support-load header, horizontal at-home chips, adult story teaser + legacy pressure ribbon

**Files to Touch:** `LifeConsoleView.swift` (dynamic header logic per currentDomain + special track), `SpecialCareerCrimeSystems.swift` (expose athlete/founder summary structs if needed for UI), `RelationshipFamilyHealthAssetSystems.swift` (adult child glance helpers), `ContentView.swift` (year summary integration if linking).

**Success Metric:** When on athlete track, the Occupation tab immediately communicates the four pillars and current drama (injury risk, brand heat, legacy path) at a glance. Family tab makes adult children feel like continuation of your story, not a separate list. Players report "this tab feels like my [athlete/founder/parent] life."

### Tier 3 (Medium — Pre-Launch Shine): Unified Signals + Micro Polish + Late-Game
**Goal:** Fame Web, D4 life-shape, and resilience feel lived across every domain tab. Consistent micro-interactions. Handles long lives gracefully.

**Features:**
- Cross-domain Fame/Recognition leakage visible: High culturalFame adds opportunity flavor or subtle header in multiple tabs (e.g., "Doors open easier because of who you are"). High notoriety adds heat/scandal risk callouts.
- Life-shape persistent accent: Active tab or momentum strip header tinted by current shape; quiet years in journal reference it.
- Assets jump button enhancement: Context-aware (highlights when in Finance/Assets tab or when collector events available). Optional quick "switch to relevant domain" from event notes.
- Late-game compact mode (finish Phase 6): Icon-first or collapsible sections in Family (long adult child lists), Occupation (history), Assets (many signature items). Trigger at age 40+ or when childCount + career complexity high.
- Micro polish: Domain color coding consistent (icons, accents, delta colors). Haptic on tab switch for meaningful state changes (cheap). ALWAYS badge visual polish. Preview popups stay lightweight (no new sheets).

**Delivered:**
- `CohesionNarrative.crossTabFameLeakageLine` + cached `domainFameLines` on `ConsolePresentationSnapshot`; shown in domain panel headers
- Life-shape accent on momentum strip; journal sheet shape echo via `LifeLogView(lifeShapeLine:)`
- `AssetsJumpSnapshot` + `AssetsJumpChromeButton` between Age Up and dock tabs (context-aware highlight)
- Late-game compact: collapsible occupation metrics when track dashboard shown; compact signature assets on Money tab when `compactLateGame`
- Micro polish: domain-colored dock icons, medium haptic on strained tab switch, ALWAYS badge stroke/shadow
- Tests: `tierThreeCrossTabFameLeakageSurfacesByDomain`, `tierThreeAssetsJumpHighlightsCollectorAndMoneyTab`, `tierThreeDomainFameLinesCachedInPresentation`

**Files to Touch:** `LifeConsoleView.swift`, `ContentView.swift` (Fame effects in headers, compact logic), `ProgressCoreSystems.swift` / `OriginSystem.swift` (if new glance helpers for legacy flags), `InstantReactionCoordinator.swift` (if new ledger signals for tab indicators).

**Success Metric:** A 60+ year life with adult children + special career + high fame feels scannable and emotionally textured in every tab without density fatigue. "One more life" replay hook is stronger because tabs make the accumulated shape/fame visible immediately.

---

## Dependencies & Risks

- **Dependencies:** Builds on D4 immersion (life-shape, stance residue), Fame Web propagation (unified culturalFame/notoriety feeding tabs), Athlete/Family depth (S3 + P3), static quick actions (D1/D2 complete), floating deltas + year cards (P1/P2). No new heavy yearly work.
- **Risks:** Over-adding indicators could erode glance rule if not subtle (keep to dots/bars + 1-line subtitles). Dynamic headers must not break tab switch performance (use computed + small extracted views). Late-game compact must preserve all taps (no lost functionality).
- **Non-Goals:** Do not reintroduce heavy popups or custom tab bars. Do not add new committed yearly actions here — keep frictionless instant focus. Avoid scope creep into new domains.

---

## Success Metrics for Launch (Measurable)

- Player can perform 2-second top-of-mind audit (top pressures + life-shape + Recognition status) from any tab without opening extra views.
- Special track tabs (athlete/founder) feel like dedicated career dashboards with clear narrative voice and mechanical drama visible at a glance.
- Family tab communicates long-term consequence and emotional texture of parenting choices (D4 modeled).
- No regression in instant action responsiveness or popup stability.
- Manual playtest of full normal life + one special path + one high-family life reaches end screen feeling "this life was mine and the tabs told the story."
- Build + sim launch clean; Instruments shows no new view body hotspots on tab switch or indicator updates.

---

## Next Agent Actions (Immediate)

1. ~~**Implement Tier 1 Glance Indicators** (start here — highest ROI for feel).~~ DONE
2. ~~**Prototype dynamic Occupation header for athlete track** (reuse existing athlete metrics; elevate to tab header).~~ DONE (Tier 2)
3. ~~**Audit Family tab current split and add adult child glance chips + teaser lines** (tie to existing adultLeavingNote + D4 flavor).~~ DONE (Tier 2)
4. ~~**Add lightweight Recognition subtitle to active tab header** (reuse existing forecast language; gate behind fame > 24).~~ DONE (Tier 1)
5. ~~**Update this doc with COMPLETE blocks** after each slice (same pattern as D/P phases).~~ DONE (Tier 1–3)
6. ~~**Begin Tier 3** — cross-tab fame leakage, late-game compact polish, Assets jump enhancement.~~ DONE

**Owner:** Implementation agents (via this briefing). COO available for clarification or mid-slice pivots.

**Philosophy:** Every change must make the core loop more fun and glanceable right now. The tabs are the persistent control surface for the life — they should feel like they belong to the story being lived, unified by the powerful systems we've built (Fame, D4, Resilience, Instant Momentum). This is the surface work that turns impressive mechanics into a shippable, replayable game.

Build green. Ship the tabs as a strength.

---

*This document is the living agent brief. Update it with progress. All feature work here directly contributes to launch by strengthening the primary navigation and feedback surface while respecting the essential-popup-only rule.*