# Session: Founder E1 Foundation Implementation

**Date:** July 11, 2026  
**Status:** In progress  
**Owner:** Systems Agent / COO handoff

## Goal

Deliver E1.1 and E1.2: establish a dedicated Founder state and yearly stage skeleton, then add the first registry-backed instant actions with reaction hooks. Preserve the four-domain scope and existing simulator mutation boundary.

## Tasks

- [ ] Add `FounderState` in the existing special-career model location.
- [ ] Seed Founder state from existing activation inputs.
- [ ] Add a stage-aware yearly resolver skeleton with crisis/pressure/exit hooks.
- [ ] Add the first Founder action IDs and registry catalog entries.
- [ ] Route actions through the existing instant-reaction pipeline.
- [ ] Add autonomous reaction stubs for morale, investor spotlight, mental load, and family ripple.
- [ ] Expose compact Founder metrics in the Occupation dashboard.
- [ ] Add deterministic unit coverage and dashboard/console parity verification.

## Planned actions

`closeMajorDeal`, `aggressiveExpansion`, `keyHire`, `cultureReset`, `mediaSpotlight`, `pivotBusiness`.

## Constraints

- No new simulation domain.
- No view-side eligibility, effect, annual-result, or event logic.
- Reuse existing registries, action cache invalidation, seeded randomness, momentum, Fame, family, D4, and resilience seams where they exist.
- Keep the session temporary until implementation is verified.

## Verification

- [ ] Clean Debug and Release builds.
- [ ] Founder activation shows seeded state and at least one available action.
- [ ] A fixed seed replays identical state/history/outcomes.
- [ ] Founder action results render in the existing compact result surface.
- [ ] 20-year seeded dashboard and console scenarios remain equivalent.

## Completion block

Add the implementation commit/PR reference, tests run, player impact, and remaining follow-up here when all E1.1/E1.2 tasks are complete. Then update [ROADMAP.md](../ROADMAP.md) and [INSTANT_ACTIONS_DOMAIN_INVENTORY.md](../INSTANT_ACTIONS_DOMAIN_INVENTORY.md), and archive this session.
