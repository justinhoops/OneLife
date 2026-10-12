# OneLife Design Codex

---

## Codex I: The Architectural Manifesto
**Title: The Orchestrator & Domain Pattern**

The Core Directive: To ensure long-term stability and prevent the "God Object" anti-pattern, the game engine follows a strict Separation of Domains. The codebase is a collection of specialized systems, not a monolith.

The Rule of Two: If a single class or system attempts to manage logic across more than two domains (e.g., Career and Finance), it must be decoupled.

The Role of GameState: GameState is the Orchestrator, not the "brain." It holds references to domain-specific states but does not calculate logic. It manages the "Yearly Tick" sequence and data persistence.

Domain Sovereignty: Each domain (Finance, Career, Relationships, Health, Family, Fame, etc.) owns its logic and state.

States: Pure data containers (Structs).

Systems: Logic processors that transform state based on inputs.

The Instant/Yearly Boundary: A clear mental model contract exists between Player Micro Moves (instant actions that feel immediate and low-cost) and Year Commitment (Age Up that carries weight, consequence, and long-term shape). The `InstantReactionCoordinator` enforces this boundary cleanly.

Efficiency & Scalability: This modularity prevents "spaghetti dependencies." New domains plug into the Orchestrator without breaking existing systems.

---

## Codex II: The Design Philosophy
**Title: Raw Authenticity vs. Playable Simulation**

The Core Directive: To build a "Life Killer" that feels raw and authentic without becoming a tedious chore. We seek "Uncomfortable Realism" that other games ignore.

The Anti-Exploit Clause: Wealth and success are earned, not given. We eliminate the "Zillionaire" trajectory. Success requires rare alignment of traits, career progression, focus, and luck — mirroring real life.

Meaningful Depth: Complexity must be proportional to impact. If a feature feels like a "second job," it is refactored for Frictionless Immersion. If a feature feels "bland," it is given Domain-Specific Consequences.

Continuity of Experience: Every new mechanic must pass the Continuity Check: "Does this feel like the same game?" We maintain consistent UI language, interaction density, and narrative voice.

The App Store Balance: We simulate life with honesty and grit while maintaining a level of abstraction that ensures accessibility and compliance. We don't sanitize; we simulate.

---

## Codex III: Optimization & System Logic
**Title: Domain Sovereignty & Hibernation**

The Core Directive: A domain should only consume resources when it is Active or Influential through State-Contingent Execution.

System Hibernation: The Orchestrator maintains awareness of which domains are currently relevant. Systems only perform heavy work when their domain is active or has meaningful downstream effects.

The Modifier Pattern: Systems interact with policy and environmental variables rather than hard-coding values.

Lazy & Event-Driven Resolution: Non-essential processing is deferred until interaction or necessity demands it.

---

## Codex IV: The UI/UX Manifesto
**Title: The Trinity of Interface (Continuity, Readability, Usability)**

The Core Directive: Deliver deep simulation through a minimalist lens. The player feels the weight of choices through visual cues, not walls of text. We follow the "Summary-to-Action" pipeline and the Glance Rule.

Readability (The Glance Rule): Prioritize Information Density over Prose Density. Icons over Adjectives. The 2-Second Audit: A player must identify their "Top 3" statuses within two seconds of opening the main view. Color as Data. Momentum strip, life shape, and key pressures must be glanceable at all times.

Ergonomics (The Thumb Zone): Primary actions and navigation live in the natural thumb reach zone. Long-press previews, quick actions, and Age Up must remain thumb-friendly even in dense late-game states.

Progressive Disclosure + Compact Modes: Tab level shows aggregated status. Deeper views and modals reveal detail only when requested. Late-game and high-family/career states automatically enter compact glance modes with collapsible sections and chips.

Current surfaces that must remain glanceable: Stat island, momentum strip (with life shape), pressure chips, stance/focus residue, and adult-child status.

---

## Codex V: The Unified Signal & Event Architecture
**Title: The Sensory Bridge**

The Core Directive: Logic systems never "push" updates to the UI. The Orchestrator uses a State-Observer Pattern so the UI remains a "dumb" skin reflecting the "smart" state.

The Feedback Pulse: State changes are categorized by magnitude to determine haptic and visual response. Micro, Minor, Major, and Critical pulses must feel consistent across both instant actions and yearly Age Up.

Floating deltas, momentum strip reactions, and stance/life-shape echoes are first-class feedback mechanisms.

---

## Codex VI: Narrative & Prose Management
**Title: The Narrative Compression Engine**

The Core Directive: To maintain authenticity without overwhelming the player, narrative events follow a Headline-First structure with clear impact and limited choice.

Information Tiering: The Headline → The Impact (bullet consequences) → The Choice (max 3 options).

Dynamic Flavor Text: Prose shifts based on the player's current NarrativeTone and life shape.

---

## Codex VII: The "Summary-to-Action" Pipeline
**Title: Data Distillation for One-Handed Play**

Information is delivered in three distinct layers to ensure the "No-Scroll" and Glance Rule goals are met.

Tier 1: The Vitality + Momentum Strip (Persistent) — Located in the natural thumb zone. Shows core stats + current life shape + recent momentum.

Tier 2: The Domain Overview (Tab Level) — Shows velocity, key pressures, and glanceable status. Uses color and icons as data.

Tier 3: The Deep Ledger / Detail (Action or Modal Level) — Only accessed when the player deliberately drills in. Long-press previews give a lightweight version of Tier 3 without leaving the main flow.

The "Natural Thumb Zone" Priority and progressive disclosure remain non-negotiable.

---

