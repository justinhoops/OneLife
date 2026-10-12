# OneLife Core Design Spec (Bare Bones — July 2026)

**Vision:** Raw authentic life simulator with realistic consequences. Playable + Immersive + Easy context pickup. Every major system ≤2 taps. Instant feedback. No repetitive chores. Player-driven with glanceable context + optional depth + meaningful Age Up resolutions. Balance via friction, trade-offs, pressure feedback loops.

**Current State:** Post-massive refactor — extremely bare bones foundation. Clean architecture. Building back up sustainably.

---

## Core Interaction Loop (Glance → Inspect → Act)

### 1. Glance Layer (Always Visible / 1 Tap Max)
- **Persistent Top Stat Island:** Happy / Health / Smart / Looks / Rep / Cash (color-coded, glanceable numbers or bars). One-hand reach.
- **Domain Tabs:** Education/Work, Finances, Relationships/Family, Health, Activities/Life, etc. (thumb-friendly).
- **In Active Domain:** 
  - Current Pressures overview (2–4 horizontal bars or chips: High/Med/Low + icons + short labels).
  - Immediately below: 3–5 **Instant Action** cards from DomainActionRegistry (title, short desc, effect preview tied to current pressures, "ALWAYS" badge for static core ones).
- **Momentum / Life-Shape Strip** (when active): Live "Shape: driven current" or similar with reactive color. Tappable for explanation.
- **Status Line (debug/minimal):** age X | cash $Y | seed info.

**Goal:** Player knows top 3–4 pressures and has obvious "what can I do right now" options within 2 seconds of opening console.

### 2. Inspect Layer (Player-Initiated, Stays in Domain View)
- Tap any pressure bar/icon → clean expandable panel or in-place details:
  - Why this pressure exists (short, state-based explanation, possibly referencing recent stances or life-shape).
  - Affected elements/NPCs/history highlights.
  - 1–2 suggested instant actions to address it.
- NPC/relationship depth lives here (tension, recent interactions, personality notes). Player controls depth.
- Long-press on any action button → preview popup with full effects + ripple preview ("Shapes your life (pragmatic) + legacy echoes", family/political capital cost, etc.).

### 3. Act Layer
- **Instant/Quick Actions:** Tap resolves a typed request through LifeSimulator and shows one compact centered outcome with a headline, impacts, and brief flavor. Routine actions have bounded annual repeat windows.
- **Age Up / Yearly Commit:** Big primary button (thumb zone). Runs the yearly systems and may present zero, one, or two sequential choices. One recap closes the whole year after all choices resolve.
- Static Always-Available (BitLife-style): Core domains + subdomains (teen education, active special career) have permanent "Right Now" instant actions in the grid. "ALWAYS" visual badge.

---

## Key Systems (Bare Bones Foundation)

- **LifeState:** Character and domain states, per-action annual use counts, recent flavor IDs, pending and queued yearly choices, history, run seed, and domain random streams.
- **ActionRequest / ActionOutcome:** Typed action identity and optional durable person target, domain effects and direct impacts, severity, flavor, and optional follow-up choices.
- **DomainAction + Registry:** ActionID, title, subtitle, effects (deltas), requirements (locked reasons), tier (instant vs committed), previewTags, microBeat. Static core lists per domain + promotions for special tracks.
- **LifeSimulator:** Observable-state orchestrator and mutation boundary. It sequences registered actions and yearly systems, publishes outcomes, invalidates caches, and queues persistence; domain calculations live in sovereign processors.
- **Effect / Progression / Influence / Social / Health Systems:** Own instant-action transformations. `InstantNarrativeSystem` converts the resolved state into compressed feedback.
- **NarrativeEventSystem:** Owns seeded stage weighting, anti-repeat selection, social context, Echo, and state-derived vibe for yearly storylets.
- **History + Journal:** Every action/year produces Headline + detail + DeltaSummary. Silence notes for quiet years flavored by state + recent focus.
- **Events:** PendingEvent system for presented choices with consequences.
- **Contextual Suggestions:** A read-only ranked row of at most three pressure, personality, person, and recent-history driven actions. Every tap rechecks eligibility against current state.
- **D4 / Focus System:** Influence snapshots accumulate into stance, intensity, and life shape; these bias events, spillovers, quiet notes, and legacy summaries.
- **LifeResilience (Planned):** Creation toggle (Grounded vs Resilient) that diverges recovery, spillover tone, adult child outcomes, late-game fighting-back moments, legacy flags.

---

## UI/Ergonomics Rules (Non-Negotiable)
- **Thumb Zone:** Primary (Age Up, key instants) bottom/center. Navigation above. Settings top.
- **2-Column Instant Grids:** Thumb-friendly, consistent "Right Now" / Quick Actions sections.
- **Long-Press Previews:** Every actionable element has rich preview (effects + life-shape/legacy ripple + political capital or family cost when relevant).
- **Floating Deltas + Momentum Strip:** Instant visual + haptic feedback on actions. Strip always visible when momentum active, shows shape + domain hints.
- **Compact Late-Game:** When age 32+/40+ or heavy family/career, enable collapsible sections, glance chips for adult children, context ribbon.
- **No Density Creep:** Preserve 2-second glance even mid/late game.

---

## Narrative & Feedback (Vibe Layers Active from Start)
- **Voice:** Second-person present, concrete.
- **Echo:** Past choices remembered in future text.
- **Silence:** Quiet years get flavored notes based on dominant pressures + recent stances/life-shape.
- **Mood:** UI tone subtly shifts with NarrativeTone or high heat/pressure.
- **Yearly Feedback Parity:** Age Up summary uses bullets/deltas + "Stance & Shape" block + "because of your focus" notes. Matches instant visceral quality.

---

## Special Careers Integration Rule
When adding Athlete / Founder / Politics / Crime:
- Dedicated State struct.
- Instant actions promoted to staticCore + availableInstant when track active.
- Full apply handlers in relevant System with domain ripples + notes.
- UI metrics card appears when active.
- All modern wiring (D4, Fame, Family, Resilience) in depth phase.

---

**Current Bare Bones Priorities:** Verify the core performance/accessibility/playtest gates, then integrate archived feature domains one vertical slice at a time through the state/system/registry/persistence/UI contract.

This spec evolves with the build. Every addition must make the glance → act loop more satisfying.
