# INSTANT_ACTIONS_EXPANSION_ROADMAP.md

**Goal:** BitLife-density direct instant actions across every domain, wired to heat/notoriety/fame/ledger reactivity.

---

## Batch 1: Relationships / Love / Family — COMPLETE

See `SESSION_Narrative_Agent_Relationships_Batch1_Flavor.md` + `RelationshipBatch1Systems.swift`.

---

## Batch 2: Crime / Risk Lane — COMPLETE (2026-06-20)

**Goal:** BitLife-style direct crime taps on the Risk — Right Now tray with tier-appropriate density and dark-fame payoff.

**New actions (15):**

| Tier | Actions |
|------|---------|
| Street | `pickpocket`, `porchPirate`, `mischiefNight`, `drugDeal` |
| Organization | `burglary`, `intimidateTarget`, `smuggleGoods`, `startGangWar` |
| Enterprise | `bankRobbery`, `embezzleFunds`, `grandTheftAuto`, `hackSystem`, `bribeOfficial`, `hitmanContract`, `arrangeHit` |

**Engineering:** `CrimeBatch2Systems.swift` — apply + catalog + registry tier gating + ledger pulses + notoriety/fame hooks.

**Registry:** Appended to `crimeInstantCore()` alongside existing CT5 tier toolkits. Street actions also surface when crime lane is active due to cash desperation (`cashOnHand < 600`).

**Tests:** `batchTwoPickpocketActivatesCrimeAndMovesHeat`, `batchTwoDesperateCrimeLaneSurfacesStreetActions`, `batchTwoEnterpriseTierSurfacesHighRiskCrimes`.

---

## Batch 3: Assets / Property / Lifestyle — COMPLETE (2026-07-04)

**Goal:** BitLife-style property and lifestyle taps on Money — Right Now, gated by home ownership, rentals, and wealth/lifestyle margin.

**New actions (14):**

| Tier | Actions |
|------|---------|
| Property | `rentOutRoom`, `listRentalUnit`, `collectRent`, `renovateHome`, `landscapeProperty`, `stageOpenHouse`, `furnishRoom`, `downsizeHome` |
| Lifestyle | `hostHouseParty`, `flauntWealth`, `inviteNeighborsOver`, `hireHousekeeper`, `weekendGetawayHome`, `quietLuxuryFlex` |

**Engineering:** `AssetsBatch3Systems.swift` — catalog + apply + registry gating + finance ledger pulses + era-aware flaunt backlash.

**Registry:** Appended to finance instant core via `AssetsBatch3Systems.registryActions(state:)`. Homeowners get renovate/party/rent-room; rentals unlock collect/list; wealth/lifestyle unlocks flaunt/quiet luxury.

**Instant reactions:** `InstantReactionCoordinator` finance core unions Batch 3; party/flex/renovate emit light autonomous echoes.

**Tests:** `batchThreeRenovateRaisesHomeValue`, `batchThreeHomeownerSurfacesPropertyActions`, `batchThreeFlauntWealthMovesFameOrNotoriety`, `batchThreeCollectRentRequiresRentals`.

**Also live (pre-Batch 3 lifestyle core):** `curateCollection`, `hostSignatureEvent`, `maintainAsset`, `flexLuxuryAsset`, luxury gala set.

---

## Next Steps

1. Sim playtest Batch 3 renovate/party/flaunt balance on Grounded vs Resilient and recession eras.
2. Optional Batch 4: Education / Identity density if still thin in playtests.
