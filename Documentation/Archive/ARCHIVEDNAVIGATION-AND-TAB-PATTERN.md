# OneLife Navigation & Tab Pattern Specification

**Version:** 1.0  
**Date:** 2026-06-19  
**Owner:** Justin  
**Status:** Draft for implementation

## Core Principles (Non-Negotiable)
- **Playability before pixels**: Console-first (LifeConsoleView), every major system reachable in ≤2 taps.
- **DomainActionRegistry** is the single source of truth for all actions, outcomes, and domain logic. UI only consumes it.
- **Year loop integrity**: beginYearChapter → cards/pendingActions → AGE UP must remain the heartbeat. Navigation must never block or duplicate this.
- **Glanceability**: Top Stat Island (Happy / Health / Smart / Looks / Rep / Cash) always visible or one-tap collapsible. Bottom tabs for navigation.
- **Thumb ergonomics & progressive disclosure**: Bottom tabs preferred. Tap → expand info. No deep nesting without clear back/escape.
- **Delete-or-wire**: Any new UI element must be wired to DomainActionRegistry or deleted.
- **Consistency**: All domains follow the same tab pattern. No special snowflakes.
- **Performance**: Animations (App Store-like pill) must be lightweight. Use `matchedGeometryEffect` + `.spring()` or native equivalents. Test on A-series chips.

## High-Level Navigation Model

### 1. Global / Root Level (Main Life View)
- **Top**: Stat Island (persistent or sticky)
- **Center**: Current context (Summary cards, pending actions, year progress)
- **Bottom Tab Bar** (persistent):
  - Life (home icon) | School | Cash | Love | Play
  - (Possibly + Career or Health if promoted from sub-domain)
- **Central FAB**: "AGE UP" with literal label (accessibility). Large, thumb-friendly.
- Tapping a main domain tab (School, Cash, etc.) navigates into that domain's default view (usually Overview).

### 2. Domain Level (When inside School / Cash / Love / Play / Careers / Assets / etc.)
- **Top**: Stat Island (or compact version)
- **Bottom Tab Bar** (replaces main bar):
  - **Life** (always leftmost, house/person icon, always returns to root main tab bar + current year state)
  - Domain-specific sub-tabs (max 5): e.g., Overview | Current | Opportunities | Skills | History
- **Animation on tab switch**: Pill/rounded selection highlight that animates smoothly (inspired by App Store Today/Games/Apps tabs). Use `matchedGeometryEffect` on the selected capsule background.
- Content area swaps based on selected sub-tab. Keep state lightweight (last selected sub-tab per domain can be persisted lightly, default to Overview on re-entry unless in active flow).
- **Escape hatches**: Life tab (primary), back gesture if using NavigationStack, or prominent close/X if modal.

### 3. Deep / Sub-Domain Flows (e.g., inside Assets → Vehicles)
- Can use sheet/modal or push navigation for individual item management (e.g., "Sell this car" action).
- Always surface "Back to Assets Overview" or rely on bottom Life/Overview tabs.
- Result modals after actions: Narrative headline + stat deltas + haptics (success/error).

### 4. Special Panels
- **Year Goal**: Accessible from main or dedicated sub-tab in relevant domains. Unblock as per 6-week plan.
- **Asset Shop / Buy Flow**: Separate but consistent — perhaps triggered from Assets Overview sub-tab. Use same result modal pattern.
- **Pending Actions / Cards**: Always surfaceable from main view or via domain sub-tabs if relevant (e.g., "Job Offers" under Careers).

## Sub-Tab Rules (Enforce Consistency)
- **Overview** (always default first tab): Glanceable summary, key stats, quick actions, net worth or progress bars.
- Limit to 4–5 sub-tabs max per domain.
- Sub-tabs represent logical groupings of actions from DomainActionRegistry, not arbitrary UI.
- If a domain would need >5, split into separate top-level domains or use cards + "See all" progressive disclosure inside Overview.
- Sub-tab selection drives which slice of DomainActionRegistry is presented (e.g., `registry.getActions(for: .assets(.vehicles))`).

## Animation & Visual Spec (App Store Inspired)
- Bottom bar: Rounded pill container, white/light material background with subtle shadow.
- Selected state: Blue or brand accent pill that slides/expands with spring animation.
- Icons: SF Symbols or custom, bold when selected.
- Label: Below icon, clear font. "Today" style — short, descriptive.
- On tap: Immediate visual feedback (scale + color), then content transition (fade or slide matching direction? keep simple crossfade or matched).
- Haptics: Light impact on tab change, success/error on action results.
- Accessibility: VoiceOver labels, large content, dynamic type support.

## State Management
- Use `GameViewModel` (or extracted `NavigationCoordinator` / `DomainTabCoordinator`) to own:
  - Current root tab
  - Current domain + selected sub-tab
  - Last viewed sub-tab per domain (optional persistence)
- DomainActionRegistry provides the data/actions for the active sub-tab.
- Year state (age, chapter, pendingActions) lives in the core loop, not tied to navigation.

## Integration Points
- **LifeConsoleView.swift**: Primary host for this pattern during refactor. Build console commands to simulate tab switches and sub-tab content for fast iteration.
- **DomainActionRegistry.swift**: Extend with domain + sub-domain enums (e.g., `DomainAction.assets(.vehicles(.sell))`). Registry must support querying by domain/sub-tab.
- **ContentView.swift**: Continue dead-code removal. Wire new tab bar here or in a dedicated `MainTabBarView`.
- **Result Modals & Cards**: Reuse existing patterns. Every action outcome feeds back into stat island and pending actions.
- **Tests**: Per phase — navigation tests, action registry tests, tap-count verification.

## When NOT to Use Sub-Tabs
- Simple domains (early game or low complexity) → use card-based progressive disclosure inside main view.
- One-off flows (e.g., initial character creation) → full screen or modal.
- Avoid tab overload on main bar. Main bar stays at 4–5 items max.

## Future Extensibility
- New domain? Add to main bar only if high-frequency. Otherwise, promote from existing (e.g., detailed Career under School or new Careers tab).
- New sub-tab category in Assets? Add to enum in Registry and corresponding sub-tab button. Update Overview summary to include quick links.
- Dark mode / themes: Bottom bar must adapt (material + accent colors).

This pattern gives glanceability without overcrowding while scaling to deep, multi-year asset/career accumulation. It directly supports the raw/authentic life sim vision.

---
**Next Steps**: See IMPLEMENTATION-PLAN.md for phased rollout per domain. Use DOMAIN-TEMPLATE.md when adding new domains.