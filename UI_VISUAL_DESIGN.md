# OneLife - UI Visual Design & Popup Polish Spec

**Date:** June 09, 2026  
**Status:** Proposed Incremental Polish (Layout Preserved)  
**Goal:** Give the popups, cards, and overall surface a stronger early-2010s Wii-era soft game feel while keeping the exact current layout, hierarchy, and all Codex principles intact. Dark mode is a true warm inverse of light mode — same friendly rounded game language, just dimmed.

## Core Visual Direction
We are **not** changing the functional layout you like (stat island top, domain tabs bottom, central AGE UP FAB, 2-col instant grids, momentum strip, floating deltas, long-press previews, etc.). This is a surface polish pass focused on warmth, friendliness, and "this is a game" feeling.

### Light Mode — Warm Cream Game Soft
- Background: Soft warm cream / off-white (#F8F5ED range). Clean but never cold or sterile.
- Cards & Popups: **Liquid glass** treatment — translucent material with subtle blur, soft inner highlight/gradient, large rounded corners (24pt+ for friendly Nintendo-like feel), gentle warm-tinted drop shadows for depth.
- Overall vibe: Early Wii menu / Wii Sports friendliness — rounded forms, warm color temperature, soft playful energy without cluttering the Glance Rule.

### Dark Mode — True Warm Inverse (Updated Direction)
- Background: Deep warm charcoal / soft dark taupe with cream undertone (#2A2721 or #1E1B17 range). Warm black — never cold gray or pure black. Feels like the same game at night.
- Cards & Popups: Darker liquid glass (regular/thick material in dark appearance) with subtle warm inner highlight, same large rounded corners, soft warm-tinted shadows (not harsh). The glass effect stays but reads as "dimmed friendly game card".
- Accents & Highlights: Inverted but still warm/soft from the light palette (mint deepens to forest-teal, coral warms to terracotta, lavender stays soft). Positive elements still pop with friendly saturation; nothing goes neon or cyber.
- Result: Dark mode feels like the exact same visual language — just the lights turned down with warm tones preserved. No "different game" split.

This inverse approach keeps visual coherence and the early-Wii soft game soul across both modes. No purple-green shift.

## What Stays Exactly the Same
- Current layout and information hierarchy (you already like it).
- All Codex IV rules: Glance Rule (2-second audit), Thumb Zone priority, Progressive Disclosure.
- Existing components: stat island, momentum strip, floating deltas, pressure chips, long-press preview behavior, AGE UP FAB.
- One-handed ergonomics and playability.
- All mechanical systems and D4 / Fame Web / Family depth.

## Focus Area: Popups, Sheets & Result Modals
These are the main elements that currently feel more "app" than "game". Goal: Every modal or result screen should feel like a deliberate, friendly game moment — rewarding to open, clear to read, warm in tone.

### Popup Design Principles (Apply to All Modals)
1. **Liquid Glass Cards**: Large corner radius (22–28pt). Use `.background(.ultraThinMaterial)` (light) or equivalent dark material + subtle warm border/highlight. Soft outer shadow with warm color tint.
2. **Warm Color Temperature Everywhere**: Even in dark mode the undertones stay warm. Success uses soft mint/forest-teal pop. Setbacks use warmer desaturated tones (never harsh red walls).
3. **Icon + Headline First** (Codex VI + VIII): Big friendly icon (SF Symbol or custom, rounded/soft treatment). Short 5–8 word headline. Then 1–3 soft delta pills with icons. One short second-person present-tense narrative line.
4. **Feedback That Feels Game-Like**:
   - Positive/Success: Warm inner glow or soft gradient highlight, gentle spring scale-up on appear, positive haptic.
   - Setback: Softer desaturated glass treatment but still rounded, readable, and recoverable-feeling.
   - Neutral/Info: Clean glass with gentle accent underline.
5. **Animations**: Spring-based entrance (scale 0.96 → 1.0 + opacity). Dismiss with soft settle. Delta numbers can have a gentle count-up or pop. Keep cheap and performant (no heavy particle systems on every tap).
6. **Thumb Zone & Accessibility**: Primary action button ("Continue", "Keep Going", "Got It") large, bottom-centered or natural thumb reach, with soft press scale + haptic. High contrast on glass. VoiceOver labels preserved/enhanced.
7. **Long-Press Preview Sheets**: Already strong affordance. Add subtle pulsing warm glass-edge highlight on hold to make the preview feel alive and game-ready.

### Specific Popup Treatments
- **Instant Action Result + Autonomous Reaction Modals** (most common): Medium glass card. Icon cluster + domain deltas in soft pills. Short "The world reacted..." voice line. Auto-dismiss option on simple actions or single "Got it" button.
- **Year Summary / Age Up Review**: Larger full-width friendly glass sheet. Prominent soft "Stance & Shape" block (from recent P work) with rounded chips. Bullet deltas. One flavorful "Because you focused on X..." sentence. Big warm "Continue" button in thumb zone.
- **Action Preview / Hold-to-See Sheets**: Frosted glass, clear "This will..." language. Domain color accent on edge. D4 callout ("Shapes your life (driven current) + legacy echoes") in friendly tone.
- **Adult Child / Legacy Story Modals**: Warm narrative glass treatment. Subtle outcome-based tint (pride = soft warm gold highlight, struggle = softer warm desaturated) but always rounded and game-like. Text-primary for now.
- **First-Time Coach / Resilience / Mode Sheets**: Subtle persistent or one-time glass coach cards with the same warm liquid treatment.

## Palette Starting Points (for Assets.xcassets)
**Light Mode**
- Background: #F8F5ED (warm cream)
- Glass Card: ultraThinMaterial + warm overlay + soft border #E8DFD0
- Positive Accent: Soft mint #6BCB9E or warm coral #E07A5F
- Success Delta Pill: Mint fill, high-contrast text
- Setback: Warm terracotta / desaturated coral
- Primary Text: Warm dark gray #3D3A36

**Dark Mode (Warm Inverse)**
- Background: #2A2721 (deep warm charcoal with cream undertone)
- Glass Card: Dark material + subtle warm inner highlight + soft border in warm taupe
- Positive Accent: Deepened forest-teal #2E8B7A or warm terracotta pop
- Success Delta Pill: Teal/forest fill with warm off-white text
- Setback: Softer warm desaturated tones
- Primary Text: Warm off-white with cream undertone

These values keep high contrast for the Glance Rule while preserving the soft friendly game temperature in both modes.

## Implementation Approach (Low Risk, High Feel)
- Create small reusable modifiers/views: `GlassCardStyle`, `ResultModal`, `WarmShadow` etc. in a dedicated UI helper so changes stay centralized.
- Wrap existing views (year summary, action result presenters, preview sheets) with the new treatment — do not rewrite layout logic.
- Update color assets for light/dark appearances.
- Pair with existing haptics and AppFeedback system.
- Test on device for material performance on long saves (80+ years, multiple adult children). Fall back gracefully if needed.
- Every change must still pass the "still feels good with one hand" and 2-second glance tests.

## Success Metrics
- Popups and cards feel like intentional game moments (players notice the warmth and friendliness without being told).
- Dark mode feels like the same game with the lights dimmed — warm, rounded, game-y — not a separate aesthetic.
- No regression on discoverability, thumb ergonomics, information hierarchy, or performance.
- The overall surface now matches the mechanical and narrative depth you've built (D4 life-shape, Fame Web, Family outcomes, instant layer).

## Next Steps
This spec is ready to drive focused implementation sessions. It directly upgrades the popup experience you flagged while keeping everything else you like about the current game.

If you want visual mockups right now (2–3 quick generated images of a year-summary popup and an instant-result popup in both light cream glass and warm dark inverse glass), say so and I’ll generate them to lock the exact look before any SwiftUI work.

Otherwise we can:
- Refine any numbers or wording in this .md
- Turn this into a short "Visual Polish Phase V1" block to drop into the main IMPLEMENTATION_PLAN.md
- Start identifying the exact files/components to touch first (ContentView summary sections, result presentation logic, etc.)

Just tell me how you want to proceed. This inverse warm-dark direction is cleaner and more consistent — good call. The game will feel like one cohesive early-Wii-inspired life sim in both modes.