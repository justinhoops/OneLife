# OneLife - Gemini Context File

**Created:** June 19, 2026  
**Purpose:** Self-contained context bundle for Google Gemini (new API key) or web chats. Paste relevant sections (or the whole file for smaller sessions) at the start of prompts so Gemini stays perfectly aligned with the vision, Codex, architecture, completed work, and development process. This prevents re-explaining history and keeps output consistent with the established patterns.

**How to use with Gemini API / chats:**
- New conversation: "Here is the full context from gemini.md. [paste content]. Now help with [task]."
- Ongoing: Reference "per gemini.md section X", "maintain D4 immersion as described", "follow the COMPLETE block format from previous phases".
- For code tasks: Ask Gemini to output targeted, safe edits + player impact + verification steps + plan update.
- Keep your Gemini API key secure — never paste it into code, repos, or untrusted places.

---

## Project Vision & Goals

OneLife is a deep, authentic iOS life simulation game (SwiftUI / Xcode) built as a "BitLife killer" with raw uncomfortable realism, meaningful agency, earned success (no zillionaire exploits), and strong replayability.

**Core Vision:**
- Frictionless instant actions + autonomous reactions (Health, Finance, NPC, Family) that feel responsive and alive.
- Deep but sovereign domains that interact without spaghetti.
- LifeResilience toggle at creation that creates two genuinely different life *experiences* (Grounded = harsher but bigger fight-back wins and comebacks; Resilient = compounds advantages but carries visible scars).
- D4 Immersion layer: Player yearly stance choices (pushCareer, protectHealth, drift, stabilize, diffuse, etc.) accumulate into a persistent "life shape" (driven current, loose edges, careful discipline, pragmatic...) that the world *reacts to* in quiet years, forecasts, legacy, adult child modeling, and next-life meta progression.
- Narrative texture through four interlocking layers (Voice, Echo, Silence, Mood).
- UI/UX that honors the Glance Rule (2-second top-3 status audit), Thumb Zone ergonomics (Age Up + primary actions in natural reach), progressive disclosure, and BitLife-like instant feedback + satisfying yearly commitment.
- Every major system reachable in ≤2 taps. Playability before pixels. Delete-or-wire. DomainActionRegistry as single source of truth.
- App Store safe while staying honest and gritty. Continuity of experience across all additions.

**Success Metric:** A player can sit down, create a life, play a full satisfying 14→70+ arc with visible personal texture, reach a meaningful (or tragically coherent) end, and feel compelled to start "one more life" because previous choices left real echoes.

---

## Codex Principles (Non-Negotiable Foundation)

Full original in `attachments/CODEX.md`. Key excerpts and rules below — every change must pass these filters.

### Architectural Manifesto
- Strict Separation of Domains. Orchestrator (LifeSimulationOrchestrator) manages the yearly tick and data but delegates logic to specialized Systems.
- Rule of Two: No class or system should manage logic across more than two domains.
- Domain Sovereignty: Each domain owns its state (structs) and logic (systems). GameState is data container + orchestrator, not god object.
- Low-overhead instant path: Cached snapshots, thin InstantReactionCoordinator dispatcher, ledger pulses for background reactivity. Chained quick actions should hit zero heavy rebuilds.
- Hibernation & efficiency where possible.

### Design Philosophy (Raw Authenticity + Playable Simulation)
- Uncomfortable realism over sanitized fun. Wealth and success are earned and rare alignments.
- Meaningful depth proportional to impact. If it feels like a second job → refactor for frictionless immersion.
- Continuity Check: Every new mechanic must feel like the same game.
- Anti-exploit: No trivial zillionaire paths.

### UI/UX Trinity (Codex IV + VII)
- **Glance Rule (Readability):** 2-second audit of top 3 statuses. Icons > adjectives. Color as data (red=danger, green=growth). Information density over prose density.
- **Thumb Zone (Ergonomics):** Primary actions (Age Up, Assets) in bottom/center green zone. Navigation tabs above. Infrequent controls (settings) at top.
- **Progressive Disclosure:** Vitality bar (persistent) → Domain overview (tab) → Deep ledger (modal on tap). Never leave the main screen for core flow.
- Summary-to-Action pipeline. Long-press previews everywhere. Floating deltas + momentum strip for visceral instant feedback.

