# Navigation Implementation Plan — OneLife

Phased rollout building on the current refactor (console shell, `DomainActionRegistry`, ≤2 taps goal, playability-first).

## Phase 0 — Registry + Nav Coordinator ✅ (in progress)

**Goal:** Single nav truth before UI polish.

- [x] `ConsoleNavigation.swift` — domain/sub enums + `ConsoleNavigationCoordinator`
- [x] `ConsoleNavigationState` on `GameViewModel`
- [x] Console command handler: `handleConsoleNavigationCommand(_:)`
- [x] `DomainActionRegistry` nav mapping helpers
- [ ] Document command list in tests

**Exit criteria:** `nav root` and `enter assets vehicles` work from test harness without UI.

## Phase 1 — Pill Dock + Life Escape ✅ (in progress)

**Goal:** App Store-style pill animation on main dock; Life always escapes to root.

- [x] `PillTabBar` component with `matchedGeometryEffect`
- [x] Replace flat dock highlight in `BitLifeGameChrome`
- [x] Life re-tap resets `ConsoleNavigationState`
- [ ] Validate `ageUp` while deep in Assets sub-tab

**Exit criteria:** Dock feels animated; Life escape works from any tab.

## Phase 2 — Assets Sub-Tabs ✅

**Goal:** Fix Assets overcrowding — first high-impact domain split.

Sub-tabs: Overview | Vehicles | Property | Jewelry | Weapons

**Exit criteria:** Core asset flows ≤2 taps from Overview; console commands land on correct sub-tab.

## Phase 3 — Careers Sub-Tabs ✅ (in progress)

**Goal:** Work tab parity with Assets pill navigation.

Sub-tabs: Overview | Current Job | Opportunities | Skills | History

- `CareerPlannerTab` uses `PillTabBar` + `CareersSubTab` binding on `GameViewModel.consoleNavigation`
- Console: `enter careers opportunities`, `enter careers skills`, etc.
- Education (teen) stays single-surface until School sub-tabs are justified

**Exit criteria:** Career overview glance + ≤2 taps to year plan actions.

## Phase 4 — Remaining Domains + Tap Audit

- Careers: Overview | Current Job | Opportunities | Skills | History
- School / Cash / Love / Play: minimal sub-tabs only where glanceability fails
- Full tap-count audit against ≤2 taps rule
- Console validation script for all domains

## Phase 4 — Future Features Template

Every new domain uses `DOMAIN-TEMPLATE.md` before shipping.

## Recommended Order

1. Phase 0 (this PR)
2. Phase 1 (dock)
3. Phase 2 (Assets) — **highest pain point**
4. Careers sub-tabs
5. Visual polish (Stitch/glass) **only after** console flow is playable

## Current Code Mapping

| Doc tab | Code `GameViewModel.Tab` |
|---------|--------------------------|
| Life | `.home` |
| School/Jobs | `.occupation` |
| Cash | `.assets` (Finance + Assets planner) |
| Love | `.relationships` |
| Play | `.activities` |

Assets planner: `AssetsPlannerTab` in `PlannerTabViews.swift`.

## Risks

- Splitting Assets without breaking UITest identifiers — preserve section accessibility IDs.
- Year chapter overlay must remain above sub-tab scroll content.
- Do not add sub-tabs to Life hub (cards only).
