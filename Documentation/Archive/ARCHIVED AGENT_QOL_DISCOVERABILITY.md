# Agent Task File: QoL Discoverability & First-Time Teaching

**Priority:** Tier 1 Critical (Highest leverage for launch)  
**Related Codex:** Glance Rule, Summary-to-Action, Frictionless Immersion, Vibe Layer (Echo + Silence + Mood)  
**Owner:** COO directive — execute in small, verifiable slices. Keep game playable after every edit.  
**Test Protocol:** After changes, create new life → play 10-15 active minutes → verify player can discover previews, understand momentum/stance without help, see resilience flavor.

## Context (From Current State)
Powerful systems exist but lack affordance:
- Long-press previews (already implemented in preview system)
- Momentum strip (domain momentum from instant actions)
- LifeResilience mode (Grounded vs Resilient — affects recovery, spillover, adult child stories)
- D4 stance/life-shape (recentStances, lifeShape derived, affects quiet years, legacy, event weights, family)
- Adult children (AdultChildProfile persistence + stories)

**Pain:** New players experience these but don't know they exist or how to steer them. First 15 minutes feel shallower than the game actually is.

## Deliverables (Prioritized Order)

### 1. Persistent Long-Press Affordances on Action Rows (Quick Win)
**Goal:** Every tappable action (quick grids, committed choices, planner) has subtle, always-visible "hold to preview" signal.

**COMPLETE — 2026-06-20**
- Action trays now separate persistent affordance from first-time teaching: preview-capable rows keep the hand/"Hold" signal visible, while the stronger pulse/footer dismisses after the first successful long-press.
- Quick/right-now, committed/year-plan, family, risk, overflow action sheets, and legacy planner rows all show a compact hold affordance without changing the two-column thumb grid.
- Fixed the crime fame result contract (`fameEffects`) that was blocking the launch-gate build.
- Verified: `xcodebuild -project OneLife.xcodeproj -scheme OneLife -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build` succeeds.

**Tasks:**
- In LifeConsoleView.swift (ActionRow / ActionSelectionModule views): Add small trailing icon (system "hand.tap" or custom "hold" symbol) + micro-text "Hold" or "Preview" in secondary color when not in compact mode.
- On first interaction per session (or per life start): Subtle one-time pulse or border glow on action rows to teach the gesture. Dismiss after first successful long-press.
- Reuse existing long-press gesture recognizer and preview popup logic — just improve visual affordance.
- Integration: Keep 2-col grid thumb targets intact. No text bloat.

**Files:** LifeConsoleView.swift (primary), ContentView.swift (if shared components), AppFeedback.swift (for teaching pulse if haptic).

**Success Signal:** Long-press preview popup appears reliably; new players use it naturally by year 2-3.

### 2. Momentum Strip v3 — Tappable Explanation + Domain Color + Build Hints
**Goal:** The strip is no longer mysterious. Players understand what it does and how to influence it.

**Tasks:**
- Enhance instantMomentumStrip in LifeConsoleView.swift:
  - Domain color coding (Health green, Finance blue, People/Relationships warm, etc. — match existing domain accents).
  - Make the whole strip or individual domain segments tappable → opens lightweight explanation sheet/modal: "Your quick actions build momentum here. High momentum biases next year's events toward this domain and softens pressure."
  - Add short "How to build: X / Y actions" micro-hint per domain when relevant (e.g., "ProtectHealth, Therapy, BodyConditioning build this").
- First-time coach banner (lightweight, dismissible): "Quick actions shape the year ahead — watch the strip grow."
- Persist a short "recent instant momentum" history that survives restart (light, already partially in GameState).

**Files:** LifeConsoleView.swift (strip UI + tap handling + sheet), GameViewModel.swift (computed build hints if needed), InstantReactionCoordinator.swift (if new signals).

**Success Signal:** Player taps strip once, understands the instant → yearly bridge, and can name 1-2 actions that build their current strongest domain.

### 3. LifeResilience Persistent Indicator + Evolving Flavor
**Goal:** Players know which mode they're in and see it affect language/outcomes without needing the creation screen.

**Tasks:**
- Add subtle persistent indicator in header or stat island area (LifeConsoleView.swift): Small icon or short phrase ("Grounded", "Resilient") with color accent. Tap opens short sheet explaining mechanical + narrative difference + "This life feels X because of your choice."
- In journal / forecast / year anticipation text: Inject mode-aware flavor (already some in P5 resilience work — extend to more SilentYearEngine notes, forecast subtitles, adult child milestone stories).
  - Grounded example: "The years of care made this conversation softer." or "You fought back and it showed."
  - Resilient example: "The scars stayed visible, but the speed carried you."
