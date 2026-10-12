# Instant actions domain inventory

**Status:** Core complete; Founder E1 in progress  
**Date:** July 11, 2026

All player actions must flow through the existing registry and simulator/reaction boundary. New actions require a title, requirement, preview copy, effect/result, narrative flavor, and deterministic seeded behavior.

## Occupation and special careers

- Athlete: mature reference path where present in the active implementation.
- Founder E1: `closeMajorDeal`, `aggressiveExpansion`, `keyHire`, `cultureReset`, `mediaSpotlight`, and `pivotBusiness` are the planned first slice.

Founder actions must expose meaningful trade-offs across execution, team health, mental load, cash, momentum, and family consequences. They must not mutate state from the view.

## Existing primary domains

- School
- Cash
- Love
- Play
- Health as a cross-cutting action surface

## Core registry acceptance

- [x] Every `ActionID` has exactly one registry entry.
- [x] Every core action has requirements, preview metadata, effects, immediate narrative, and a micro-beat.
- [x] Every core action executes in a valid state fixture and returns an immediate `ActionOutcome`.
- [x] Fixed seed + fixed state + fixed action produces the same state and outcome.
- [x] ID/domain lookup is pre-indexed; views do not scan or calculate action effects.
- [x] Mutually exclusive stage/school actions hibernate off the visible UI surface.
- [x] Persistence runs outside the tap-to-result path and lifecycle flushes preserve newest-state ordering.

## Founder E1 acceptance checklist

- [ ] Every Founder action is registry-backed and requirement-gated.
- [ ] Every action produces a deterministic result for a fixed seed.
- [ ] Instant reactions cover morale, investor attention, mental load, or family ripple where applicable.
- [ ] Momentum modifies outcomes without bypassing requirements.
- [ ] Occupation UI exposes only read-only cached state/results.
- [ ] Dashboard and Debug console replay the same seeded outcome/history.
