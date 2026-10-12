# OneLife — Known Issues

Live bug and edge-case list. Update after every playtest session and P5 sub-phase.

**Priority:** P0 = ship blocker · P1 = should fix before launch · P2 = post-launch · P3 = nice-to-have

---

## P0 — Ship Blockers

*None filed at P5 Cycle 2 kickoff.*

---

## P1 — Launch Should-Fix

| ID | Area | Issue | Status |
|----|------|-------|--------|
| KI-001 | Narrative | Regular 5-voice parity gap | **Fixed** P5-2 — stance/shape voices |
| KI-002 | Narrative | Thin regular End of the Road | **Fixed** P5-2 — shape variants |
| KI-003 | Accessibility | VoiceOver on strip/recognition | **Fixed** P5-2 — labels + hints |
| KI-004 | Accessibility | No high-contrast mode | **Fixed** P5-2 — `highContrast` setting |
| KI-005 | Accessibility | Reduced motion partial | **Improved** — strip + settings copy; full delta audit post-launch |
| KI-006 | Onboarding | No fame threshold hint | **Fixed** P5-4 — fame coach |
| KI-007 | Onboarding | Resilience indicator missed | **Fixed** P5-4 — recovery coach |
| KI-008 | Meta | Weak replay hook | **Improved** — creation echoes + Origin bonuses |
| KI-009 | Content | Mid/late silent repetition | **Improved** — midLateGameFlavor pool |
| KI-010 | Variance | Doping/founder telegraph | **Fixed** P5-3 — threshold warnings |

*Re-file from manual playtest if friction remains.*

---

## P2 — Post-Launch

| ID | Area | Issue | Notes |
|----|------|-------|-------|
| KI-020 | Feature | Entrepreneur/founder path shallower than athlete in moment-to-moment agency | E1 revival queued |
| KI-021 | Feature | Mortality / estate planning absent — late game lacks finality beyond career exit | **Fixed** — final affairs and estate aftermath |
| KI-022 | Health | Health domain feels acute/binary vs chronic conditions | **Fixed** — chronic load feeds prognosis |
| KI-023 | Y3 | Cast strip exists; autonomous toasts / montage not implemented | **Fixed** — chapter toasts and final montage |
| KI-024 | Tests | Legacy test file compile debt unrelated to main target | `OneLifeTests.swift` |
| KI-025 | Career | Diamond tier not first-class (movie producer, coach partially implemented) | CareerTiers plan |

---

## P3 — Nice-to-Have

| ID | Area | Issue |
|----|------|-------|
| KI-030 | Settings | Color-blind accent palette |
| KI-031 | UI | Journal search / filter |
| KI-032 | Meta | Life stats dashboard (shape history teaser) |

---

## Verified Fixed (P5 Foundation)

- Long saves bloated by adult-child stories → pruned in `Persistence` ✅
- Generic game-over text on infamous/broke/childless → context-aware orchestrator texts ✅
- No dossier/stance teaching in first life → coach line extension ✅
- Basic shape strip a11y → labels on life-shape text ✅

---

## Playtest Log

| Date | Session | Result | Notes |
|------|---------|--------|-------|
| 2026-06-29 | Automated P5 matrix | **PASS** | 10/10 `p5PlaytestMatrix_*` tests green |
| — | Manual CEO session | Pending | See manual guide in this file |

---

*When fixing: move row to "Verified Fixed" with date, or delete if obsolete. File new issues from playtests immediately.*
