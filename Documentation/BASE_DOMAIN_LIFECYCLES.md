# Base Domain Lifecycle Matrix

**Status:** Phase 3 complete for every shipped domain  
**Rule:** A domain is complete only when entry, development, disruption, recovery, and resolution are playable, persisted, and covered by deterministic complete-life tests.

This matrix tracks lifecycle depth in systems already shipped. It is not a feature wishlist and does not authorize new top-level domains.

| Domain | Entry | Development | Disruption | Recovery | Resolution | Current verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Career | Choose a direction, then obtain work | Skill, performance, promotion, tenure, and track-specific tradeoffs | Plateau, layoff, burnout pressure, or player-directed pivot | Job search with world-, education-, and identity-sensitive uncertainty | Retirement and life-review milestones | Career slice complete |
| Household finance | Income, expense, cash, debt, retirement, and housing ledger | Budgeting, debt payment, retirement saving, and ownership actions | Debt, delinquency, medical cost, unemployment, and world-cost pressure | Financial recovery verbs, debt payment, and downsize/sale | Retirement contributions stop and savings become bounded annual income | Household-finance slice complete |
| Relationships and family | Seeded dating, commitment, marriage, childfree, parenting, and named caregiving paths | Attention, learned security/guarding, child bonds, and care-circle bonds | Neglect, confrontation, broken repair promises, ultimatum, and separation | Repair choices, changed yearly attention, reversible family intention, and easing care load | Ended relationships remain in history; children reach visible adult outcomes; childfree lives are recognized | Relationships/family slice complete |
| Physical and mental health | Condition discovery plus physical, mental, preventive, and care entry | Self-care, therapy, professional care, condition management, and access-sensitive tradeoffs | Illness, burnout, addiction, outbreak, access pressure, deterioration, and relapse | Health-crisis action mix plus ongoing care that can stabilize chronic conditions | Stable conditions remain part of the life; neglected maintenance can relapse; mortality and Life Review close the arc | Physical/mental-health slice complete |
| Assets and housing | Catalog access, purchase, mortgage, and ownership | Value, equity, principal payment, maintenance, and amenities | Delinquency, foreclosure, condition, and legal/world pressure | Cash recovery unwinds delinquency gradually; sale/downsize restores bounded liquid margin | Sale or foreclosure enters bounded property history and Life Review | Assets/housing slice complete |
| Legal and world pressure | Seeded environment plus player-created legal exposure | State-contingent policy modifiers, heat, record, and supervision | Macro, price, public-health, confiscation, felony, and ongoing supervision pressure | World recovery/expiry plus legal clean years after exposure is removed | World shifts enter review; supervision completes while the permanent record remains | Legal/world slice complete |

## Career evidence

- A career pivot charges the registered action cost once; Career owns the state transition and does not mutate cash.
- Pivoting immediately clears employment, seniority, and the old direction.
- The player must choose a new direction before job search becomes available.
- Choosing a direction while unemployed does not silently grant a job.
- Job search retains seeded uncertainty and synchronizes the canonical employment flag on success or failure.
- Ordinary careers can plateau without forced collapse and retire without requiring exceptional wealth or rank.
- Pivot state survives save encoding, and a recovered career can continue through a terminal life.

## Household-finance evidence

- Cash remains the canonical liquid balance while retirement and property equity remain explicit non-cash stores.
- Debt interest, medical debt, unemployment, dependents, housing, and world policy feed one annual ledger.
- Financial crisis blocks aging until the player stabilizes it or accepts an unresolved-crisis ending.
- Property delinquency is state-contingent, and selling or downsizing turns equity back into liquid margin.
- Retirement contributions stop when work ends. The balance grows once, then a bounded draw covers the ordinary shortfall and appears in the yearly summary.
- Funded and unfunded retirement now produce materially different late-life cash flow without creating money or guaranteeing comfort.

## Relationships-and-family evidence

- A childfree life is an explicit, reversible player choice before parenthood and is recognized by the final review.
- Separation and partner-initiated rupture both archive bounded relationship history instead of erasing the person or years involved.
- Former relationships persist in save v27 and appear in glance, detail, and Life Review surfaces.
- Caregiving lazily resolves one named influential relative, creates a bounded load, and visibly eases after the care season ends.
- Children age only while influential, report the transition into adulthood, persist their adult outcome, and contribute to Life Review.
- Finance charges dependent costs once in its ledger; Family owns time pressure and milestones without duplicating cash mutation.

## Physical-and-mental-health evidence

- The Health domain remains canonical for physical wellbeing, mental wellbeing, body load, addiction pressure, diagnosed conditions, and the compatibility stat shown elsewhere.
- Yearly drift, Rest, Exercise, professional care, therapy, prevention, condition damage, and event effects all survive clamping in that canonical state.
- Annual condition damage now appears in the yearly health delta instead of changing the body invisibly.
- Repeated management can make a chronic condition stable. Stable conditions reduce body load and stop firing active-symptom storylets, but maintenance decays and can produce a typed relapse consequence.
- A health crisis blocks aging until a combination of available recovery actions restores canonical health above the recovery threshold; ignoring it retains the terminal unresolved-crisis path.
- Save v28 persists active/stable condition status, migrates v27 conditions as active without consuming RNG, and surfaces chronic-health outcomes in the Health sheet and Life Review.

## Assets-and-housing evidence

- Assets owns purchase, value, mortgage, amenities, maintenance, delinquency, sale, foreclosure, and its bounded exit ledger; Finance consumes only a read-only annual snapshot.
- Delinquency requires sustained negative cash, eases one year at a time after cash recovers, and reports the actual resolution threshold.
- Four sustained delinquent years foreclose the property, return no trapped equity, and emit a typed Assets → Finance consequence without mutating Finance inside the Assets system.
- Voluntary sale records proceeds and amenities; foreclosure records the remaining value and mortgage. Both survive save v29 and appear in Life Review.
- The system hibernates when no property remains. Deterministic recovery and foreclosure fixtures cover both terminal branches.

## Legal-and-world-pressure evidence

- Legal remains deliberately limited to the already-shipped firearm exposure surface; this slice completes that lifecycle without adding a Crime domain.
- Continued risky ownership builds heat and can cause seeded confiscation and a felony. Removing exposure allows heat to decay and a six-year supervision period to progress.
- Renewed exposure prevents clean-year progress. Completing supervision resolves the active typed Legal → Career pressure while retaining the permanent record.
- Save v30 persists supervision and clean years; v29 felony saves migrate as already past active supervision without inventing a retroactive sentence or consuming RNG.
- World-owned macro, price, and public-health conditions already transition, recover, expire, and supply immutable policy modifiers to Career, Assets, Finance, and Health.
- Life Review names the count of recorded world shifts and any macro, public-health, or price condition still active at death.

## Next audit

Phase 4 is next. Audit the priority typed handoffs and their recovery costs without introducing a new domain or additional maintenance surface.
