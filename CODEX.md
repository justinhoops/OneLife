# OneLife Design Codex

---

## Codex I: The Architectural Manifesto
**Title: The Orchestrator & Domain Pattern**

The Core Directive: To ensure long-term stability and prevent the "God Object" anti-pattern, the game engine follows a strict Separation of Domains. The codebase is a collection of specialized systems, not a monolith.

The Rule of Two: If a single class or system attempts to manage logic across more than two domains (e.g., Career and Finance), it must be decoupled.

The Role of GameState: GameState is the Orchestrator, not the "brain." It holds references to domain-specific states but does not calculate logic. It manages the "Yearly Tick" sequence and data persistence.

Domain Sovereignty: Each domain (Finance, Career, Relationships, Health) owns its logic.

States: Pure data containers (POJOs/Structs).

Systems: Logic processors that transform state based on inputs.

Efficiency & Scalability: This modularity prevents "spaghetti dependencies." New domains (e.g., Politics, Crime) plug into the Orchestrator without breaking existing systems.

---

## Codex II: The Design Philosophy
**Title: Raw Authenticity vs. Playable Simulation**

The Core Directive: To build a "Life Killer" that feels raw and authentic without becoming a tedious chore. We seek "Uncomfortable Realism" that other games ignore.

The Anti-Exploit Clause: Wealth is earned, not given. We eliminate the "Zillionaire" trajectory. Success requires a rare alignment of traits, career progression, and luck—mirroring real life.

Meaningful Depth: Complexity must be proportional to impact. If a feature feels like a "second job," it is refactored for Frictionless Immersion. If a feature feels "bland," it is given Domain-Specific Consequences (e.g., a toxic job drains Health and Relationships).

Continuity of Experience: Every new mechanic must pass the Continuity Check: "Does this feel like the same game?" We maintain consistent UI language and interaction density.

The App Store Balance: We simulate life with honesty and grit while maintaining a level of abstraction that ensures accessibility and compliance. We don't sanitize; we simulate.

---

## Codex III: Optimization & System Logic
**Title: Domain Sovereignty & Hibernation**

The Core Directive: A domain should only consume resources when it is Active or Influential through State-Contingent Execution.

System Hibernation: The Orchestrator maintains a SystemRegistry. During each tick, it checks the IsActive flag. (e.g., If Age < 5, Career and Finance systems are bypassed).

The Modifier Pattern: Systems interact with a Policy Domain to retrieve environmental variables (Taxes, Cost of Living) rather than hard-coding values, ensuring global balance.

Lazy NPC Resolution: The Social Domain will not process aging or decay for non-essential NPCs until the player interacts with the Social Tab, saving processing power during transitions.

---

## Codex IV: The UI/UX Manifesto
**Title: The Trinity of Interface (Continuity, Readability, Usability)**

The Core Directive: Deliver deep simulation through a minimalist lens. The player feels the weight of choices through visual cues, not walls of text. We follow the "Summary-to-Action" pipeline.

Readability (The Glance Rule): Prioritize Information Density over Prose Density. Icons over Adjectives: Use symbols for stats (e.g., lightning for energy). The 2-Second Audit: A player must identify their "Top 3" statuses within two seconds of opening a tab. Color as Data: Red = Danger/Deficit; Green = Growth/Surplus. No decorative use of these colors.

Ergonomics (The Thumb Zone): Green Zone (Bottom/Center): Primary buttons like "Age" or "Next." Yellow Zone (Middle): Navigation tabs for Relationships or Assets. Red Zone (Top): Settings and headers; infrequent interactions.

Progressive Disclosure: Tab Level: Aggregated status (e.g., "Net: +$200"). Feature Overview: Specific buckets (e.g., Taxes, Living Costs). Action/Summary: Granular decision or result pop-up.

---

## Codex V: The Unified Signal & Event Architecture
**Title: The Sensory Bridge**

The Core Directive: Logic systems never "push" updates to the UI. The Orchestrator uses a State-Observer Pattern so the UI remains a "dumb" skin reflecting the "smart" state.

The Feedback Pulse: State changes are categorized by magnitude to determine haptic and visual response. Micro: Low-latency haptic click for button taps. Minor: Subtle color flash on icons for small stat shifts. Major: Distinct "double-tap" haptic and modal pop-up for domain shifts (e.g., Promotion). Critical: Heavy haptic and full-screen overlay for life-altering events (e.g., Death).

---

## Codex VI: Narrative & Prose Management
**Title: The Narrative Compression Engine**

The Core Directive: To maintain authenticity without overwhelming the player, narrative events follow a Headline-First structure.

Information Tiering: The Headline: A 5–7 word summary (e.g., "Your Startup Has Failed"). The Impact: Direct bullet points showing domain consequences (e.g., Health -10). The Choice: A maximum of three options to prevent decision paralysis.

Dynamic Flavor Text: Prose shifts based on state. If a player is "Depressed" or "Burned Out," UI descriptions shift from "Professional" to "Cynical" to reflect the psychological state of the character.

---

## Codex VII: The "Summary-to-Action" Pipeline
**Title: Data Distillation for One-Handed Play**

Information Tiering following the "Glance Rule," data is delivered in three distinct layers to ensure the "No-Scroll" goal is met.

Tier 1: The Vitality Bar (Persistent) — Located in the Green Zone (Natural Thumb Reach). Shows: Net Worth, Health %, and Age.

