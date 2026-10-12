# Current architecture

One Life is a local, deterministic SwiftUI life simulator. `LifeSimulator` is the only gameplay mutation boundary; SwiftUI views render its published state and invoke actions or choices by ID.

## Core types

- `LifeState`: character, domain states, per-action annual use records, a short recent-flavor history, a persisted queue of at most one further yearly choice, immutable run seed, and persisted domain RNG streams.
- `LifeSimulator`: thin orchestrator and sole gameplay mutation boundary. `execute(ActionRequest)` accepts registered actions, authored contextual actions, and typed domain commands; `execute(ActionID)` forwards through it for existing callers. It publishes the result synchronously and queues persistence after commit.
- `ActionOutcome`: one result contract for headline, direct deltas and impacts, severity, flavor, and optional follow-up choices. `ActionCadenceSystem` owns each registered action's annual use window and repeat outcome band.
- Sovereign systems (return deltas / outcomes; simulator sequences them):
  - `EffectResolutionSystem` — deterministic declarative effect rolls, diminishing returns, and state application
  - `EducationSystem` — high-school commitments, Grades/Belonging/Future, school choice consequences, and graduation paths
  - `ProgressionSystem` — life-stage transitions, postsecondary exit, retirement, and unemployment
  - `FinanceSystem` — policy-backed annual accounting, taxes, retirement, unsecured obligations, survivable hardship and debt relief
  - `HealthSystem` — yearly drift, health recovery
  - `MortalitySystem` — telegraphed late-life pressure, seeded natural death, max age, and death prose
  - `SocialReactivitySystem` — partner + lightweight NPCs
  - `PersonalitySystem` — shared five-axis player/NPC identity, readable paired flags, accumulated impulses, and bounded yearly development
  - `LifeGenerationSystem` — deterministic Random and Custom previews committed by their displayed seed
  - `InfluenceSystem` — instant choice-ledger pulse, yearly close, and focus summary
  - `InstantNarrativeSystem` / `NarrativeEventSystem` — immediate feedback and seeded yearly storylet selection/flavor
- `SystemRegistry`: state-contingent execution for both yearly and instant paths. Progression, finance, health, and influence are core yearly systems; mortality and partner-year processing hibernate until relevant. Background NPCs never wake that yearly phase and resolve lazily only for matching actions/events. Instant actions always wake effects, personality, and narrative, then wake progression, influence, social, and recovery only when action metadata or state requires them.
- `YearContext` / `DomainConsequence`: immutable yearly context and typed cross-domain hand-offs. A source system emits a consequence; the receiving domain reads its pressure and remains the only owner allowed to mutate its state.
- `LifeThreadSystem`: persists at most three highest-impact consequences, deduplicates recurring pressure, supports explicit stabilization, and expires threads without processing an unbounded history.
- `DomainActionRegistry` / `LifeEventRegistry`: indexed content registries. Views never calculate effects or eligibility. Chapter-irrelevant actions hibernate off the visible action surface.
- `NarrativeVibeResolver`: derives grounded/driven/connected/strained/crisis tone from live state. Narrative systems consume it; the simulator does not compose domain prose.
- `LifePersistence`: validated local JSON (v48), atomic writes, legacy-safe. v47 action-use ages migrate to one use in that age; flavor and yearly choice queues start empty. Migration preserves the run seed and existing random-stream positions. Rapid commits coalesce to at most one in-flight write plus the newest queued snapshot.
- Automatic persistence is a store capability. Production stores retain queued commits; pure deterministic probes may decline automatic writes while explicit lifecycle saves remain functional.
- `YearSummarySystem`: distills already-resolved domain outcomes into typed importance, semantic deltas, developments, world news, stage transitions, and mortality warnings. This is presentation composition, not gameplay mutation; save v32 preserves it for exact relaunch.

## Unified life differentiation

- `PersonalityProfile` is the shared human model for player, partner, friend, teacher, and boss. Relationship bond, resentment, rapport, importance, stance, cooldown memory, and interaction history remain Social-domain state.
- Contextual NPCs split durable Bond from present rapport. Each has two to four compatible stable character tags, one or two private goals, connection history, bounded observation evidence, temporary circumstances, and a compressed independent life. Traits and tags become readable only after repeated or strongly revealing behavior; goals remain simulation state rather than player-facing meters. Active and pivotal people advance yearly; dormant people catch up deterministically only when reactivated.
- Strong flags activate outside a neutral 39…61 band and use hysteresis after activation, so labels neither invent a tendency at 50 nor flicker near a threshold. Compound signatures such as Methodical Builder and Quiet Anchor give recurring combinations a playable identity without adding another mutable state domain.
- `SimulationSignalSnapshot` is the read-only bridge used by generic reaction predicates and bundled events. Content predicates can combine personality, stable tags, circumstances, goals, current connections, remembered actions, independent-life chapters, bond, rapport, and time since contact without letting content mutate domains directly.
- Sovereign domains emit typed `LifeSignal` facts for promotion, loss, crisis, graduation, household change, foreclosure, public success, and recovery. The Social domain interprets at most the most important signal for each relevant person, producing different relationship responses from the same life event without Finance, Career, Health, Education, or Family mutating NPC state.
- `PersonalityEvents.json` is the validated shipped content pack. Its twelve initial moments combine identity signatures, NPC roles, relationship state, talents, and world conditions. Unknown enums, duplicate IDs, bad ranges, contradictory flags, unreachable thresholds, malformed headline/impact data, and choice counts above three are rejected before registration.
- Randomness is split into persisted generation, action, career, finance, family, health/mortality, personality, social/NPC, event, narrative, economy, and public-health lanes. NPC streams derive from the run seed plus stable role/identity, so inspecting one person cannot reorder another domain.
- AI is not part of the runtime or build. Authored or AI-assisted drafts become ordinary reviewed JSON in the repository before shipping.

