# UI Consistency Guide — OneLife

Ruthless checklist for keeping OneLife playable as depth grows.

## Mantra

**Playability before pixels.** Delete-or-wire. No decorative UI without mechanical backing.

## Glanceability (2-Second Rule)

- Player must read top pressure + primary stat in ≤2 seconds.
- Late game: top-3 pressures default; rest behind disclosure.
- One canonical echo per system (see `CohesionNarrative.swift`).

## Action Feedback

Every meaningful instant action shows:

1. **Narrative headline** (DomainNote title or micro-beat)
2. **Visible deltas** (floating deltas / stat change)
3. **Haptic** (`AppFeedback.impact` or `.notify`)

## Navigation

- ≤**2 taps** for core flows (buy asset, flex collection, set year stance).
- Life tab = universal escape.
- Sub-tabs for inventory domains; cards for Life hub.
- No duplicate surfaces for the same system (recognition, collection, fame).

## Reject List

Reject PRs that:

- Add core flows requiring **>2 taps** without audit exception
- Ship **unwired UI** (buttons with no action)
- Add **polish before playability** (glass/juice before console validation)
- Create **snowflake navigation** outside `NAVIGATION-AND-TAB-PATTERN.md`
- Duplicate glance chips **and** full cards for the same data

## Quick Decision Framework

| Question | Yes → | No → |
|----------|-------|------|
| Does this need a new sub-tab? | Use `DOMAIN-TEMPLATE.md` | Use a card or sheet |
| Is this visible elsewhere? | Consolidate via CohesionNarrative | Ship |
| Can player reach it in 2 taps? | Ship | Redesign or add Overview link |
| Does Registry know this action? | Wire UI | Wire Registry first |

## Pill Tab Visual

- Use shared `PillTabBar` — do not hand-roll per domain.
- Spring: 0.32 / 0.86.
- Max 5 pills visible; scroll horizontally if needed.

## Delete-or-Wire

If a UI element exists for >1 sprint without behavior:

- **Wire it** to Registry + orchestrator, or
- **Delete it** — dead UI erodes trust faster than missing UI.

## References

- [NAVIGATION-AND-TAB-PATTERN.md](NAVIGATION-AND-TAB-PATTERN.md)
- [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md)
- [UI_VISUAL_DESIGN.md](../UI_VISUAL_DESIGN.md) (polish pass — after playability)