## Codex VIII: The Narrative Compression Engine
**Title: Prose Density Management**

(Principles from original Codex VI/VIII remain foundational and are now realized through the Vibe Layer in Codex IX and X.)

---

## Codex IX: The Vibe Layer
**Title: Voice, Echo, Silence & Mood**

### The Core Directive
The feeling of the game is delivered by four interlocking layers that must all work together. A game with great events but neutral prose feels hollow. A game with vivid prose but no consequence memory feels disposable. All four layers are non-negotiable.

### Layer 1: Voice — The Proximity Rule
The player must always feel *inside* the moment. Every piece of prose is written in tight second-person, present tense, with concrete specificity.

### Layer 2: Echo — Consequence Memory
The past must be present. Meaningful choices set flags and residue that future events, silent years, forecasts, and adult child stories can reference. The world feels continuous rather than episodic.

### Layer 3: Silence — The Weight of Nothing
Not every year deserves an event. `SilentYearEngine` generates emotionally weighted one-line journal notes based on the player's dominant state, recent stances, and life shape when no major event fires. Quiet years are a feature, not a failure.

### Layer 4: Mood — The UI Carries the Weight
The interface is not neutral. `NarrativeTone` (grinding, burnedOut, isolated, holding, hopeful, cornered, clear) and current life shape influence accent color temperature, stat label tone, micro-copy register, and the emotional temperature of the momentum strip and forecasts.

**The Vibe Contract** remains in force: Break any one of these four layers and the game regresses to a spreadsheet. Maintain all four and the game earns the right to call itself a life simulator.

---

## Codex X: Realized Evolution (Mid-2026)

This section documents the major systems that have been built and integrated since the original codex. These are now part of the living design contract and must be respected in all future work.

### X.1 Frictionless Instant Layer + Static "Right Now" Actions
A complete, low-cost instant action pipeline exists alongside the yearly commitment. Players can perform meaningful domain-specific actions at any time that calculate instantly, produce visible journal + stat feedback, trigger autonomous world reactions, and contribute to momentum — without queuing for Age Up.

Key realized elements:
- Clear mental model boundary between Player Micro Move (instant) and Year Commitment (Age Up).
- Domain and subdomain static always-available quick actions ("Right Now" grids) that feel like they belong to the current chapter of life.
- "ALWAYS" visual language and consistent thumb-friendly presentation.
- Warm snapshot caching so chained quick actions remain lightweight.

### X.2 Fame Web — Unified Recognition
Fame is no longer fragmented across silos. A single `FameProfile` (culturalFame + notoriety + knownFor tags) is fed by every avenue that can generate recognition:
- Athlete peak performance, personalBrand, and accolades
- Founder/creator/entertainment breakout success
- Military medals and rank
- High LifestyleScore / visible assets
- Strong public reputation and social wins
- Regular career high performance in public-facing roles

High fame/notoriety creates real mechanical and narrative feedback loops (opportunity access, heat/scandal risk, family pressure, event weighting). Legacy harvest now includes Cultural Icon, Infamous Figure, and Household Name paths with distinct flavor.

### X.3 D4 Immersion Layer — Life Shape & Stance Memory
Player focus choices now visibly shape the texture of the entire life:
- `recentStances` tracking produces a computed `currentLifeShape` (driven / loose / careful / pragmatic).
- Stance residue and focus echoes carry forward into forecasts, silent years, journal entries, adult child development notes, and next-life meta progression.
- Life shape meaningfully modulates curves and outcomes (athlete late-career resistance, founder burn rate, crime risk/reward, regular archetype performance).

This layer turns "what I chose to focus on" into a persistent, observable force rather than ephemeral numbers.

### X.4 Family as Persistent Story
Family is no longer a simple supportLoad counter. Children have:
- `ChildTemperament` (easygoing / spirited / sensitive / independent / intense) that influences behavior and development.
- Measurable bond, curiosity, and emotionalSensitivity that drift based on household conditions and player investment.
- `AdultChildProfile` persistence after emancipation, carrying outcome, relationshipQuality, lifeVibe, and keyStories seeded from childhood bond + temperament + the player's actual focus history and stance residue.

Adult children can reappear with stories that reference what the player modeled. Late-life emotional ripples (pride, worry, regret) and legacy harvest now reflect real family texture.

### X.5 Narrative Realization
The Vibe Layer (Voice + Echo + Silence + Mood) is fully implemented and reactive:
- `NarrativeToneResolver` computes current emotional register.
- `EchoFlavorResolver` prepends consequence memory to events.
- `SilentYearEngine` generates weighted quiet-year notes tied to recent stances and life shape.
- Uniform 5-voice literary treatment exists across founder, athlete, creator, politics, and regular career paths.
- "The End of the Road" and legacy text are now D4-aware and path-specific.

Every life can now tell a distinct story that the game remembers and reflects back at the end and into the next generation.

### X.6 Glance Rule & Hierarchy Enforcement
Phase 6 compaction work is in place:
- Icon-first glance surfaces and momentum strip with live life-shape subtitle (reactive color).
- Compact late-game mode (age 32+/40+ or heavy family/career) with collapsible sections and adult-child glance chips.
- Yearly Age Up now produces floating deltas for stance, focus, and tradeoff (visceral parity with the instant layer).
- Long-press previews surface D4 impact ("Shapes your life… + legacy echoes").

The original "2-second audit" and thumb ergonomics remain enforced even as systems have grown deeper.

---

**This document is the living design contract.**  
Update it when major new systems are realized. All future agent sessions and feature work must align with Codex I–X. The original principles (I–IX) remain the foundation. Codex X records what we have actually built and must now protect.