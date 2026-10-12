# OneLife UI & Feature Consistency Guide

**Purpose**: Living checklist and rules so every new feature, domain, or polish pass stays aligned with the vision: raw/authentic life sim that is playable, glanceable, and fun without grind or bloat.

**Core Mantra**: Playability before pixels. Delete-or-wire. Every major system ≤2 taps. DomainActionRegistry is truth.

## Must-Follow Rules for All New Work

### Navigation & Tabs (See NAVIGATION-AND-TAB-PATTERN.md)
- Main bottom bar: Max 5 items. Life (persistent escape) + 4 domain tabs.
- Inside any domain: Replace bar with Life (left) + max 4–5 domain sub-tabs.
- First sub-tab is always **Overview** (glanceable summary + quick actions).
- Animation: Smooth pill/rounded selection (matchedGeometryEffect + spring). Consistent across all tabs.
- "Life" tab behavior is sacred: always returns player to root main view with current year state intact.
- No exceptions for special domains. If it doesn't fit, redesign the domain split.

### Glanceability & Information Hierarchy
- Top Stat Island (Happy/Health/Smart/Looks/Rep/Cash) is the north star. Always visible or one-tap away.
- Overview sub-tab must answer in <3 seconds: "Where am I? What's my status? What can I do right now?"
- Use cards for progressive disclosure. Big numbers + small deltas. Narrative headlines in results.
- Avoid walls of text or deep scrolling in primary views. Lists in sub-tabs should be filterable/searchable for late-game scale.

### Actions & Feedback
- Every action comes from DomainActionRegistry. No hardcoded buttons.
- After action: Result modal with 
  1. Punchy narrative headline
  2. Clear stat deltas (+/-)
  3. Any new pending actions or consequences
  4. Haptic feedback (success = light/medium, error = error pattern)
- Pending actions / year cards must surface prominently from main view or relevant domain Overview.
- AGE UP FAB is central, labeled, accessible. It is the heartbeat.

### Domain Design Rules
- Use DOMAIN-TEMPLATE.md for every new domain or major sub-tab group.
- Logical groupings only — map directly to Registry action categories.
- If a domain needs >5 sub-tabs, split it or push complexity into cards + sheets.
- Cross-domain links are encouraged (e.g., Assets Overview links to Cash impact) but keep primary home in one place.
- Early game = simple defaults. Late game = same structure with more data (filtering, summaries).

### Technical & Refactor Rules
- LifeConsoleView.swift is your fast iteration shell. New features must be exercisable via console commands before full UI work.
- Continue aggressive dead code removal from ContentView.swift. New code must be wired or it doesn't ship.
- GameViewModel / NavigationCoordinator owns tab state. Year loop model owns time, stats, pending actions. Clear separation.
- Persistence: Core game state yes. Heavy nav state no (light "last sub-tab" prefs OK).
- Performance: Animations lightweight. Test tab switches + year advance together on older hardware.
- Accessibility: VoiceOver labels on every tab/button, dynamic type, minimum tap targets 44pt.

### Visual & Polish Rules (Stitch Phase Only)
- Do visual work only after playability is proven in console for that feature.
- Consistent iconography (SF Symbols preferred for system feel, custom where branding demands).
- Bottom tab bar: Rounded pill container, material background, subtle shadow. Selected pill in brand accent.
- Color feedback: Green for positive deltas, red for negative, neutral for info. Haptics reinforce.
- Spacing & thumb reach: Bottom tabs easy for one-handed use. Stat island not fighting dynamic island.
- No feature-specific snowflake UI. If it feels special, make it follow the pattern or justify in template.

### Year Goal & Asset Shop (Priority Unblocks)
- Surface clearly in relevant Overview tabs (Assets, Careers, Cash).
- Use same result modal + consequence pattern.
- Year Goal should feel like a persistent companion, not a separate chore screen.

### What Gets Rejected
- Any UI that requires >2 taps for core actions (age up, manage key asset, respond to pending event, check status).
- Overcrowded single views (this is why we have sub-tabs).
- Actions not routed through DomainActionRegistry.
- New screens without console test coverage.
- Visual polish before the feature is playable end-to-end.
- Breaking the year loop or making AGE UP less prominent.

## Quick Decision Framework for New Ideas
1. Does this fit an existing domain/sub-tab? → Extend it using the template.
2. Does it need a new domain? → Fill DOMAIN-TEMPLATE.md first. Get sign-off on nav placement.
3. Can it be a card or sheet inside Overview instead of new tab? → Prefer this for simplicity.
4. Does it increase tap count or reduce glanceability? → Redesign.
5. Is it wired to Registry and testable in console? → Required before any merge.

## Living Document
Update this guide, NAVIGATION-AND-TAB-PATTERN.md, IMPLEMENTATION-PLAN.md, and DOMAIN-TEMPLATE.md whenever the pattern evolves or a new domain is added. These files are the law for consistency.

Future developers (or future you in 6 months) will thank you.

---
**Current Status**: Pattern defined for main tabs + Assets/Careers sub-tabs. Core nav shell in progress. Follow phases in IMPLEMENTATION-PLAN.md.

Stay ruthless about playability. The raw life sim vision only works if players can actually live it without fighting the UI.