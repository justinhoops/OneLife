# Navigation & Tab Pattern — OneLife

Single source of truth for how players move through the game shell.

## Bottom Bar (Persistent)

Main dock stays lean — max 5 tabs:

| Tab | Label | Role |
|-----|-------|------|
| **Life** | Life | Leftmost. Universal escape hatch — always returns to root main view + current year state. |
| **Work** | School / Jobs | Career or education depending on life phase. |
| **Money** | Cash | Finance + assets domain. |
| **Social** | Love | Relationships + family. |
| **Play** | Play | Activities / instant hub. |

Journal and Settings live outside the dock (More menu / sheet).

## Life Escape Hatch

- **Life tab is always visible** in the bottom bar.
- Tap **Life** when already on Life → reset domain sub-navigation to root (Overview).
- Tap **Life** from any other tab → switch to Life tab + reset sub-nav.
- Year advance (`ageUp` / `beginYearChapter`) must work from any sub-tab depth.

## Domain Sub-Tabs

Inside any domain with depth, use **horizontal pill sub-tabs**:

- First sub-tab is always **Overview** (glance + primary actions).
- Max **4–5 sub-tabs** per domain.
- Use sub-tabs when a domain has distinct inventory lanes (Assets, Careers).
- Use cards/sections when content is narrative or low-volume (Life hub pressures).

### Pill Animation Spec

- `matchedGeometryEffect` on selected pill background.
- Spring animation: `response: 0.32, dampingFraction: 0.86`.
- Selected: accent fill + white label. Unselected: subtle fill + secondary label.
- Component: `PillTabBar` in `PillTabBar.swift`.

## When Sub-Tabs vs Cards

| Use sub-tabs | Use cards/sections |
|--------------|-------------------|
| Distinct inventories (vehicles, jewelry, weapons) | Life hub (pressures, pace, pulse) |
| Career ladder (job, skills, history) | Single-glance metrics |
| 3+ peer categories at same depth | Narrative beats |

## State Management

- `ConsoleNavigationState` on `GameViewModel` holds active sub-tab per domain.
- `ConsoleNavigationCoordinator` parses console/debug commands and mutates state.
- `DomainActionRegistry` remains action truth; navigation enums live in `ConsoleNavigation.swift`.
- Sub-tab selection persists while in domain; resets on Life escape or `nav root`.

## Integration Points

| File | Responsibility |
|------|----------------|
| `LifeConsoleView.swift` | Domain console panels |
| `GameChromeViews.swift` | Bottom dock + Age Up FAB |
| `ContentView.swift` | Planner tab content (Assets, Finance, etc.) |
| `DomainActionRegistry.swift` | Action availability |
| `ConsoleNavigation.swift` | Nav enums + coordinator |
| `PillTabBar.swift` | Shared pill UI |

## Accessibility

- Each pill: `accessibilityIdentifier("pill-tab-{id}")`.
- Dock tabs keep existing `uiTestTabIdentifier` values.
- Sub-tab content: `{domain}-subtab-{id}-content`.

## Haptics

- Tab switch: `AppFeedback.impact(.light)`.
- Life escape to root: `AppFeedback.impact(.medium)`.

## Console Commands (Debug / Test)

```
nav root
enter assets overview
enter assets vehicles
enter assets property
enter assets jewelry
enter assets weapons
enter careers overview
```

Returns human-readable confirmation string for test harnesses.
