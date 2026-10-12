# OneLife Domain Addition Template

**Use this template for every new domain or major sub-tab addition.**  
Copy this file, rename to `NEW-DOMAIN-NAME.md`, fill it out, and update IMPLEMENTATION-PLAN.md + NAVIGATION-AND-TAB-PATTERN.md as needed.

## Domain Name
[ e.g., Assets, Careers, Health ]

## Why This Domain?
[One sentence justification. Must tie back to raw/authentic life sim vision and player agency over decades.]

## Current State (Pre-Implementation)
- Existing UI location: [Main tab? Sub-flow?]
- Pain points: [Overcrowding? Missing actions? Poor glanceability?]
- Registry coverage: [What actions already exist? What's missing?]

## Target Navigation
- Appears in main bottom tab bar? [Yes/No — only if high-frequency]
- When entered, shows these sub-tabs (max 5, first = default Overview):
  1. Overview — [What does the player see at a glance? Key metrics, quick actions]
  2. [Sub-tab 2 name] — [Purpose + main actions from Registry]
  3. [Sub-tab 3]
  4. [Sub-tab 4]
  5. [Sub-tab 5 — optional]

- "Life" tab always present on left → returns to root main view.

## DomainActionRegistry Mapping
- New enum cases needed: `enum Domain { case [domain]([SubEnum]) }` or extend existing.
- List key action groups per sub-tab:
  - Overview: [quick view actions, aggregate queries]
  - Sub-tab 2: [specific actions]
- Any new action types or outcome effects on stats/pending events?

## UI Components Required
- New views or reuse: [e.g., AssetListView, CareerDetailSheet]
- Shared: Bottom dynamic tab bar, pill selection, result modal (must reuse existing)
- Stat Island updates? [Any domain-specific glances?]
- Sheets / modals for item details or shop flows.

## Integration Points
- **LifeConsoleView.swift / Console commands**: What new commands for testing? (e.g., `enter assets vehicles`, `perform action sell-car-42`)
- **GameViewModel / NavigationCoordinator**: How does this domain update or observe year state?
- **Year loop (beginYearChapter / cards / pendingActions)**: Any new pending action types or chapter effects from this domain?
- **Other domains**: Cross-links? (e.g., Careers → School education requirements, Assets → Cash net worth)
- **Asset Shop / Year Goal**: Entry point here? How surfaced?

## Playability & Tap Count
- Primary flows: [e.g., "From main → Assets → Vehicles → Sell specific car" = ? taps]
- Must be ≤2 taps for core actions. Document the path.
- How does player escape back to Life / main tabs?

## Visual & Animation Notes
- Follow NAVIGATION-AND-TAB-PATTERN.md exactly for bottom bar and pill animation.
- Any domain-specific iconography or color accents? (Keep minimal — consistency first)
- Haptics on tab switch and key actions.

## Testing Checklist (Before Merge)
- [ ] Console shell can fully exercise domain + all sub-tabs + actions without year loop breakage.
- [ ] Every sub-tab wired to real Registry data/actions (no placeholders).
- [ ] Tap count verified.
- [ ] Glance test: Can player understand domain state in <3 seconds on Overview?
- [ ] Result modals fire correctly with narrative + deltas.
- [ ] Accessibility: VoiceOver, dynamic type, large tap targets.
- [ ] No new dead code introduced.
- [ ] This template + IMPLEMENTATION-PLAN.md updated.

## Risks & Open Questions
- [List any concerns: complexity, overlap with other domains, late-game bloat, etc.]
- Mitigation plan.

## Priority & Phase
[ e.g., Phase 2, after core nav shell ]

## Sign-off
- [ ] Architecture reviewed against NAVIGATION-AND-TAB-PATTERN.md
- [ ] Registry changes approved
- [ ] Playability validated in console
- Date: ____   Developer: ____

---
**Remember**: If it doesn't fit this template cleanly, the pattern may need adjustment — update the master docs first. Playability and consistency win over cleverness.