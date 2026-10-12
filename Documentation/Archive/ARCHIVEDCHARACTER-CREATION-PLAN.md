# Character Creation Overhaul — OneLife

High-leverage replayability work: seed **life gravity** at birth so runs diverge in texture, risk, and payoff from Year 1.

## Pressure assignment: automatic vs player choice

| Path | Pressures | Why |
|------|-----------|-----|
| **Quick Start** | Automatic (weighted) | Fast "what gravity did I get?" — discovery and replay |
| **Templates** | Automatic (fixed per archetype) | Curated fantasy — player picks the *story*, not the wiring |
| **Build Your Origin** | **Player chooses 2–3** | Agency + teaches the gravity mental model; birthplace **suggests** chips you can override |

## Three Creation Paths — all slices complete

| Path | Slice |
|------|-------|
| **Quick Start** | ✅ 1–3 |
| **Templates** | ✅ 1–3 |
| **Build Your Origin** | ✅ 2–3 |

## Slice 3 (shipped)

- **`CharacterCreationPolish.swift`** — shared glass cards, pressure chip tones, region pills, gravity meter
- **Rich gravity summary copy** — headline, forecast line, early-life weight meter, empty-state guidance
- **Accessibility** — VoiceOver labels/hints on hub paths, templates, pressures, regions, reroll, summary
- **Differentiated haptics** — `CreationPathHaptics` (medium for primary paths, light for toggles, success on begin)
- **Visual polish** — template card symbols + scroll-to-select, bouncy path cards, challenge/advantage chip colors

## Architecture

- `OriginSystem.makePreview(customPressures:)` — custom wiring
- `LifeGravityCatalog` — selection rules, summary copy, guardrails
- `CharacterCreationDraft` → `commitCharacterCreation(from:)` — single commit funnel

## Tests

- `lifeGravitySummaryRichCopyWhenComplete`
- `customCreationPressuresWireIntoPreviewState`
- `savedCustomOriginTemplateRoundTrips`
