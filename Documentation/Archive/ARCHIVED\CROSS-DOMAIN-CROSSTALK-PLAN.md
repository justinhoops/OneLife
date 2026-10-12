# Cross-Domain Crosstalk Plan

## Goal

Make OneLife feel raw and continuous by letting pressure in one domain create visible, mechanical consequences in adjacent domains without breaking domain sovereignty.

The player should feel: "This happened because the life I built had obligations, people, and weak points."

## Architecture Rule

`GameState` stays the orchestrator and persistence container. It does not calculate crosstalk.

Crosstalk lives in `CrossDomainPressureSystem`:

1. Read a snapshot of relevant domain states.
2. Detect threshold-based pressure patterns.
3. Return `DomainYearResult` effects for target domains.
4. Let existing domain systems apply those effects.

No domain should directly mutate another domain's state.

## First Slice: Work Loss Meets Real Obligations

Trigger when career pressure becomes materially unstable:

- Job loss: employed last year, unemployed this year.
- Income shock: annual income falls below half of last year's income.
- Soft collapse: job security falls below a danger threshold.

Then read obligation exposure:

- Debt payments.
- Mortgage payments.
- High-maintenance luxury or signature assets.
- Partner and dependent children.

Apply consequences:

- Finance: stress rises.
- Health: mental wellness and stress management fall.
- Relationships: partner bond, friend connection, private reputation, and future alignment take a hit.
- Family: at-home child bonds dip when dependents are present.
- Summary: emit a structured spillover signal so yearly recap shows the link.

## Crosstalk Matrix

Career -> Finance / Family / Relationships / Health:
Job loss, toxic workplace, income volatility, schedule pressure.

Finance -> Health / Relationships / Housing:
Debt, negative cash, delinquency risk, unaffordable lifestyle.

Assets -> Finance / Relationships / Legal:
Mortgage drag, high-maintenance assets, illegal assets, distress sales.

Family -> Career / Finance / Health:
Childcare load, pregnancy, postpartum years, care obligations.

Health -> Career / Education / Relationships:
Burnout, depression, chronic illness, untreated conditions.

Legal / Crime -> Career / Family / Finance:
Custody, active case, record pressure, seized assets, reputation damage.

## Design Standard

Every crosstalk result needs three things:

- A mechanical effect.
- A short note in headline-first language.
- A structured spillover signal for the yearly summary.

This keeps the game raw without drowning the player in prose.
