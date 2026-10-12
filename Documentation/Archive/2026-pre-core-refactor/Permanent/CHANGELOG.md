# OneLife — Changelog

Concise history of major changes per phase. Use for launch notes and agent handoff.

---

## [Unreleased] — P5 Launch Polish (Cycle 2) — June 29, 2026

**Target:** Professional ship quality — narrative volume, accessibility, edges, onboarding, launch assets.

### P5-1 Narrative
- Mid/late-game silent year flavor (era, path, fame, shape, adult-child aware) in `SilentYearEngine`
- Regular archetype 5-voice extension with stance/shape/resilience conditioning
- Shape-aware regular career "End of the Road" variants
- Adult-child "Next Generation" closer in `finalizeLifePath`

### P5-2 Accessibility
- High-contrast color emphasis setting + global contrast modifier
- Combined VoiceOver label on momentum strip (domains + shape + resilience)
- Recognition glance row accessibility + explainer sheet
- Reduced-motion honored on momentum strip container animation
- Settings copy clarifying Reduced Motion

### P5-3 Edges
- Athlete enhancement heat telegraph (40/55/70 thresholds)
- Founder board pressure telegraph (70/85 before coup)
- Crime heat telegraph before forced underground

### P5-4 Onboarding
- First fame/Recognition coach via `DiscoverabilityState`
- First harsh-pressure resilience recovery coach
- Recognition card tap-to-explain pattern

### P5-5 Meta & Launch
- Creation preview: life shape tendency + previous-life meta echoes
- Stronger harvest → next-life stat/note bonuses in `OriginSystem`
- Game-over button adult-child remember line
- App Store screenshot storyboard (`APP_STORE_SCREENSHOTS.md`)

**Build:** BUILD SUCCEEDED (iPhone 17 simulator)

---

## P5 Foundation — Final Shine (June 2026)

Executed on `p5` after P4 balance pass.

- **P5-1:** Context-aware "Life Ended" texts; late-life SilentYearEngine flavor (80+, notoriety, zero-kid, broke)
- **P5-2:** `Persistence.prunedState` caps adult-child `keyStories` for large families / age 75+
- **P5-3:** VoiceOver labels on Age Up, game-over, momentum strip life-shape
- **P5-4:** Dossier/stance coach line in `DiscoverabilityState.pendingCoachLine`
- **P5-5:** Richer `finalizeLifePath` closer naming shape + resilience + era
- **P5-6:** Build hygiene; verification on normal + special + long runs

---

## P4 — Balance, Fairness & Replay Hook (June 2026)

- Safety nets + risk telegraph for high-variance paths
- Regular career archetype ramps + dossier/shape modulation
- Athlete/founder/crime variance buffers + shape modulation
- Resilience divergence in spillovers; era reward notes
- Stronger next-life echo seeding from harvest

---

## P3 — Narrative Voice & Endgame Texture

- Uniform 5-voice literary treatment on special careers (founder, athlete, crime, CE4)
- Regular archetype voice seeds (6+ flavors in `EducationCareerSystems`)
- D4 legacy flags; richer "End of the Road" with shape modifiers
- Legacy harvest expansion; adult-child callback hooks

---

## P2 — Visceral Feedback & Yearly Parity

- `spawnYearlyDeltas` extended for stance/shape/pressure changes
- Summary view stance & shape block; momentum on year summary
- Haptic/visual unification (instant + yearly)
- "Small Win To Try" on harsh years

---

## P1 — Playable Baseline & Discoverability Tier 1

- Momentum strip v2/v3 (domain bars, tap-to-explain, coach banner)
- Long-press hold hints; resilience sheet; instant/yearly mental model banner
- Adult-children first-appearance coach
- LifeResilience fighting-back bonus + spillover priority

---

## D-Phases — Domain & Immersion

- **D1–D2:** Domain static always-instants; Right Now grids across domains
- **D3:** Regular career archetypes (6 paths) with differentiated curves
- **D4:** Yearly stances, life shape, residue in forecasts/quiet years/legacy

---

## Fame Web (F1–F3)

- `FameProfile` unified cultural fame + notoriety
- Cross-domain propagation (athlete brand, crime heat, military medals, lifestyle)
- Recognition card + fame gravity in events and family spillover

---

## Special Career Revivals

- **Athlete S1–S3a:** AthleteState, instant layer, potential/brand/doping/accolades
- **Politics P1–P4:** Full path with fame, cost, legacy
- **Creator CE1–CE4:** Content creator pipeline + post-exit identities
- **Crime / Enterprise:** Literary voices, heat/notoriety, family cost

---

## Infrastructure & UI Shell

- TabView + pill dock console; domain sub-tabs (Assets, Careers, School, Cash, Love, Play)
- `ConsoleNavigationCoordinator`; tap audit ≤2 taps
- Orchestrator cleanup; snapshot caching; frictionless instant pipeline
- Childhood dossier + teen precursors + special career coupling
- Tier A playability: Now lane, soft run goals, cast strip, MVP onboarding

---

*Format: newest first. Minor fixes and copy tweaks omitted unless player-visible.*
