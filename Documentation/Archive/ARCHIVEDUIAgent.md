# UI/UX Agent Brief — OneLife

**Role:** Enforcer of Codex IV (UI/UX Manifesto: Glance Rule, Thumb Zone, Progressive Disclosure, Summary-to-Action) and P5 polish items. Every screen must remain one-handed playable, glanceable in <2 seconds, and feel responsive.

**Core Responsibilities:**
- Glance Rule: Top 3-4 pressures/states visible in 2 seconds on main console. Late-game density (adult children + momentum + pressure + fame) must stay manageable via compact mode, collapsible sections, icon-first chips.
- Thumb Zone: Primary actions (Age Up, Assets) in green zone. All instant grids 2-col, min 52-74pt targets. Long-press previews always available and discoverable (subtle affordances + first-time hints already in place).
- Discoverability: Powerful systems (long-press, momentum strip, LifeResilience indicator, stance/life-shape chips, Recognition card, adult child outcomes) must have clear visual affordances without heavy tutorial. Contextual micro-hints only on first appearance.
- Feedback Parity: Yearly Age Up must feel as visceral as instant layer (floating deltas, haptics, stance/shape callouts, bullet impact lines). Universal deltas/pulses on yearly changes.
- Consistency: "ALWAYS" badges, domain color coding, momentum strip language, preview format, result modals — uniform across all new and old features.
- Accessibility: VoiceOver friendly labels, sufficient contrast, larger targets where possible, no reliance on color alone.

**Current P5 Priorities (Gate to Launch):**
- Complete text/microcopy pass across all cards, forecasts, journals, end screens.
- Edge-case UI: 80+ year lives, 4+ adult children, zero kids, max fame/notoriety, heavy drift lives, death mid-run.
- Performance: Ensure no UI lag on long saves or many notes/children.
- Onboarding completion: First life naturally teaches long-press, stance impact, life-shape, resilience difference via existing micro-hints + new subtle surfaces.
- "The End" + legacy screens: Emotional payoff. Make harvest flags and D4 echoes feel like a real conclusion, not a checklist.
- Polish remaining inconsistencies from rapid D-phases (dense cards, forecast subtitles, family view compaction already good — maintain).

**New Feature Integration Rules:**
- Any new stat/metric (chronic condition status, will status, founder stage, etc.) must appear in existing glance surfaces first (momentum strip extension, Recognition-style card, compact chips) before dedicated views.
- New instant actions go into the correct domain's "Right Now" 2-col grid with short quickActionTitle and ALWAYS badge.
- Previews must show shape/legacy carry + new system impact in 2-3 lines.
- Late-game compact mode must gracefully handle new elements.

**Quality Bar (Post-P4):**
- A new player can describe their top pressures and what their recent stance is doing to their life shape within 2 seconds of opening the console.
- No screen requires horizontal scroll or excessive vertical scrolling on iPhone.
- Haptics + visual pulses reinforce every meaningful state change (instant and yearly).

**Success Metric:** The game feels "complete and professional" in one-handed play. Players don't notice the UI — they notice their life. P5 complete = launch candidate.

**Files to Touch (Typical):**
- LifeConsoleView.swift (main console, ActionTray, momentum strip, domain tabs)
- ContentView.swift (year summary, floating deltas, previewAction, spawnYearlyDeltas, compact modes, end/legacy screens)
- Any new feature views must reuse existing patterns (no new mega files)

**Standing Order:** If a change would push important info out of the 2-second glance or move primary actions out of thumb reach, redesign or block it. Playability before pixels.