# OneLife Domain Tab Implementation Plan

**Version:** 1.0  
**Date:** 2026-06-19  
**Based on:** Current refactor state (LifeConsoleView.swift, DomainActionRegistry.swift, ~9.1k lines dead UI removal in ContentView.swift, 6-week playability plan)  
**Goal:** Roll out App Store-inspired bottom tab + sub-tab pattern across domains for glanceability without overcrowding. Persistent "Life" tab as universal escape. Integrate with existing year loop, console shell, and registry.

## Overarching Phases (Build on Existing 6-Week Plan)

**Phase 0: Foundations (In Progress / 1 week)**
- Lock DomainActionRegistry as single source of truth. Add domain + sub-domain enums (e.g., `enum Domain { case assets(AssetSub), case careers(CareerSub), ... }`).
- Extract / solidify `GameViewModel` + lightweight `NavigationCoordinator` or `DomainTabCoordinator`.
- Continue dead UI deletion in ContentView.swift. Move toward LifeConsoleView as primary dev shell.
- Define shared UI components: StatIslandView, BottomTabBar (dynamic), PillSelectionView (with matchedGeometryEffect), ResultModal.
- Console commands in LifeConsoleView for: switch domain, switch sub-tab, simulate action, print current nav state.
- Verify year loop (beginYearChapter / cards / pendingActions) is untouched by navigation.

**Phase 1: Core Navigation Shell (1–1.5 weeks)**
- Implement persistent bottom tab bar in main Life view (Life | School | Cash | Love | Play).
- Add "Life" tab behavior: always resets to root main view + current year state.
- Build dynamic sub-tab bar component that swaps in when entering a domain.
- Wire basic animation (pill highlight with spring).
- Hook initial domains (start with 1–2) to prove pattern.
- Add haptics on tab change and action results.
- Update accessibility labels and VoiceOver.
- Console test: full nav flow without crashing year loop.

**Phase 2: High-Impact Domains Rollout (2 weeks)**
- Assets (biggest overcrowding risk)
- Careers (key progression domain)
- Then School, Cash, Love, Play if they benefit from sub-tabs.
- Each domain gets Overview + logical sub-tabs mapped to Registry actions.
- Integrate Year Goal and Asset Shop flows into relevant sub-tabs.
- Polish result modals, stat deltas, narrative headlines.

**Phase 3: Remaining Domains + Polish (1–2 weeks)**
- Health, Relationships, Activities, Crime (if present), etc.
- Visual pass / Stitch-style polish only after playability is proven in console.
- Full tap-count audit: every core flow ≤2 taps.
- Performance testing on older devices.
- Persistence of light nav state (last sub-tab per domain?).
- Documentation handoff and consistency enforcement via these MD files.

**Phase 4: Future Features**
- New domains follow DOMAIN-TEMPLATE.md exactly.
- Asset shop expansions, deeper career trees, etc., slot into existing sub-tab structure.

**Testing Strategy (Every Phase)**
- Console-driven: LifeConsoleView commands to exercise every tab/sub-tab/action.
- Unit: DomainActionRegistry queries per sub-tab.
- UI/UX: Manual thumb reach, glance test (can I understand state in <3s?), accessibility audit.
- Integration: Year chapter advance while deep in Assets sub-tab → correct return state.
- Delete-or-wire: Any new view must be wired or removed before merge.

## Per-Domain Breakdown

### 1. Main / Root Life View (The Hub)
**Current State (from refactor):** Stat island top, central content (summary/cards/pending), bottom tabs (School/Cash/Love/Play), central AGE UP FAB. Heavy dead UI cleanup ongoing. LifeConsoleView as shell.

**Target:**
- Bottom tabs: Life (icon) | School | Cash | Love | Play   [Life always present, even if others change]
- Life tab = home (current main view). Tapping it from anywhere returns here.
- Content: Glanceable year summary, quick stats, pending actions cards, prominent Year Goal teaser if active.
- No sub-tabs here — this is the "all original tabs" landing zone.

**Implementation Steps:**
1. In LifeConsoleView / MainView: Build BottomTabBar component that accepts array of tabs + selected binding.
2. Life tab action: `coordinator.goToRoot()`
3. Wire existing domain taps to enter domain with default sub-tab = .overview
4. Ensure AGE UP FAB remains central and always available.
5. Add console command: `nav root` or `show main`