## Life arc (universal loop)

```
Create → High School (14–17) → Launch (18–24) → Build (25–44) → Pressure (45–64) → Legacy (65+)
      → mortality / recovery / max age → Life Review → New Life
```

Stage transitions are headline-first events. Irreversible registered actions remain once per age; routine actions use a finite annual repeat window and income actions have a shorter capped window. A yearly tick may produce no choice, one choice, or two sequential choices before one recap.

## Player shell (Codex Glance + Thumb)

1. Stat Island — Happy, Health, Smart, Looks, Rep, Cash + stage + mortality
2. Stage strip + **What Matters** (tappable → switches domain and runs suggested instant)
3. Recovery card with **Stabilize** primary CTA (thumb-reachable)
4. Domain tabs (School → **Skills** after leaving education); Health cross-cutting
5. Pressures + read-only row of at most three contextual suggestions + 2-column static action grid; a selected person can focus relevant Love actions
6. Age Up (thumb zone) + up to two centered yearly choices + one centered recap
7. Menu: Journal / New Life; terminal review is the end payoff

## Chapter content

- Stage-weighted `LifeEventRegistry` beats (Launch / Build / Pressure / Legacy) with concrete second-person Voice.
- High school runs as a four-year identity chapter with one yearly commitment, persistent teacher/friend contacts, and state-derived graduation outcomes.
- `EchoFlavorResolver` prepends recent focus memory to yearly events; state-derived vibe selects a seed-stable, state-specific line without advancing gameplay RNG.
- Cross-domain storylets surface collisions between work/home, money/trust, overtime/health, and career isolation/friendship while keeping two-choice interaction density.
- Persisted six-beat event memory prevents immediate storylet repeats and down-weights recently seen content.
- Post-school skills instants: Network, Side hustle, Skill course (same School domain, left-school gate).
- Career class is first-class: Normal careers retain the broad lightweight catalog; Part-time trades income/progression for life capacity; Special careers require talent or an exceptional record and carry momentum/variance; Diamond careers require a proven Special peak, senior standing, reputation, and capital before institution-scale leverage becomes available.

## Instant vs Yearly

- Instant: effect processor → active social reaction → influence/progression/recovery hooks → narrative processor over the final state → synchronous outcome
- Yearly: progression → finance → health → active mortality → core influence close → active social → prioritized event → optional compatible queued event → one recap
- The flavor composer draws only from the persisted narrative stream, suppresses recently used variants, and never changes gameplay streams. The second yearly choice is revalidated after the first resolves. Unresolved choices survive relaunch.
- Gameplay outcomes and choices use a compact centered popup; the full Life Review remains the end-of-run surface.
- Mutation-scoped normalization keeps each instant/domain processor responsible for only the state it changes. The yearly orchestration boundary performs the single whole-state clamp after domain results are applied.

## Continuity contract

- Career burnout → Health and Relationships: receivers own lost capacity and household strain; boundaries selectively stabilize burnout at a performance cost.
- Debt → Relationships, Assets, and Health: household tension, housing recovery, and wellbeing respond without Finance mutating those states.
- Illness → Career and Family: low capacity constrains work and adds care load; professional care selectively stabilizes relevant health-targeted pressure.
- Caregiving → Health, Career, and Finance: sustained family load wears down capacity and margin until its pressure eases.
- Property delinquency → Finance and felony → Career, Finance, and Relationships: asset/legal systems describe consequences; receivers own the resulting mutation.
- World → Career, Housing, and healthcare access: immutable policy modifiers shape receivers without hard-coded cross-domain mutation.
- The dashboard shows active threads in one compact card between What Matters and the current domain surface.
- The dashboard's Life Right Now card ranks three read-only domain signals for a two-second audit. Defining milestones persist outside the 40-entry journal cap as the character's biography.

## Privacy

All life data stays in the app container. No network, analytics, or cloud.
