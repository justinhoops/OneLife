# Essential-Life Expansion

Implemented as five compact slices while keeping the four-tab dashboard and `LifeSimulator` mutation boundary.

## Phase 1 — Career

- Canonical `CareerState` with track, level, performance, security, burnout, tenure, unemployment duration, and last transition.
- Office, trades, care/service, freelance, and undecided paths.
- Path choice, job search, pivot, promotion pursuit, skill development, and boundary protection actions.
- Deterministic layoffs and six career/collision storylets.

## Phase 2 — Household

- A household ledger with unsecured debt, retirement, stress, renting, ownership, mortgage, equity, maintenance, and delinquency.
- Debt payment, retirement adjustment, home purchase, sale/downsize, and domain-owned budgeting.
- Cash remains canonical on `LifeState`; net worth is derived.
- Six household/collision storylets.

## Phase 3 — Partner and Family

- Dating, committed, married, separated, and former-partner lifecycle.
- Inclusive family intention and compact child aging, temperament, bond, dependency, residence, and adult outcomes.
- Commitment, marriage, separation, family planning, parenting presence, and caregiving actions.
- Partner and dependent children tick while background contacts remain hibernated.
- Six family/collision storylets.

## Phase 4 — Health

- Canonical physical and mental wellbeing, body load, care access, addiction pressure, and a three-condition cap.
- Therapy/support, condition management, preventive care, and cut-back actions.
- Overall Health is a derived compatibility display for compact-core callers and old saves.
- Condition processing hibernates when no condition or addiction pressure is active.
- Six health/collision storylets.

## Phase 5 — Continuity and Legacy

- Supported, Ordinary, and Precarious contexts plus Driven, Empathetic, and Adaptable traits; every choice has a cost.
- At most three deterministic unresolved `LifeThread` echoes.
- A separate local legacy archive retains the latest three completed-life narratives only. It never grants cash or stats, and abandoned lives are excluded.

## Automated Gate

- 43 synchronous registry actions.
- Migration fixtures cover v3 through v11, including a direct v6 compact save.
- Optimized probe: 360/360 endings, zero replay mismatches, 270/270 policy divergence, peak cash below $10,000.
- Physical-device accessibility, performance, and ten human playtest lives remain release gates rather than automated claims.

## Continuity depth slice

- Typed `DomainConsequence` hand-offs preserve domain sovereignty while allowing multi-year effects.
- `YearContext` exposes world, personality, stage, and active-thread pressure as immutable inputs.
- Life threads now carry source, destination, detail, and resolution state; old thread payloads decode with neutral defaults.
- Budgeting, debt payments, and condition management explicitly stabilize relevant threads.
- The dashboard exposes the three active burdens without adding a new navigation level.
