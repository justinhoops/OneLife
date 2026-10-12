# OneLife — Roadmap Summary (Executive Overview)

**Date:** June 29, 2026  
**Status:** P5 Launch Polish (Cycle 2) — **ship gate complete**; automated playtest + CEO proxy + screenshot capture **PASS**  
**Source of truth for phase detail:** `IMPLEMENTATION_PLAN.md`  
**Design anchor:** `CODEX.md`

---

## Vision

OneLife is a raw, glanceable, thumb-friendly life sim where every year commits with weight, every instant move shapes momentum, and every life ends with emotional payoff strong enough to trigger "one more life." The mechanical core (D1–D4, Fame Web, Family depth, athlete/founder/politics/creator/crime revivals, LifeResilience, frictionless instants) is **done**. What remains is professional polish, content volume, accessibility, edge resilience, and launch assets.

---

## Phase Status at a Glance

| Phase / Track | Status | Notes |
|---------------|--------|-------|
| D1–D4 Domain parity + immersion | ✅ Complete | Stance, life shape, ledger, quiet years, legacy flags |
| Fame Web (F1–F3) | ✅ Complete | Unified cultural fame + notoriety |
| Athlete (S1–S3a) | ✅ Complete | Potential, brand, doping, accolades |
| Politics / Creator / Crime / CE revivals | ✅ Complete | 5-voice literary treatment on specials |
| P1–P4 Playability + balance | ✅ Complete | Discoverability tier 1, fairness nets, visceral yearly |
| P5 Foundation (prior "p5" pass) | ✅ Complete | Edge texts, save prune, basic a11y, coach extension |
| **P5 Launch Polish (Cycle 2)** | 🔄 **Active** | Narrative volume, a11y audit, edges, onboarding, launch assets |
| Y3 (cast toasts / montage) | ⬜ Not started | Post-launch or if time |
| Entrepreneur / Mortality / Chronic Health | ✅ Foundation complete | Mortality now includes prognosis, final affairs, estate friction, and aftermath |
| Career Tiers (Regular / Special / Diamond) | 📋 Planned | Enhancement plan in IMPLEMENTATION_PLAN |

---

## P5 Launch Polish — Five Workstreams

### P5-1 — Narrative & Content Completion
Extend 5-voice treatment to remaining regular archetypes and late-game events. Expand legacy harvest + "End of the Road" with D4/shape/resilience variants and adult-child callbacks. Add 15–25 lightweight storylets/silent notes (era + path + fame + stance aware).

### P5-2 — Accessibility & Inclusivity
Dynamic Type pass, larger tap targets where needed, VoiceOver labels on momentum strip / resilience / fame card, color contrast audit + high-contrast mode, wire reduced-motion and haptic settings through all feedback surfaces.

### P5-3 — Edge-Case & Performance Hardening
Test/fix 80+ year lives, 5+ adult children, max fame/notoriety, extreme resilience modes. Profile save size + snapshot caching. Guardrails/telegraphing for high-variance paths (athlete doping, founder ousters).

### P5-4 — Onboarding & Discoverability
2–3 contextual micro-hints (first fame trigger, first adult child, LifeResilience indicator). Polish Recognition/Fame card and momentum strip affordances.

### P5-5 — Launch Assets & Meta
Update creation screen previews with D4/meta echoes. Marketing screenshots / App Store assets. Final balance/meta tuning for replay hook (stronger next-life starting differences from harvest).

---

## Success Metrics (Launch Gate)

A new player can complete **2–3 satisfying lives** (one normal + one special path) with:

1. **Emotional texture** — endings feel specific to their dossier, shape, stance, and resilience mode.
2. **No major friction** — 2-second glance holds through mid/late game; systems discoverable without a guide.
3. **Clear replay pull** — "Echo from Before" and harvest visibly change the next life's start.
4. **Premium feel** — accessible, performant on long runs, professional microcopy and feedback parity.

---

## Launch Checklist

### Must Ship (P5 Cycle 2)
- [x] P5-1 through P5-5 implementation
- [x] BUILD SUCCEEDED on simulator target
- [x] Automated playtest matrix (10 tests)
- [x] CEO playtest gate (`ceoPlaytestRun*` automated proxy; manual optional)
- [x] App Store screenshot capture (`Scripts/capture_app_store_screenshots.sh`)

### Post-Launch (v1.0+)
- [ ] Y3 cast toasts + montage
- [ ] Entrepreneur/CEO revival (E1+)
- [x] Mortality + estate planning track
- [x] Career Tiers ladder (Regular → Special → Diamond)
- [x] Journal search, life stats dashboard, color-blind palette

## Consequential Life Expansion

Implemented as backward-compatible, hibernating domain systems:

- Mortality prognosis, directives, beneficiaries, funeral choice, estate friction, death cause, and final cast aftermath
- Pooled/hybrid/separate household economics with monthly net, fairness, strain, unpaid labor, and transparency
- Bounded relationship memory with Trust, Strain, Unsaid, decay, and breaking-point consequences
- Stabilized social mobility that preserves origin class and requires sustained movement
- Consequential opportunity windows with narrowing, closure, and credible reopening
- Policy-derived institutional access modifiers owned and interpreted by sovereign domains
- State-driven life chapters, cast toasts, and bounded final montage

---

## Agent Commands

| Command | Workstream |
|---------|------------|
| `start p5` | Full P5 kickoff — read P5_TASKS.md, begin P5-1 |
| `p5-1 narrative` | Narrative & content completion |
| `p5-2 accessibility` | Accessibility & inclusivity pass |
| `p5-3 edges` | Edge-case & performance hardening |
| `p5-4 onboarding` | Onboarding & discoverability |
| `p5-5 launch` | Launch assets & meta tuning |

Session detail lives in `Documentation/AgentWork/P5_TASKS.md`. Audits: `CONTENT_AUDIT.md`, `ACCESSIBILITY_AUDIT.md`, `TEST_RUN_NOTES.md` (create per session).

---

## Documentation Map

| File | Purpose |
|------|---------|
| `CODEX.md` | Design principles — never drift |
| `IMPLEMENTATION_PLAN.md` | Master roadmap + completed blocks |
| `ROADMAP_SUMMARY.md` | This file — executive view + launch gate |
| `CHANGELOG.md` | Major changes per phase (launch notes source) |
| `KNOWN_ISSUES.md` | Live bug/edge list with priority |
| `AGENTS_INDEX.md` | Agent team + operating rules |
| `QOL_LAUNCH_ROADMAP.md` | QoL feature backlog (Tier 1–3) |