**Key Registry Integration:** Root actions like "Advance Year", "View Summary", quick domain entry.

**Priority:** Highest — foundation for everything else.

**Risks & Mitigations:** Navigation state drift during year advance → keep year state in dedicated model, nav only observes.

### 2. Assets Domain (Highest Value for Sub-Tabs)
**Current State:** Likely a single crowded view or list. Player accumulates Cars, Houses, Jewelry, Weapons, etc. over years. No good management UI yet. Asset shop unblocked per plan.

**Target Sub-Tabs (max 5):**
- Overview (default): Total net worth, quick stats (vehicles owned, property value), prominent "Shop" or "Buy New" action, summary cards for each category.
- Vehicles: List/manage cars, motorcycles, etc. Actions: Buy, Sell, Maintain, Customize?
- Property: Houses, apartments, land. Actions: Buy, Sell, Upgrade, Rent?
- Jewelry & Valuables: Smaller high-value items.
- Weapons & Gear: If crime/lifestyle relevant. Actions: Acquire, Sell, Use?
- (Optional 5th: Other / Collectibles or Misc)

**Implementation Steps:**
1. Extend Registry: `enum AssetCategory { case vehicles, property, jewelry, weapons, other }`
2. Create AssetsDomainView or reuse panel that takes selected sub-tab.
3. Map each sub-tab to filtered actions from Registry + domain-specific views (list + detail sheets).
4. Overview pulls aggregated data + quick action buttons that jump to relevant sub-tab or open shop modal.
5. Wire Asset Shop flow into Overview or dedicated entry.
6. Console: `enter assets vehicles`, `list assets`, `sell vehicle 3`

**Key Registry Integration:** All buy/sell/maintain actions live here. Outcomes update cash, stats, pending events.

**Priority:** Phase 2, early. Directly solves "one domain overcrowded".

**Risks:** Inventory bloat in late game. Mitigation: Good filtering + search in lists, progressive disclosure (tap item → detail sheet).

### 3. Careers Domain
**Current State:** Probably tied to School or basic job list. Needs depth for progression, multiple careers over life, skills, opportunities.

**Target Sub-Tabs:**
- Overview (default): Current job summary, income, satisfaction, promotion progress, quick "Look for Jobs" or "Quit" actions.
- Current Job: Detailed view, daily/weekly actions, performance.
- Opportunities: Job offers, applications, career changes. (Integrate with Year Goal if relevant)
- Skills & Progress: Education/skills tree or bars, training options.
- History: Past jobs, career achievements, resume-like log.

**Implementation Steps:**
1. Registry enums for CareerSub: .overview, .current, .opportunities, .skills, .history
2. Similar structure to Assets: Coordinator-driven sub-tab content.
3. Link to School domain where relevant (education feeds skills).
4. Unblock Year Goal integration here if career-focused.
5. Console commands for job-related actions.

**Priority:** Phase 2, alongside Assets. Core progression loop.

**Risks:** Overlapping with School. Mitigation: Keep School focused on current education/grades; Careers on post-school/work life. Clear handoff actions.

### 4. School / Education Domain
**Current State:** Part of main bottom tabs. Likely handles classes, grades, studying, perhaps early career entry.

**Target Sub-Tabs (if complexity warrants; start simple):**
- Overview: Current school status, GPA/progress, upcoming tests/events.
- Classes / Schedule: Manage or view classes.
- Studying / Actions: Study sessions, extracurriculars.
- Opportunities: Scholarships, clubs, early job leads.
- History / Records: Past performance, diplomas.

**Implementation Steps:**
1. Evaluate if  current view is already glanceable. If yes, minimal sub-tabs (Overview + 2–3 others).
2. Map studying/actions to Registry.
3. Ensure smooth transition to Careers domain when graduating or dropping out.
4. Console support.

**Priority:** Phase 2 or 3. Lower if current implementation is clean.

**Risks:** Feature creep into full school sim. Keep focused on life impact (grades → job opportunities → stats).

### 5. Cash / Finance Domain
**Current State:** Main bottom tab. Budgeting, income, expenses, perhaps investments or debt.

**Target Sub-Tabs:**
- Overview: Net cash, income sources, major expenses, budget health glance.
- Income: Jobs, side hustles, assets generating money.
- Expenses & Budget: Recurring costs, one-time spends.
- Investments / Assets Link: Quick view or jump to Assets.
- History / Transactions: Log of money moves.

