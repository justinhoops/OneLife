# Navigation Implementation Plan — OneLife

Phased rollout building on the current refactor (console shell, `DomainActionRegistry`, ≤2 taps goal, playability-first).

## Phase 0 — Registry + Nav Coordinator ✅

**Goal:** Single nav truth before UI polish.

- [x] `ConsoleNavigation.swift` — domain/sub enums + `ConsoleNavigationCoordinator`
- [x] `ConsoleNavigationState` on `GameViewModel`
- [x] Console command handler: `handleConsoleNavigationCommand(_:)`
- [x] `DomainActionRegistry` nav mapping helpers
- [x] Document command list in tests (`ConsoleNavigationValidator.standardCommands`)

**Exit criteria:** `nav root` and `enter assets vehicles` work from test harness without UI.

## Phase 1 — Pill Dock + Life Escape ✅

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

## Phase 3 — Careers Sub-Tabs ✅

**Goal:** Work tab parity with Assets pill navigation.

Sub-tabs: Overview | Current Job | Opportunities | Skills | History

- `CareerPlannerTab` uses `PillTabBar` + `CareersSubTab` binding on `GameViewModel.consoleNavigation`
- Console: `enter careers opportunities`, `enter careers skills`, etc.

**Exit criteria:** Career overview glance + ≤2 taps to year plan actions.

## Phase 4 — Remaining Domains + Tap Audit ✅

- [x] **School** sub-tabs: Overview | Climate | Plan (`EducationPlannerTab`)
- [x] **Cash** sub-tabs: Overview | Finance | Assets (`CashPlannerTab` — Assets keeps nested sub-tabs)
- [x] **Love** sub-tabs: Overview | Connections | Family (`RelationshipsPlannerTab`)
- [x] **Play** sub-tabs: Overview | Activities (`PlayPlannerTab`)
- [x] `NavigationTapAudit.swift` — documented core flows ≤2 taps from domain Overview
- [x] `ConsoleNavigationValidator` + `validateConsoleNavigationSuite()` on `GameViewModel`
- [x] Console commands for all domain/sub routes

**Exit criteria:** Tap audit passes; validation suite covers all standard commands.

## Phase 5 — Future Features Template

Every new domain uses `DOMAIN-TEMPLATE.md` before shipping.

## Recommended Order

1. Phase 0 (this PR)
2. Phase 1 (dock)
3. Phase 2 (Assets) — **highest pain point**
4. Careers sub-tabs
5. Phase 4 remaining domains
6. Visual polish (Stitch/glass) **only after** console flow is playable

## Current Code Mapping

| Doc tab | Code `GameViewModel.Tab` |
|---------|--------------------------|
| Life | `.home` |
| School/Jobs | `.occupation` |
| Cash | `.assets` (`CashPlannerTab` → Finance + Assets) |
| Love | `.relationships` |
| Play | `.activities` |

Planners: `PlannerTabViews.swift` — `CashPlannerTab`, `AssetsPlannerTab`, `EducationPlannerTab`, `CareerPlannerTab`, `RelationshipsPlannerTab`, `PlayPlannerTab`.

## Risks

- Sub-tab proliferation without overview shop links → re-audit taps when adding lanes
- Cash tab now two-level (Cash → Assets → SKU) — console `enter assets jewelry` sets both levels