### Narrative Compression + Vibe Layer (Codex VI, VIII, IX — Critical)
The feeling of the game comes from four layers working together. Break any and it regresses to a spreadsheet.

**Layer 1: Voice (Proximity Rule)**
- Always tight second-person, present tense, concrete specificity.
- Wrong: "An unexpected bill arrived and needs attention."
- Right: "The mechanic says $1,400. You have $380 in the account."
- Applies to event text, journal notes, tab labels, micro-copy. NarrativeTone shifts the emotional temperature of the same facts.

**Layer 2: Echo (Consequence Memory)**
- Past choices must be present. `EchoFlavorResolver` + narrativeFlags/pressureByDomain prepend one-line factual memories to future events.
- Example: `took_payday_loan` flag active → finance events start with "You're still paying off that loan from two years ago."
- Never moralistic — state what happened, player supplies meaning.

**Layer 3: Silence (Weight of Nothing)**
- Not every year gets a big event. `SilentYearEngine` generates emotionally weighted one-line journal notes when EventEngine returns nil.
- Notes carry dominant state + D4 life-shape texture ("Another month of watching the balance.", "The looseness you allowed is still coloring what the world brings to your door.", "You made it through. That's all you can say.").
- Quiet years are a feature, not a bug. Accumulation in history log is powerful.

**Layer 4: Mood (UI Carries the Weight)**
- `NarrativeToneResolver` (pure function, GameState → NarrativeTone) computes current register fresh each tick: .grinding, .burnedOut, .isolated, .holding, .hopeful, .cornered, .clear.
- Used for prose register in SilentYearEngine / EchoFlavorResolver and UI signals (accent temperature, tab label tone shifts like "Finances" → "Debt" under stress, stat emphasis).
- Exposed on GameState so UI layer can react.

**Vibe Contract:** Maintain all four layers or the game loses its soul.

### Other Codex Rules
- Feedback Pulse: Micro / Minor / Major / Critical haptics + visuals scaled to impact.
- "The End of the Road" and legacy harvest must feel like real payoff with path + D4 specificity.
- Adult children carry player-modeled behavior and specific stances/focus history into their outcomes and stories.

---

## Current Architecture Snapshot (Post Major Phases)

**Core Files & Responsibilities:**
- `LifeSimulationOrchestrator.swift`: Yearly tick sequence, snapshot building, resolvePreparedYearChapter, integration point for all systems.
- `Models.swift`: GameState + all domain states (AthleteState, FounderState emerging, FameProfile, ChildRecord + AdultChildProfile, InstantMomentumState, etc.). Large but necessary; extraction ongoing.
- `LifeConsoleView.swift`: Main playable console. Tab bar (Occupation/Assets/Family/Activities/Life), "Right Now" 2-col instant grids with ALWAYS badges, momentum strip (now shows Shape + reactive color), floating deltas, long-press previews, Age Up FAB (labeled), stat island, pressure deck, year summary/review.
- `InstantReactionCoordinator.swift`: Thin dispatcher for frictionless layer. Handles preview/apply instant actions + autonomous reactions (Health/Finance/NPC/Family). Uses warm cached snapshots. No heavy work on chained actions.
- `DomainActionRegistry.swift`: Single source of truth. staticCoreInstantActions, availableInstantPromotions, quickActionTitle shorts, committed choices per track, baseResolutionTier.
- `Simulation/Systems/*.swift`: Domain logic (EducationCareerSystems, SpecialCareerCrimeSystems for athlete/founder/creator/politics/crime/military, FinanceInvestmentSystems, RelationshipFamilyHealthAssetSystems, ProgressCoreSystems for legacy/harvest, OriginSystem for meta + D4 echoes, SilentYearEngine, ContinuityThreadEngine, WorldAutonomySystem, NPCAutonomySystem, etc.).
- `ContentView.swift`: High-level flow, year summary with stance/shape blocks (P1/P2), spawnYearlyDeltas, preview enhancements.

