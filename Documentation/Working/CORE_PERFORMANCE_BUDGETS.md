# Core performance budgets

**Date:** July 17, 2026  
**Scope:** Active compact engine; measured in a Release build

## Player-facing contract

"Instant" means the complete action result is available during the same main-thread turn and is visible within one 60 Hz frame. No file read, file write, network request, deferred domain resolver, or inactive-system work may sit between the tap and `ActionOutcome`.

Zero compute time is not physically measurable. The release contract is therefore one-frame feedback with bounded work and no blocking I/O.

## Budgets

| Path | Target (p95) | Hard ceiling | Measurement |
| --- | ---: | ---: | --- |
| Registered instant action → complete outcome | ≤ 8 ms | 16.7 ms | `Instant Action` Points of Interest interval |
| Common yearly tick without storylet | ≤ 16.7 ms | 33 ms | `Yearly Tick` Points of Interest interval |
| Yearly tick with event/recovery/mortality | ≤ 33 ms | 50 ms | `Yearly Tick` interval, classified by resulting state |
| Persistence enqueue on interaction path | ≤ 1 ms | 2 ms | Time Profiler/main-thread inspection |
| Background JSON encode + atomic write | ≤ 50 ms | 100 ms | `Background Save` Points of Interest interval |
| Warm local save load + migration | ≤ 50 ms | 100 ms | `Save Load` Points of Interest interval |
| Core life-state growth | bounded | no monotonic leak | history ≤ 40, recent events ≤ 6, compact NPC directory |

The p95 gates require at least 100 repetitions after five warm-up iterations. Report median, p95, maximum, device model, OS version, and Release commit. Simulator results are regression evidence only; a lower-end supported physical device is the release authority.

## Existing structural controls

- `execute(_:)` synchronously returns the exact `ActionOutcome` published to the UI.
- Persistence begins only after outcome creation and runs on a serial utility queue.
- `SystemRegistry` keeps core yearly systems active and hibernates mortality/social until state makes them influential.
- The instant activation plan wakes only effects/narrative plus relevant progression, influence, social, or recovery processors; empty effect ranges return without RNG draws or mutations.
- Registries and visible-action queries are bounded; available actions cache by domain and invalidate on commit.
- History and narrative anti-repeat memory are capped during state clamping.

## Release profiling flow

1. Build Release with Points of Interest enabled.
2. Record one focused action-card tap and one Age Up transition with ETTrace/Instruments.
3. Process the trace and inspect `Instant Action` and `Yearly Tick` intervals plus hottest symbolicated stacks.
4. Repeat the focused flow 100 times for percentile evidence.
5. Fail the gate if any inactive domain appears on a hot path or if blocking persistence work appears on the main thread.

## Current evidence status

`Scripts/run_core_probe.sh` compiles the production core sources as an optimized native executable, excludes five warm-ups, drains background persistence outside timed intervals, and measures 5,000 synchronous actions distributed across all 20 registry entries plus 250 yearly ticks. Quiet-host repeats on July 29, 2026 measured action p95 at 0.121–0.138 ms and yearly-tick p95 at 0.510–0.654 ms. This is strong persistence-inclusive engine-regression evidence and sits far below the frame budgets, but it is not an iOS UI or device authority.

Numeric ETTrace evidence is still pending physical-device access. The paired iPhone 16 Pro Max runs iOS 26.3 beta build 23D127 with Developer Mode enabled, but Xcode 26.4 reports DDI services unavailable and rejects the developer-image mount. A matching phone/Xcode combination—and ultimately a lower-end supported physical device—remains the release authority.