- On mode-relevant events (recovery actions, hard years, adult child outcomes): Stronger narrative differentiation.

**Files:** LifeConsoleView.swift (indicator + sheet), ContentView.swift (forecast/yearSummary injection points), SilentYearEngine.swift, RelationshipFamilyHealthAssetSystems.swift (adult child notes), ProgressCoreSystems.swift (legacy).

**Success Signal:** Player can name their resilience mode by year 5 and sees different language in quiet years vs a different mode life.

### 4. D4 / Stance / Life-Shape First-Life Teaching Moments (Contextual, Not Tutorial)
**Goal:** Players discover that their focus choices (pushCareer, protectHealth, drift, etc.) have visible residue in the world and future.

**Tasks:**
- Add 2-3 lightweight first-life journal entries (seeded in OriginSystem or early ContinuityThreadEngine):
  - After first stance choice or year 2-3: "Your recent focus is already rewriting what the world brings you."
  - After first quiet year with strong recentStances: "The push you chose is coloring this quiet stretch."
  - Shape emergence: "The shape of recent years is still with you. (driven current / loose edges / careful steadiness)"
- Forecast subtitles and year anticipation text: Always surface current lifeShape + dominant stance residue when relevant (e.g., "Your driven current makes opportunities sharper but burnout heavier.").
- Long-press preview append: "Shapes your life (X) + legacy echoes" + "Carries into future focus & quiet years."

**Files:** OriginSystem.swift (early seeding), SilentYearEngine.swift (pickNote D4 extensions), ContinuityThreadEngine.swift (lookbacks), ContentView.swift (forecast + previewAction enhancement), LifeConsoleView.swift (shape in momentum strip — already color reactive post-P2).

**Success Signal:** By year 4-5, player notices quiet years feel different based on what they focused on and can connect it to their stance choices.

### 5. Adult Children First-Appearance Coach + Glance Improvement
**Goal:** When adult children section appears, player immediately understands these are *their* children with long-term outcomes, not new NPCs.

**Tasks:**
- On first render of "Adult Children" section (ContentView.swift or LifeConsoleView family module): Short explanatory banner or line: "These are the same children from earlier years. Their bond, personality, and your investment shaped who they became."
- Enhance adult child glance chips (already in Phase 6 compact work): Icon + name + vibe/status + 1-line recent story teaser. Tap expands to full profile + key stories.
- In year summary when a child emancipates or has milestone: Richer note tying back to player stance/resilience during their childhood.

**Files:** ContentView.swift (family sections + chips + first-appearance logic), RelationshipFamilyHealthAssetSystems.swift (emancipation + milestone notes), LifeConsoleView.swift (glance rendering).

**Success Signal:** Player sees adult children appear and immediately understands the continuity and emotional weight without confusion.

## Integration Rules (Non-Negotiable)
- All teaching is contextual and lightweight — no modal tutorials, no "how to play" screens that break immersion.
- Reuse existing patterns: long-press preview system, AppFeedback, ALWAYS badges, domain color accents, DomainNote style.
- Keep instant path cheap (no heavy snapshot work for hints).
- Every change adds at least one visible feedback moment.
- After slice: Build + sim launch + 15-min play session clean. Game must feel *more* playable.

## Verification Checklist (After Full Slice)
- [ ] Long-press affordance visible and functional on all action types.
- [ ] Momentum strip tappable with clear explanation; player can name build actions.
- [ ] Resilience mode visible in play + language shifts in journal/forecast.
- [ ] D4 stance/shape teaching appears naturally in first life; player connects focus → world reaction.
- [ ] Adult children section has coach text + useful glance chips.
- [ ] No regression in thumb ergonomics, 2-col grids, or existing preview/haptic behavior.
- [ ] New player (simulated) can explain the instant/yearly bridge and why their quiet years feel personal.

## Files to Touch (Summary)
Primary: LifeConsoleView.swift, ContentView.swift  
Secondary: OriginSystem.swift, SilentYearEngine.swift, ContinuityThreadEngine.swift, RelationshipFamilyHealthAssetSystems.swift, ProgressCoreSystems.swift, GameViewModel.swift

**Ready for execution.** When command given, implement in order above, updating this file with COMPLETE blocks per sub-task (like prior D/P phases). Build green after each. Report player impact clearly.

Next agent handoff ready on "qol discoverability" or specific sub-task.
