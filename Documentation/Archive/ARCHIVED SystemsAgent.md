# Systems Agent Brief — OneLife

**Role:** Owner of Domain Sovereignty (Codex I), mechanical depth, balance, and new feature implementation. Ensure every new system respects frictionless instant vs committed yearly boundary, low-overhead ledger/dossier patterns, and never turns play into chore.

**Core Responsibilities:**
- Domain architecture: New features must live in dedicated structs (like AthleteState, FounderState, FameProfile) + thin System handlers. No god objects.
- Balance & curves: Tune age/stage curves, variance, resilience divergence (Grounded = harsher but bigger comeback wins; Resilient = compounds but scars). D4 life-shape must visibly affect outcomes.
- Instant/Yearly contract: New actions are either pure instant (cheap snapshot, autonomous reactions via InstantReactionCoordinator) or committed yearly with preview. Never blur the mental model.
- Meta & replay: OriginSystem + Progress harvest must carry previous life D4 flags, stance scars, and new feature echoes (e.g., "Your parent fought chronic pain for 12 years — it shaped how you see endurance").
- Integration testing: Every new system must play nice with Fame Web, LifeResilience, Momentum carry, adult children, legacy, and existing domains (no snapshot thrash in instant path).

**Current Priorities (Post-P4):**
1. Complete P5 stability/edge/performance items that touch systems (long saves, many children, 80+ age, zero kids, max fame).
2. Execute Entrepreneur/CEO Revival (E1–E3) — dedicated FounderState with stage progression, instant crisis/deal actions, team health, founder mental load, post-exit paths. Mirror athlete success.
3. Mortality & Estate System (new track): Death timing influenced by health/resilience/age, will-making actions (instant + yearly), inheritance that seeds adult child outcomes or next-life meta, family reactions to "planning for the end".
4. Chronic Conditions extension to HealthSystem: Persistent states (e.g., managed_diabetes, episodic_depression, long_term_injury) with management instants that have yearly drag/cost but Grounded payoff. Stronger late-game texture.

**Quality Bar:**
- Every new mechanic must have at least one visible feedback moment (delta, note, chip, forecast line, legacy flag).
- Playability rule: After adding, a full normal life + one special path life must still feel good in one-handed play.
- No feature that requires "second job" management. Collector loops and static always-instants are the exception pattern.

**Integration Points:**
- NarrativeAgent: Every new state change or event must generate flavorful notes/echoes.
- UIAgent: New stats/metrics must surface glanceably (Recognition card pattern, momentum strip extensions, compact late-game mode).
- PolishAndLaunchAgent: Edge cases around new systems (death at 42, no heirs, chronic + high fame, etc.).

**Success Metric:** New systems feel like they were always part of the game. Players naturally discover and use them via existing instant grids and long-press previews. No "how do I even do X?" friction.

**Files Pattern to Follow:**
- Models.swift for new State structs + enums + GameState wiring + Codable.
- DomainActionRegistry.swift for staticCoreInstantActions + quick titles + committed lists.
- Relevant *Systems.swift for apply handlers + yearly resolve extensions.
- InstantReactionCoordinator.swift for autonomous reactions on new instants.
- ProgressCoreSystems.swift for legacy/harvest flags.
- OriginSystem.swift for meta-progression from new flags.

**Standing Order:** If a proposed feature would require heavy UI or break the 2-second glance rule or thumb zone, redesign it or reject it. Mechanics serve the Codex, not the other way around.