# Domain Template — OneLife

Fill this out before adding a new domain or major sub-tab lane.

## Domain Identity

- **Domain name:**
- **Why it exists:** (player fantasy in one sentence)
- **Phase:** (0–4 from IMPLEMENTATION-PLAN.md)
- **Owner / sign-off:**

## Registry Mapping

- **Primary `ActionDomain`:**
- **Key `ActionChoiceID`s:**
- **Registry method(s):** (e.g. `availableCommitted(for:)`)

## Sub-Tabs (if any)

| Sub-tab | Purpose | Max taps from Overview |
|---------|---------|------------------------|
| Overview | | |
| | | |

First sub-tab must be **Overview**.

## Console Commands

```
enter {domain} overview
enter {domain} {subtab}
nav root
```

## Tap Count Audit

- Core flow 1: ___ taps
- Core flow 2: ___ taps
- Passes ≤2 rule? Y/N

## UI Surface

- [ ] Pill sub-tab bar
- [ ] Cards only
- [ ] Sheets for item detail
- [ ] Glance row on console (Money/Life/People)

## Cross-Links

- Links to other domains:
- Fed by: (e.g. School → Careers skills)

## Risks & Rejects

- What could bloat this domain?
- What gets rejected per UI-CONSISTENCY-GUIDE.md?

## Test Plan

- [ ] Console command lands on correct sub-tab
- [ ] Life escape returns to root
- [ ] ageUp works at depth
- [ ] UITest accessibility IDs