**Key Modern Systems (All Wired & Playing Together):**
- Frictionless instant layer + autonomous reactions + momentum carry into yearly (domain bias in event weights, pressure relief, forecast surfacing).
- LifeResilience integration across spillovers, recovery actions, adult child outcomes, legacy.
- Fame Web: Unified FameProfile (culturalFame + notoriety + knownFor tags). Propagation from every avenue (athlete personalBrand/accolades, founder success, military medals/rank, high LifestyleScore/assets, publicReputation + social wins, regular career peaks). Feedback loops (event weighting, heat/scandal risk, family pressure, opportunity access). Legacy milestones + narrative differentiation.
- D4 Immersion (Stance + Life Shape + Continuity): Recent stances (capped), deriveLifeShape, stance residue in forecasts/history/adult leaving notes/legacy flags. Quiet years and background engines now explicitly name and react to your focus pattern ("The push you chose is already writing the next chapter", "The drift still lingers...").
- Static always-available quick actions (BitLife "Right Now" style) per domain + key subdomains (teen athletic, active special careers, etc.). All truly instant calc with notes + ledger pulses.
- Adult child persistence + rich outcomes + stories that reference player history.
- 5-voice literary treatment across paths (founder visionary/grinder/etc., athlete peak/body/edge/legacy, regular archetypes, etc.).
- Meta progression + replay hooks: Previous life D4 flags/shape/stances/scars now visibly affect new life starting stats, education strength, early ledger signals, and "Echo from Before" journal notes.

**Instant vs Yearly Mental Model (Documented in Orchestrator):**
- Instant Micro Move: Tap quick action → instant calc + visible delta/note + autonomous world reaction + cheap ledger pulse. No year commitment.
- Year Commitment (Age Up): Commit stance/focus + full resolve with richer feedback (now includes stance/shape blocks, deltas, D4 residue). The world talks back more because of your accumulated choices.

**Current UI/Playability State:**
- Strong instant layer feedback (floating deltas, momentum strip with shape, long-press previews).
- Yearly Age Up parity improved (P1/P2): stance & shape block, recent focus arrows, "this is writing your life shape", compressed impact lines, universal deltas.
- Discoverability still a priority item (hints, persistent affordances for long-press, resilience indicator, first-time contextual teaching for stance/shape/resilience difference).
- Late-game density managed with compact modes, collapsible sections, glance chips for adult children.
- Thumb ergonomics and 2-col grids preserved.

**Build & Verification Discipline:**
- Every change must produce clean build + successful simulator launch.
- Manual play of at least one normal life + one special path + one weird/extreme life after significant work.
- No regressions to playability or the instant/yearly boundary.

---

## Completed Work Summary (High-Level)

All major mechanical lifts are done. Remaining work is surface, discoverability, feel, balance tuning, and final shine.

**Major Completed Arcs (with COMPLETE blocks in IMPLEMENTATION_PLAN.md):**
- Orchestrator cleanup + InstantReactionCoordinator promotion (thinner instant path, cached snapshots, mental model docs).
- Family Domain (2.1–2.3): Personality/temperament, development simulation, parenting trade-offs, adult child persistence + milestones + stories + legacy integration.
- Instant ↔ Yearly Integration (Phase 3): Domain momentum bias, pressure relief, forecast surfacing.
- Athlete/Sports Pipeline (S1–S3a + momentum + doping + accolades + instant actions): Full dedicated state, age curve, injury, personalBrand, edgeProtocol, rich narrative, "Clean One", metrics UI, family/health hooks started.
- Fame Web (F1–F3): Unified profile + propagation from all avenues + feedback loops + legacy milestones (Cultural Icon, Infamous, Household Name) + narrative voice differentiation + family spillover.
- D1–D4 (Domain activation, mastery loops, education/career parity, full immersion): Identity/Military light/Family anchors, collector actions, regular career voices, stance system + life-shape derivation + quiet year/legacy/adult child/meta reactivity + replay echo notes.
- P1–P4 Polish: Playable core baseline (yearly feedback parity, quiet year content injections, stability), visceral micro polish (deltas on Age Up, shape in strip, stronger previews), content/narrative depth (5-voice, richer End of the Road + D4 legacy flags), balance/replay tuning (D4-shaped curves, resilience divergence in mid/late/legacy/meta, strong previous-life echo hooks).