Tier 2: The Domain Overview (Tab Level) — Shows "Net Velocity" (e.g., Finance shows "$+500/mo" rather than a full ledger). Uses Color as Data to signal distress immediately.

Tier 3: The Deep Ledger (Action Level) — Only accessed when a player clicks a specific bucket. Presented in a Contextual Modal so the player never "leaves" the main screen, maintaining Continuity of Experience.

The "Natural Thumb Zone" Priority: The interface is weighted toward the bottom 30% of the screen. Primary Action (Age Up): Center-Bottom. Navigation (Tabs): Directly above the Primary Action. Secondary Actions (Assets/Activities): Flanking the Primary Action.

---

## Codex VIII: The Narrative Compression Engine
**Title: Prose Density Management**

The Core Directive: To satisfy the "Life Killer" authenticity without the "Tedious Chore," narrative events must follow a Headline-First structure.

The Headline: A 5–7 word summary of the event (e.g., "Your Startup Has Failed"). The Impact: Direct bullet points showing Domain consequences (e.g., Health -10, Finance -$50,000). The Choice: Maximum of three distinct options to prevent decision paralysis.

---

## Codex IX: The Vibe Layer
**Title: Voice, Echo, Silence & Mood**

### The Core Directive
The feeling of the game is not delivered by any single system — it is the sum of four interlocking layers that must all work together. A game with great events but neutral prose feels hollow. A game with vivid prose but no consequence memory feels disposable. All four layers are non-negotiable.

---

### Layer 1: Voice — The Proximity Rule
**Rule: The player must always feel *inside* the moment, not narrated at from a distance.**

Every piece of prose in this game — event text, journal notes, tab labels, stat descriptions — is written in tight second-person, present tense, with concrete specificity. No abstractions. No passive distance.

**Wrong:** "An unexpected bill arrived and needs attention."
**Right:** "The mechanic says $1,400. You have $380 in the account."

**Wrong:** "A new connection feels promising."
**Right:** "She gave you her number. You haven't texted yet."

Voice is a writing constraint, not a content constraint. It applies equally to static events, procedurally generated events, and UI micro-copy. The `NarrativeTone` of the player's current state (see Layer 4) modifies the register of this voice — same facts, different emotional temperature.

---

### Layer 2: Echo — Consequence Memory
**Rule: The past must be present. A choice that isn't remembered never mattered.**

The `ConsequenceState` system (narrativeFlags + pressureByDomain) is the backbone of this layer. When a player makes a meaningful choice, the game sets a flag. When future events fire, the `EchoFlavorResolver` checks those flags and prepends a one-line memory to the event text — making the world feel continuous rather than episodic.

**Example:** Flag `took_payday_loan` is active → any finance event prefixes: *"You're still paying off that loan from two years ago."*

**Example:** Flag `missed_checkup_streak >= 2` → health event prefixes: *"You haven't seen a doctor in years."*

Echo lines are short (one sentence maximum), factual, and never moralistic. They state what happened, not what it means. The player supplies the meaning.

**Implementation:** `EchoFlavorResolver.swift` — maps active narrative flags to contextual prefix strings, resolved per event at display time.

---

### Layer 3: Silence — The Weight of Nothing
**Rule: Not every year deserves an event. Some years are just years.**

When the EventEngine returns nil — no eligible event fires — the game does not skip the year silently. Instead, `SilentYearEngine` generates a one-line journal note based on the player's current dominant state. These notes are added to `history` as a `HistoryEntry` with the `lifeEvent` tag.

Silence notes are not neutral. They carry the emotional weight of the player's situation:

- High financial stress, no event: *"Another month of watching the balance."*
- Stable, career plateaued: *"Same job. Third year running."*
- Low relationships, isolated: *"Quiet year. Nobody really checked in."*
- Burned out, health declining: *"You made it through. That's all you can say."*
- Genuinely stable: *"Nothing broke. You almost didn't notice."*

Silence is not a fallback — it is a feature. The accumulation of quiet years in the history log is one of the most powerful narrative tools in the game.

**Implementation:** `SilentYearEngine.swift` — maps `NarrativeTone` + `criticalStatuses` to a weighted pool of silence notes.

---

### Layer 4: Mood — The UI Carries the Weight
**Rule: The interface is not neutral. It reflects the life being lived.**

The `NarrativeTone` system derives the player's current emotional register from game state. This tone is computed, not stored — it is always current. It has two functions:

1. **Prose register** — passed to `SilentYearEngine` and `EchoFlavorResolver` to adjust the register of generated text.
2. **UI signal** — exposed as a property on `GameState` so the UI layer can adjust visual treatment: accent color temperature, stat label tone, and the register of micro-copy (e.g., a `financialStress >= 65` state turns the finance tab label from "Finances" to "Debt").

The `NarrativeTone` cases:
- `.grinding` — financially stressed, no relief in sight
- `.burnedOut` — high career/education burnout, low energy
- `.isolated` — low relationships, low belonging
- `.holding` — stable but not thriving; the plateau
- `.hopeful` — genuine upward momentum in at least one domain
- `.cornered` — multiple critical statuses active simultaneously
- `.clear` — genuinely stable across all domains

**Implementation:** `NarrativeToneResolver.swift` — pure function: `GameState → NarrativeTone`. No stored state. Computed fresh each tick.

---

### The Vibe Contract
These four layers are a contract with the player. Break any one of them and the game regresses to a spreadsheet. Maintain all four and the game earns the right to call itself a life simulator.

> "The specificity of the language is the empathy."
