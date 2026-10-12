# OneLife Design Codex (Clean Version — Bare Bones Aligned)

**Core Directive:** Build a raw, authentic life simulator ("BitLife killer") that feels immersive and replayable without becoming a chore. Every system must pass the Continuity Check: "Does this feel like the same game?" Frictionless where it matters, meaningful depth proportional to impact. No god-objects. Sustainable architecture.

---

## Codex I: Architectural Manifesto — Orchestrator & Domain Pattern
- **Separation of Domains:** Game engine is collection of specialized systems, not monolith.
- **Rule of Two:** If a class manages logic across >2 domains, decouple it.
- **GameState Role:** Orchestrator/holder of domain states + yearly tick + persistence. Does **not** calculate domain logic.
- **Domain Sovereignty:** Each domain (Finance, Career/Politics, Relationships/Family, Health, etc.) owns its state + logic.
  - States = pure data containers.
  - Systems = logic processors.
- **Efficiency:** Domain hibernation (only active/influential domains consume resources). Modifier Pattern for global vars (taxes, cost of living). Lazy resolution where possible.
- **Instant vs Yearly Boundary:** Instant actions are cheap micro-moves with immediate feedback + autonomous reactions. Yearly Age Up is the committed simulation tick with heavier narrative weight. Clear mental model for player.

---

## Codex II: Design Philosophy — Raw Authenticity vs. Playable Simulation
- **Uncomfortable Realism:** Simulate life with honesty and grit. No sanitized or zillionaire exploits. Success requires rare alignment of traits + choices + luck.
- **Meaningful Depth:** Complexity must earn its weight. If it feels like a second job → refactor for frictionless. If bland → give domain-specific consequences.
- **Anti-Exploit:** Wealth/power earned. Trade-offs everywhere.
- **App Store Balance:** Honest simulation + accessible abstraction level. No gratuitous content.
- **Replayability Levers:** LifeResilience modes (Grounded vs Resilient) must feel viscerally different in moment-to-moment + long-term legacy. Meta progression from previous life choices (D4 life-shape, stances, scars) changes next-life start.

---

## Codex III: UI/UX Trinity — Glance Rule, Thumb Zone, Progressive Disclosure
- **Glance Rule (Readability):** 2-second audit of top 3–4 pressures/states on opening main view. Icons + color as data first. Short impact lines over walls of text. "What matters right now?"
- **Thumb Zone (Ergonomics):** Primary actions (Age Up, key instants) in natural bottom/center green zone. Navigation above. Infrequent (settings) at top. Never break one-handed play.
- **Progressive Disclosure:** Tab = aggregated status. Tap pressure = details + suggested actions. Modal or in-place for deep ledger only when needed. Maintain "never leave main screen" feel.
- **Information Hierarchy:** Vitality/Stat Island (persistent) → Domain Overview (Net Velocity + pressures) → Deep inspect (player-initiated).
- **Feedback Pulse:** Micro (button tap), Minor (small stat shift), Major (domain shift), Critical (life-altering). Haptic + visual match magnitude. Floating deltas on instant; strong cards/deltas on yearly.

---

## Codex IV: Vibe Layers — Voice, Echo, Silence, Mood (Non-Negotiable)
The feeling comes from all four working together. Break one → game feels hollow or spreadsheet-like.

1. **Voice (Proximity Rule):** Tight second-person, present tense, concrete specificity. No abstractions or passive distance.
   - Wrong: "An unexpected bill arrived."
   - Right: "The mechanic says $1,400. You have $380."

2. **Echo (Consequence Memory):** Past meaningful choices remembered. Flags + pressureByDomain set by player actions. Future events prepend one-line memory via EchoFlavorResolver. "You're still paying off that loan from two years ago." Makes world feel continuous.

3. **Silence (Weight of Nothing):** Not every year gets a big event. SilentYearEngine generates flavored one-line journal notes based on dominant state + recent stances/life-shape. Quiet years carry emotional weight and accumulate in history. "Another month of watching the balance." or "The looseness you allowed is still coloring what the world brings to your door."

4. **Mood (UI Carries the Weight):** NarrativeTone (grinding, burnedOut, isolated, holding, hopeful, cornered, clear) computed fresh each tick from state. Passed to prose generators and exposed to UI for accent color temperature, tab label tone shifts, micro-copy register. High scandal heat in Politics → colder/more paranoid UI tone.

**Vibe Contract:** Maintain all four or regress to generic sim.

---

## Codex V: Narrative Compression & Summary-to-Action Pipeline
- **Headline-First:** 5–7 word summary → direct bullet impacts (domain deltas) → max 3 choices.
- **Dynamic Flavor:** Prose register shifts with NarrativeTone / current pressures / D4 life-shape / resilience mode.
- **Tiering:** Tier 1 Vitality Bar (persistent glance) → Tier 2 Domain Overview (Net Velocity + pressures) → Tier 3 Deep Ledger (player-initiated, contextual).

---

## Codex VI: Special Careers & Depth Mandate
Every special path (Athlete, Founder/CEO, Politics, Crime) **must** avoid shallow gaps:
- Dedicated State struct with real pillars/stage curve.
- Full instant quick-action layer (static always-available, BitLife-style) with autonomous reactions.
- Bidirectional integration across domains + Fame + D4 + LifeResilience.
- Rich narrative (5-voice archetypes, Echo for past choices, Silence with path flavor).
- UI dashboard + glanceable metrics + legacy/post-career paths with mechanical weight.
- Resilience divergence visible in stories, spillovers, and harvest flags.

Shallow = just generic fame/heat numbers + a few yearly rolls. We do not ship that.

---

## Codex VII: Implementation & Polish Philosophy
- **Playable After Every Slice:** Core loop must be more fun immediately after any phase. No regressions.
- **Low Overhead:** Reuse ledger, dossier/stance residue, existing patterns. Instant path stays cheap (cached snapshots, no heavy rebuilds).
- **Every Addition Has Visible Feedback:** Note, delta, chip change, forecast line, or journal entry.
- **Test Rule:** Manual full life playthrough (normal + special path + weird/extreme) after major slices.
- **Discoverability:** Powerful systems (long-press previews, momentum/life-shape, resilience mode, adult child stories) must have clear affordances and lightweight first-time teaching. No external explanation needed.
- **Hierarchy & Late-Game:** Compact mode for dense mid/late game. Preserve 2-sec glance and thumb reach.
- **Feedback Parity:** Yearly Age Up must feel as visceral as instant layer (deltas, stance/shape callouts, haptics where cheap).

**Final Filter:** Does this change make a player say "This feels like *my* life and the world is reacting to *my* choices" while staying fun and glanceable? If not, iterate.

---

*This Codex is the contract. All planning and code must honor it. Update only with explicit consensus on philosophy shifts.*