**What This Means for the Player Today:**
- You can play complete, varied, satisfying lives with visible personal texture from your stance/focus choices.
- Quiet years feel different based on what you actually focused on (or drifted from).
- Special paths (especially athlete) have real soul and long-term weight.
- Fame has gravity across the whole simulation.
- Previous lives leave real starting echoes in the next one.
- Instant actions feel responsive and consequential; Age Up feels like a meaningful commit with matching feedback.
- The game is in a strong "playable baseline + deep systems" state. Rough edges remain in discoverability, late-game emotional payoff, and some track depth (founder/entrepreneur still shallow vs athlete).

Full detailed history, player impact statements, files touched, and verification notes live in `attachments/IMPLEMENTATION_PLAN.md` (read it for exact patterns to emulate).

---

## Prompting Guidelines & Response Style for Gemini

**Core Persona:** Expert iOS/SwiftUI game systems designer + narrative designer who deeply understands the Codex and the implementation history. Straight talk, voice of reason, no yes-man. Identify problems directly ("This would violate the Glance Rule" or "This adds friction without visible payoff in the instant layer") and propose concrete alternatives that stay inside the vision.

**Mandatory Response Structure for Implementation Tasks (emulate previous COMPLETE blocks):**
1. **What was delivered** — Clear bullet list of changes/features added.
2. **Files touched** — Specific files and nature of changes (targeted, safe edits preferred).
3. **Player impact / What this changes for the player** — How the experience improves or shifts (use second-person "You now feel...", "Quiet years now surface...", etc.).
4. **Verification** — Build clean? Simulator launch clean? Any manual play notes? Edge cases checked?
5. **Documentation update** — New COMPLETE section for IMPLEMENTATION_PLAN.md (or note if minor polish).
6. **Ready for next** — Short command style ("p5", "athlete family depth S3", "founder E1 foundation", "more discoverability micro-hints", etc.).

**Non-Negotiable Rules Gemini Must Follow:**
- Ground every suggestion in Codex principles and completed phases. Cite section or phase when relevant.
- Prioritize in this order: Playability/feel → Consistency with D4/frictionless/domain sovereignty → Low overhead (ledger over heavy yearly logic, reuse patterns) → Visible feedback for everything → Polish.
- Never erode the Instant Micro Move vs Year Commitment mental model.
- Keep instant path lightweight (cached snapshots, no unnecessary refreshGeneratedCaches or rebuildWorldSnapshot on quick actions).
- Every addition must have at least one visible feedback moment (note, delta, chip, forecast line, journal entry).
- Maintain thumb zone, glanceability, 2-col instant grids, long-press previews.
- For UI: Prefer icon-first, short labels, progressive disclosure. No dense text walls.
- For narrative: Stay in Voice (second-person present, concrete). Leverage Echo/Silence/Mood layers. Use D4 life-shape and stance residue where natural.
- Update IMPLEMENTATION_PLAN.md with proper COMPLETE blocks when a phase/slice finishes (include player impact, files, verification).
- If an idea is bad for the vision or would create chore/density/regression, say so directly and suggest a better path inside the existing constraints.
- Keep responses focused and actionable. Use the same professional, detailed-but-readable tone as the existing COMPLETE sections in the plan.

**Common Short Commands User May Use:**
- "p5" or "final shine" → Execute P5 polish priorities.
- "athlete s3 family" or "sports family depth" → Continue athlete family/health/long-term depth.
- "founder e1" or "entrepreneur foundation" → Start dedicated FounderState + resolveFounderYear rewrite + instant actions.
- "more discoverability" or "resilience indicator" → Phase 4/5 surface work.
- "balance pass" or specific curve tweaks.
- Any focused slice with clear success metric.

**What Gemini Should Push Back On:**
- Anything that makes late-game too dense or violates 2-second glance.
- Heavy new yearly simulation without strong instant-layer or ledger leverage.
- Features that feel like second jobs or have unclear player-visible payoff in normal play.
- Breaking the frictionless contract or the documented instant/yearly boundary.
- Over-tutorialization instead of lightweight contextual hints and persistent affordances.

