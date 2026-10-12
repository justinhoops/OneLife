# Agent Task File: QoL Glance Rule & Late-Game Hierarchy Enforcement

**Priority:** Tier 1 Critical (Prevents disengagement in mid/late game)  
**Related Codex:** The Glance Rule (2-second audit), Thumb Zone, Progressive Disclosure, Information Hierarchy  
**Owner:** COO — density wins without losing depth or tap targets.  
**Test Protocol:** Play to age 40+ with 2+ adult children or heavy career → verify 2-second top pressures + life shape identification. Compact mode must feel lighter but fully functional.

## Context (From Current State)
- Phase 6 Tier 1+ complete: icon-first glance strip, compact late-game mode (age 32+/40+ or heavy family), collapsible console sections, context ribbon, adult-child glance chips, collapsible planner/feed cards.
- Remaining gap: Late game still dense in complex runs (adult children stories + momentum + pressure + shape + fame). 2-second audit fails when lists grow. Players lose the "I can see my life at a glance" feeling that early game has.
- Adult child section and pressure deck are the biggest density culprits.

## Deliverables (Prioritized)

### 1. Strengthen Compact Late-Game Mode (Trigger Logic + Polish)
**Goal:** Automatically lighten the console when life gets complex without player manual work.

**Tasks:**
- Refine compact mode trigger in LifeConsoleView.swift / GameViewModel.swift: age >= 32 OR childCount(atHome + adult) >= 2 OR active special career with high audience/fame OR pressureCount > 4. Make it feel natural, not abrupt.
- Collapsible sections: Family (At Home list vs Adult Children glance-only by default), Notes/History (smart default collapsed after year 10), Planner cards (expandable but default glanceable headline + deltas).
- Context ribbon (top or under stat island): Always shows top 3 current pressures with domain icon + short label + delta arrow. Tap opens full pressure deck. Replaces or augments dense list when compact.
- Ensure all existing functionality preserved: long-press, taps, navigation, Age Up FAB remains prominent in thumb zone.

**Files:** LifeConsoleView.swift (compact logic, ribbon, collapsibles), ContentView.swift (family rendering, pressure views), GameViewModel.swift (computed compact state + top pressures).

**Success Signal:** At age 45 with 2 adult kids + career + momentum active, player opens console and immediately sees top pressures + shape without scrolling or hunting.

### 2. Adult Child Glance Chips — Icon-First + Teaser + Expand
**Goal:** Adult children section is glanceable and emotionally meaningful, not a wall of profiles.

**Tasks:**
- Render adult children as horizontal or compact vertical chips (reuse compactItem pattern): 
  - Leading icon (age-appropriate or personality vibe emoji/icon)
  - Name + short status/vibe (e.g., "Ivy, 24 — thriving in tech")
  - 1-line recent story teaser (e.g., "Proud update last year")
  - Subtle bond or outcome indicator (color dot or small heart)
- Tap chip → expands to full card or modal with key stories, current lifeVibe, relationshipQuality, any reappearance hooks.
- In compact mode: Adult section defaults to "3 adult children — 2 thriving, 1 struggling" summary + "View details" affordance. No functionality lost.
- First-appearance coach (cross-ref Discoverability agent): Short line explaining continuity.

**Files:** ContentView.swift (family sections + chip rendering + expand logic), RelationshipFamilyHealthAssetSystems.swift (AdultChildProfile data + recent story access), LifeConsoleView.swift (if shared family glance).

**Success Signal:** Player glances at adult children section and knows emotional state of each without reading full paragraphs. Can expand for depth only when wanted.

### 3. Pressure Deck & Planner Card Density Reduction
**Goal:** Pressure and feed views stay informative but never overwhelming.

**Tasks:**
- Pressure deck (ContentView.swift): Icon + short label for each pressure type. Entire row remains large tap target (min 52pt). "X more" truncation with expand.
- Planner / feed cards: Headline + 1-2 impact bullets + stance/focus callout. Collapse long prose by default; "Read more" for full DomainNote if needed.
- Use existing compactItem and icon-first patterns heavily.
- In compact mode: Hide secondary pressures or show only top 3 + "Manage pressures" entry point.

**Files:** ContentView.swift (pressure views, planner/feed cards), LifeConsoleView.swift (any shared card components).

**Success Signal:** Player can name current top pressures in <2 seconds even with 5+ active pressures.

### 4. Main Console 2-Second Audit Pass (Validation + Micro-Fixes)
**Goal:** Re-validate the core "I open the game and know my life state instantly" promise.

**Tasks:**
- Audit stat island (Happy/Health/Smart/Looks/Rep/cash): Ensure icons + numbers + subtle delta arrows are primary; labels secondary.
- Momentum strip: Already prominent — ensure shape color + current strongest domain pops.
- Recommended / Right Now chips: Icon-first, short titles, ALWAYS badge consistent.
- Top pressures / context ribbon: Visible without scroll.
- Age Up FAB: Large, labeled, thumb-center, never obscured.
- Micro-fixes: Consistent spacing, no overlapping elements in compact, dynamic type safe, high contrast accents remain readable.

**Files:** LifeConsoleView.swift + ContentView.swift (main console layout).

**Success Signal:** In any life stage, opening the console lets player answer "What matters most right now?" in 2 seconds or less.

### 5. Progressive Disclosure Hygiene
**Goal:** Depth is available but never forced on first glance.

**Tasks:**
- History / journal / notes lists: Default to last 5-8 entries + "View full history" (searchable later in Tier 3).
- Long note text in modals: Headline + bullets first, full prose expandable.
- Adult child / asset / relationship detail views: Summary card first, details on demand.
- All "show more" affordances use consistent language and icon.

**Files:** ContentView.swift, LifeConsoleView.swift (list rendering).

## Integration Rules
- Compact mode must feel like a *relief*, not a restriction. All core interactions (Age Up, quick actions, long-press, navigation) remain equally easy or easier.
- Reuse every existing compact/glance pattern from Phase 6 work.
- No loss of information — only better hierarchy and progressive disclosure.
- Every density win must preserve or improve thumb ergonomics.
- Test with heavy late-game state (many notes, adult children, active fame/momentum, multiple pressures).

## Verification Checklist
- [ ] Compact mode triggers naturally and lightens the view without hiding critical info.
- [ ] Adult child chips are glanceable (status + teaser) and expandable without breaking flow.
- [ ] Top 3 pressures visible in <2s on main console even in complex runs.
- [ ] All tap targets remain strong (52pt+), long-press works everywhere expected.
- [ ] No visual clutter or overlapping elements; consistent icon-first language.
- [ ] Game feels *lighter* in late game while retaining full depth on demand.
- [ ] Build + sim launch + 40+ year play session with family/career complexity clean.

## Files to Touch (Summary)
Primary: ContentView.swift, LifeConsoleView.swift  
Secondary: GameViewModel.swift, RelationshipFamilyHealthAssetSystems.swift

**Ready for execution.** Implement in priority order. Update this file with COMPLETE blocks + player impact notes after each sub-task. Keep the "one-handed, glanceable, thumb-friendly" contract sacred.

Handoff ready on "qol glance" command.