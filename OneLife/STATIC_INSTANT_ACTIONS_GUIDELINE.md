# OneLife — Static Instant Actions Guideline (v2)

**Goal:** BitLife-style "Right Now" density on every main tab, upgraded with OneLife-specific depth so taps feel personal—not generic clones.

**v2 changes:** Full static cores per domain, `StaticInstantActionFlavor` helpers (dossier, LifeResilience, life-shape/stance, fame/notoriety, adult-child echoes), ledger `instantActionPulse` on every core action, instant-first UI (year-plan collapsed or removed on main tabs).

---

## Core Principles

- **Static & Always Available** — 6–7 actions in each domain's Right Now grid; ALWAYS badge + HOLD TO PREVIEW.
- **Instant Feedback** — Stat deltas, DomainNote, momentum strip, optional autonomous reaction.
- **OneLife Soul** — Every handler consults dossier aptitudes, Grounded/Resilient mode, stance/life-shape residue, fame gravity, and (where relevant) adult-child `developmentNotes`.
- **Cheap Path** — Tap → apply → enrich → momentum. No year-plan commitment required.
- **Ledger Pulses** — `StaticInstantActionFlavor.publishPulse` so SilentYearEngine, ContinuityThreadEngine, and autonomy systems react in quiet years.

---

## Static Cores (v2)

### Home / Identity (7)
| ID | Grid | OneLife depth |
|----|------|---------------|
| `morningReflection` | Morning Reflect | Analytical dossier → sharper insight note |
| `reconcileWithPast` | Reconcile | Stronger with stance streak residue |
| `protectYourEnergy` | Protect Energy | Grounded → bigger relief + pressure drop |
| `tryNewPersona` | New Persona | High fame → riskier shift note |
| `processCrisis` | Process Crisis | Grounded = fight-back win; Resilient = scar note |
| `journalTheShape` | Journal | Publishes life-shape residue to ledger |
| `quietTheNoise` | Quiet Noise | RumorHeat + notoriety counter for loud lives |

*Extras (not core):* `publicReset`, `therapySession` — still in catalog, available via promotions/extras.

### Body / Health (6)
| ID | Grid | OneLife depth |
|----|------|---------------|
| `bodyConditioning` | Condition | Physical dossier + athlete potential nudge |
| `recurringTherapy` | Therapy | Social/analytical dossier; fame public-pressure note |
| `manageMeds` | Meds | Grounded → long-term stability flavor |
| `seeDoctor` | Doctor | Grounded fight-back recovery; Resilient patch-and-move |
| `sleepLikeItMatters` | Sleep Hard | Strong mental + next-year pressure relief via ledger |
| `coldExposureDrill` | Cold Drill | Physical dossier + driven-current synergy |

### People / Relationships (6–7)
| ID | Grid | OneLife depth |
|----|------|---------------|
| `deepenSpecificBond` | Deepen | Social dossier flavor |
| `fuelRivalry` | Fuel Rivalry | Fame/notoriety interaction |
| `splitReputation` | Split Rep | High-fame lives get easier performance split |
| `realConversation` | Real Talk | Adult-child developmentNote; Grounded warmth |
| `setBoundary` | Boundary | Grounded vs Resilient relief notes |
| `networkWithoutMask` | Unmasked | Notoriety risk on honest networking |
| `checkInOnChild` | Check Kids | *Conditional* — when children exist; seeds developmentNotes |

### Money / Finance (6 core + extras)
| ID | Grid | OneLife depth |
|----|------|---------------|
| `curateCollection` | Curate | Athlete/founder path flavor |
| `hostSignatureEvent` | Host Event | High notoriety risk note |
| `maintainAsset` | Maintain | Prevents decay narrative |
| `negotiateBetterTerms` | Push Terms | Entrepreneurial/analytical boost; founder board tension |
| `quietlyBuildCushion` | Cushion | Index-fund stash; Grounded safety-net flavor |
| `reviewNumbersRuthlessly` | Review #s | pushCareer / driven-current synergy |

*Extras:* `sideGig`, `negotiateBill`, `treatYourself`, debt/housing/investing conditional instants.

### Work / Career — regular (7)
| ID | Grid | OneLife depth |
|----|------|---------------|
| `putYourHeadDown` | Head Down | Driven-current + stance streak in note |
| `protectWorkLifeLine` | Work-Life | Grounded chest-level relief note |
| `network` | Network | (existing career handler) |
| `seekMentor` | Mentor | |
| `documentWins` | Doc Wins | |
| `improveSkill` | Skill Up | |
| `managePolitics` | Politics | |

Special tracks (athlete, founder, creator, politics) keep dedicated static decks.

### Play (5)
| ID | Grid | OneLife depth |
|----|------|---------------|
| `hobbySession` | Hobby | Social dossier belonging note |
| `socialOuting` | Go Out | Fame gravity on phones |
| `creativeOutlet` | Create | Creator audience tick when on track |
| `adventure` | Adventure | Grounded picks survivable chaos; notoriety content risk |
| `relaxRoutine` | Relax | Resilience-scaled mental + burnout relief |

---

## Implementation Pattern

### 1. Models
- `ActionChoiceID` case + `ActionChoiceCatalog` definition (`baseResolutionTier: .instant`)

### 2. Registry (`DomainActionRegistry.swift`)
- Add to `staticCoreInstantActions(for:)`
- Short `quickActionTitle` for 2-col grid
- Conditional extras via `conditionalInstantExtras(for:)` — never replace the static core

### 3. Apply handler
- Route in the correct system file; pass full `GameState` when flavor needs shape/fame/dossier
- Use `StaticInstantActionFlavor` for shared depth
- Always `publishPulse` on static core actions

### 4. InstantReactionCoordinator
- Domain static core set → momentum + domain-specific enrichment (recovery balance for health/play, etc.)

### 5. UI (`LifeConsoleView`)
- `quickActions` = full static core via `availableQuick(for:)`
- Main tabs: **instant-first** — `actions: []` / no year-plan sections on Home, Body, People, Money, Play
- Year-plan remains available on Work/Education and special lanes where committed actions matter

### 6. Tests
- Grid count + key IDs per domain
- At least one orchestrator instant test per domain verifying stat movement + notes

---

## Success Criteria (v2)

- Player can spend 10–15 minutes tapping Right Now actions across tabs without opening Year Plan.
- Notes reference dossier, resilience mode, or life-shape at least some of the time—not every tap, but enough to feel authored.
- Ledger receives pulses from static cores; momentum strip moves on every domain.
- Special career tracks retain their deeper dedicated instants without diluting main-domain cores.

---

## File Map

| Concern | File |
|---------|------|
| Flavor helpers | `Simulation/Systems/StaticInstantActionFlavor.swift` |
| Registry + grids | `DomainActionRegistry.swift` |
| Identity + Play + Career | `Simulation/Systems/EducationCareerSystems.swift` |
| Health + Relationships | `Simulation/Systems/RelationshipFamilyHealthAssetSystems.swift` |
| Finance | `Simulation/Systems/FinanceInvestmentSystems.swift` |
| Momentum / autonomy enrich | `Simulation/Systems/InstantReactionCoordinator.swift` |
| UI grids | `LifeConsoleView.swift` |