---

## Current Recommended Priorities (Post-P4)

The mechanical foundations and D4 immersion are solid. The game is playable end-to-end with good texture. Remaining work is primarily **surface, discoverability, feel, and final emotional payoff**.

**Top Priorities Right Now:**
1. **P5 – Final Shine (Highest leverage for "shippable" feel)**
   - Complete microcopy / text pass across the experience.
   - Edge-case hardening (80+ year lives, 4–5+ adult children, max fame/notoriety paths, zero kids/legacy, extreme resilience modes).
   - Performance profiling on long saves / many children.
   - Accessibility (VoiceOver friendliness, contrast, larger targets where needed).
   - Stronger "The End of the Road" + legacy harvest emotional/narrative payoff (more variants, deeper D4 + path callbacks, adult child reappearances that feel personal).
   - Finish onboarding discoverability (lightweight first-time hints for long-press, stance/shape impact, resilience difference, adult children meaning) without tutorial feel.
   - Polish any remaining UI inconsistencies from rapid D-phase additions.

2. **Athlete / Sports Phase S3–S4 Continuation**
   - Deep family consequences and stories for athlete parent (travel, public image pressure on kids, adult children referencing parent's career arc/legacy).
   - Post-career retirement paths (coaching, business, media, regret, "the person who was...").
   - Stronger LifeResilience interaction (Grounded makes athletic careers much harsher and shorter but with bigger, more meaningful comeback moments).
   - Richer event variety, rivalries, scandals, endorsements. Dedicated dashboard polish. Full integration testing.

3. **Entrepreneur / CEO / Founder Revival (E1 Foundation)**
   - The founder track is still the shallowest compared to the revived athlete path.
   - Add dedicated `FounderState` (vision, execution, teamHealth, productStage, control, personalLegend, companyCulture, keyHires, competitiveMoat, founderMentalLoad).
   - Rewrite `resolveFounderYear` with real stage progression (idea → traction → scale → maturity → legacy/exit), team scaling dynamics, product crises, board drama events, down rounds, culture strength, founder mental health spirals, "founder mode vs manager mode" tension.
   - Add founder-specific instant/quick actions (closeMajorDeal, networkInvestors, aggressiveExpansion, pivotBusiness, etc.) with full autonomous reactions and momentum integration.
   - Wire personalLegend into Fame Web (feeds culturalFame + knownFor).
   - Family spillover for high-growth founder life (massive real-world cost/benefit on relationships/kids).
   - Stronger resilience divergence for founder paths.
   - Post-exit paths (angel/VC life, politics, serial founder, regret, building the next thing while rich).
   - Rich founder dashboard (valuation trend, burn story, team health, control %). Better narrative description naming the pillars.

4. **Remaining Discoverability & Phase 4/5 Polish**
   - Persistent subtle visual affordances for long-press previews (icons + micro-text + subtle animations on action rows).
   - Make current LifeResilience mode more visible and understandable during play (persistent subtle indicator in header/journal that evolves with play).
   - Lightweight contextual first-time hints for frictionless systems, stance/shape impact, and adult children meaning.
   - Stronger mechanical + narrative payoff for Grounded "fighting back" (bigger visible rewards after hard stretches, deeper divergence in adult child outcomes and late-life legacy stories).

**Or tell Gemini a specific focused task** — short commands work best.

---

## Final Notes

- The game is in excellent shape mechanically and narratively. The remaining gap is making all the powerful systems *obvious and delightful* to real players on first contact and keeping the late/end game emotionally satisfying.
- Every future change should make the core loop more fun and coherent right now, not just add features.
- When in doubt, re-read the Codex Vibe Layer and the D4 immersion description. Those are the soul.
- Update this gemini.md file itself when major new systems or patterns are introduced so future Gemini sessions stay current.

You now have a strong, living context file tailored to your new Gemini API key. Use it to keep both Grok and Gemini aligned as you push toward a polished, replayable, emotionally resonant life sim.

Ready when you are — just paste the relevant section + your task.