**Implementation Steps:**
1. Strong integration with Assets and Careers (income from jobs/assets).
2. Actions for budgeting, loans, etc., via Registry.
3. Overview should feel like a financial dashboard.
4. Link to Year Goal (financial targets).

**Priority:** Phase 2–3.

### 6. Love / Relationships Domain
**Current State:** Main bottom tab. Dating, marriage, family, friendships?

**Target Sub-Tabs:**
- Overview: Current relationship status, key people, happiness from relationships.
- Dating / Partners: Current partner details, dating pool/actions.
- Family: Parents, kids, extended (if deep).
- Friends / Social: Broader network.
- History: Relationship milestones, breakups, etc.

**Implementation Steps:**
1. Careful with emotional depth — keep actions meaningful but not grindy.
2. Registry actions for dates, proposals, conflicts, support.
3. Link to overall Happy/Health stats.
4. Result modals with narrative weight.

**Priority:** Phase 3.

### 7. Play / Activities / Hobbies Domain
**Current State:** Main bottom tab. Leisure, sports, entertainment, side activities.

**Target Sub-Tabs:**
- Overview: Current hobbies, energy/fun balance, recent activities.
- Activities: List of available things to do (gym, travel, games, etc.).
- Hobbies Management: Level up or maintain hobbies.
- Social Activities: Group events.
- History: Memorable experiences.

**Implementation Steps:**
1. Balance realism (time/energy cost) with fun.
2. Actions feed into Happy, Health, Smart, Looks, Rep.
3. Good candidate for light sub-tabs or heavy card disclosure.

**Priority:** Phase 3.

### 8. Other Potential Domains (Health, Crime, Goals, etc.)
- **Health/Wellness**: Overview + Physical + Mental + Habits. Link heavily to stats.
- **Crime / Risky Behavior** (if included for raw realism): Careful — high consequence actions. Sub-tabs: Overview, Opportunities, Heat/Consequences, History.
- **Year Goal / Long-term Goals**: Can live as persistent panel or dedicated sub-tab in relevant domains (Careers, Cash, Assets). Unblock per existing plan.
- New domains must follow the exact pattern in this doc + DOMAIN-TEMPLATE.md. No exceptions.

## Cross-Cutting Concerns
- **Asset Shop & Year Goal**: Unblock early. Surface entry points in Assets Overview and Careers/Cash sub-tabs. Use consistent result modal + stat impact.
- **Pending Actions / Cards**: Always visible from main or relevant domain sub-tabs. Never buried.
- **Result Feedback**: Every action → clear narrative headline, +/- stat deltas, haptics, possible new pending cards. Reuse components.
- **Persistence & Save**: Nav state is ephemeral except light "last sub-tab" prefs. Core game state (inventory, jobs, relationships) in proper models.
- **Dead Code & Refactor**: As you extract panels into domain views, continue aggressive deletion from ContentView.swift.
- **Stitch Polish**: Only after Phase 2 playability is solid in console. Visuals (colors, spacing, icons) last.

## Success Metrics
- Every core player action (age up, manage asset, change job, etc.) reachable in ≤2 taps from any screen.
- No domain feels overcrowded even after 20+ in-game years of accumulation.
- Console shell allows full simulation of a year including deep domain navigation.
- New feature developer (or future you) can add a sub-tab in <1 day by following the MD files.
- Player feedback (when testable): "I always know where I am and how to get back."

## Risks & Mitigations
- Tab overload → Strict 4–5 max sub-tabs. Use cards inside Overview for anything else.
- Animation jank → Prototype early with matchedGeometryEffect. Fall back to simpler crossfade if needed.
- State bugs during year advance → Strong separation: year loop owns time/state, nav owns presentation.
- Scope creep → Stick to phases. Console validation before any visual work.
- Consistency drift → These MD files are law. Update them when pattern evolves. Reference in every PR or planning note.

This plan turns the good idea (App Store tabs + sub-tabs + persistent Life) into a maintainable, scalable system that protects the raw/authentic life sim vision while making it actually playable.

---
**Immediate Next Action**: Review NAVIGATION-AND-TAB-PATTERN.md. Then start Phase 0/1 work in LifeConsoleView.swift by adding the dynamic BottomTabBar component and Life tab behavior. Use console to validate before touching real UI.

Update this plan as phases complete. Keep DOMAIN-TEMPLATE.md and UI-CONSISTENCY-GUIDE.md in sync.